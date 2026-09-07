import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtisanApplicationApprovedScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const ArtisanApplicationApprovedScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2825) : const Color(0xFF004D40).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Congratulations!',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 36,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your application has been approved by the Heritage Council. You are now officially recognized as a Master Artisan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 48),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Enter Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? const Color(0xFF041412) : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
