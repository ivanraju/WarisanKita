import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/data/services/connectivity_service.dart';

/// Wraps the application viewport with a subtle, animated top banner
/// that informs users when network connectivity is lost or restored.
class OfflineBannerWrapper extends StatefulWidget {
  final Widget child;

  const OfflineBannerWrapper({
    super.key,
    required this.child,
  });

  @override
  State<OfflineBannerWrapper> createState() => _OfflineBannerWrapperState();
}

class _OfflineBannerWrapperState extends State<OfflineBannerWrapper> {
  Timer? _dismissTimer;
  bool _dismissedByUser = false;
  bool _isChecking = false;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _handleOnlineRecovery(ConnectivityService service) {
    if (_dismissTimer == null || !_dismissTimer!.isActive) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          service.clearWasOffline();
          setState(() {
            _dismissedByUser = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read connectivity service safely (null-safe in isolated widget tests)
    final connectivityService = context.watch<ConnectivityService?>();

    if (connectivityService == null) {
      return widget.child;
    }

    final isOffline = connectivityService.isOffline;
    final wasOffline = connectivityService.wasOffline;

    // Reset user dismissal if we transition to online
    if (!isOffline && wasOffline) {
      _handleOnlineRecovery(connectivityService);
    } else if (isOffline && _dismissTimer != null) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
    }

    final showOffline = isOffline && !_dismissedByUser;
    final showOnlineRestored = !isOffline && wasOffline;
    final isBannerVisible = showOffline || showOnlineRestored;

    return Stack(
      children: [
        // Main App Content
        widget.child,

        // Top Connectivity Alert Banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            offset: isBannerVisible ? const Offset(0, 0) : const Offset(0, -1.2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              opacity: isBannerVisible ? 1.0 : 0.0,
              child: Material(
                type: MaterialType.transparency,
                child: IgnorePointer(
                  ignoring: !isBannerVisible,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: showOffline
                          ? const Color(0xFFC2410C) // Terracotta / Amber Heritage
                          : const Color(0xFF004D40), // Malaysian Emerald
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      minimum: const EdgeInsets.only(top: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              showOffline
                                  ? Icons.wifi_off_rounded
                                  : Icons.wifi_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                showOffline
                                    ? "You're offline. Some features may be unavailable."
                                    : "Back online. Connection restored.",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showOffline) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _isChecking
                                    ? null
                                    : () async {
                                        setState(() => _isChecking = true);
                                        await connectivityService.checkConnectivity();
                                        if (mounted) {
                                          setState(() => _isChecking = false);
                                        }
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: _isChecking
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Check',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _dismissedByUser = true;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
