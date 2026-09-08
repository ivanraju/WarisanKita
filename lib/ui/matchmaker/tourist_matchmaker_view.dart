import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/viewmodels/map_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

import 'package:warisan_kita/domain/models/nearby_artisan.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';

import 'package:warisan_kita/ui/matchmaker/widgets/artisan_match_card.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/heritage_map_chrome.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/empty_matchmaker_widget.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/shimmer_loading_card.dart';

import 'package:warisan_kita/ui/map/widgets/google_map_widget.dart';
import 'package:warisan_kita/ui/gamification/quest_view.dart';

import 'package:warisan_kita/ui/tourist/widgets/daily_mood_checkin_dialog.dart';
import 'package:warisan_kita/ui/core/widgets/translation_language_dialog.dart';

import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';

class TouristMatchmakerView extends StatefulWidget {
  final bool isActive;

  const TouristMatchmakerView({super.key, this.isActive = true});

  @override
  State<TouristMatchmakerView> createState() => _TouristMatchmakerViewState();
}

class _TouristMatchmakerViewState extends State<TouristMatchmakerView> {
  double get _sheetMinSize =>
      ((HeritageSheetHeader.heightFor(
                    MediaQuery.textScalerOf(context).scale(1),
                  ) +
                  MediaQuery.paddingOf(context).bottom +
                  86) /
              MediaQuery.sizeOf(context).height)
          .clamp(0.18, 0.45);
  static const double _sheetMiddleSize = 0.50;
  static const double _sheetMaxSize = 0.88;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  ScrollController? _sheetScrollController;
  double? _sheetHeaderDragStartSize;
  double? _sheetHeaderDragSize;
  final Map<String, GlobalKey> _artisanCardKeys = {};
  int _revealRequestId = 0;

  MapViewModel? _mapVM;
  bool _locationTrackingStarted = false;
  bool _isOpeningQuest = false;
  String? _proximityQuestId;
  bool? _lastReportedQuestInside;
  final Set<String> _discoveredQuestIds = <String>{};

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
  void didUpdateWidget(covariant TouristMatchmakerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      unawaited(context.read<MapViewModel>().loadJourneyData());
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

  void _onWorkshopSelected(BuildContext context, WorkshopLocation workshop) {
    final mapVM = context.read<MapViewModel>();
    mapVM.selectWorkshop(workshop);

    if (mapVM.selectedWorkshop?.id == workshop.id) {
      _revealWorkshopCard(workshop.id);
    } else {
      _revealRequestId++;
    }
  }

  Future<void> _revealWorkshopCard(String workshopId) async {
    final requestId = ++_revealRequestId;

    if (_sheetController.isAttached) {
      await _sheetController.animateTo(
        0.50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted || requestId != _revealRequestId) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (requestId != _revealRequestId ||
        await _ensureWorkshopCardVisible(workshopId)) {
      return;
    }

    // SliverList builds lazily. Move near the expected card first so its
    // GlobalKey obtains a context, then use ensureVisible for exact alignment.
    final mapVM = _mapVM;
    final scrollController = _sheetScrollController;

    if (mapVM == null ||
        scrollController == null ||
        !scrollController.hasClients) {
      return;
    }

    const double sheetHeaderExtent = 135;
    const double sectionHeaderExtent = 80;
    const double estimatedCardExtent = 175;
    const double otherSectionDividerExtent = 115;

    final nearbyIndex = mapVM.nearbyArtisans.indexWhere(
      (artisan) => artisan.id == workshopId,
    );
    final otherIndex = mapVM.otherArtisans.indexWhere(
      (artisan) => artisan.id == workshopId,
    );

    double? estimatedOffset;

    if (nearbyIndex >= 0) {
      estimatedOffset =
          sheetHeaderExtent +
          sectionHeaderExtent +
          (nearbyIndex * estimatedCardExtent);
    } else if (otherIndex >= 0) {
      estimatedOffset =
          sheetHeaderExtent +
          sectionHeaderExtent +
          (mapVM.nearbyArtisans.length * estimatedCardExtent) +
          otherSectionDividerExtent +
          (otherIndex * estimatedCardExtent);
    }

    if (estimatedOffset == null) {
      return;
    }

    final targetOffset = estimatedOffset
        .clamp(0.0, scrollController.position.maxScrollExtent)
        .toDouble();

    await scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );

    if (!mounted || requestId != _revealRequestId) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    await _ensureWorkshopCardVisible(workshopId);
  }

  Future<bool> _ensureWorkshopCardVisible(String workshopId) async {
    final cardContext = _artisanCardKeys[workshopId]?.currentContext;

    if (cardContext == null) {
      return false;
    }

    await Scrollable.ensureVisible(
      cardContext,
      alignment: 0.12,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    return true;
  }

  // ============================================================
  // NEARBY ARTISAN SELECTION
  // ============================================================

  void _onNearbyArtisanSelected(BuildContext context, NearbyArtisan artisan) {
    final mapVM = context.read<MapViewModel>();
    _revealRequestId++;

    WorkshopLocation? matchingWorkshop;

    for (final workshop in mapVM.workshops) {
      if (workshop.id == artisan.id) {
        matchingWorkshop = workshop;
        break;
      }
    }

    if (matchingWorkshop != null) {
      mapVM.focusWorkshop(matchingWorkshop);
    }
  }

  // ============================================================
  // VIEW ARTISAN PROFILE
  // ============================================================

  void _handleViewProfile(BuildContext context, NearbyArtisan artisan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(
          artisanName: artisan.name,
          craftCategory: artisan.craftCategory,
          state: artisan.locationName,
          imageUrl: artisan.imageUrl,
          rating: artisan.rating,
          address: artisan.workshop?.address,
          latitude: artisan.latitude,
          longitude: artisan.longitude,
        ),
      ),
    );
  }

