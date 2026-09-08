import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef MapTranslate = String Function(String);

String heritageJourneySummary(int quests) =>
    '$quests ${quests == 1 ? 'quest available' : 'quests available'}';

class HeritageMapControls extends StatelessWidget {
  final MapTranslate translate;
  final VoidCallback onSettings;
  const HeritageMapControls({
    super.key,
    required this.translate,
    required this.onSettings,
  });
  @override
  Widget build(BuildContext context) => Row(
    key: const Key('heritage-map-controls'),
    children: [
      Flexible(
        child: Chip(
          avatar: const Icon(
            Icons.explore_rounded,
            size: 16,
            color: Color(0xFFFFD54F),
          ),
          backgroundColor: const Color(0xFF004D40),
          label: Text(
            translate('All Living Crafts'),
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          side: BorderSide.none,
        ),
      ),
      const Spacer(),
      IconButton.filledTonal(
        key: const Key('map-settings'),
        tooltip: translate('Map filters and settings'),
        onPressed: onSettings,
        icon: const Icon(Icons.tune_rounded, size: 20),
      ),
    ],
  );
}

class HeritageNearbyBanner extends StatelessWidget {
  final String title;
  final int distanceMeters;
  final VoidCallback onTap;
  final MapTranslate translate;
  const HeritageNearbyBanner({
    super.key,
    required this.title,
    required this.distanceMeters,
    required this.onTap,
    required this.translate,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF5EBCF) : const Color(0xFF004D40);
    return Material(
      key: const Key('heritage-nearby-banner'),
      color: dark ? const Color(0xFF0D2825) : const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFC28D16),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      translate('Heritage Quest Nearby'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$title · ${translate('$distanceMeters m away')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: ink,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ink, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class HeritageSheetHeader extends StatelessWidget {
  final int nearbyCount;
  final int questCount;
  final bool expanded;
  final VoidCallback onToggle;
  final MapTranslate translate;
  const HeritageSheetHeader({
    super.key,
    required this.nearbyCount,
    required this.questCount,
    required this.expanded,
    required this.onToggle,
    required this.translate,
  });

  static double heightFor(double scale) => 92 + (scale - 1).clamp(0, 2) * 46;
  static double minimumExtent(double availableHeight, double scale) =>
      ((heightFor(scale) + 4) / availableHeight).clamp(0.18, 0.45);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFFFD54F) : const Color(0xFF004D40);
    return SizedBox(
      height: heightFor(MediaQuery.textScalerOf(context).scale(1)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: dark ? Colors.white38 : const Color(0xFFC5C2B5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    translate('Heritage Trails Near You'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: ink),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  translate('$nearbyCount nearby'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: ink),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    translate(heritageJourneySummary(questCount)),
                    key: const Key('heritage-sheet-summary'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: dark ? Colors.white70 : const Color(0xFF5D6259),
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: translate(
                      expanded
                          ? 'Collapse heritage trails'
                          : 'Expand heritage trails',
                    ),
                    onPressed: onToggle,
                    color: ink,
                    icon: Icon(
                      expanded
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
