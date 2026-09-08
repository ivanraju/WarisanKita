import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';
import 'package:warisan_kita/ui/matchmaker/craft_matchmaker_quiz_wizard.dart';
import 'package:warisan_kita/ui/core/edit_profile_screen.dart';
import 'package:warisan_kita/ui/core/widgets/translation_language_dialog.dart';
import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _locationAlerts = true;

  void _handleLogout(LanguageViewModel langVM) {
    final nav = Navigator.of(context, rootNavigator: true);
    final authVM = context.read<AuthViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(langVM.translate('Log Out'), style: GoogleFonts.dmSerifDisplay(color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))),
        content: Text(langVM.translate('Are you sure you want to log out of WarisanKita?'), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155))),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: Text(langVM.translate('Cancel'), style: TextStyle(color: isDark ? Colors.white60 : null))),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await authVM.logout();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text(langVM.translate('Log Out')),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(LanguageViewModel langVM) {
    final nav = Navigator.of(context, rootNavigator: true);
    final authVM = context.read<AuthViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          langVM.translate('Delete Account'),
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFEF4444)),
        ),
        content: Text(
          langVM.translate(
            'This action is permanent and will remove all your data, unlocked heritage badges, and craft profile records.',
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              langVM.translate('Cancel'),
              style: TextStyle(color: isDark ? Colors.white60 : null),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final result = await authVM.deleteCurrentAccount();
              if (!mounted) return;
              if (result.success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      langVM.translate(
                        'Your account has been permanently deleted.',
                      ),
                    ),
                    backgroundColor: const Color(0xFF004D40),
                  ),
                );
                nav.pushNamedAndRemoveUntil('/login', (route) => false);
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result.message ??
                          langVM.translate('Failed to delete account.'),
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(langVM.translate('PERMANENTLY DELETE')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeViewModel>().isDarkMode;
    final langVM = context.watch<LanguageViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final matchmakerVM = context.watch<MatchmakerViewModel>();
    final isQuizCompleted = matchmakerVM.isQuizCompleted;
    final personality = matchmakerVM.currentPersonality;
    final user = authVM.currentUser;
    final username = user?.effectiveUsername ?? 'Aiman Haziq';
    final initials = user?.initials ?? 'AH';
    final email = user?.email ?? 'tourist@warisankita.my';
    final role = user?.role ?? 'Tourist';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          langVM.translate('Settings & Account'),
          style: GoogleFonts.dmSerifDisplay(color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40), fontSize: 22),
        ),
        backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
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
          // User Account Profile Card Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2825) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF004D40),
                  backgroundImage: user?.avatarImageProvider,
                  child: user?.avatarImageProvider != null
                      ? null
                      : Text(
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
                        username,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          color: isDark ? Colors.white : const Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF34D399).withValues(alpha: 0.15) : const Color(0xFF004D40).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1: Account
          _buildSectionHeader(langVM.translate('ACCOUNT'), isDark: isDark),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            isDark: isDark,
            icon: Icons.person_outline_rounded,
            title: langVM.translate('Edit Profile'),
            subtitle: langVM.translate('Update avatar, name, and phone number'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            isDark: isDark,
            icon: Icons.auto_awesome_outlined,
            title: langVM.translate(
              isQuizCompleted
                  ? 'Update Craft Matchmaker Quiz'
                  : 'Take / Update Craft Matchmaker Quiz',
            ),
            subtitle: isQuizCompleted && personality != null
                ? '${langVM.translate('Your Craft Soul:')} ${personality.title} • ${personality.primaryCategory}'
                : langVM.translate('Customize your cultural preferences'),
            trailing: isQuizCompleted
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF34D399).withValues(alpha: 0.15)
                          : const Color(0xFF004D40).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF34D399).withValues(alpha: 0.3)
                            : const Color(0xFF004D40).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      langVM.translate('MATCHED'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                      ),
                    ),
                  )
                : null,
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
            isDark: isDark,
            icon: Icons.lock_reset_rounded,
            title: langVM.translate('Change Password'),
            subtitle: langVM.translate('Reset account password via email instructions'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
          ),

          const SizedBox(height: 28),

          // Section 2: Preferences
          _buildSectionHeader(langVM.translate('PREFERENCES'), isDark: isDark),
          const SizedBox(height: 10),
          _buildSwitchTile(
            context,
            isDark: isDark,
            icon: Icons.notifications_none_rounded,
            title: langVM.translate('Push Notifications'),
            subtitle: langVM.translate('Workshop reminders and thread updates'),
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          _buildSwitchTile(
            context,
            isDark: isDark,
            icon: Icons.near_me_outlined,
            title: langVM.translate('Geofence Radar Alerts'),
            subtitle: langVM.translate('Alert when passing nearby master artisan studios'),
            value: _locationAlerts,
            onChanged: (val) => setState(() => _locationAlerts = val),
          ),

          _buildSwitchTile(
            context,
            isDark: isDark,
            icon: Icons.dark_mode_outlined,
            title: langVM.translate('Dark Theme Mode'),
            subtitle: langVM.translate('Adjust app interface contrast for night browsing'),
            value: isDark,
            onChanged: (val) => context.read<ThemeViewModel>().toggleTheme(val),
          ),
          _buildSettingsTile(
            context,
            isDark: isDark,
            icon: Icons.language_rounded,
            title: langVM.translate('App Language & Translation'),
            subtitle: langVM.currentLanguageName,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => TranslationLanguageDialog(
                  currentLanguage: langVM.currentLanguageCode,
                  onLanguageChanged: (code, name) {
                    context.read<LanguageViewModel>().setLanguage(code, name);
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Section 3: Danger Zone
          _buildSectionHeader(langVM.translate('ACCOUNT MANAGEMENT'), isDark: isDark),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            isDark: isDark,
            icon: Icons.logout_rounded,
            title: langVM.translate('Log Out'),
            subtitle: langVM.translate('Safely exit current session'),
            textColor: const Color(0xFFEF4444),
            onTap: () => _handleLogout(langVM),
          ),
          _buildSettingsTile(
            context,
            isDark: isDark,
            icon: Icons.delete_forever_outlined,
            title: langVM.translate('Delete Account'),
            subtitle: langVM.translate('Permanently delete account and all saved data'),
            textColor: const Color(0xFFEF4444),
            onTap: () => _handleDeleteAccount(langVM),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDark ? const Color(0xFFFFD54F) : Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: textColor ?? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
          ),
          trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 20),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9)),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFFD54F),
          activeTrackColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
          secondary: Icon(icon, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