  // ============================================================
  // VIEW QUEST
  // ============================================================

  Future<void> _handleViewQuest(
    BuildContext context,
    NearbyArtisan artisan,
  ) async {
    final workshop = artisan.workshop;

    if (workshop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workshop details are unavailable.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isOpeningQuest) {
      return;
    }

    _isOpeningQuest = true;

    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => QuestView(workshop: workshop)));
    } finally {
      _isOpeningQuest = false;
      if (context.mounted) {
        unawaited(context.read<MapViewModel>().loadJourneyData());
        unawaited(context.read<GamificationViewModel>().loadPassport());
      }
    }
  }

  List<NearbyArtisan> _selectedFirst(
    List<NearbyArtisan> artisans,
    String? selectedId,
  ) {
    if (selectedId == null ||
        artisans.isEmpty ||
        artisans.first.id == selectedId) {
      return artisans;
    }
    final selectedIndex = artisans.indexWhere((item) => item.id == selectedId);
    if (selectedIndex < 0) return artisans;
    return [
      artisans[selectedIndex],
      ...artisans.where((item) => item.id != selectedId),
    ];
  }

  Widget _buildArtisanCard(
    BuildContext context,
    MapViewModel mapVM,
    NearbyArtisan artisan,
  ) {
    return ArtisanMatchCard(
      key: _artisanCardKeys.putIfAbsent(
        artisan.id,
        () => GlobalKey(debugLabel: 'artisan_card_${artisan.id}'),
      ),
      artisan: artisan,
      isSelected: mapVM.selectedWorkshop?.id == artisan.id,
      onTap: () {
        _onNearbyArtisanSelected(context, artisan);
      },
      onViewProfile: () {
        _handleViewProfile(context, artisan);
      },
      onViewQuest: () {
        if (artisan.journey == null) {
          _handleViewProfile(context, artisan);
        } else {
          _handleViewQuest(context, artisan);
        }
      },
    );
  }

  Widget _buildStudioSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int count,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 19,
                    color: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A34)
                      : const Color(0xFF004D40).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineStudioMessage(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF041412) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF64748B),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reportActiveQuestProximity(
    MapViewModel mapViewModel,
    GamificationViewModel gamificationViewModel,
  ) {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    final quest = gamificationViewModel.selectedQuest;
    final isQuestInProgress =
        gamificationViewModel.questProgressStatus?.toUpperCase() ==
        'IN_PROGRESS';
    if (quest == null || !isQuestInProgress) {
      _proximityQuestId = null;
      _lastReportedQuestInside = null;
      return;
    }

    WorkshopLocation? workshop;
    for (final candidate in mapViewModel.workshops) {
      if (candidate.id == quest.artisanId) {
        workshop = candidate;
        break;
      }
    }

    if (workshop == null) return;
    final distance = mapViewModel.getDistanceToWorkshop(workshop);
    if (distance == null) return;

    final isInside = distance <= quest.geofenceRadiusMeters;
    if (_proximityQuestId == quest.id && _lastReportedQuestInside == isInside) {
      return;
    }

    _proximityQuestId = quest.id;
    _lastReportedQuestInside = isInside;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !(ModalRoute.of(context)?.isCurrent ?? false) ||
          gamificationViewModel.selectedQuest?.id != quest.id ||
          gamificationViewModel.questProgressStatus?.toUpperCase() !=
              'IN_PROGRESS') {
        return;
      }
      unawaited(gamificationViewModel.handleQuestProximityChanged(isInside));
    });
  }

  void _reportQuestDiscovery(
    NearbyArtisan? artisan,
    MapViewModel mapViewModel,
  ) {
    final journey = artisan?.journey;
    if (artisan == null ||
        journey == null ||
        journey.state == WorkshopQuestState.completed ||
        _discoveredQuestIds.contains(journey.questId) ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }

    _discoveredQuestIds.add(journey.questId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF004D40),
            content: Text(
              'Heritage Quest Discovered • ${artisan.name}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        );
      if (mapViewModel.selectedWorkshop?.id != artisan.id &&
          artisan.workshop != null) {
        mapViewModel.selectWorkshop(artisan.workshop);
        unawaited(_revealWorkshopCard(artisan.id));
      }
    });
  }

  Future<void> _showMapSettings() async {
    final lang = context.read<LanguageViewModel>();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(lang.translate('Mood & craft preferences')),
              onTap: () => Navigator.pop(context, 'mood'),
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(lang.translate('Language')),
              onTap: () => Navigator.pop(context, 'language'),
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: Text(lang.translate('Refresh studios')),
              onTap: () => Navigator.pop(context, 'refresh'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'mood') _triggerMoodCheckin(context);
    if (action == 'refresh') context.read<MapViewModel>().refreshWorkshops();
    if (action == 'language') {
      showDialog(
        context: context,
        builder: (_) => TranslationLanguageDialog(
          currentLanguage: lang.currentLanguageCode,
          onLanguageChanged: (code, name) => lang.setLanguage(code, name),
        ),
      );
    }
  }

  // ============================================================
  // MOOD CHECK-IN
  // ============================================================

  void _triggerMoodCheckin(BuildContext context) {
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
        _sheetMiddleSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _sheetController.animateTo(
        _sheetMinSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _startSheetHeaderDrag(DragStartDetails details) {
    if (!_sheetController.isAttached) return;

    _revealRequestId++;
    _sheetHeaderDragStartSize = _sheetController.size;
    _sheetHeaderDragSize = _sheetController.size;
  }

  void _updateSheetHeaderDrag(DragUpdateDetails details) {
    if (!_sheetController.isAttached || _sheetHeaderDragSize == null) return;

    final screenHeight = MediaQuery.sizeOf(context).height;
    if (screenHeight <= 0) return;

    final nextSize = (_sheetHeaderDragSize! - details.delta.dy / screenHeight)
        .clamp(_sheetMinSize, _sheetMaxSize)
        .toDouble();
    _sheetHeaderDragSize = nextSize;
    _sheetController.jumpTo(nextSize);
  }

  void _endSheetHeaderDrag(DragEndDetails details) {
    if (!_sheetController.isAttached) {
      _clearSheetHeaderDrag();
      return;
    }

    final startSize = _sheetHeaderDragStartSize ?? _sheetController.size;
    final currentSize = _sheetHeaderDragSize ?? _sheetController.size;
    final velocity = details.primaryVelocity ?? 0;
    final draggedDown = currentSize < startSize - 0.015;
    final draggedUp = currentSize > startSize + 0.015;

    final double targetSize;
    if (velocity > 250 || draggedDown) {
      targetSize = _sheetMinSize;
    } else if (velocity < -250 || draggedUp) {
      targetSize = startSize < 0.35 ? _sheetMiddleSize : _sheetMaxSize;
    } else {
      targetSize = startSize;
    }

    _clearSheetHeaderDrag();
    unawaited(
      _sheetController.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _clearSheetHeaderDrag() {
    _sheetHeaderDragStartSize = null;
    _sheetHeaderDragSize = null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final mapVM = context.watch<MapViewModel>();
    final gamificationVM = context.watch<GamificationViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nearbyArtisans = _selectedFirst(
      mapVM.nearbyArtisans,
      mapVM.selectedWorkshop?.id,
    );
    final otherArtisans = _selectedFirst(
      mapVM.otherArtisans,
      mapVM.selectedWorkshop?.id,
    );
    _reportActiveQuestProximity(mapVM, gamificationVM);
    NearbyArtisan? nearestQuestArtisan;
    for (final artisan in mapVM.nearbyArtisans) {
      if (artisan.workshop != null &&
          artisan.journey != null &&
          artisan.distanceMeters <= mapVM.questInteractionRadiusMeters) {
        nearestQuestArtisan = artisan;
        break;
      }
    }
    _reportQuestDiscovery(nearestQuestArtisan, mapVM);

    const double navigationBarHeight = 58.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF041412)
          : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // ======================================================
          // 1. GOOGLE MAP
          // ======================================================
          Positioned.fill(
            key: const ValueKey('heritage-map-layer'),
            child: GoogleMapWidget(
              workshops: mapVM.workshops,
              journeysByWorkshopId: mapVM.journeysByWorkshopId,
              selectedWorkshop: mapVM.selectedWorkshop,
              onWorkshopSelected: (workshop) {
                _onWorkshopSelected(context, workshop);
              },
              // Show Google Maps blue live-location dot
              // only after permission has been granted.
              myLocationEnabled: mapVM.hasLocationPermission,
              userLocation: mapVM.userLocation,
              interactionRadiusMeters: mapVM.questInteractionRadiusMeters,
              isActive: widget.isActive,
              isLoading: mapVM.isLoading,
              controlsBottom:
                  MediaQuery.sizeOf(context).height * _sheetMinSize + 12,
            ),
          ),

          // ======================================================
          // 2. TOP ACTION BAR
          // ======================================================
          Positioned(
            key: const ValueKey('heritage-map-controls-layer'),
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            right: 16,
            child: HeritageMapControls(
              translate: langVM.translate,
              onSettings: _showMapSettings,
            ),
          ),
          if (nearestQuestArtisan != null)
            Positioned(
              key: const ValueKey('heritage-nearby-banner-layer'),
              top: MediaQuery.paddingOf(context).top + 62,
              left: 16,
              right: 16,
              child: HeritageNearbyBanner(
                title: nearestQuestArtisan.journey!.questTitle,
                distanceMeters: nearestQuestArtisan.distanceMeters.round(),
                translate: langVM.translate,
                onTap: () => _handleViewQuest(context, nearestQuestArtisan!),
              ),
            ),

          // ======================================================
          // 4. DRAGGABLE NEARBY ARTISAN SHEET
          // ======================================================
          Positioned.fill(
            key: const ValueKey('heritage-trails-sheet-layer'),
            bottom: 0,
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _sheetMinSize,
              minChildSize: _sheetMinSize,
              maxChildSize: _sheetMaxSize,
              snap: true,
              snapSizes: [_sheetMinSize, _sheetMiddleSize, _sheetMaxSize],
              builder: (context, scrollController) {
                _sheetScrollController = scrollController;

                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0D2825)
                        : const Color(0xFFF7F2E8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    border: isDark
                        ? const Border(
                            top: BorderSide(color: Color(0xFF1E3A34)),
                          )
                        : null,
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
                      DecoratedSliver(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D2825)
                              : const Color(0xFFF7F2E8),
                          image: isDark
                              ? null
                              : const DecorationImage(
                                  image: ResizeImage(
                                    AssetImage(
                                      'assets/images/heritage_batik_background.png',
                                    ),
                                    width: 768,
                                  ),
                                  fit: BoxFit.fitWidth,
                                  alignment: Alignment.topCenter,
                                  repeat: ImageRepeat.repeatY,
                                  opacity: 0.14,
                                ),
                        ),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            // ==========================================
                            // HEADER
                            // ==========================================
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _PinnedSheetHeaderDelegate(
                                child: GestureDetector(
                                  key: const Key(
                                    'master-studios-sheet-drag-handle',
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  onVerticalDragStart: _startSheetHeaderDrag,
                                  onVerticalDragUpdate: _updateSheetHeaderDrag,
                                  onVerticalDragEnd: _endSheetHeaderDrag,
                                  onVerticalDragCancel: _clearSheetHeaderDrag,
                                  child: ListenableBuilder(
                                    listenable: _sheetController,
                                    builder: (context, _) =>
                                        HeritageSheetHeader(
                                          nearbyCount:
                                              mapVM.nearbyArtisans.length,
                                          questCount: mapVM.nearbyQuestCount,
                                          translate: langVM.translate,
                                          expanded:
                                              _sheetController.isAttached &&
                                              _sheetController.size >
                                                  _sheetMinSize + 0.03,
                                          onToggle: _toggleSliderSheet,
                                        ),
                                  ),
                                ),
                                height: HeritageSheetHeader.heightFor(
                                  MediaQuery.textScalerOf(context).scale(1),
                                ),
                              ),
                            ),

                            if (mapVM.journeyError != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    12,
                                  ),
                                  child: Material(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(14),
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.cloud_off_rounded,
                                        color: Color(0xFFB45309),
                                      ),
                                      title: Text(
                                        mapVM.journeyError!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: TextButton(
                                        onPressed: mapVM.loadJourneyData,
                                        child: const Text('RETRY'),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // ==========================================
                            // LOADING
                            // ==========================================
                            if (mapVM.isLoading)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return const ShimmerLoadingCard();
                                  }, childCount: 3),
                                ),
                              )
                            // ==========================================
                            // NO APPROVED WORKSHOPS IN DATABASE
                            // ==========================================
                            else if (mapVM.workshops.isEmpty)
                              const SliverToBoxAdapter(
                                child: EmptyMatchmakerWidget(),
                              ),

                            // ==========================================
                            // NEARBY MASTER STUDIOS
                            // ==========================================
                            if (!mapVM.isLoading &&
                                mapVM.workshops.isNotEmpty &&
                                nearbyArtisans.isEmpty)
                              SliverToBoxAdapter(
                                child: _buildInlineStudioMessage(
                                  context,
                                  mapVM.userLocation == null
                                      ? langVM.translate(
                                          'Waiting for your location to calculate studio distances.',
                                        )
                                      : langVM.translate(
                                          'No studios within 5 km of your current location.',
                                        ),
                                ),
                              ),

                            if (!mapVM.isLoading &&
                                mapVM.workshops.isNotEmpty &&
                                nearbyArtisans.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final artisan = nearbyArtisans[index];

                                    return _buildArtisanCard(
                                      context,
                                      mapVM,
                                      artisan,
                                    );
                                  }, childCount: nearbyArtisans.length),
                                ),
                              ),

                            // ==========================================
                            // OTHER MASTER STUDIOS
                            // ==========================================
                            if (!mapVM.isLoading && mapVM.workshops.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Divider(
                                        height: 24,
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    _buildStudioSectionHeader(
                                      context,
                                      title: langVM.translate(
                                        'Other Master Studios',
                                      ),
                                      subtitle: langVM.translate(
                                        'Explore artisan studios across Malaysia',
                                      ),
                                      count: otherArtisans.length,
                                    ),
                                  ],
                                ),
                              ),

                            if (!mapVM.isLoading &&
                                mapVM.workshops.isNotEmpty &&
                                otherArtisans.isEmpty)
                              SliverToBoxAdapter(
                                child: _buildInlineStudioMessage(
                                  context,
                                  mapVM.userLocation == null
                                      ? langVM.translate(
                                          'Waiting for your location to classify other studios.',
                                        )
                                      : langVM.translate(
                                          'All available studios are within 5 km of you.',
                                        ),
                                ),
                              ),

                            if (!mapVM.isLoading &&
                                mapVM.workshops.isNotEmpty &&
                                otherArtisans.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final artisan = otherArtisans[index];

                                    return _buildArtisanCard(
                                      context,
                                      mapVM,
                                      artisan,
                                    );
                                  }, childCount: otherArtisans.length),
                                ),
                              ),

                            // ==========================================
                            // NAVIGATION BAR SAFE SPACE
                            // ==========================================
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    navigationBarHeight + bottomSafeArea + 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedSheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  final double height;
  const _PinnedSheetHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF0D2825) : const Color(0xFFF7F2E8),
      elevation: overlapsContent ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSheetHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
