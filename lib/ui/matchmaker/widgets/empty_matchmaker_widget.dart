import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyMatchmakerWidget extends StatelessWidget {
  const EmptyMatchmakerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D2825) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No master studios available',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF0F3D3E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'There are currently no approved artisan workshops to display.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
