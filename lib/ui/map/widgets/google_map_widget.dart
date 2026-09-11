import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/domain/models/user_location.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';

class GoogleMapWidget extends StatefulWidget {
  final List<WorkshopLocation> workshops;
  final Map<String, WorkshopQuestJourney> journeysByWorkshopId;

  final WorkshopLocation? selectedWorkshop;

  final ValueChanged<WorkshopLocation> onWorkshopSelected;

  final bool myLocationEnabled;

  // Current live GPS position from MapViewModel.
  final UserLocation? userLocation;

  // Application-defined quest range supplied by MapViewModel.
  final double interactionRadiusMeters;

  // True while this map is the visible IndexedStack tab.
  final bool isActive;

  final bool isLoading;
  final double controlsBottom;

  const GoogleMapWidget({
    super.key,
    required this.workshops,
    this.journeysByWorkshopId = const {},
    required this.selectedWorkshop,
    required this.onWorkshopSelected,
    required this.myLocationEnabled,
    required this.userLocation,
    required this.interactionRadiusMeters,
    this.isActive = true,
    this.isLoading = false,
    this.controlsBottom = 190,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;

  late final AnimationController _headingController;
  Animation<double>? _headingAnimation;
  double _displayedHeading = 0.0;

  bool _hasAutoCentered = false;
  bool _autoCenterScheduled = false;
  bool _followUserLocation = false;
  bool _programmaticCameraMove = false;
  bool _followCameraUpdateInProgress = false;
  LatLng? _lastFollowedLocation;

  BitmapDescriptor _touristMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueCyan,
  );
  BitmapDescriptor _workshopMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueOrange,
  );
  BitmapDescriptor _selectedWorkshopMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor _activeQuestMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  BitmapDescriptor _completedQuestMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor _unavailableQuestMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);

  static const double _minimumZoom = 3.0;
  static const double _maximumZoom = 20.0;
  static const double _locationZoom = 18.0;

  // Local map styling keeps live Google streets and geographic labels.
  static const String _heritageMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#f7f2e8"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#51483f"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#f7f2e8"}]},
    {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#d0dbc6"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#e4d5bc"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d5c3a5"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#b59a79"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#a38a6c"}]},
    {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#a6c5c3"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#526e70"}]}
  ]
  ''';

  // Night palette based on Warisan Kita's deep emerald, bronze, and gold
  // identity. Business clutter stays hidden while cultural attractions retain
  // a restrained gold treatment.
  static const String _darkHeritageMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#101c19"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#c8bda8"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#101c19"}]},
    {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#56645d"}]},
    {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#263b35"}]},
    {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#3e574f"}]},
    {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.attraction","elementType":"labels.text.fill","stylers":[{"color":"#d5a928"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#28483a"}]},
    {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9caf9d"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#786950"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#4d4639"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#e4dac5"}]},
    {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#2b2923"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#a58a59"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#5c4c35"}]},
    {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#394a43"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#123e43"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#8eafb0"}]}
  ]
  ''';

  // Default Malaysia view.
  static const LatLng _initialPosition = LatLng(3.1390, 101.6869);

  @override
  void initState() {
    super.initState();
    _displayedHeading = _normalizedHeading(widget.userLocation?.heading ?? 0);
    _headingController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 360),
        )..addListener(() {
          final animation = _headingAnimation;
          if (mounted && animation != null) {
            setState(() {
              _displayedHeading = _normalizedHeading(animation.value);
            });
          }
        });
    _loadGameMarkerIcons();
  }

  @override
  void didUpdateWidget(covariant GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.userLocation?.heading != oldWidget.userLocation?.heading) {
      _animateTouristHeading(widget.userLocation?.heading);
    }

    final locationChanged =
        widget.userLocation?.latitude != oldWidget.userLocation?.latitude ||
        widget.userLocation?.longitude != oldWidget.userLocation?.longitude;
    if (locationChanged) {
      _followLatestUserLocation();
    }

    if (widget.selectedWorkshop?.id != oldWidget.selectedWorkshop?.id &&
        widget.selectedWorkshop != null) {
      _followUserLocation = false;
      _centerOnWorkshop(widget.selectedWorkshop!);
    }

    if (widget.isActive && !oldWidget.isActive) {
      _hasAutoCentered = false;
      _tryAutoCenterOnUser();
      return;
    }

    if (!_hasAutoCentered && widget.isActive) {
      _tryAutoCenterOnUser();
    }
  }

  double _normalizedHeading(double heading) =>
      heading.isFinite ? (heading % 360 + 360) % 360 : 0.0;

  void _animateTouristHeading(double? rawHeading) {
    if (rawHeading == null ||
        !rawHeading.isFinite ||
        rawHeading < 0 ||
        rawHeading >= 360) {
      return;
    }

    final target = _normalizedHeading(rawHeading);
    // Rotate through the shortest direction across the 0/360 boundary.
    final delta = (target - _displayedHeading + 540) % 360 - 180;
    if (delta.abs() < 0.5) return;

    if (!widget.isActive) {
      _headingController.stop();
      _displayedHeading = target;
      return;
    }

    // Short compass animations overlap live sensor updates without creating
    // visible steps. Larger turns receive slightly more travel time.
    final animationMilliseconds = (85 + delta.abs() * 0.65)
        .clamp(85, 190)
        .round();
    _headingController.duration = Duration(milliseconds: animationMilliseconds);

    _headingAnimation =
        Tween<double>(
          begin: _displayedHeading,
          end: _displayedHeading + delta,
        ).animate(
          CurvedAnimation(parent: _headingController, curve: Curves.easeOut),
        );
    _headingController.forward(from: 0);
  }

  bool _hasValidUserLocation() {
    final location = widget.userLocation;

    return location != null &&
        location.latitude.isFinite &&
        location.longitude.isFinite &&
        location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }

  Future<void> _loadGameMarkerIcons() async {
    final icons = await Future.wait([
      _createGameMarkerIcon(
        backgroundColor: const Color(0xFF00695C),
        borderColor: const Color(0xFFFFD54F),
        glyph: _drawTouristGlyph,
        directional: true,
      ),
      _createGameMarkerIcon(
        backgroundColor: const Color(0xFFFFD54F),
        borderColor: const Color(0xFF00695C),
        glyph: _drawWorkshopGlyph,
      ),
      _createGameMarkerIcon(
        backgroundColor: const Color(0xFFD97706),
        borderColor: const Color(0xFFFFF8E1),
        glyph: _drawWorkshopGlyph,
        selected: true,
      ),
      _createGameMarkerIcon(
        backgroundColor: const Color(0xFFE67E00),
        borderColor: const Color(0xFFFFD54F),
        glyph: _drawWorkshopGlyph,
      ),
      _createGameMarkerIcon(
        backgroundColor: const Color(0xFF00695C),
        borderColor: const Color(0xFFFFD54F),
        glyph: _drawCompletedGlyph,
      ),
      _createGameMarkerIcon(
        backgroundColor: const Color(0xFF94A3B8),
        borderColor: const Color(0xFFE2E8F0),
        glyph: _drawLockedGlyph,
      ),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _touristMarkerIcon = icons[0];
      _workshopMarkerIcon = icons[1];
      _selectedWorkshopMarkerIcon = icons[2];
      _activeQuestMarkerIcon = icons[3];
      _completedQuestMarkerIcon = icons[4];
      _unavailableQuestMarkerIcon = icons[5];
    });
  }

  Future<BitmapDescriptor> _createGameMarkerIcon({
    required Color backgroundColor,
    required Color borderColor,
    required void Function(ui.Canvas canvas, ui.Offset center) glyph,
    bool directional = false,
    bool selected = false,
  }) async {
    const double width = 112;
    final double height = directional ? 112 : 140;
    final ui.Offset center = ui.Offset(width / 2, directional ? 56 : 55);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    if (directional) {
      canvas.drawCircle(
        center.translate(0, 4),
        44,
        ui.Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
      canvas.drawCircle(center, 44, ui.Paint()..color = backgroundColor);
      canvas.drawCircle(
        center,
        44,
        ui.Paint()
          ..color = borderColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 7,
      );
    } else {
      final pinPath = ui.Path()
        ..moveTo(56, 134)
        ..cubicTo(48, 113, 13, 88, 13, 55)
        ..cubicTo(13, 31, 32, 12, 56, 12)
        ..cubicTo(80, 12, 99, 31, 99, 55)
        ..cubicTo(99, 88, 64, 113, 56, 134)
        ..close();

      canvas.drawPath(
        pinPath.shift(const ui.Offset(0, 4)),
        ui.Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
      canvas.drawPath(pinPath, ui.Paint()..color = backgroundColor);
      canvas.drawPath(
        pinPath,
        ui.Paint()
          ..color = borderColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 7,
      );
    }
    canvas.drawCircle(
      center,
      32,
      ui.Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = ui.PaintingStyle.fill,
    );

    glyph(canvas, center);

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.bytes(
      byteData.buffer.asUint8List(),
      width: directional ? 52 : (selected ? 52 : 46),
      height: directional ? 52 : (selected ? 65.5 : 58),
    );
  }

  void _drawTouristGlyph(ui.Canvas canvas, ui.Offset center) {
    final whitePaint = ui.Paint()..color = Colors.white;
    final accentPaint = ui.Paint()..color = const Color(0xFFFFD54F);

    // The arrow is drawn facing north, then Google Maps rotates the complete
    // circular marker using the live GPS heading.
    final directionArrow = ui.Path()
      ..moveTo(center.dx, center.dy - 29)
      ..lineTo(center.dx + 21, center.dy + 23)
      ..lineTo(center.dx, center.dy + 13)
      ..lineTo(center.dx - 21, center.dy + 23)
      ..close();

    canvas.drawPath(directionArrow, whitePaint);
    canvas.drawCircle(center.translate(0, 5), 7, accentPaint);
  }

  void _drawWorkshopGlyph(ui.Canvas canvas, ui.Offset center) {
    final whitePaint = ui.Paint()..color = Colors.white;
    final accentPaint = ui.Paint()..color = const Color(0xFF00695C);

    canvas.drawRect(
      ui.Rect.fromCenter(center: center.translate(0, 9), width: 39, height: 28),
      whitePaint,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: center.translate(0, -9),
          width: 47,
          height: 16,
        ),
        const ui.Radius.circular(5),
      ),
      whitePaint,
    );
    canvas.drawRect(
      ui.Rect.fromCenter(
        center: center.translate(0, 10),
        width: 10,
        height: 20,
      ),
      accentPaint,
    );
    canvas.drawCircle(center.translate(-13, 9), 4, accentPaint);
    canvas.drawCircle(center.translate(13, 9), 4, accentPaint);
  }

  void _drawCompletedGlyph(ui.Canvas canvas, ui.Offset center) {
    final check = ui.Path()
      ..moveTo(center.dx - 20, center.dy)
      ..lineTo(center.dx - 6, center.dy + 15)
      ..lineTo(center.dx + 23, center.dy - 18);
    canvas.drawPath(
      check,
      ui.Paint()
        ..color = Colors.white
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round,
    );
  }

  void _drawLockedGlyph(ui.Canvas canvas, ui.Offset center) {
    final paint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = ui.StrokeCap.round;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: center.translate(0, 9),
          width: 38,
          height: 31,
        ),
        const ui.Radius.circular(5),
      ),
      paint,
    );
    canvas.drawArc(
      ui.Rect.fromCenter(
        center: center.translate(0, -7),
        width: 25,
        height: 28,
      ),
      3.14,
      3.14,
      false,
      paint,
    );
  }

  BitmapDescriptor _iconForWorkshop(
    WorkshopQuestJourney? journey, {
    required bool isSelected,
  }) {
    if (journey?.state == WorkshopQuestState.completed) {
      return _completedQuestMarkerIcon;
    }
    if (isSelected) return _selectedWorkshopMarkerIcon;
    return switch (journey?.state) {
      WorkshopQuestState.inProgress => _activeQuestMarkerIcon,
      WorkshopQuestState.available => _workshopMarkerIcon,
      WorkshopQuestState.blockedByOtherQuest => _unavailableQuestMarkerIcon,
      WorkshopQuestState.completed => _completedQuestMarkerIcon,
      WorkshopQuestState.unavailable || null => _unavailableQuestMarkerIcon,
    };
  }

  // ============================================================
  // WORKSHOP MARKERS
  // ============================================================

  Set<Marker> _buildMarkers() {
    final markers = widget.workshops.map((workshop) {
      final bool isSelected = widget.selectedWorkshop?.id == workshop.id;
      final journey = widget.journeysByWorkshopId[workshop.id];

      return Marker(
        markerId: MarkerId(workshop.id),

        position: LatLng(workshop.latitude, workshop.longitude),

        icon: _iconForWorkshop(journey, isSelected: isSelected),

        infoWindow: InfoWindow(
          title: workshop.name,
          snippet: journey == null
              ? '${workshop.craftCategory} • View quest'
              : '${journey.stateLabel} • ${journey.progressLabel}',
        ),

        onTap: () {
          widget.onWorkshopSelected(workshop);
        },
      );
    }).toSet();

    final location = widget.userLocation;

    if (_hasValidUserLocation() && location != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('tourist_live_location'),
          position: LatLng(location.latitude, location.longitude),
          icon: _touristMarkerIcon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: _displayedHeading,
          infoWindow: const InfoWindow(
            title: 'You are here',
            snippet: 'Tourist quest position',
          ),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // QUEST INTERACTION RADIUS
  // ============================================================

  Set<Circle> _buildInteractionCircles() {
    final location = widget.userLocation;

    if (!_hasValidUserLocation() ||
        location == null ||
        !widget.interactionRadiusMeters.isFinite ||
        widget.interactionRadiusMeters <= 0) {
      return const <Circle>{};
    }

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('user_interaction_radius'),
        center: LatLng(location.latitude, location.longitude),
        radius: widget.interactionRadiusMeters,
        strokeColor: const Color(0xFF00897B),
        strokeWidth: 2,
        fillColor: const Color(0xFF26A69A).withValues(alpha: 0.11),
        consumeTapEvents: false,
      ),
    };
    return circles;
  }

  // ============================================================
  // RECENTER TO LIVE GPS LOCATION
  // ============================================================

  Future<void> _tryAutoCenterOnUser() async {
    final controller = _mapController;
    final location = widget.userLocation;

    if (_hasAutoCentered ||
        _autoCenterScheduled ||
        controller == null ||
        !widget.isActive ||
        !widget.myLocationEnabled ||
        !_hasValidUserLocation() ||
        location == null) {
      return;
    }

    // Wait for platform-map layout, including IndexedStack tab activation.
    _autoCenterScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted ||
            !widget.isActive ||
            !widget.myLocationEnabled ||
            !_hasValidUserLocation() ||
            _mapController != controller) {
          return;
        }
        final latestLocation = widget.userLocation!;
        await controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(latestLocation.latitude, latestLocation.longitude),
              zoom: _locationZoom,
            ),
          ),
        );
        if (mounted && widget.isActive) {
          _hasAutoCentered = true;
          _followUserLocation = true;
          _lastFollowedLocation = LatLng(
            latestLocation.latitude,
            latestLocation.longitude,
          );
        }
      } catch (error) {
        debugPrint('Initial map centering failed: $error');
      } finally {
        _autoCenterScheduled = false;
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _recenterToUser() async {
    final controller = _mapController;
    final location = widget.userLocation;

    if (controller == null) {
      return;
    }

    if (!widget.myLocationEnabled || location == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location is not available yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final target = LatLng(location.latitude, location.longitude);
    _followUserLocation = true;
    _lastFollowedLocation = target;
    await _runProgrammaticCameraUpdate(
      controller,
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: _locationZoom),
      ),
    );
  }

  Future<void> _followLatestUserLocation() async {
    final controller = _mapController;
    final location = widget.userLocation;
    if (!_followUserLocation ||
        _followCameraUpdateInProgress ||
        controller == null ||
        !widget.isActive ||
        !widget.myLocationEnabled ||
        !_hasValidUserLocation() ||
        location == null) {
      return;
    }

    final target = LatLng(location.latitude, location.longitude);
    final previousTarget = _lastFollowedLocation;
    if (previousTarget != null &&
        _distanceMeters(previousTarget, target) < 2.0) {
      return;
    }

    _followCameraUpdateInProgress = true;
    _lastFollowedLocation = target;
    try {
      final zoom = await controller.getZoomLevel();
      if (!mounted || !_followUserLocation || !widget.isActive) return;
      await _runProgrammaticCameraUpdate(
        controller,
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (error) {
      debugPrint('Live map following failed: $error');
    } finally {
      _followCameraUpdateInProgress = false;
      if (mounted && _followUserLocation) {
        final latest = widget.userLocation;
        if (latest != null &&
            _distanceMeters(
                  target,
                  LatLng(latest.latitude, latest.longitude),
                ) >=
                2.0) {
          _followLatestUserLocation();
        }
      }
    }
  }

  Future<void> _runProgrammaticCameraUpdate(
    GoogleMapController controller,
    CameraUpdate update,
  ) async {
    _programmaticCameraMove = true;
    try {
      await controller.animateCamera(update);
    } finally {
      _programmaticCameraMove = false;
    }
  }

  double _distanceMeters(LatLng from, LatLng to) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(to.latitude - from.latitude);
    final longitudeDelta = _toRadians(to.longitude - from.longitude);
    final fromLatitude = _toRadians(from.latitude);
    final toLatitude = _toRadians(to.latitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(fromLatitude) *
            math.cos(toLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final boundedHaversine = haversine.clamp(0.0, 1.0);
    return earthRadiusMeters *
        2 *
        math.atan2(
          math.sqrt(boundedHaversine),
          math.sqrt(1 - boundedHaversine),
        );
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  Future<void> _centerOnWorkshop(WorkshopLocation workshop) async {
    final controller = _mapController;
    if (controller == null ||
        !widget.isActive ||
        !_hasAutoCentered ||
        _autoCenterScheduled) {
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(workshop.latitude, workshop.longitude)),
    );
  }

  // ============================================================
  // ZOOM IN
  // ============================================================

  Future<void> _zoomIn() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    final currentZoom = await controller.getZoomLevel();

    final newZoom = (currentZoom + 1)
        .clamp(_minimumZoom, _maximumZoom)
        .toDouble();

    await _runProgrammaticCameraUpdate(
      controller,
      CameraUpdate.zoomTo(newZoom),
    );
  }

  // ============================================================
  // ZOOM OUT
  // ============================================================

  Future<void> _zoomOut() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    final currentZoom = await controller.getZoomLevel();

    final newZoom = (currentZoom - 1)
        .clamp(_minimumZoom, _maximumZoom)
        .toDouble();

    await _runProgrammaticCameraUpdate(
      controller,
      CameraUpdate.zoomTo(newZoom),
    );
  }

  // ============================================================
  // CONTROL BUTTON
  // ============================================================

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    String? tooltip,
  }) {
    return Material(
      color: isDark ? const Color(0xFF173C35) : Colors.white,
      elevation: 4,
      shadowColor: isDark ? Colors.black87 : Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFFB8943E) : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              size: 24,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = widget.userLocation;
    final hasInitialUserLocation =
        widget.isActive && widget.myLocationEnabled && _hasValidUserLocation();

    return Stack(
      children: [
        // ======================================================
        // GOOGLE MAP
        // ======================================================
        Positioned.fill(
          child: GoogleMap(
            style: isDark ? _darkHeritageMapStyle : _heritageMapStyle,
            initialCameraPosition: CameraPosition(
              target: hasInitialUserLocation && location != null
                  ? LatLng(location.latitude, location.longitude)
                  : _initialPosition,
              zoom: hasInitialUserLocation ? _locationZoom : 6.0,
            ),

            markers: _buildMarkers(),

            circles: _buildInteractionCircles(),

            mapType: MapType.normal,

            // ==================================================
            // CUSTOM LIVE TOURIST MARKER
            // ==================================================

            // Google's native blue dot cannot be styled. The live tourist
            // marker is included in _buildMarkers() instead.
            myLocationEnabled: false,

            // Disabled because we are using
            // our own recenter button.
            myLocationButtonEnabled: false,

            // Disabled because we are using
            // custom + and - buttons.
            zoomControlsEnabled: false,

            compassEnabled: true,

            rotateGesturesEnabled: true,

            scrollGesturesEnabled: true,

            zoomGesturesEnabled: true,

            tiltGesturesEnabled: true,

            buildingsEnabled: true,

            trafficEnabled: false,

            // ==================================================
            // MAP CONTROLLER
            // ==================================================
            onMapCreated: (controller) {
              _mapController = controller;
              _tryAutoCenterOnUser();
            },
            onCameraMoveStarted: () {
              if (!_programmaticCameraMove) {
                _followUserLocation = false;
              }
            },
          ),
        ),

        // ======================================================
        // MAP CONTROLS
        // ======================================================
        Positioned(
          right: 16,

          // Keeps controls above the collapsed
          // Nearby Master Studios sheet.
          bottom: widget.controlsBottom,

          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==============================================
                // RECENTER
                // ==============================================
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  isDark: isDark,
                  tooltip: 'My location',
                  onPressed: () {
                    _recenterToUser();
                  },
                ),

                const SizedBox(height: 12),

                // ==============================================
                // ZOOM IN
                // ==============================================
                _buildMapButton(
                  icon: Icons.add_rounded,
                  isDark: isDark,
                  tooltip: 'Zoom in',
                  onPressed: () {
                    _zoomIn();
                  },
                ),

                const SizedBox(height: 6),

                // ==============================================
                // ZOOM OUT
                // ==============================================
                _buildMapButton(
                  icon: Icons.remove_rounded,
                  isDark: isDark,
                  tooltip: 'Zoom out',
                  onPressed: () {
                    _zoomOut();
                  },
                ),
              ],
            ),
          ),
        ),

        // ======================================================
        // LOADING
        // ======================================================
        if (widget.isLoading)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _headingController.dispose();
    _mapController?.dispose();

    super.dispose();
  }
}
