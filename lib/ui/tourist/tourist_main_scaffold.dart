import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/ui/core/account_suspended_screen.dart';
import 'package:warisan_kita/ui/matchmaker/tourist_matchmaker_view.dart';
import 'package:warisan_kita/ui/core/live_forum_tab.dart';
import 'package:warisan_kita/ui/tourist/tourist_directory_tab.dart';
import 'package:warisan_kita/ui/tourist/tourist_profile_tab.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/map_viewmodel.dart';

class TouristMainScaffold extends StatefulWidget {
  final bool enableLivePolling;
  const TouristMainScaffold({super.key, this.enableLivePolling = true});

  @override
  State<TouristMainScaffold> createState() => _TouristMainScaffoldState();
}

class _TouristMainScaffoldState extends State<TouristMainScaffold> {
  int _currentIndex = 0;
  Timer? _statusPollTimer;
  bool _journeyRestoreScheduled = false;
  bool _isRejectionBannerDismissed = false;

  bool _rejectionDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await context.read<AuthViewModel>().refreshCurrentUser();
        if (mounted) {
          _checkRejectionBannerDismissed();
          _checkAndShowRejectionDialog();
        }
      }
    });
    if (widget.enableLivePolling) {
      _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (mounted) {
          final auth = context.read<AuthViewModel>();
          if (auth.currentUser != null && !auth.currentUser!.isSuspended) {
            await auth.refreshCurrentUser();
            if (mounted) {
              _checkAndShowRejectionDialog();
            }
          }
        }
      });
    }
  }

  Future<void> _checkRejectionBannerDismissed() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool('dismissed_rejection_banner_${user.id}') ?? false;
      if (mounted && dismissed) {
        setState(() => _isRejectionBannerDismissed = true);
      }
    }
  }

  Future<void> _checkAndShowRejectionDialog() async {
    if (_rejectionDialogShowing || !mounted) return;
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null && user.isRejectedArtisan) {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('shown_rejection_dialog_${user.id}') ?? false;
      if (!shown && mounted) {
        _rejectionDialogShowing = true;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
            final studioName = (user.studioName != null && user.studioName!.trim().isNotEmpty)
                ? user.studioName!.trim()
                : 'your studio';
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_late_outlined,
                      color: Color(0xFFEF4444),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Application Update',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3F161A) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: const Text(
                      'REQUIRES REVISION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Your Master Artisan application for "$studioName" was reviewed by Kraftangan Malaysia. Some documents or details require revision before your studio can be approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await prefs.setBool('shown_rejection_dialog_${user.id}', true);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () async {
                          await prefs.setBool('shown_rejection_dialog_${user.id}', true);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ArtisanApplicationPendingScreen(
                                  studioName: user.studioName ?? 'Your Craft Studio',
                                  craftCategory: user.craftCategory ?? 'Malaysian Heritage Craft',
                                  ssmNumber: user.ssmNumber ?? 'Pending Document Verification',
                                ),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Review & Re-apply',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
        _rejectionDialogShowing = false;
      }
    }
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    // Security Guard: If account is administratively suspended, immediately lock out
    if (user != null && (user.isSuspended || user.status == 'SUSPENDED')) {
      return const AccountSuspendedScreen();
    }

    if (user == null) {
      if (!authVM.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              ModalRoute.of(context)?.isCurrent == true &&
              context.read<AuthViewModel>().currentUser == null) {
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _scheduleJourneyRestoration();

    final langVM = context.watch<LanguageViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArtisanRejected = user.isRejectedArtisan;
    if (isArtisanRejected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAndShowRejectionDialog();
        }
      });
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF041412)
          : const Color(0xFFF8F9FA),
      extendBody: true,
      body: Column(
        children: [
          if (isArtisanRejected && !_isRejectionBannerDismissed)
            Material(
              color: isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2),
              elevation: 2,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF5C1D24) : const Color(0xFFFCA5A5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Artisan Application Not Approved',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                              ),
                            ),
                            Text(
                              'Kraftangan review required document updates.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArtisanApplicationPendingScreen(
                                studioName: user.studioName ?? '',
                                craftCategory: user.craftCategory ?? '',
                                ssmNumber: user.ssmNumber ?? '',
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Review',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                        ),
                        tooltip: 'Dismiss message',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () async {
                          setState(() => _isRejectionBannerDismissed = true);
                          final prefs = await SharedPreferences.getInstance();
                          final uid = context.read<AuthViewModel>().currentUser?.id;
                          if (uid != null) {
                            await prefs.setBool('dismissed_rejection_banner_$uid', true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const TouristDirectoryTab(),
                TouristMatchmakerView(isActive: _currentIndex == 1),
                const LiveForumTab(),
                const TouristProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2825) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF004D40).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E3A34)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: langVM.translate('Explore'),
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.near_me_outlined,
                activeIcon: Icons.near_me_rounded,
                label: langVM.translate('Matchmaker'),
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum_rounded,
                label: langVM.translate('Forum'),
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.badge_outlined,
                activeIcon: Icons.badge_rounded,
                label: langVM.translate('Passport'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleJourneyRestoration() {
    if (_journeyRestoreScheduled) return;
    _journeyRestoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gamificationViewModel = context.read<GamificationViewModel?>();
      final mapViewModel = context.read<MapViewModel?>();
      if (gamificationViewModel != null) {
        unawaited(gamificationViewModel.loadActiveQuestState());
      }
      if (mapViewModel != null) {
        unawaited(mapViewModel.loadJourneyData());
      }
    });
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004D40) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF004D40).withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? const Color(0xFFFFD54F) : Colors.white60,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
