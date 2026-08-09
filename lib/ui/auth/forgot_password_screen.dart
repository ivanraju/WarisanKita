import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    setState(() => _isSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
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
            child: _isSubmitted ? _buildConfirmationView() : _buildEmailFormView(),
          ),
        ),
      ),
    );
  }

  // Step 1: Email Input Screen
  Widget _buildEmailFormView() {
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
          'Enter your registered email address and we will send password recovery instructions.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, height: 1.4),
        ),

        const SizedBox(height: 28),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed: _handleSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF004D40),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'SEND INSTRUCTIONS',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Step 2: 'Check your inbox' Confirmation Screen featuring a friendly illustration
  Widget _buildConfirmationView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Friendly Mail Illustration Icon
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 54, color: Color(0xFF0284C7)),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Check Your Inbox!',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),

        Text(
          'We have sent a password reset link to ${_emailController.text}. Please check your email inbox to create a new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
        ),

        const SizedBox(height: 32),

        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF004D40),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'BACK TO LOGIN',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
