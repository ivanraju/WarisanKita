import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/ui/auth/login_screen.dart';
import 'package:warisan_kita/ui/auth/widgets/password_strength_meter.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/data/services/connectivity_service.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final int initialStep;
  final String? initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialStep = 1,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late int _currentStep;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _screenError;
  String? _emailError;
  String? _newError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    _newPasswordController.addListener(_onPasswordChanged);
    _emailController.addListener(_clearErrorOnTyping);
    _tokenController.addListener(_clearErrorOnTyping);
    _newPasswordController.addListener(_clearErrorOnTyping);
    _confirmPasswordController.addListener(_clearErrorOnTyping);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().clearError();
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  void _clearErrorOnTyping() {
    if (_screenError != null ||
        _emailError != null ||
        _newError != null ||
        _confirmError != null) {
      setState(() {
        _screenError = null;
        _emailError = null;
        _newError = null;
        _confirmError = null;
      });
    }
    final authVM = context.read<AuthViewModel>();
    if (authVM.errorMessage != null) {
      authVM.clearError();
    }
  }

  void _onPasswordChanged() {
    _clearErrorOnTyping();
    setState(() {});
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onPasswordChanged);
    _emailController.removeListener(_clearErrorOnTyping);
    _tokenController.removeListener(_clearErrorOnTyping);
    _newPasswordController.removeListener(_clearErrorOnTyping);
    _confirmPasswordController.removeListener(_clearErrorOnTyping);
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Step 1: Submit Email for Reset Token (UC003 Step 1-6)
  Future<void> _handleSendResetEmail() async {
    final connectivity = context.read<ConnectivityService?>();
    if (connectivity != null && connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Cannot reset password while offline. Please connect to the internet.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFC2410C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your registered email');
      return;
    }
    final emailError = ProfileValidator.validateEmail(email);
    if (emailError != null) {
      setState(() => _emailError = emailError);
      return;
    }

    final authVM = context.read<AuthViewModel>();

    final result = await authVM.sendPasswordReset(email);

    if (!mounted) return;

    if (!result.success) {
      final msg = result.message ?? 'EMAIL ADDRESS NOT FOUND IN SYSTEM';
      setState(() => _screenError = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PASSWORD RESET LINK HAS BEEN SENT TO YOUR EMAIL'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() => _currentStep = 2);
  }

  // Step 3: Submit New Password (UC003 Step 9-13)
  Future<void> _handleConfirmReset() async {
    final connectivity = context.read<ConnectivityService?>();
    if (connectivity != null && connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Cannot reset password while offline. Please connect to the internet.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFC2410C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _screenError = null;
      _newError = null;
      _confirmError = null;
    });

    bool hasError = false;

    if (newPassword.isEmpty) {
      _newError = 'Please enter a new password';
      hasError = true;
    } else if (newPassword.length < 8) {
      _newError = 'New password must be at least 8 characters';
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmError = 'Please confirm your new password';
      hasError = true;
    } else if (newPassword.isNotEmpty && newPassword != confirmPassword) {
      _confirmError = 'New passwords do not match';
      hasError = true;
    }

    final personalErr = ProfileValidator.validatePasswordPersonalDetails(
      newPassword,
      email: email,
    );
    if (!hasError && personalErr != null) {
      _newError = personalErr;
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final authVM = context.read<AuthViewModel>();

    final result = await authVM.confirmPasswordReset(
      email: email,
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    if (!result.success) {
      final msg = result.message ?? 'Password reset failed';
      setState(() {
        _screenError = msg;
        if (msg.toUpperCase().contains('TOO SIMILAR') ||
            msg.toUpperCase().contains('SAME AS YOUR CURRENT PASSWORD') ||
            msg.toUpperCase().contains('SHOULD BE DIFFERENT')) {
          _newError = 'New password must be different from current password';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // UC003 - M3: "PASSWORD RESET SUCCESSFUL: YOU MAY NOW LOGIN"
    context.read<AuthViewModel>().clearError();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PASSWORD RESET SUCCESSFUL: You may now sign in with your new password'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            onPressed: () {
              context.read<AuthViewModel>().clearError();
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: isDesktop ? 480 : double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D2825) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A34) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : const Color(0xFF004D40).withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: _buildCurrentStepContent(authVM, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(AuthViewModel authVM, bool isDark) {
    if (_currentStep == 1) {
      return _buildEmailFormView(authVM, isDark);
    } else if (_currentStep == 2) {
      return _buildTokenInboxView(isDark);
    } else {
      return _buildNewPasswordFormView(authVM, isDark);
    }
  }

  // Step 1: Email Input Screen (UC003 Step 1-4)
  Widget _buildEmailFormView(AuthViewModel authVM, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A34)
                  : const Color(0xFF004D40).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Enter your registered email address to receive a password reset link.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        if (authVM.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3B1515)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
              ),
            ),
            child: Text(
              authVM.errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Registered Email Address',
            errorText: _emailError,
            labelStyle: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white70 : null,
            ),
            hintText: 'e.g. user@example.com',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white38 : null,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 20,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF1E3A34) : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed: authVM.isLoading ? null : _handleSendResetEmail,
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF004D40),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: authVM.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  'SEND RESET LINK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ],
    );
  }

  // Step 2: Token Inbox Notice
  Widget _buildTokenInboxView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF063529) : const Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 48,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF0284C7),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Check Your Inbox!',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF041412) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            'A secure recovery link has been dispatched to:\n${_emailController.text}',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D1F08) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use the latest reset link from your email. If it has expired, request a new one. Check your spam folder if needed.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Back to Sign In
        FilledButton.icon(
          onPressed: () {
            context.read<AuthViewModel>().clearError();
            ScaffoldMessenger.of(context).clearSnackBars();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('BACK TO SIGN IN'),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF004D40),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() => _currentStep = 1),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          ),
          child: const Text('Resend / Change Email Address'),
        ),
      ],
    );
  }

  // Step 3: Set New Password Form
  Widget _buildNewPasswordFormView(AuthViewModel authVM, bool isDark) {
    final displayError = _screenError ?? authVM.errorMessage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A34)
                  : const Color(0xFF004D40).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.key_rounded,
              size: 36,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Set New Password',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 6),

        Text(
          'Please choose a strong password for your account',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),

        const SizedBox(height: 20),

        if (displayError != null) ...[
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
                    displayError,
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

        // New Password Input
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'New Password',
            labelStyle: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white70 : null,
            ),
            hintText: 'At least 8 characters',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            errorText: _newError,
            prefixIcon: Icon(
              Icons.key_rounded,
              size: 20,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF1E3A34) : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                width: 2,
              ),
            ),
          ),
        ),

        // 📊 Interactive Password Strength Meter & Live Checklist
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: PasswordStrengthMeter(password: _newPasswordController.text),
        ),

        const SizedBox(height: 16),

        // Confirm Password Input
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Confirm New Password',
            labelStyle: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white70 : null,
            ),
            hintText: 'Re-enter your new password',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            errorText: _confirmError,
            prefixIcon: Icon(
              Icons.lock_reset_outlined,
              size: 20,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF1E3A34) : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed: authVM.isLoading ? null : _handleConfirmReset,
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF004D40),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: authVM.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  'RESET PASSWORD',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ],
    );
  }
}

