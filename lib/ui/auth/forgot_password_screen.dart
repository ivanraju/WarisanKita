import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController(text: 'tourist@warisankita.my');
  final _tokenController = TextEditingController(text: 'TOKEN-SAMPLE');
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // 1: Email Form, 2: Token Inbox Notice, 3: Set New Password Form
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Step 1: Submit Email for Reset Token (UC003 Step 1-6)
  Future<void> _handleSendResetEmail() async {
    final email = _emailController.text.trim();
    final authVM = context.read<AuthViewModel>();

    final result = await authVM.sendPasswordReset(email);

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'EMAIL ADDRESS NOT FOUND IN SYSTEM'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PASSWORD RESET LINK HAS BEEN SENT TO YOUR EMAIL (Valid for 15 mins)'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() => _currentStep = 2);
  }

  // Step 3: Submit New Password (UC003 Step 9-13)
  Future<void> _handleConfirmReset() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final authVM = context.read<AuthViewModel>();

    final result = await authVM.confirmPasswordReset(
      email: email,
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Password reset failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // UC003 - M3: "PASSWORD RESET SUCCESSFUL: YOU MAY NOW LOGIN"
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PASSWORD RESET SUCCESSFUL: YOU MAY NOW LOGIN'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: isDesktop ? 480 : double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004D40).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: _buildCurrentStepContent(authVM),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(AuthViewModel authVM) {
    if (_currentStep == 1) {
      return _buildEmailFormView(authVM);
    } else if (_currentStep == 2) {
      return _buildTokenInboxView();
    } else {
      return _buildNewPasswordFormView(authVM);
    }
  }

  // Step 1: Email Input Screen (UC003 Step 1-4)
  Widget _buildEmailFormView(AuthViewModel authVM) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 36, color: Color(0xFF004D40)),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFF004D40)),
        ),
        const SizedBox(height: 8),

        Text(
          'PLEASE ENTER YOUR REGISTERED EMAIL ADDRESS',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: const Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 6),

        Text(
          'We will dispatch a secure, single-use password recovery link valid for 15 minutes [C1].',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54, height: 1.4),
        ),

        const SizedBox(height: 20),

        if (authVM.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Text(
              authVM.errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Registered Email Address',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed: authVM.isLoading ? null : _handleSendResetEmail,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF004D40),
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
                  'DISPATCH RESET LINK [M1]',
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

  // Step 2: Token Inbox Notice (UC003 Step 5-8)
  Widget _buildTokenInboxView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 48, color: Color(0xFF0284C7)),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Check Your Inbox!',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),

        Text(
          'A secure recovery link has been dispatched to:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Token Constraint: Expires in 15 minutes [C1]. Strictly single-use [C4].',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action 1: Open Reset Link / Proceed to Step 3 (Simulates clicking email reset link)
        FilledButton.icon(
          onPressed: () => setState(() => _currentStep = 3),
          icon: const Icon(Icons.password_rounded, size: 18),
          label: const Text('OPEN RESET FORM & ENTER NEW PASSWORD (STEP 8-9)'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF004D40),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() => _currentStep = 1),
          child: const Text('Resend / Change Email'),
        ),
      ],
    );
  }

  // Step 3: Set New Password Form (UC003 Step 9-13)
  Widget _buildNewPasswordFormView(AuthViewModel authVM) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.key_rounded, size: 36, color: Color(0xFF004D40)),
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Set New Password',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFF004D40)),
        ),
        const SizedBox(height: 6),

        Text(
          'ENTER NEW CREDENTIALS (UC003 STEP 9-10)',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: const Color(0xFF004D40),
          ),
        ),

        const SizedBox(height: 20),

        if (authVM.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Text(
              authVM.errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // New Password Input
        TextField(
          controller: _newPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'New Password (> 7 characters) [C2]',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 16),

        // Confirm Password Input
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm New Password [C3]',
            prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed: authVM.isLoading ? null : _handleConfirmReset,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF004D40),
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
                  'UPDATE ENCRYPTED PASSWORD IN DB [M3]',
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

