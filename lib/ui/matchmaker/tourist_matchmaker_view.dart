import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/viewmodels/map_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

import 'package:warisan_kita/domain/models/nearby_artisan.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';

import 'package:warisan_kita/ui/matchmaker/widgets/artisan_match_card.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/empty_matchmaker_widget.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/shimmer_loading_card.dart';

import 'package:warisan_kita/ui/map/widgets/google_map_widget.dart';

import 'package:warisan_kita/ui/tourist/widgets/geofence_unlocked_dialog.dart';
import 'package:warisan_kita/ui/tourist/widgets/daily_mood_checkin_dialog.dart';
import 'package:warisan_kita/ui/core/widgets/translation_language_dialog.dart';

import 'package:warisan_kita/ui/tourist/quest_completion_screen.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';

class TouristMatchmakerView extends StatefulWidget {
  const TouristMatchmakerView({super.key});

  @override
  State<TouristMatchmakerView> createState() => _TouristMatchmakerViewState();
}

class _TouristMatchmakerViewState extends State<TouristMatchmakerView> {
  final DraggableScrollableController _sheetController =
  DraggableScrollableController();

  MapViewModel? _mapVM;
  bool _locationTrackingStarted = false;

  // ============================================================
  // START LIVE GPS
  // ============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_locationTrackingStarted) {
      _mapVM = context.read<MapViewModel>();
      _locationTrackingStarted = true;

      // Starts GPS permission request + live position stream.
      _mapVM!.startLocationTracking();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();

    // Stop GPS stream when this page is removed.
    _mapVM?.stopLocationTracking();

