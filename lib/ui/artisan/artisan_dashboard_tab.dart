import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/artisan/artisan_task_management_screen.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/ui/core/live_forum_tab.dart';
import 'package:warisan_kita/ui/artisan/artisan_settings_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/domain/models/artisan_heritage_analytics.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

class ArtisanDashboardTab extends StatefulWidget {
  const ArtisanDashboardTab({super.key});

  @override
  State<ArtisanDashboardTab> createState() => _ArtisanDashboardTabState();
}

class _ArtisanDashboardTabState extends State<ArtisanDashboardTab> {
  bool _isStudioOpen = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      _isStudioOpen = user.isLiveOpen;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GamificationViewModel>().loadArtisanHeritageAnalytics();
      }
    });
  }

  Future<void> _toggleStudioStatus(bool isOpen) async {
    setState(() => _isStudioOpen = isOpen);
    try {
      await context.read<AuthViewModel>().updateProfile(isLiveOpen: isOpen);
      if (mounted) {
        context.read<DirectoryViewModel>().fetchArtisans();
      }
    } catch (e) {
      if (mounted) {
        final user = context.read<AuthViewModel>().currentUser;
        setState(() => _isStudioOpen = user?.isLiveOpen ?? !isOpen);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update live demo status: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOpen
              ? '🟢 Studio Live Status: OPEN FOR EDUCATIONAL WALK-INS & DEMOS'
              : '🔴 Studio Live Status: CLOSED FOR DEMOS (VISITORS PAUSED)',
        ),
        backgroundColor: isOpen
            ? const Color(0xFF004D40)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final gamificationVM = context.watch<GamificationViewModel>();
    final user = authVM.currentUser;
    final studioName =
        user?.studioName ?? user?.displayName ?? 'Artisan Studio';
    final handle = user?.handle ?? (user?.effectiveUsername ?? '');
    final craft = user?.craftCategory ?? 'Heritage Craft';
    final initials = user?.initials ?? 'AS';
    final isStudioOpen = user != null ? user.isLiveOpen : _isStudioOpen;

    return HeritageBackground(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top App Bar
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Master Artisan Command Dashboard',
                style: GoogleFonts.dmSerifDisplay(
                  color: isDark
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFF004D40),
                  fontSize: 21,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFF004D40),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ArtisanSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏛️ MASTER HERITAGE GUILD & ACCREDITATION HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF0D2825), const Color(0xFF061A18)]
                            : [
                                const Color(0xFF0A192F),
                                const Color(0xFF004D40),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: isDark
                          ? Border.all(color: const Color(0xFF1E3A34))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF004D40).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFFFD54F),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      CircleAvatar(
                                        radius: 27,
                                        backgroundColor: const Color(
                                          0xFFFFD54F,
                                        ),
                                        child: Text(
                                          initials,
                                          style: GoogleFonts.dmSerifDisplay(
                                            color: const Color(0xFF004D40),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studioName,
                                          softWrap: true,
                                          style: GoogleFonts.dmSerifDisplay(
                                            color: Colors.white,
                                            fontSize: 22,
                                          ),
                                        ),
                                        Text(
                                          '@$handle • $craft',
                                          softWrap: true,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFFFFD54F),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Accreditation Badges Strip
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildHeaderBadge(
                              '🏆 Kraftangan Certified Master',
                              const Color(0xFFFFD54F),
                              const Color(0xFF004D40),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),

                        // Studio Live Availability Toggle Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Studio Live Cultural Status:',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    isStudioOpen
                                        ? '🟢 OPEN FOR EDUCATIONAL DEMOS'
                                        : '🔴 LIVE DEMOS PAUSED (CLOSED TO VISITORS)',
                                    softWrap: true,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isStudioOpen
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: isStudioOpen,
                              onChanged: _toggleStudioStatus,
                              activeThumbColor: const Color(0xFFFFD54F),
                              activeTrackColor: const Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ⚡ MASTER STUDIO MANAGEMENT ACTIONS
                  Text(
                    'Studio Management Portal',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.stars_rounded,
                          label: 'Manage Quests',
                          color: const Color(0xFFD97706),
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ArtisanTaskManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.history_edu_rounded,
                          label: 'Craft Portfolio',
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF004D40),
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileBuilderTab(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.forum_rounded,
                          label: 'Live Forum',
                          color: const Color(0xFF0284C7),
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LiveForumTab(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Heritage Preservation Metrics',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verified workshop arrivals and quest achievements',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeritageAnalytics(gamificationVM),
                  const SizedBox(height: 16),
                  // 📜 INFORMATIONAL HERITAGE PRESERVATION CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D2825)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E3A34)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF166534),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'National Heritage Accreditation Verified:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF14532D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your studio is recognized as an official Cultural Preservation Site by Kraftangan Malaysia. All completed quests contribute directly to national craft heritage documentation.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF166534),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: textCol,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D2825) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E3A34)
                : color.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeritageAnalytics(GamificationViewModel viewModel) {
    if (viewModel.isLoadingArtisanHeritageAnalytics &&
        viewModel.artisanHeritageAnalytics == null) {
      return _analyticsShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            5,
            (index) => Container(
              height: index == 4 ? 120 : 18,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );
    }

    final analytics = viewModel.artisanHeritageAnalytics;
    if (analytics == null) {
      return _analyticsShell(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFFFD54F)),
            const SizedBox(height: 10),
            Text(
              viewModel.artisanHeritageAnalyticsError ??
                  'Heritage analytics are currently unavailable.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: viewModel.loadArtisanHeritageAnalytics,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD54F),
                side: const BorderSide(color: Color(0xFFFFD54F)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final highestCount = analytics.dailyVisitors.fold<int>(
      0,
      (highest, day) => day.count > highest ? day.count : highest,
    );
    final highlightedIndex = analytics.highlightedDayIndex;
    final visitorWord = analytics.totalUniqueVisitors == 1
        ? 'Visitor'
        : 'Visitors';
    final completionProgress = analytics.completionProgress;

    return _analyticsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Verified Workshop Visitors',
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Last 7 Days',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFFFD54F),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${analytics.totalUniqueVisitors} $visitorWord',
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            analytics.totalUniqueVisitors == 0
                ? 'No verified workshop visits in this period.'
                : 'Unique tourists who reached your workshop',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            analytics.visitorSource == 'completed_quest'
                ? 'Verified from completed quests (arrival-task fallback)'
                : 'Verified from completed workshop arrival tasks',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF34D399)),
            ),
            child: Text(
              analytics.passportStampsAwarded == null
                  ? 'Passport Stamps Awarded · Unavailable'
                  : '${analytics.passportStampsAwarded} Passport Stamps Awarded',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6EE7B7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            completionProgress == null
                ? 'Tourist Quest Completions'
                : 'Quest Completion Goal',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            analytics.completedTourists == null
                ? 'Unavailable'
                : completionProgress == null
                ? '${analytics.completedTourists} Completed'
                : '${analytics.completedTourists} / ${analytics.completionTarget} Quests Completed',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (completionProgress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completionProgress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: Colors.white24,
              color: const Color(0xFFFFD54F),
            ),
            const SizedBox(height: 5),
            Text(
              completionProgress >= 1
                  ? 'Goal Achieved'
                  : '${(completionProgress * 100).round()}% Goal Progress',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFFFD54F),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 132,
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (_) => Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(analytics.dailyVisitors.length, (
                    index,
                  ) {
                    final day = analytics.dailyVisitors[index];
                    final highlighted = index == highlightedIndex;
                    final ratio = highestCount == 0
                        ? 0.0
                        : day.count / highestCount;
                    final height = day.count == 0 ? 4.0 : 18.0 + 58 * ratio;
                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showDailyVisitors(day),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${day.count}',
                              style: GoogleFonts.plusJakartaSans(
                                color: highlighted
                                    ? const Color(0xFFFFD54F)
                                    : Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 18,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: highlighted
                                    ? const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Color(0xFFF59E0B),
                                          Color(0xFFFFD54F),
                                        ],
                                      )
                                    : const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Color(0xFF00796B),
                                          Color(0xFF34D399),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _weekday(day.date),
                              style: GoogleFonts.plusJakartaSans(
                                color: highlighted
                                    ? const Color(0xFFFFD54F)
                                    : Colors.white70,
                                fontSize: 9,
                                fontWeight: highlighted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A192F), Color(0xFF063C36)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E5B52)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  void _showDailyVisitors(DailyVerifiedVisitors day) {
    final countLabel = day.count == 1 ? 'visitor' : 'visitors';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${day.date.day.toString().padLeft(2, '0')}/'
            '${day.date.month.toString().padLeft(2, '0')}/${day.date.year}: '
            '${day.count} $countLabel',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _weekday(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }
}
