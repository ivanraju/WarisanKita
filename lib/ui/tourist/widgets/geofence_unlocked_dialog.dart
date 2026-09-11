import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GeofenceUnlockedDialog extends StatelessWidget {
  final String artisanName;
  final String craftCategory;
  final VoidCallback onClaim;
  final VoidCallback? onViewProfile;

  const GeofenceUnlockedDialog({
    super.key,
    this.artisanName = 'Pak Mat Pottery Studio',
    this.craftCategory = 'Pottery & Ceramics',
    required this.onClaim,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vibrant Celebratory Badge Container
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFD97706),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 44,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tagline Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🎉 You discovered a hidden workshop!',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF004D40),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                artisanName,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'You stepped within the historic $craftCategory workshop zone in Melaka! Earned +150 Heritage XP.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons: View Profile & Claim Heritage Badge
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewProfile?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF004D40),
                        side: const BorderSide(
                          color: Color(0xFF004D40),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'View Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClaim();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Claim Badge',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
