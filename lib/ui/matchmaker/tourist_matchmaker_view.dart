import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/artisan_match_card.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/empty_matchmaker_widget.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/map_placeholder_view.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/shimmer_loading_card.dart';
import 'package:warisan_kita/ui/tourist/widgets/geofence_unlocked_dialog.dart';
import 'package:warisan_kita/ui/tourist/widgets/daily_mood_checkin_dialog.dart';
import 'package:warisan_kita/ui/core/widgets/translation_language_dialog.dart';
import 'package:warisan_kita/ui/tourist/quest_completion_screen.dart';
import 'package:warisan_kita/domain/models/nearby_artisan.dart';

class TouristMatchmakerView extends StatefulWidget {
  const TouristMatchmakerView({super.key});

  @override
  State<TouristMatchmakerView> createState() => _TouristMatchmakerViewState();
}

class _TouristMatchmakerViewState extends State<TouristMatchmakerView> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onArtisanSelected(BuildContext context, NearbyArtisan artisan) {
    final vm = context.read<MatchmakerViewModel>();
    vm.selectArtisan(artisan);
  }

  void _handleViewProfile(BuildContext context, NearbyArtisan artisan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestCompletionScreen(
          workshopName: artisan.name,
          craftCategory: artisan.craftCategory,
          locationName: artisan.locationName,
          distanceMeters: 35.0, // 35m inside 50m geofence range
        ),
      ),
    );
  }

  void _triggerGeofencePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GeofenceUnlockedDialog(
        artisanName: 'Pak Mat Pottery Studio',
        craftCategory: 'Pottery & Ceramics',
        onClaim: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎉 Heritage Badge added to your Tourist Passport! (+150 XP)'),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchmakerViewModel(),
      child: Consumer<MatchmakerViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_rounded, color: Color(0xFF004D40), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Heritage Quest Map',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF004D40),
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                // 🔥 Streak Count & Daily Check-in Badge
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => DailyMoodCheckinDialog(
                        onMoodSelected: (mood) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Map filtered for today\'s choice: $mood!'),
                              backgroundColor: const Color(0xFF004D40),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFD97706), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '7 Days',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.g_translate_rounded, color: Color(0xFF004D40)),
                  tooltip: 'Translate Page Live',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => TranslationLanguageDialog(
                        onLanguageChanged: (code, name) => setState(() {}),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F)),
                  tooltip: 'Simulate Geofence Alert Popup',
                  onPressed: () => _triggerGeofencePopup(context),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF004D40)),
                  tooltip: 'Reload Radar',
                  onPressed: () => viewModel.refreshMatchmaker(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // Top 60% Map Placeholder View
                Positioned.fill(
                  bottom: MediaQuery.of(context).size.height * 0.38,
                  child: MapPlaceholderView(
                    artisans: viewModel.nearbyArtisans,
                    selectedArtisan: viewModel.selectedArtisan,
                    onArtisanSelected: (artisan) => _onArtisanSelected(context, artisan),
                    isLoading: viewModel.isLoading,
                  ),
                ),

                // 🎯 FLOATING GAMIFIED RADAR QUEST CARD ABOVE MAP
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      if (viewModel.nearbyArtisans.isNotEmpty) {
                        _handleViewProfile(context, viewModel.nearbyArtisans.first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF004D40), Color(0xFF0F172A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF004D40).withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.radar_rounded, color: Color(0xFF004D40), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'PROXIMITY QUEST RADAR',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFFFD54F),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('35m AWAY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pak Mat Pottery Studio Quest Ready!',
                                  style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 15),
                                ),
                                Text(
                                  'Earn +500 EXP & Plaque of Authenticity',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFD54F), size: 14),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Interactive Draggable Bottom Sheet
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.48,
                  minChildSize: 0.28,
                  maxChildSize: 0.88,
                  snap: true,
                  snapSizes: const [0.28, 0.48, 0.88],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          )
                        ],
                      ),
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          // Draggable Handle & Header Section
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Center(
                                  child: Container(
                                    width: 44,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 🏆 DAILY GAMIFICATION QUESTS CAROUSEL
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Daily Heritage Challenges',
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 18,
                                          color: const Color(0xFF004D40),
                                        ),
                                      ),
                                      Text(
                                        'Reset in 14h',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                SizedBox(
                                  height: 80,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    children: [
                                      _buildChallengeCard(
                                        title: '🏺 Master Clay Pottery',
                                        reward: '+200 Bonus XP',
                                        progress: '1/1 Done',
                                        isCompleted: true,
                                      ),
                                      _buildChallengeCard(
                                        title: '📜 Artisan QR Handshake',
                                        reward: '+150 Bonus XP',
                                        progress: '0/1 Scanned',
                                        isCompleted: false,
                                      ),
                                      _buildChallengeCard(
                                        title: '🏆 Top Melaka Explorer',
                                        reward: '#3 Rank',
                                        progress: 'Leaderboard',
                                        isCompleted: true,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Bottom Sheet Header Title & Distance Badge
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nearby Master Studios',
                                            style: GoogleFonts.dmSerifDisplay(
                                              fontSize: 20,
                                              color: const Color(0xFF004D40),
                                            ),
                                          ),
                                          Text(
                                            'Tap any studio to launch +500 EXP quest',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFFB45309)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '< 2 km Radar',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFB45309),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),
                                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),

                          // Scrollable Content List
                          if (viewModel.isLoading)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => const ShimmerLoadingCard(),
                                  childCount: 3,
                                ),
                              ),
                            )
                          else if (viewModel.nearbyArtisans.isEmpty)
                            SliverToBoxAdapter(
                              child: EmptyMatchmakerWidget(
                                onReset: () => viewModel.refreshMatchmaker(),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final artisan = viewModel.nearbyArtisans[index];
                                    final isSelected = viewModel.selectedArtisan?.id == artisan.id;

                                    return ArtisanMatchCard(
                                      artisan: artisan,
                                      isSelected: isSelected,
                                      onTap: () => _onArtisanSelected(context, artisan),
                                      onViewProfile: () => _handleViewProfile(context, artisan),
                                    );
                                  },
                                  childCount: viewModel.nearbyArtisans.length,
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 40),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String reward,
    required String progress,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 13,
              color: isCompleted ? const Color(0xFF14532D) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                reward,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• $progress',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
