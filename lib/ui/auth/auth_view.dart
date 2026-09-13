import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/ui/widgets/heritage_logo.dart';
import 'package:warisan_kita/ui/auth/sign_up_view.dart';
import 'package:warisan_kita/ui/dashboard/dashboard_view.dart';
import 'package:warisan_kita/ui/dashboard/artisan_dashboard_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004D40), Color(0xFF00251A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 48),
                  _buildLoginCard(context, authState),
                  const SizedBox(height: 32),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        const HeritageLogo(
          size: 64,
          glow: true,
          badgeColor: Colors.white,
          primaryColor: Color(0xFF004D40),
          accentColor: Color(0xFFFFD54F),
        ),
        const SizedBox(height: 24),
        Text(
          'WarisanKita',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 48,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 1, color: Colors.white38),
            const SizedBox(width: 8),
            Text(
              'LIVING CULTURAL HERITAGE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFD54F),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 14, height: 1, color: Colors.white38),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, AuthViewModel authState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 32),
          _buildLoginButton(authState),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthViewModel authState) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFF4511E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: authState.isLoading
            ? null
            : () async {
                await authState.login(_emailController.text, _passwordController.text);
                if (mounted && authState.currentUser != null) {
                  if (authState.currentUser!.role == 'Artisan') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ArtisanDashboardScreen()));
                  } else {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TouristDashboardScreen()));
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
            : const Text('EXPLORE NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
          child: const Text(
            "Join us",
            style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
