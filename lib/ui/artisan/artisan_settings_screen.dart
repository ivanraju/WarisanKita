import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/artisan/artisan_task_management_screen.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

class ArtisanSettingsScreen extends StatefulWidget {
  const ArtisanSettingsScreen({super.key});

  @override
  State<ArtisanSettingsScreen> createState() => _ArtisanSettingsScreenState();
}

class _ArtisanSettingsScreenState extends State<ArtisanSettingsScreen> {
  void _handleLogout() {
    final nav = Navigator.of(context, rootNavigator: true);
    final authVM = context.read<AuthViewModel>();
    final studio = authVM.currentUser?.studioName ?? 'Artisan Studio';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out Studio Account',
          style: GoogleFonts.dmSerifDisplay(
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          ),
        ),
        content: Text(
          'Are you sure you want to log out of $studio?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : null),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await authVM.logout();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _handleDeactivateStudio() {
    final nav = Navigator.of(context, rootNavigator: true);
    final authVM = context.read<AuthViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Color(0xFFD97706),
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Close Studio & Revert to Explorer',
                  style: GoogleFonts.dmSerifDisplay(
                    color: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to close your artisan studio listing?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Your studio workshop will be removed from the public craft directory and interactive map.\n'
                  '• Your active artisan quests will be retired.\n'
                  '• YOUR TOURIST ACCOUNT STAYS ACTIVE: You keep all your passport stamps, earned XP, saved bookmarks, and forum discussions.\n'
                  '• You will seamlessly transition back to the Cultural Explorer (Tourist) view.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white60 : null),
              ),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final result = await authVM.deactivateArtisanStudio();
                      if (!mounted) return;
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                      if (result.success) {
                        try {
                          context.read<DirectoryViewModel>().fetchArtisans();
                        } catch (_) {}
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              result.message ??
                                  'Studio closed. You are now exploring as a Cultural Explorer.',
                            ),
                            backgroundColor: const Color(0xFF004D40),
                          ),
                        );
                        nav.pushNamedAndRemoveUntil(
                          '/tourist',
                          (route) => false,
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              result.message ?? 'Failed to close studio.',
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('CLOSE STUDIO & REVERT'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteAccount() {
    final nav = Navigator.of(context, rootNavigator: true);
    final authVM = context.read<AuthViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? localError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete Account Permanently',
                  style: GoogleFonts.dmSerifDisplay(
                    color: const Color(0xFFEF4444),
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is irreversible and permanently deletes your studio, crafts, tourist passport, and credentials. (If you only want to close your studio, choose "Close Studio & Revert to Explorer" instead).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your password to confirm permanent deletion:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  enabled: !isSubmitting,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF041412)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E3A34)
                            : Colors.grey[300]!,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                      onPressed: () {
                        setDialogState(
                          () => obscurePassword = !obscurePassword,
                        );
                      },
                    ),
                  ),
                ),
                if (localError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    localError!,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white60 : null),
              ),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final pwd = passwordController.text.trim();
                      if (pwd.isEmpty) {
                        setDialogState(() {
                          localError = 'Please enter your current password.';
                        });
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        localError = null;
                      });
                      final result = await authVM.deleteCurrentAccount(
                        password: pwd,
                      );
                      if (!mounted) return;
                      if (result.success) {
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Your account has been permanently deleted.',
                            ),
                            backgroundColor: Color(0xFF004D40),
                          ),
                        );
                        nav.pushNamedAndRemoveUntil('/login', (route) => false);
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          String? msg = result.message;
                          if (msg != null) {
                            final match = RegExp(
                              r'message:\s*([^,\)]+)',
                            ).firstMatch(msg);
                            if (match != null) {
                              msg = match.group(1)!.trim();
                            }
                            msg = msg
                                .replaceAll(
                                  RegExp(r'^AuthException:\s*|^Exception:\s*'),
                                  '',
                                )
                                .trim();
                          }
                          localError = (msg != null && msg.isNotEmpty)
                              ? msg
                              : 'Failed to delete account.';
                        });
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('PERMANENTLY DELETE ACCOUNT'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeViewModel>().isDarkMode;
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final studioName =
        user?.studioName ?? user?.displayName ?? 'Artisan Studio';
    final handle = user?.handle ?? (user?.effectiveUsername ?? '');
    final initials = user?.initials ?? 'AS';
    final craft = user?.craftCategory ?? 'Heritage Craft';

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Artisan Studio Settings',
            style: GoogleFonts.dmSerifDisplay(
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                  ),
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
                color: isDark ? const Color(0xFF0D2825) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isDark
                    ? Border.all(color: const Color(0xFF1E3A34))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFD97706),
                    backgroundImage: user?.avatarImageProvider,
                    child: user?.avatarImageProvider != null
                        ? null
                        : Text(
                            initials,
                            style: GoogleFonts.dmSerifDisplay(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF004D40),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$handle • $craft',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
              subtitle:
                  'Update business bio, category, and 3x3 portfolio photos',
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
              subtitle:
                  'Configure tasks & pre-defined library quests for tourists',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ArtisanTaskManagementScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Section 2: Preferences
            _buildSectionHeader('PREFERENCES'),
            const SizedBox(height: 10),
            _buildSwitchTile(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Dark Theme Mode',
              subtitle: 'Adjust studio interface contrast for night operations',
              value: isDark,
              onChanged: (val) =>
                  context.read<ThemeViewModel>().toggleTheme(val),
            ),

            const SizedBox(height: 28),

            // Section 3: Portal Switcher
            _buildSectionHeader('PORTAL SWITCHER'),
            const SizedBox(height: 10),
            _buildSettingsTile(
              context,
              icon: Icons.explore_rounded,
              title: 'Switch to Cultural Explorer (Tourist) View',
              subtitle:
                  'Browse craft directory, map radar, community forum, and quests',
              onTap: () {
                authVM.selectActiveRole('Tourist');
                Navigator.of(context).pushReplacementNamed('/tourist');
              },
            ),

            const SizedBox(height: 28),

            // Section 4: Account & Studio Management
            _buildSectionHeader('STUDIO & ACCOUNT MANAGEMENT', isDanger: true),
            const SizedBox(height: 10),
            _buildWarningTile(
              icon: Icons.storefront_outlined,
              title: 'Close Studio & Revert to Explorer',
              subtitle:
                  'Retire your workshop listing. Keeps your personal account, passport stamps, and forum history intact.',
              onTap: _handleDeactivateStudio,
            ),
            _buildDangerTile(
              icon: Icons.logout_rounded,
              title: 'Logout of Studio Account',
              onTap: _handleLogout,
            ),
            _buildDangerTile(
              icon: Icons.delete_forever_outlined,
              title: 'Permanently Delete Account',
              subtitle:
                  'Permanently remove your studio, craft items, tourist passport, and credentials.',
              onTap: _handleDeleteAccount,
            ),

            const SizedBox(height: 32),
          ],
        ),
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
    final isDark = context.read<ThemeViewModel>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A34)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
        ),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? Colors.white54 : Colors.grey,
        ),
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
    final isDark = context.read<ThemeViewModel>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A34)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFFFD54F),
        activeTrackColor: const Color(0xFF10B981),
        secondary: Icon(
          icon,
          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
        ),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFD97706)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB45309),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF92400E),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFD97706),
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    String? subtitle,
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
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFFB91C1C),
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }
}
