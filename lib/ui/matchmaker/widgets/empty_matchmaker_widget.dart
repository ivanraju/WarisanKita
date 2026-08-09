import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyMatchmakerWidget extends StatelessWidget {
  final VoidCallback onReset;

  const EmptyMatchmakerWidget({
    super.key,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No artisans found nearby',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F3D3E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No master artisan workshops were found within your current location radius. Try expanding your search distance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onReset,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F3D3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.zoom_out_map_rounded, size: 18),
              label: Text(
                'Expand Search Radius',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
