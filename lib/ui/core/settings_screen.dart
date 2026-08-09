import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';
import 'package:warisan_kita/ui/matchmaker/craft_matchmaker_quiz_wizard.dart';
import 'package:warisan_kita/ui/core/edit_profile_screen.dart';
import 'package:warisan_kita/ui/core/widgets/translation_language_dialog.dart';
import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _locationAlerts = true;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: GoogleFonts.dmSerifDisplay(color: Theme.of(context).colorScheme.primary)),
        content: Text('Are you sure you want to log out of WarisanKita?', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFEF4444))),
        content: Text(
          'This action is permanent and will remove all your data, unlocked heritage badges, and craft profile records.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('PERMANENTLY DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeViewModel>().isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings & Account',
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
          // Section 1: Account
          _buildSectionHeader('ACCOUNT'),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: 'Update avatar, name, and phone number',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.auto_awesome_outlined,
            title: 'Take / Update Craft Matchmaker Quiz',
            subtitle: 'Customize your cultural preferences (A1 Wizard)',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => CraftMatchmakerQuizWizard(
                  onCompleted: (tags) {
                    setState(() {});
                  },
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Reset account password via email instructions',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
          ),

          const SizedBox(height: 28),

          // Section 2: Preferences
          _buildSectionHeader('PREFERENCES'),
          const SizedBox(height: 10),
          _buildSwitchTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            subtitle: 'Workshop reminders and thread updates',
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.near_me_outlined,
            title: 'Geofence Radar Alerts',
            subtitle: 'Alert when passing nearby master artisan studios',
            value: _locationAlerts,
            onChanged: (val) => setState(() => _locationAlerts = val),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Theme Mode',
            subtitle: 'Adjust app interface contrast for night browsing',
            value: isDark,
            onChanged: (val) => context.read<ThemeViewModel>().toggleTheme(val),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language_rounded,
            title: 'App Language & Translation',
            subtitle: context.watch<LanguageViewModel>().currentLanguageName,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => TranslationLanguageDialog(
                  currentLanguage: context.read<LanguageViewModel>().currentLanguageCode,
                  onLanguageChanged: (code, name) {
                    context.read<LanguageViewModel>().setLanguage(code, name);
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Section 3: Danger Zone (Red Styling)
          _buildSectionHeader('DANGER ZONE', isDanger: true),
          const SizedBox(height: 10),
          _buildDangerTile(
            icon: Icons.logout_rounded,
            title: 'Logout of Account',
            onTap: _handleLogout,
          ),
          _buildDangerTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            onTap: _handleDeleteAccount,
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
