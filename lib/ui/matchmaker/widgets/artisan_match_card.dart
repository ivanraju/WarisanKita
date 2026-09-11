import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/nearby_artisan.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';

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
    final journey = artisan.journey;
    final journeyColor = _journeyColor(journey?.state);

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
              ? (isDark ? const Color(0xFF3B2C1B) : const Color(0xFFFFF8E1))
              : (isDark ? const Color(0xFF17332E) : Colors.white),
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
            ),
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
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: artisan.imageUrl.startsWith('http')
                                  ? Image.network(
                                      artisan.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFF0F3D3E),
                                        child: const Icon(
                                          Icons.storefront_rounded,
                                          color: Color(0xFFFFD54F),
                                          size: 40,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFF0F3D3E),
                                      child: const Icon(
                                        Icons.storefront_rounded,
                                        color: Color(0xFFFFD54F),
                                        size: 40,
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
                                      color: isDark
                                          ? const Color(0xFF294941)
                                          : const Color(
                                              0xFF0F3D3E,
                                            ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      artisan.craftCategory,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: isDark
                                            ? const Color(0xFFD9F2E8)
                                            : const Color(0xFF0F3D3E),
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
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 12,
                                        color: Color(0xFFB45309),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'VERIFIED',
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
                              style: GoogleFonts.plusJakartaSans(
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
                                      color: isDark
                                          ? const Color(0xFF294941)
                                          : const Color(
                                              0xFF004D40,
                                            ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.directions_walk_rounded,
                                          size: 11,
                                          color: isDark
                                              ? const Color(0xFF6EE7B7)
                                              : const Color(0xFF004D40),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          artisan.distance,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? const Color(0xFFD9F2E8)
                                                : const Color(0xFF004D40),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            if (journey != null) ...[
                              const SizedBox(height: 9),
                              _JourneyPreview(journey: journey),
                            ],

                            const SizedBox(height: 10),

                            // Action Buttons: View Profile & View Quest
                            Row(
                              children: [
                                // 1. View Profile
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: onViewProfile,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFFFFD54F)
                                            : const Color(0xFF004D40),
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
                                        color: isDark
                                            ? const Color(0xFFFFD54F)
                                            : const Color(0xFF004D40),
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
                                      backgroundColor: journeyColor,
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
                                    icon: Icon(
                                      _journeyIcon(journey?.state),
                                      size: 12,
                                      color:
                                          journey?.state ==
                                              WorkshopQuestState.available
                                          ? const Color(0xFF004D40)
                                          : const Color(0xFFFFD54F),
                                    ),
                                    label: Text(
                                      journey?.actionLabel ?? 'VIEW QUEST',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            journey?.state ==
                                                WorkshopQuestState.available
                                            ? const Color(0xFF004D40)
                                            : Colors.white,
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

  Color _journeyColor(WorkshopQuestState? state) => switch (state) {
    WorkshopQuestState.available => const Color(0xFFFFD54F),
    WorkshopQuestState.inProgress => const Color(0xFFE67E00),
    WorkshopQuestState.stopped => const Color(0xFFB45309),
    WorkshopQuestState.blockedByOtherQuest => const Color(0xFFB45309),
    WorkshopQuestState.completed => const Color(0xFF00695C),
    WorkshopQuestState.unavailable || null => const Color(0xFF004D40),
  };

  IconData _journeyIcon(WorkshopQuestState? state) => switch (state) {
    WorkshopQuestState.available => Icons.flag_rounded,
    WorkshopQuestState.inProgress => Icons.directions_walk_rounded,
    WorkshopQuestState.stopped => Icons.stop_circle_outlined,
    WorkshopQuestState.blockedByOtherQuest => Icons.lock_clock_rounded,
    WorkshopQuestState.completed => Icons.workspace_premium_rounded,
    WorkshopQuestState.unavailable || null => Icons.storefront_rounded,
  };
}

class _JourneyPreview extends StatelessWidget {
  final WorkshopQuestJourney journey;

  const _JourneyPreview({required this.journey});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? const Color(0xFFFFD54F)
        : switch (journey.state) {
            WorkshopQuestState.available => const Color(0xFFB45309),
            WorkshopQuestState.inProgress => const Color(0xFFE67E00),
            WorkshopQuestState.stopped => const Color(0xFFB45309),
            WorkshopQuestState.blockedByOtherQuest => const Color(0xFFB45309),
            WorkshopQuestState.completed => const Color(0xFF00695C),
            WorkshopQuestState.unavailable => const Color(0xFF64748B),
          };
    final stampUrl = journey.stampImageUrl;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                clipBehavior: Clip.antiAlias,
                child: stampUrl.startsWith('http')
                    ? Image.network(
                        stampUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFB45309),
                          size: 19,
                        ),
                      )
                    : const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFB45309),
                        size: 19,
                      ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.stateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      journey.progressLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (journey.xpReward > 0)
                Text(
                  '+${journey.xpReward} XP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB45309),
                  ),
                ),
            ],
          ),
          if (journey.totalTaskCount > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: journey.progress,
                minHeight: 4,
                backgroundColor: Colors.white,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
