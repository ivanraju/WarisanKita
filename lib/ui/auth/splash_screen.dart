import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/widgets/heritage_logo.dart';
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
        if (kIsWeb) {
          if (user.role == 'Admin') {
            Navigator.of(context).pushReplacementNamed('/admin');
          } else {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else {
          // Native Mobile & Desktop Client (Android, iOS, Windows)
          if (user.isSuspended || user.status == 'SUSPENDED') {
            Navigator.of(context).pushReplacementNamed('/tourist');
          } else if (user.role == 'Admin') {
            // Admin accounts must access web portal (UC001 A7)
            Navigator.of(context).pushReplacementNamed('/login');
          } else if (user.role == 'Artisan' || user.role == 'Master Artisan') {
            if (!user.isApprovedArtisan) {
              Navigator.of(context).pushReplacementNamed('/pending-artisan');
            } else {
              Navigator.of(context).pushReplacementNamed('/artisan');
            }
          } else {
            Navigator.of(context).pushReplacementNamed('/tourist');
          }
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
                    // Brand Logo Badge with authentic Malaysian Bunga Tanjung craft motif
                    const HeritageLogo(
                      size: 84,
                      glow: true,
                      badgeColor: Colors.white,
                      primaryColor: Color(0xFF004D40),
                      accentColor: Color(0xFFFFD54F),
                    ),

                    const SizedBox(height: 28),

                    // App Title
                    Text(
                      'WarisanKita',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Cultural Heritage Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 1.5,
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'LIVING CULTURAL HERITAGE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 20,
                          height: 1.5,
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Living Heritage & Artisan Discovery Tagline (Not a marketplace)
                    Text(
                      'Traditional Crafts • Living Culture • Master Artisans',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
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
