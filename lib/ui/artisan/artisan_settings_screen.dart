import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/artisan/artisan_task_management_screen.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class ArtisanSettingsScreen extends StatefulWidget {
  const ArtisanSettingsScreen({super.key});

  @override
  State<ArtisanSettingsScreen> createState() => _ArtisanSettingsScreenState();
}

class _ArtisanSettingsScreenState extends State<ArtisanSettingsScreen> {
  bool _proximityAlerts = true;

  void _handleLogout() {
    final nav = Navigator.of(context, rootNavigator: true);
    final authVM = context.read<AuthViewModel>();
    final studio = authVM.currentUser?.studioName ?? 'Pak Mat Pottery Studio';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out Studio Account', style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40))),
        content: Text('Are you sure you want to log out of $studio?', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await authVM.logout();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeViewModel>().isDarkMode;
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final studioName = user?.studioName ?? user?.effectiveUsername ?? 'Pak Mat Pottery Studio';
    final initials = user?.initials ?? 'PM';
    final craft = user?.craftCategory ?? 'Pottery & Ceramics';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Artisan Studio Settings',
          style: GoogleFonts.dmSerifDisplay(color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40), fontSize: 22),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Studio Account Profile Card Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFD97706),
                  child: Text(
                    initials,
                    style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studioName,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          color: isDark ? Colors.white : const Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        craft,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFD97706), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1: Studio & Business Management
          _buildSectionHeader('STUDIO & BUSINESS MANAGEMENT'),
          const SizedBox(height: 10),

          _buildSettingsTile(
            context,
            icon: Icons.storefront_rounded,
            title: 'Edit Studio Profile & Story',
            subtitle: 'Update business bio, category, and 3x3 portfolio photos',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileBuilderTab()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.stars_rounded,
            title: 'Manage Gamification Quests',
            subtitle: 'Configure tasks & pre-defined library quests for tourists',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ArtisanTaskManagementScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.badge_rounded,
            title: 'Verification & SSM Documents',
            subtitle: 'Inspect SSM license and Kraftangan master certificates',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SSM Registration #002941-X • Kraftangan License #KFG-2024-889 VERIFIED.'),
                  backgroundColor: Color(0xFF004D40),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Section 2: Studio Proximity & Radar Controls
          _buildSectionHeader('PROXIMITY RADAR & ALERTS'),
          const SizedBox(height: 10),
          _buildSwitchTile(
            context,
            icon: Icons.radar_rounded,
            title: 'Tourist Proximity Alerts',
            subtitle: 'Broadcast alerts when tourists enter 50m workshop geofence',
            value: _proximityAlerts,
            onChanged: (val) => setState(() => _proximityAlerts = val),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Theme Mode',
            subtitle: 'Adjust studio interface contrast for night operations',
            value: isDark,
            onChanged: (val) => context.read<ThemeViewModel>().toggleTheme(val),
          ),

          const SizedBox(height: 28),

          // Section 3: Portal Switcher
          _buildSectionHeader('PORTAL SWITCHER'),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.explore_rounded,
            title: 'Switch to Cultural Explorer (Tourist) View',
            subtitle: 'Browse craft directory, map radar, community forum, and quests',
            onTap: () {
              authVM.selectActiveRole('Tourist');
              Navigator.of(context).pushReplacementNamed('/tourist');
            },
          ),

          const SizedBox(height: 28),

          // Section 4: Account & Studio Security
          _buildSectionHeader('ACCOUNT SECURITY', isDanger: true),
          const SizedBox(height: 10),
          _buildDangerTile(
            icon: Icons.logout_rounded,
            title: 'Logout of Studio Account',
            onTap: _handleLogout,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDanger = false}) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isDanger ? const Color(0xFFEF4444) : Colors.grey[500],
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = context.read<ThemeViewModel>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.grey),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = context.read<ThemeViewModel>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFFFD54F),
        activeTrackColor: const Color(0xFF10B981),
        secondary: Icon(icon, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFEF4444)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEF4444),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444)),
      ),
    );
  }
}
