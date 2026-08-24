import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/nearby_artisan.dart';

class ArtisanMatchCard extends StatelessWidget {
  final NearbyArtisan artisan;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onViewProfile;
  final VoidCallback onViewQuest;

  const ArtisanMatchCard({
    super.key,
    required this.artisan,
    required this.isSelected,
    required this.onTap,
    required this.onViewProfile,
    required this.onViewQuest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      scale: isSelected ? 1.015 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(
          top: isSelected ? 6 : 0,
          bottom: isSelected ? 22 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.32)
              : const Color(0xFFFFF8E1))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : (isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 20 : 10,
              spreadRadius: isSelected ? 1 : 0,
              offset: Offset(0, isSelected ? 7 : 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    color: const Color(0xFFD97706),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SELECTED WORKSHOP',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image with Status Tag
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          artisan.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF0F3D3E),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: artisan.isOpenNow
                              ? const Color(0xFF10B981)
                              : Colors.grey[600],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          artisan.isOpenNow ? 'OPEN' : 'CLOSED',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Artisan Information & Action Buttons Row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Match Score Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F3D3E)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                artisan.craftCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF0F3D3E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  size: 12,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '98% MATCH',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Artisan Name
                      Text(
                        artisan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Location & Calculated GPS Distance Row
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artisan.locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          if (artisan.distance.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004D40)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.directions_walk_rounded,
                                    size: 11,
                                    color: Color(0xFF004D40),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    artisan.distance,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF004D40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Action Buttons: View Profile & View Quest
                      Row(
                        children: [
                          // 1. View Profile
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onViewProfile,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF004D40),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'View Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF004D40),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 2. View Quest
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onViewQuest,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.explore_rounded,
                                size: 12,
                                color: Color(0xFFFFD54F),
                              ),
                              label: Text(
                                'View Quest',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
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
              ],
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
