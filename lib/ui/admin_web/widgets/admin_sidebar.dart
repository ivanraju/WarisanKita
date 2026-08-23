import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

class AdminSidebar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabSelected;

  const AdminSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    ModerationViewModel? modVM;
    try {
      modVM = context.watch<ModerationViewModel>();
    } catch (_) {}

    final user = authVM.currentUser;
    final username = user?.effectiveUsername ?? 'Admin';
    final email = user?.email ?? 'admin@warisankita.my';
    final initials = user?.initials ?? 'AD';
    final pendingCount = modVM?.totalPendingCount ?? 5;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A), // Dark slate theme for professional admin navigation
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portal Brand Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WARISAN KITA',
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Admin Portal v1.0',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Navigation Links
          _buildNavItem(
            context,
            icon: Icons.dashboard_rounded,
            tabId: 'Overview',
            label: 'Overview & Analytics',
          ),
          const SizedBox(height: 4),
          _buildNavItem(
            context,
            icon: Icons.verified_user_rounded,
            tabId: 'Pending Approvals',
            label: 'Artisan Verification',
            badgeText: pendingCount > 0 ? '$pendingCount PENDING' : 'CLEAR',
          ),
          const SizedBox(height: 4),
          _buildNavItem(
            context,
            icon: Icons.storefront_rounded,
            tabId: 'Active Artisans',
            label: 'Active Artisans',
          ),
          const SizedBox(height: 4),
          _buildNavItem(
            context,
            icon: Icons.manage_accounts_rounded,
            tabId: 'User Management',
            label: 'User Management',
          ),
          const SizedBox(height: 4),
          _buildNavItem(
            context,
            icon: Icons.stars_rounded,
            tabId: 'Quest Approvals',
            label: 'Quest Moderation',
            badgeText: '2 NEW',
          ),
          const SizedBox(height: 4),
          _buildNavItem(
            context,
            icon: Icons.forum_rounded,
            tabId: 'Forum Moderation',
            label: 'Community Forum',
            badgeText: 'FLAGGED',
          ),
          const SizedBox(height: 4),
          _buildNavItem(
            context,
            icon: Icons.settings_rounded,
            tabId: 'Settings',
            label: 'System Settings',
          ),

          const Spacer(),

          // Bottom Admin Profile Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        softWrap: true,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                  tooltip: 'Admin Logout',
                  onPressed: () async {
                    await authVM.logout();
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String tabId,
    required String label,
    String? badgeText,
  }) {
    final bool isSelected = activeTab == tabId || activeTab == label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            onTabSelected(tabId);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF38BDF8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}