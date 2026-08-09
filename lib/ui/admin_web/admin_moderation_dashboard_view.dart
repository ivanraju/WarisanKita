import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_forum_moderation_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_quest_approvals_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_sidebar.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_system_settings_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_overview_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_active_artisans_tab.dart';
import 'package:warisan_kita/ui/admin_web/widgets/pending_artisans_table.dart';
import 'package:warisan_kita/ui/admin_web/widgets/user_management_table.dart';

class AdminModerationDashboardView extends StatelessWidget {
  const AdminModerationDashboardView({super.key});

  void _handleApprove(BuildContext context, PendingArtisanProfile artisan) {
    final vm = context.read<ModerationViewModel>();
    vm.approveArtisan(artisan.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('PROFILE APPROVED SUCCESSFULLY (${artisan.name})'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 480,
      ),
    );
  }

  void _handleReject(BuildContext context, PendingArtisanProfile artisan) {
    final vm = context.read<ModerationViewModel>();
    vm.rejectArtisan(artisan.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('PROFILE REJECTED (${artisan.name})'),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 480,
      ),
    );
  }

  void _handleSuspendUser(BuildContext context, UserModel user) {
    final vm = context.read<ModerationViewModel>();
    vm.suspendUser(user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account for ${user.displayName ?? user.email} has been suspended.'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 480,
      ),
    );
  }

  void _handleReactivateUser(BuildContext context, UserModel user) {
    final vm = context.read<ModerationViewModel>();
    vm.reactivateUser(user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account for ${user.displayName ?? user.email} has been reactivated.'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 480,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ModerationViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Consumer<ModerationViewModel>(
          builder: (context, viewModel, child) {
            final isUserManagementTab = viewModel.activeTab == 'User Management';

            return Row(
              children: [
                // Left side: 20% width persistent sidebar
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.20,
                  child: AdminSidebar(
                    activeTab: viewModel.activeTab,
                    onTabSelected: (tab) => viewModel.setActiveTab(tab),
                  ),
                ),

                // Right side: 80% width main content area
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        // Top Navbar / User bar
                        _buildTopHeaderBar(context),

                        // Main Scrollable Area
                        Expanded(
                          child: viewModel.activeTab == 'Overview'
                              ? AdminOverviewTab(onNavigateTab: (tab) => viewModel.setActiveTab(tab))
                              : viewModel.activeTab == 'Active Artisans'
                                  ? const AdminActiveArtisansTab()
                                  : viewModel.activeTab == 'Quest Approvals'
                                      ? const AdminQuestApprovalsTab()
                                      : viewModel.activeTab == 'Settings'
                                          ? const AdminSystemSettingsTab()
                                          : viewModel.activeTab == 'Forum Moderation'
                                              ? const AdminForumModerationTab()
                                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title & Subtitle Header
                                      Text(
                                        isUserManagementTab ? 'Registered User Management' : 'Pending Artisan Profiles',
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isUserManagementTab
                                            ? 'Manage, monitor, and suspend active tourist and artisan accounts.'
                                            : 'Review, verify, and approve traditional Malaysian artisan profile submissions.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      // Summary Metric Cards Row
                                      _buildMetricsRow(viewModel, isUserManagementTab),

                                      const SizedBox(height: 32),

                                      if (!isUserManagementTab) ...[
                                        // Controls Row: Search Input + Craft Category Dropdown Filter
                                        _buildFilterControlsRow(context, viewModel),
                                        const SizedBox(height: 20),
                                      ],

                                      // Main Data Table Component
                                      isUserManagementTab
                                          ? UserManagementTable(
                                              users: viewModel.registeredUsers,
                                              onSuspend: (user) => _handleSuspendUser(context, user),
                                              onReactivate: (user) => _handleReactivateUser(context, user),
                                            )
                                          : PendingArtisansTable(
                                              artisans: viewModel.filteredArtisans,
                                              onApprove: (artisan) => _handleApprove(context, artisan),
                                              onReject: (artisan) => _handleReject(context, artisan),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeaderBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                'Moderation Center',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
                onPressed: () {},
                tooltip: 'Moderation Guidelines',
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthViewModel>().logout();
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
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildMetricsRow(ModerationViewModel viewModel, bool isUserManagement) {
    if (isUserManagement) {
      return Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Total Users',
              value: viewModel.registeredUsers.length.toString(),
              subtitle: 'Active platform accounts',
              icon: Icons.people_outline_rounded,
              accentColor: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              title: 'Tourists',
              value: viewModel.registeredUsers.where((u) => u.role == 'Tourist').length.toString(),
              subtitle: 'Cultural explorers',
              icon: Icons.explore_outlined,
              accentColor: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              title: 'Artisans',
              value: viewModel.registeredUsers.where((u) => u.role == 'Artisan').length.toString(),
              subtitle: 'Verified studio masters',
              icon: Icons.storefront_outlined,
              accentColor: const Color(0xFFD97706),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Pending Applications',
            value: viewModel.totalPendingCount.toString(),
            subtitle: 'Requires admin review',
            icon: Icons.pending_actions_rounded,
            accentColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            title: 'Approved Today',
            value: '12',
            subtitle: '+24% from yesterday',
            icon: Icons.check_circle_rounded,
            accentColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            title: 'Avg. Review Time',
            value: '1.4 days',
            subtitle: 'Target: < 2.0 days',
            icon: Icons.timer_outlined,
            accentColor: const Color(0xFF3B82F6),
          ),
        ),
      ],
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
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControlsRow(BuildContext context, ModerationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Search Input Bar
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                onChanged: (val) => viewModel.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search by artisan name, state, or email...',
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
            ),
          ),

          const SizedBox(width: 16),

          // Craft Category Dropdown Filter
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}
