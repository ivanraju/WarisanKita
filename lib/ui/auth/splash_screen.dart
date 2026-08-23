import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // 1.4-second splash timer: restore active session & route dynamically
    Timer(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      final authVM = context.read<AuthViewModel>();
      final user = await authVM.restoreSession();

      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      if (user != null) {
        if (user.role == 'Admin') {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else if (user.role == 'Artisan' || user.role == 'Master Artisan') {
          if (!user.isApprovedArtisan) {
            Navigator.of(context).pushReplacementNamed('/pending-artisan');
          } else {
            Navigator.of(context).pushReplacementNamed('/artisan');
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/tourist');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40), // Deep Malaysian Emerald
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Icon Badge
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 8,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        size: 64,
                        color: Color(0xFF004D40),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App Title
                    Text(
                      'WarisanKita',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Heritage Marketplace & Artisan Matchmaker',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Loading Indicator
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