    super.dispose();
  }

  // ============================================================
  // MAP WORKSHOP SELECTION
  // ============================================================

  void _onWorkshopSelected(
      BuildContext context,
      WorkshopLocation workshop,
      ) {
    context.read<MapViewModel>().selectWorkshop(workshop);
  }

  // ============================================================
  // NEARBY ARTISAN SELECTION
  // ============================================================

  void _onNearbyArtisanSelected(
      BuildContext context,
      NearbyArtisan artisan,
      ) {
    final mapVM = context.read<MapViewModel>();

    WorkshopLocation? matchingWorkshop;

    for (final workshop in mapVM.workshops) {
      if (workshop.id == artisan.id) {
        matchingWorkshop = workshop;
        break;
      }
    }

    if (matchingWorkshop != null) {
      mapVM.selectWorkshop(matchingWorkshop);
    }
  }

  // ============================================================
  // VIEW ARTISAN PROFILE
  // ============================================================

  void _handleViewProfile(
      BuildContext context,
      NearbyArtisan artisan,
      ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(
          artisanName: artisan.name,
          craftCategory: artisan.craftCategory,
          state: artisan.locationName,
          imageUrl: artisan.imageUrl,
          rating: artisan.rating,
        ),
      ),
    );
  }

  // ============================================================
  // VIEW QUEST
  // ============================================================

  void _handleViewQuest(
      BuildContext context,
      NearbyArtisan artisan,
      ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestCompletionScreen(
          workshopName: artisan.name,
          craftCategory: artisan.craftCategory,
          locationName: artisan.locationName,
          // Real GPS distance in metres calculated by MapViewModel
          distanceMeters: artisan.distanceMeters,
        ),
      ),
    );
  }

  // ============================================================
  // GEOFENCE DEMO
  // ============================================================

  void _triggerGeofencePopup(
      BuildContext context,
      ) {
    showDialog(
      context: context,
      builder: (_) => GeofenceUnlockedDialog(
        artisanName: 'Pak Mat Pottery Studio',
        craftCategory: 'Pottery & Ceramics',
        onClaim: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '🎉 Heritage Badge added to your Tourist Passport! (+150 XP)',
              ),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // MOOD CHECK-IN
  // ============================================================

  void _triggerMoodCheckin(
      BuildContext context,
      ) {
    showDialog(
      context: context,
      builder: (_) => DailyMoodCheckinDialog(
        onMoodSelected: (moodCategory) {
          context.read<MapViewModel>().refreshWorkshops();
        },
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET TOGGLE
  // ============================================================

  void _toggleSliderSheet() {
    if (!_sheetController.isAttached) {
      return;
    }

    if (_sheetController.size < 0.3) {
      _sheetController.animateTo(
        0.50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _sheetController.animateTo(
        0.20,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final mapVM = context.watch<MapViewModel>();

    const double navigationBarHeight = 58.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ======================================================
          // 1. GOOGLE MAP
          // ======================================================
          Positioned.fill(
            child: GoogleMapWidget(
              workshops: mapVM.workshops,
              selectedWorkshop: mapVM.selectedWorkshop,
              onWorkshopSelected: (workshop) {
                _onWorkshopSelected(context, workshop);
              },
              // Show Google Maps blue live-location dot
              // only after permission has been granted.
              myLocationEnabled: mapVM.hasLocationPermission,
              userLocation: mapVM.userLocation,
              isLoading: mapVM.isLoading,
            ),
          ),

          // ======================================================
          // 2. TOP ACTION BAR
          // ======================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D40),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.explore_rounded,
                        color: Color(0xFFFFD54F),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        langVM.translate('All Living Crafts'),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Translate
                FloatingActionButton.small(
                  heroTag: 'translate_btn',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => TranslationLanguageDialog(
                        currentLanguage: langVM.currentLanguageCode,
                        onLanguageChanged: (code, name) {
                          context
                              .read<LanguageViewModel>()
                              .setLanguage(code, name);
                        },
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.g_translate_rounded,
                    color: Color(0xFF004D40),
                    size: 18,
                  ),
                ),

                const SizedBox(width: 8),

                // Geofence demo
                FloatingActionButton.small(
                  heroTag: 'geofence_demo',
                  onPressed: () {
                    _triggerGeofencePopup(context);
                  },
                  backgroundColor: const Color(0xFFFFD54F),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: Color(0xFF004D40),
                    size: 18,
                  ),
                ),

                const SizedBox(width: 8),

                // Mood
                FloatingActionButton.small(
                  heroTag: 'mood_checkin',
                  onPressed: () {
                    _triggerMoodCheckin(context);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF004D40),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // 3. PROXIMITY QUEST BANNER
          // ======================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                _triggerGeofencePopup(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF004D40),
                      Color(0xFF065F46),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
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
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Color(0xFF004D40),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  langVM.translate('PROXIMITY QUEST RADAR'),
                                  softWrap: true,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFFFD54F),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '35m AWAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            langVM.translate(
                              'Pak Mat Pottery Studio Quest Ready!',
                            ),
                            style: GoogleFonts.dmSerifDisplay(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            langVM.translate(
                              'Earn +500 EXP & Plaque of Authenticity',
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFFFD54F),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // 4. DRAGGABLE NEARBY ARTISAN SHEET
          // ======================================================
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.22,
            minChildSize: 0.20,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [
              0.20,
              0.50,
              0.88,
            ],
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
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // ==========================================
                    // HEADER
                    // ==========================================
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
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _toggleSliderSheet,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          langVM.translate(
                                            'Nearby Master Studios',
                                          ),
                                          softWrap: true,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 20,
                                            color: const Color(0xFF004D40),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          langVM.translate(
                                            'Tap or slide up to view master studios',
                                          ),
                                          softWrap: true,
                                          style:
                                          GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF004D40),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.unfold_more_rounded,
                                          size: 14,
                                          color: Color(0xFFFFD54F),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          langVM.translate('Slide Studios'),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                    // ==========================================
                    // LOADING
                    // ==========================================
                    if (mapVM.isLoading)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return const ShimmerLoadingCard();
                            },
                            childCount: 3,
                          ),
                        ),
                      )

                    // ==========================================
                    // EMPTY NEARBY LIST
                    // ==========================================
                    else if (mapVM.nearbyArtisans.isEmpty)
                      SliverToBoxAdapter(
                        child: EmptyMatchmakerWidget(
                          onReset: () {
                            mapVM.expandNearbyRadius();
                          },
                        ),
                      )

                    // ==========================================
                    // NEARBY ARTISANS
                    // ==========================================
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final artisan = mapVM.nearbyArtisans[index];
                              final isSelected =
                                  mapVM.selectedWorkshop?.id == artisan.id;

                              return ArtisanMatchCard(
                                artisan: artisan,
                                isSelected: isSelected,
                                onTap: () {
                                  _onNearbyArtisanSelected(context, artisan);
                                },
                                onViewProfile: () {
                                  _handleViewProfile(context, artisan);
                                },
                                onViewQuest: () {
                                  _handleViewQuest(context, artisan);
                                },
                              );
                            },
                            childCount: mapVM.nearbyArtisans.length,
                          ),
                        ),
                      ),

                    // ==========================================
                    // NAVIGATION BAR SAFE SPACE
                    // ==========================================
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: navigationBarHeight + bottomSafeArea + 30,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}