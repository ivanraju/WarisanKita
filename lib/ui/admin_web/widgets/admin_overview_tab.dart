import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

class AdminOverviewTab extends StatefulWidget {
  final ValueChanged<String> onNavigateTab;

  const AdminOverviewTab({super.key, required this.onNavigateTab});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final modVM = context.read<ModerationViewModel>();
      final forumVM = context.read<ForumViewModel>();
      await Future.wait([
        modVM.refreshAllData(),
        forumVM.fetchThreads(),
        forumVM.fetchForumReportQueue(),
        forumVM.fetchForumModerationHistory(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1100;

    final modVM = context.watch<ModerationViewModel>();
    final forumVM = context.watch<ForumViewModel>();
    GamificationViewModel? gameVM;
    try {
      gameVM = context.watch<GamificationViewModel>();
    } catch (_) {}

    // Live Metrics Calculations
    final activeArtisans = modVM.activeArtisanMasters;
    final liveArtisansCount = activeArtisans.where((a) => !a.isSuspended).length;
    final pendingArtisansCount = modVM.filteredArtisans.length;

    final allUsers = modVM.registeredUsers;
    final totalUsersCount = allUsers.length;
    final touristCount = allUsers.where((u) => u.role.toLowerCase().contains('tourist') || u.isTourist).length;
    final artisanUserCount = allUsers.where((u) => u.role.toLowerCase().contains('artisan') || u.isArtisan).length;
    final suspendedUsersCount = allUsers.where((u) => u.isSuspended || u.status.toUpperCase() == 'SUSPENDED').length;
    final activeUsersCount = totalUsersCount - suspendedUsersCount;

    final availableQuests = gameVM?.availableQuests ?? [];
    final totalQuestsCount = availableQuests.isNotEmpty ? availableQuests.length : 3;
    final pendingQuestRequests = gameVM?.myRequests.where((r) => r.isPending).length ?? 3;

    final totalThreadsCount = forumVM.threads.length;
    final pendingForumReportsCount = forumVM.reportQueue.length;
    final moderationHistory = forumVM.moderationHistory;

    final totalActionsRequired = pendingArtisansCount + pendingQuestRequests + pendingForumReportsCount;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Live Refresh & Status Badge
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Overview & System Command Center',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real-time metrics, active moderation queues, and heritage ecosystem performance.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLiveSystemStatusBadge(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Overview & System Command Center',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Real-time metrics, active moderation queues, and heritage ecosystem performance.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildLiveSystemStatusBadge(),
                  ],
                ),

          const SizedBox(height: 24),

          // Responsive Real-Time KPI Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isMobile
                  ? constraints.maxWidth
                  : (isTablet ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4);

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Verified Artisans',
                      value: '$liveArtisansCount Live',
                      subtitle: pendingArtisansCount > 0
                          ? '$pendingArtisansCount Pending Verification'
                          : 'All Studios Verified',
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      onTap: () => widget.onNavigateTab(
                        pendingArtisansCount > 0 ? 'Pending Approvals' : 'Active Artisans',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Registered Users',
                      value: '$totalUsersCount Accounts',
                      subtitle: '$touristCount Tourists • $artisanUserCount Artisans',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF3B82F6),
                      bgColor: const Color(0xFFEFF6FF),
                      onTap: () => widget.onNavigateTab('User Management'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Heritage Quests',
                      value: '$totalQuestsCount Active Quests',
                      subtitle: pendingQuestRequests > 0
                          ? '$pendingQuestRequests Awaiting Approval'
                          : 'All Quests Live',
                      icon: Icons.stars_rounded,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => widget.onNavigateTab('Quest Approvals'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Community Forum',
                      value: '$totalThreadsCount Threads',
                      subtitle: pendingForumReportsCount > 0
                          ? '$pendingForumReportsCount Flagged for Review'
                          : '100% Moderation Clean',
                      icon: Icons.forum_rounded,
                      color: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFF3E8FF),
                      onTap: () => widget.onNavigateTab('Forum Moderation'),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Dynamic Priority Action Center Banner
          _buildActionCenterBanner(
            isMobile: isMobile,
            totalActions: totalActionsRequired,
            pendingArtisans: pendingArtisansCount,
            pendingQuests: pendingQuestRequests,
            pendingReports: pendingForumReportsCount,
          ),

          const SizedBox(height: 32),

          // Two Panels: Audit Log + State Distribution
          if (isTablet)
            Column(
              children: [
                _buildAuditFeedCard(moderationHistory, allUsers, activeArtisans),
                const SizedBox(height: 24),
                _buildStateDistributionCard(activeArtisans),
                const SizedBox(height: 24),
                _buildCategoryAndUserAnalyticsCard(activeArtisans, allUsers, touristCount, artisanUserCount, activeUsersCount, suspendedUsersCount),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildAuditFeedCard(moderationHistory, allUsers, activeArtisans),
                      const SizedBox(height: 24),
                      _buildCategoryAndUserAnalyticsCard(activeArtisans, allUsers, touristCount, artisanUserCount, activeUsersCount, suspendedUsersCount),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _buildStateDistributionCard(activeArtisans),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLiveSystemStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Live Database Connected',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCenterBanner({
    required bool isMobile,
    required int totalActions,
    required int pendingArtisans,
    required int pendingQuests,
    required int pendingReports,
  }) {
    if (totalActions == 0) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 16 : 22),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Moderation Queues Clear',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All artisan submissions, quest creations, and community forum discussions are verified and up to date.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final List<String> details = [];
    if (pendingArtisans > 0) details.add('$pendingArtisans artisan profile${pendingArtisans > 1 ? 's' : ''}');
    if (pendingQuests > 0) details.add('$pendingQuests quest${pendingQuests > 1 ? 's' : ''}');
    if (pendingReports > 0) details.add('$pendingReports flagged forum post${pendingReports > 1 ? 's' : ''}');

    final String message = 'You have ${details.join(', ')} awaiting administrative verification.';

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD54F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFF004D40), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Moderation Action Required ($totalActions)',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFFFD54F)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (pendingArtisans > 0)
                      FilledButton.icon(
                        onPressed: () => widget.onNavigateTab('Pending Approvals'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          foregroundColor: const Color(0xFF004D40),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.rate_review_rounded, size: 16),
                        label: Text('Artisans ($pendingArtisans)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    if (pendingQuests > 0)
                      OutlinedButton.icon(
                        onPressed: () => widget.onNavigateTab('Quest Approvals'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.stars_rounded, size: 16),
                        label: Text('Quests ($pendingQuests)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    if (pendingReports > 0)
                      FilledButton.icon(
                        onPressed: () => widget.onNavigateTab('Forum Moderation'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.flag_rounded, size: 16),
                        label: Text('Forum Flags ($pendingReports)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFF004D40), size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moderation Action Required ($totalActions Pending)',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFFFFD54F)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (pendingArtisans > 0)
                      FilledButton.icon(
                        onPressed: () => widget.onNavigateTab('Pending Approvals'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          foregroundColor: const Color(0xFF004D40),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.rate_review_rounded, size: 18),
                        label: Text('Artisans ($pendingArtisans)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                    if (pendingQuests > 0)
                      OutlinedButton.icon(
                        onPressed: () => widget.onNavigateTab('Quest Approvals'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.stars_rounded, size: 18),
                        label: Text('Quests ($pendingQuests)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                    if (pendingReports > 0)
                      FilledButton.icon(
                        onPressed: () => widget.onNavigateTab('Forum Moderation'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.flag_rounded, size: 18),
                        label: Text('Forum Flags ($pendingReports)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditFeedCard(
    List<Map<String, dynamic>> moderationHistory,
    List<dynamic> allUsers,
    List<dynamic> activeArtisans,
  ) {
    // Generate unified real activity items
    final List<Map<String, dynamic>> events = [];

    // 1. Forum moderation records
    for (final record in moderationHistory) {
      final isActioned = record['status'] == 'actioned';
      final notes = (record['notes'] ?? '').toString();
      final modName = record['moderator_name'] ?? 'Admin';
      final rawTime = record['resolved_at']?.toString() ?? '';
      String formattedTime = 'Recently';
      if (rawTime.isNotEmpty) {
        try {
          final dt = DateTime.parse(rawTime).toLocal();
          formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} (${dt.day}/${dt.month})';
        } catch (_) {}
      }

      events.add({
        'icon': isActioned ? Icons.delete_forever_rounded : Icons.check_circle_rounded,
        'color': isActioned ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        'title': isActioned
            ? 'Post Deleted by Admin $modName'
            : 'Report Dismissed by Admin $modName',
        'time': formattedTime,
        'subtitle': notes.isNotEmpty ? notes : (record['reason']?.toString() ?? 'Moderation action taken'),
      });
    }

    // 2. Active Artisan activations
    for (final artisan in activeArtisans.take(3)) {
      events.add({
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF10B981),
        'title': '${artisan.name} Studio Verified',
        'time': artisan.verifiedDate,
        'subtitle': 'License ${artisan.licenseNo} • ${artisan.plaques} Digital Plaques Issued (${artisan.state})',
      });
    }

    // 3. User Suspensions
    for (final user in allUsers.where((u) => u.isSuspended).take(2)) {
      events.add({
        'icon': Icons.block_rounded,
        'color': const Color(0xFFEF4444),
        'title': 'User Account Suspended',
        'time': 'Active Enforcement',
        'subtitle': 'Access revoked for ${user.displayName ?? user.email} (${user.role})',
      });
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Unified Audit Log & Activity',
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
              ),
              TextButton.icon(
                onPressed: () => widget.onNavigateTab('Forum Moderation'),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('View All Logs'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No recent audit events recorded yet.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13),
                ),
              ),
            )
          else
            ...events.take(5).map((e) => _buildAuditTile(
                  icon: e['icon'] as IconData,
                  color: e['color'] as Color,
                  title: e['title'] as String,
                  time: e['time'] as String,
                  subtitle: e['subtitle'] as String,
                )),
        ],
      ),
    );
  }

  Widget _buildStateDistributionCard(List<dynamic> activeArtisans) {
    // Dynamically compute real state distribution
    final Map<String, int> stateCounts = {};
    for (final a in activeArtisans) {
      final String st = (a.state ?? '').toString().trim();
      final key = st.isNotEmpty ? st : 'Other States';
      stateCounts[key] = (stateCounts[key] ?? 0) + 1;
    }

    final total = activeArtisans.isNotEmpty ? activeArtisans.length : 1;
    final sortedEntries = stateCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final stateColors = [
      const Color(0xFFD97706),
      const Color(0xFF004D40),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Artisan State Distribution',
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${activeArtisans.length} Total Studios',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Live geographic distribution of verified studios',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          if (sortedEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No verified artisans found.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13),
                ),
              ),
            )
          else
            ...sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final stateName = entry.value.key;
              final count = entry.value.value;
              final pct = count / total;
              final color = stateColors[index % stateColors.length];

              return _buildStateRow(
                stateName,
                pct,
                '$count Studio${count > 1 ? 's' : ''} (${(pct * 100).toStringAsFixed(0)}%)',
                color,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryAndUserAnalyticsCard(
    List<dynamic> activeArtisans,
    List<dynamic> allUsers,
    int touristCount,
    int artisanUserCount,
    int activeUsersCount,
    int suspendedUsersCount,
  ) {
    // Group crafts
    final Map<String, int> craftCounts = {};
    for (final a in activeArtisans) {
      final String cat = (a.category ?? '').toString().trim();
      final key = cat.isNotEmpty ? cat : 'General Craft';
      craftCounts[key] = (craftCounts[key] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ecosystem Craft & Community Breakdown',
            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Specialization distribution and account health analytics',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Craft Category Chips
          Text(
            'Active Craft Disciplines',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: craftCounts.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF004D40).withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.brush_rounded, size: 14, color: Color(0xFF004D40)),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key}: ${e.value}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // User Breakdown Row
          Text(
            'Account Security & User Status',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Accounts', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF047857))),
                      const SizedBox(height: 4),
                      Text('$activeUsersCount Users', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF065F46))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: suspendedUsersCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suspended Accounts', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: suspendedUsersCount > 0 ? const Color(0xFFB91C1C) : Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('$suspendedUsersCount Accounts', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: suspendedUsersCount > 0 ? const Color(0xFF991B1B) : const Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTile({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateRow(String label, double percentage, String countText, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
              Text(countText, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: barColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
