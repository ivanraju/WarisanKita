import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/ui/auth/email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Tourist';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Join the Community', style: GoogleFonts.dmSerifDisplay()),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF004D40),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Begin Your Heritage Journey',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose your role and start exploring the traditions of Malaysia.',
                style: GoogleFonts.plusJakartaSans(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 32),
              // Role Selection
              Row(
                children: [
                  _buildRoleCard('Tourist', Icons.map_outlined, 'Explore & Collect'),
                  const SizedBox(width: 16),
                  _buildRoleCard('Artisan', Icons.brush_outlined, 'Showcase Craft'),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) => (value != null && value.contains('@')) ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) => (value != null && value.length >= 8) ? null : 'Min 8 characters',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: (value) => value == _passwordController.text ? null : 'Passwords mismatch',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFF4511E)], // Sunset Orange
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7043).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final result = await authState.signUp(_emailController.text, _passwordController.text, _selectedRole);
                              if (!context.mounted || !result.success) return;
                              if (result.requiresEmailVerification) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => EmailVerificationScreen(
                                    email: result.unverifiedEmail!,
                                    targetRoute: result.route,
                                  ),
                                ));
                              } else {
                                Navigator.of(context).pushNamedAndRemoveUntil(result.route ?? '/tourist', (_) => false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon, String subtitle) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF004D40) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? const Color(0xFF004D40) : Colors.black12,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF004D40).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF004D40)),
              const SizedBox(height: 12),
              Text(
                role,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
