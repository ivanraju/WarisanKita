import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';
import 'package:warisan_kita/ui/auth/widgets/password_strength_meter.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String? _dialogError;
  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onPasswordChanged);
    _currentPasswordController.addListener(_clearErrors);
    _confirmPasswordController.addListener(_clearErrors);
  }

  void _onPasswordChanged() {
    _clearErrors();
    setState(() {});
  }

  void _clearErrors() {
    if (_dialogError != null ||
        _currentError != null ||
        _newError != null ||
        _confirmError != null) {
      setState(() {
        _dialogError = null;
        _currentError = null;
        _newError = null;
        _confirmError = null;
      });
    }
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onPasswordChanged);
    _currentPasswordController.removeListener(_clearErrors);
    _confirmPasswordController.removeListener(_clearErrors);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    LanguageViewModel? langVM;
    try {
      langVM = context.read<LanguageViewModel>();
    } catch (_) {}
    String tr(String text) => langVM?.translate(text) ?? text;

    setState(() {
      _dialogError = null;
      _currentError = null;
      _newError = null;
      _confirmError = null;
    });

    bool hasError = false;

    if (currentPassword.isEmpty) {
      _currentError = tr('Please enter your current password');
      hasError = true;
    }

    if (newPassword.isEmpty) {
      _newError = tr('Please enter a new password');
      hasError = true;
    } else if (newPassword.length < 8) {
      _newError = tr('New password must be at least 8 characters');
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmError = tr('Please confirm your new password');
      hasError = true;
    } else if (newPassword.isNotEmpty && newPassword != confirmPassword) {
      _confirmError = tr('New passwords do not match');
      hasError = true;
    }

    if (!hasError && currentPassword.toLowerCase() == newPassword.toLowerCase()) {
      _newError = tr('New password must be different from current password');
      _dialogError =
          tr('NEW PASSWORD IS TOO SIMILAR TO YOUR CURRENT PASSWORD: Please choose a completely new password, not just a change in uppercase or lowercase.');
      hasError = true;
    }

    final currentUser = context.read<AuthViewModel>().currentUser;
    final personalErr = ProfileValidator.validatePasswordPersonalDetails(
      newPassword,
      email: currentUser?.email,
      username: currentUser?.username,
      fullName: currentUser?.displayName,
    );
    if (!hasError && personalErr != null) {
      _newError = tr(personalErr);
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
      _dialogError = null;
    });

    final authVM = context.read<AuthViewModel>();
    final result = await authVM.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.success) {
      final msg = result.message ?? 'Failed to change password';
      if (msg.toUpperCase().contains('INCORRECT CURRENT PASSWORD')) {
        setState(() {
          _currentError = tr('Incorrect current password. Please try again.');
          _dialogError = tr(msg);
        });
      } else {
        setState(() => _dialogError = tr(msg));
      }
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('PASSWORD CHANGED SUCCESSFULLY: Your account credentials have been updated.')),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    LanguageViewModel? langVM;
    try {
      langVM = context.watch<LanguageViewModel>();
    } catch (_) {}
    String tr(String text) => langVM?.translate(text) ?? text;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isDark
            ? const BorderSide(color: Color(0xFF1E3A34), width: 1)
            : BorderSide.none,
      ),
      backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFFFD54F).withValues(alpha: 0.15)
                          : const Color(0xFF004D40).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Change Password'),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22,
                            color: isDark ? Colors.white : const Color(0xFF004D40),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('Verify current credentials to update'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Error Banner
              if (_dialogError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr(_dialogError!),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Current Password Field
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: tr('Current Password'),
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  errorText: _currentError,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // New Password Field
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: tr('New Password'),
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  hintText: tr('Must be at least 8 characters'),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  errorText: _newError,
                  prefixIcon: Icon(
                    Icons.key_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Live Password Strength Checklist
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: PasswordStrengthMeter(password: _newPasswordController.text),
              ),

              const SizedBox(height: 16),

              // Confirm New Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: tr('Confirm New Password'),
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  errorText: _confirmError,
                  prefixIcon: Icon(
                    Icons.lock_reset_outlined,
                    size: 20,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Forgot Current Password link
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    final email = context.read<AuthViewModel>().currentUser?.email;
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(initialEmail: email),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.mail_outline_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                  ),
                  label: Text(
                    tr('Forgot current password? Reset via email'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    child: Text(
                      tr('Cancel'),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleChangePassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF00695C) : const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            tr('Update Password'),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
