import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_forum_moderation_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_quest_approvals_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_sidebar.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_overview_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_active_artisans_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/pending_artisans_table.dart';
import 'package:warisan_kita/ui/admin_web/widgets/user_management_table.dart';
import 'package:warisan_kita/ui/auth/login_screen.dart';

class AdminModerationDashboardView extends StatefulWidget {
  const AdminModerationDashboardView({super.key});

  @override
  State<AdminModerationDashboardView> createState() => _AdminModerationDashboardViewState();
}

class _AdminModerationDashboardViewState extends State<AdminModerationDashboardView> {
  bool _isVerifyingSession = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authVM = context.read<AuthViewModel>();
      UserModel? user = authVM.currentUser ?? await authVM.restoreSession();

      if (!mounted) return;

      if (user == null || !user.isAdmin) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      setState(() {
        _isVerifyingSession = false;
      });

      context.read<ModerationViewModel>().refreshAllData();
    });
  }

  Future<void> _handleApprove(BuildContext context, PendingArtisanProfile artisan) async {
    final vm = context.read<ModerationViewModel>();
    final success = await vm.approveArtisan(artisan.id);

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PROFILE APPROVED SUCCESSFULLY (${artisan.name})',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          width: 480,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  vm.artisanApprovalError ?? 'Approval failed. Please check artisan quest state.',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          width: 480,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context, PendingArtisanProfile artisan, [String? reason]) async {
    final vm = context.read<ModerationViewModel>();
    await vm.rejectArtisan(artisan.id, reason: reason);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason != null && reason.trim().isNotEmpty
                    ? 'PROFILE REJECTED (${artisan.name}): "$reason"'
                    : 'PROFILE REJECTED (${artisan.name})',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 520,
      ),
    );
  }

  void _handleSuspendUser(BuildContext context, UserModel user) {
    final authVm = context.read<AuthViewModel>();
    final currentAdminEmail = authVm.currentUser?.email ?? '';

    // Enforce C2: Administrator accounts are strictly protected from suspension
    if (user.isAdmin ||
        user.role.toLowerCase().contains('admin') ||
        user.email.toLowerCase() == currentAdminEmail.toLowerCase() ||
        user.email.toLowerCase() == 'admin@warisankita.my' ||
        user.username?.toLowerCase() == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('ADMIN SECURITY RESTRICTION: ADMINISTRATOR ACCOUNTS ARE PROTECTED AND CANNOT BE SUSPENDED'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          width: 560,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 10),
              Text(
                'Suspend User Account',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to suspend ${user.displayName ?? user.email}? This will immediately invalidate their active sessions.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final vm = context.read<ModerationViewModel>();
                vm.suspendUser(user.id);
                Navigator.pop(dialogCtx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('USER ACCOUNT SUSPENDED: Login access revoked (${user.displayName ?? user.email})'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    width: 480,
                  ),
                );
              },
              child: const Text('CONFIRM SUSPENSION', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleReactivateUser(BuildContext context, UserModel user) {
    final vm = context.read<ModerationViewModel>();
    vm.reactivateUser(user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('USER ACCOUNT REACTIVATED SUCCESSFULLY (${user.displayName ?? user.email})'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 480,
      ),
    );
  }

  void _handleResetPassword(BuildContext context, UserModel user) {
    if (user.isAdmin ||
        user.role.toLowerCase().contains('admin') ||
        user.email.toLowerCase() == 'admin@warisankita.my' ||
        user.username?.toLowerCase() == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('ADMIN SECURITY RESTRICTION: Administrator credentials cannot be reset via moderation console.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          width: 560,
        ),
      );
      return;
    }

    final vm = context.read<ModerationViewModel>();
    vm.sendPasswordResetEmail(user.email);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('PASSWORD RESET EMAIL SENT TO ${user.email}'),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 520,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    if (_isVerifyingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
          ),
        ),
      );
    }

    if (authVM.currentUser == null || !authVM.currentUser!.isAdmin) {
      return const LoginScreen();
    }

    ModerationViewModel? globalVM;
    try {
      globalVM = context.watch<ModerationViewModel>();
    } catch (_) {}

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isMobile = screenWidth < 650;

    return ChangeNotifierProvider.value(
      value: globalVM ?? ModerationViewModel(),
      child: Consumer<ModerationViewModel>(
        builder: (context, viewModel, child) {
          final isUserManagementTab = viewModel.activeTab == 'User Management';

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            drawer: !isDesktop
                ? Drawer(
                    child: AdminSidebar(
                      activeTab: viewModel.activeTab,
                      onTabSelected: (tab) => viewModel.setActiveTab(tab),
                    ),
                  )
                : null,
            body: Row(
              children: [
                // Left side: Persistent sidebar on Desktop
                if (isDesktop)
                  SizedBox(
                    width: 260,
                    child: AdminSidebar(
                      activeTab: viewModel.activeTab,
                      onTabSelected: (tab) => viewModel.setActiveTab(tab),
                    ),
                  ),

                // Right side: Main content area
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        // Top Navbar / User bar
                        _buildTopHeaderBar(context, isDesktop),

                        // Main Scrollable Area
                        Expanded(
                          child: viewModel.activeTab == 'Overview'
                              ? AdminOverviewTab(onNavigateTab: (tab) => viewModel.setActiveTab(tab))
                              : viewModel.activeTab == 'Active Artisans'
                                  ? const AdminActiveArtisansTab()
                                  : viewModel.activeTab == 'Quest Approvals'
                                      ? const AdminQuestApprovalsTab()
                                      : viewModel.activeTab == 'Forum Moderation'
                                          ? const AdminForumModerationTab()
                                          : SingleChildScrollView(
                                  padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title & Subtitle Header
                                      Text(
                                        isUserManagementTab ? 'Registered User Management' : 'Pending Artisan Profiles & Relocations',
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: isMobile ? 24 : 32,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isUserManagementTab
                                            ? 'Manage, monitor, and suspend active tourist and artisan accounts.'
                                            : 'Review, verify, and approve traditional Malaysian artisan profile submissions and workshop premise relocations.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: isMobile ? 12 : 14,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // Summary Metric Cards Row
                                      _buildMetricsRow(context, viewModel, isUserManagementTab),

                                      const SizedBox(height: 28),

                                      // Controls Row
                                      if (isUserManagementTab)
                                        _buildUserFilterControlsRow(context, viewModel)
                                      else
                                        _buildFilterControlsRow(context, viewModel),
                                      const SizedBox(height: 20),

                                      // Main Data Table Component
                                      isUserManagementTab
                                          ? UserManagementTable(
                                              users: viewModel.filteredUsers,
                                              onSuspend: (user) => _handleSuspendUser(context, user),
                                              onReactivate: (user) => _handleReactivateUser(context, user),
                                              onResetPassword: (user) => _handleResetPassword(context, user),
                                            )
                                          : PendingArtisansTable(
                                              artisans: viewModel.filteredArtisans,
                                              onApprove: (artisan) => _handleApprove(context, artisan),
                                              onReject: (artisan, reason) => _handleReject(context, artisan, reason),
                                            ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeaderBar(BuildContext context, bool isDesktop) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (!isDesktop)
                  Builder(
                    builder: (scaffoldCtx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Color(0xFF334155)),
                      onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
                      tooltip: 'Open Menu',
                    ),
                  ),
                const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Moderation Center',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                tooltip: 'Refresh Moderation & User Data',
                onPressed: () async {
                  final modVM = context.read<ModerationViewModel>();
                  final forumVM = context.read<ForumViewModel>();
                  await Future.wait([
                    modVM.refreshAllData(),
                    forumVM.fetchThreads(),
                    forumVM.fetchForumReportQueue(),
                    forumVM.fetchForumModerationHistory(),
                  ]);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All platform data refreshed!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
                  onPressed: () {
                    final pendingCount = context.read<ModerationViewModel>().pendingArtisans.length;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              pendingCount > 0
                                  ? '$pendingCount pending artisan application(s) awaiting review.'
                                  : 'All caught up! No pending moderation tasks.',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Notifications',
                ),
              ],
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthViewModel>().logout();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Admin session ended successfully.',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, ModerationViewModel viewModel, bool isUserManagement) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 800;

    final cards = isUserManagement
        ? [
            _buildMetricCard(
              title: 'Total Users',
              value: viewModel.registeredUsers.length.toString(),
              subtitle: 'Active platform accounts',
              icon: Icons.people_outline_rounded,
              accentColor: const Color(0xFF2563EB),
            ),
            _buildMetricCard(
              title: 'Tourists',
              value: viewModel.registeredUsers.where((u) => u.role.toLowerCase().contains('tourist')).length.toString(),
              subtitle: 'Cultural explorers',
              icon: Icons.explore_outlined,
              accentColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Artisans',
              value: viewModel.registeredUsers.where((u) => u.role.toLowerCase().contains('artisan')).length.toString(),
              subtitle: 'Verified studio masters',
              icon: Icons.storefront_outlined,
              accentColor: const Color(0xFFD97706),
            ),
          ]
        : [
            _buildMetricCard(
              title: 'Pending Applications',
              value: viewModel.totalPendingCount.toString(),
              subtitle: viewModel.pendingRelocationCount > 0
                  ? '${viewModel.pendingNewProfilesCount} new • ${viewModel.pendingRelocationCount} relocations'
                  : 'Requires admin review',
              icon: Icons.pending_actions_rounded,
              accentColor: const Color(0xFFF59E0B),
            ),
            _buildMetricCard(
              title: 'Approved Today',
              value: viewModel.approvedTodayCount.toString(),
              subtitle: viewModel.approvedTodaySubtitle,
              icon: Icons.check_circle_rounded,
              accentColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Avg. Review Time',
              value: viewModel.averageReviewTime,
              subtitle: viewModel.averageReviewTimeSubtitle,
              icon: Icons.timer_outlined,
              accentColor: const Color(0xFF3B82F6),
            ),
          ];

    if (isCompact) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControlsRow(BuildContext context, ModerationViewModel viewModel) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final typeFilterPills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTypeFilterChip(
          label: 'All Requests',
          count: viewModel.pendingArtisans.length,
          isSelected: viewModel.applicationTypeFilter == 'All',
          onTap: () => viewModel.setApplicationTypeFilter('All'),
        ),
        _buildTypeFilterChip(
          label: 'New Profiles',
          count: viewModel.pendingNewProfilesCount,
          isSelected: viewModel.applicationTypeFilter == 'New Profiles',
          onTap: () => viewModel.setApplicationTypeFilter('New Profiles'),
        ),
        _buildTypeFilterChip(
          label: 'Premise Relocations',
          count: viewModel.pendingRelocationCount,
          isSelected: viewModel.applicationTypeFilter == 'Relocations',
          highlightColor: const Color(0xFFF59E0B),
          icon: Icons.swap_horiz_rounded,
          onTap: () => viewModel.setApplicationTypeFilter('Relocations'),
        ),
      ],
    );

    final searchInput = SizedBox(
      height: 44,
      child: TextField(
        onChanged: (val) => viewModel.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search by studio or artisan name, state, or email...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF10B981)),
          ),
        ),
      ),
    );

    final categoryDropdown = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              onChanged: (val) {
                if (val != null) viewModel.setSelectedCategory(val);
              },
              items: viewModel.categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          typeFilterPills,
          const SizedBox(height: 14),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchInput,
                const SizedBox(height: 12),
                categoryDropdown,
              ],
            )
          else
            Row(
              children: [
                Expanded(child: searchInput),
                const SizedBox(width: 16),
                categoryDropdown,
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color highlightColor = const Color(0xFF10B981),
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? highlightColor.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? highlightColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? highlightColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (highlightColor == const Color(0xFFF59E0B)
                        ? const Color(0xFFB45309)
                        : highlightColor)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? highlightColor : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFilterControlsRow(BuildContext context, ModerationViewModel viewModel) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final searchInput = SizedBox(
      height: 44,
      child: TextField(
        onChanged: (val) => viewModel.setUserSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search by user name, email, or @handle...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF10B981)),
          ),
        ),
      ),
    );

    final roleDropdown = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.userRoleFilter,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              onChanged: (val) {
                if (val != null) viewModel.setUserRoleFilter(val);
              },
              items: viewModel.userRoles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    final statusDropdown = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.userStatusFilter,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              onChanged: (val) {
                if (val != null) viewModel.setUserStatusFilter(val);
              },
              items: viewModel.userStatuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchInput,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    roleDropdown,
                    statusDropdown,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: searchInput),
                const SizedBox(width: 16),
                roleDropdown,
                const SizedBox(width: 16),
                statusDropdown,
              ],
            ),
    );
  }
}
