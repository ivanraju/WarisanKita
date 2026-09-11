import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().refreshCurrentUser();
      }
    });
    if (widget.enableLivePolling) {
      _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) {
          final auth = context.read<AuthViewModel>();
          if (auth.currentUser != null && !auth.currentUser!.isSuspended) {
            auth.refreshCurrentUser();
          }
        }
      });
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

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF041412)
          : const Color(0xFFF8F9FA),
      extendBody: true,
      body: Column(
        children: [
          if (isArtisanRejected)
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
