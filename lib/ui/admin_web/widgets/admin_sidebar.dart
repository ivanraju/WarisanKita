import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WarisanKita',
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Admin Portal v1.0',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Section Title Label
          Text(
            'NAVIGATION',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Menu Links
          _buildNavItem(
            icon: Icons.dashboard_rounded,
            label: 'Overview',
            badgeText: null,
          ),
          _buildNavItem(
            icon: Icons.rate_review_rounded,
            label: 'Pending Approvals',
            badgeText: '5',
          ),
          _buildNavItem(
            icon: Icons.stars_rounded,
            label: 'Quest Approvals',
            badgeText: '3',
          ),
          _buildNavItem(
            icon: Icons.forum_rounded,
            label: 'Forum Moderation',
            badgeText: '2',
          ),
          _buildNavItem(
            icon: Icons.people_alt_rounded,
            label: 'User Management',
            badgeText: '4',
          ),
          _buildNavItem(
            icon: Icons.storefront_rounded,
            label: 'Active Artisans',
            badgeText: null,
          ),
          _buildNavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            badgeText: null,
          ),

          const Spacer(),

          // Bottom Admin Profile Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                  child: const Text(
                    'AD',
                    style: TextStyle(
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
                        'Admin Officer',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'moderator@warisankita.my',
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
                  onPressed: () {
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    String? badgeText,
  }) {
    final bool isSelected = activeTab == label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onTabSelected(label),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        fontSize: 11,
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