import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/domain/models/user_location.dart';

class GoogleMapWidget extends StatefulWidget {
  final List<WorkshopLocation> workshops;

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

  const GoogleMapWidget({
    super.key,
    required this.workshops,
    required this.selectedWorkshop,
    required this.onWorkshopSelected,
    required this.myLocationEnabled,
    required this.userLocation,
    required this.interactionRadiusMeters,
    this.isActive = true,
    this.isLoading = false,
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

  BitmapDescriptor _touristMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueCyan,
  );
  BitmapDescriptor _workshopMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueOrange,
  );
  BitmapDescriptor _selectedWorkshopMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  static const double _minimumZoom = 3.0;
  static const double _maximumZoom = 20.0;
  static const double _locationZoom = 18.0;

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

    if (widget.isActive && !oldWidget.isActive) {
      _hasAutoCentered = false;
      _tryAutoCenterOnUser();
      return;
    }

    if (!_hasAutoCentered &&
        widget.isActive &&
        widget.userLocation != oldWidget.userLocation) {
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
    _headingController.duration = Duration(
      milliseconds: animationMilliseconds,
    );

    _headingAnimation =
        Tween<double>(
          begin: _displayedHeading,
          end: _displayedHeading + delta,
        ).animate(
          CurvedAnimation(
            parent: _headingController,
            curve: Curves.easeOut,
          ),
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
        backgroundColor: const Color(0xFFFFC107),
        borderColor: const Color(0xFF00695C),
        glyph: _drawWorkshopGlyph,
      ),
      _createGameMarkerIcon(
        backgroundColor: const Color(0xFFD97706),
        borderColor: const Color(0xFFFFF8E1),
        glyph: _drawWorkshopGlyph,
      ),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _touristMarkerIcon = icons[0];
      _workshopMarkerIcon = icons[1];
      _selectedWorkshopMarkerIcon = icons[2];
    });
  }

  Future<BitmapDescriptor> _createGameMarkerIcon({
    required Color backgroundColor,
    required Color borderColor,
    required void Function(ui.Canvas canvas, ui.Offset center) glyph,
    bool directional = false,
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
      width: directional ? 52 : 46,
      height: directional ? 52 : 58,
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

  // ============================================================
  // WORKSHOP MARKERS
  // ============================================================

  Set<Marker> _buildMarkers() {
    final markers = widget.workshops.map((workshop) {
      final bool isSelected = widget.selectedWorkshop?.id == workshop.id;

      return Marker(
        markerId: MarkerId(workshop.id),

        position: LatLng(workshop.latitude, workshop.longitude),

        icon: isSelected ? _selectedWorkshopMarkerIcon : _workshopMarkerIcon,

        infoWindow: InfoWindow(
          title: workshop.name,
          snippet: workshop.craftCategory,
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

    return {
      Circle(
        circleId: const CircleId('user_interaction_radius'),
        center: LatLng(location.latitude, location.longitude),
        radius: widget.interactionRadiusMeters,
        strokeColor: const Color(0xFF00897B),
        strokeWidth: 2,
        fillColor: const Color(0xFF26A69A).withValues(alpha: 0.16),
        consumeTapEvents: false,
      ),
    };
  }

  // ============================================================
  // RECENTER TO LIVE GPS LOCATION
  // ============================================================

  Future<void> _tryAutoCenterOnUser() async {
    final controller = _mapController;
    final location = widget.userLocation;

    if (_hasAutoCentered ||
        controller == null ||
        !widget.isActive ||
        !widget.myLocationEnabled ||
        !_hasValidUserLocation() ||
        location == null) {
      return;
    }

    // Set before awaiting so rapid Provider updates cannot start a second
    // camera animation. Later GPS movement only moves the marker and circle.
    _hasAutoCentered = true;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: _locationZoom,
        ),
      ),
    );
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

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: _locationZoom,
        ),
      ),
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

    await controller.animateCamera(CameraUpdate.zoomTo(newZoom));
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

    await controller.animateCamera(CameraUpdate.zoomTo(newZoom));
  }

  // ============================================================
  // CONTROL BUTTON
  // ============================================================

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, size: 24, color: const Color(0xFF004D40)),
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
          ),
        ),

        // ======================================================
        // MAP CONTROLS
        // ======================================================
        Positioned(
          right: 16,

          // Keeps controls above the collapsed
          // Nearby Master Studios sheet.
          bottom: 190,

          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==============================================
                // RECENTER
                // ==============================================
                _buildMapButton(
                  icon: Icons.my_location_rounded,
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
