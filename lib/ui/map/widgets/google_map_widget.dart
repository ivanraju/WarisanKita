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

  final bool isLoading;

  const GoogleMapWidget({
    super.key,
    required this.workshops,
    required this.selectedWorkshop,
    required this.onWorkshopSelected,
    required this.myLocationEnabled,
    required this.userLocation,
    this.isLoading = false,
  });

  @override
  State<GoogleMapWidget> createState() =>
      _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;

  double _currentZoom = 6.0;

  static const double _minimumZoom = 3.0;
  static const double _maximumZoom = 20.0;

  // Default Malaysia view.
  static const LatLng _initialPosition = LatLng(
    3.1390,
    101.6869,
  );

  // ============================================================
  // WORKSHOP MARKERS
  // ============================================================

  Set<Marker> _buildMarkers() {
    return widget.workshops.map(
          (workshop) {
        final bool isSelected =
            widget.selectedWorkshop?.id ==
                workshop.id;

        return Marker(
          markerId: MarkerId(
            workshop.id,
          ),

          position: LatLng(
            workshop.latitude,
            workshop.longitude,
          ),

          icon:
          BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),

          infoWindow: InfoWindow(
            title: workshop.name,
            snippet:
            workshop.craftCategory,
          ),

          onTap: () {
            widget.onWorkshopSelected(
              workshop,
            );
          },
        );
      },
    ).toSet();
  }

  // ============================================================
  // RECENTER TO LIVE GPS LOCATION
  // ============================================================

  Future<void> _recenterToUser() async {
    final controller = _mapController;
    final location = widget.userLocation;

    if (controller == null) {
      return;
    }

    if (!widget.myLocationEnabled ||
        location == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Current location is not available yet.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    const double locationZoom = 16.0;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            location.latitude,
            location.longitude,
          ),
          zoom: locationZoom,
        ),
      ),
    );

    _currentZoom = locationZoom;
  }

  // ============================================================
  // ZOOM IN
  // ============================================================

  Future<void> _zoomIn() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    final currentZoom =
    await controller.getZoomLevel();

    final newZoom =
    (currentZoom + 1)
        .clamp(
      _minimumZoom,
      _maximumZoom,
    )
        .toDouble();

    await controller.animateCamera(
      CameraUpdate.zoomTo(
        newZoom,
      ),
    );

    _currentZoom = newZoom;
  }

  // ============================================================
  // ZOOM OUT
  // ============================================================

  Future<void> _zoomOut() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    final currentZoom =
    await controller.getZoomLevel();

    final newZoom =
    (currentZoom - 1)
        .clamp(
      _minimumZoom,
      _maximumZoom,
    )
        .toDouble();

    await controller.animateCamera(
      CameraUpdate.zoomTo(
        newZoom,
      ),
    );

    _currentZoom = newZoom;
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
      borderRadius:
      BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius:
        BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              size: 24,
              color: const Color(
                0xFF004D40,
              ),
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
    return Stack(
      children: [
        // ======================================================
        // GOOGLE MAP
        // ======================================================

        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition:
            const CameraPosition(
              target:
              _initialPosition,
              zoom: 6.0,
            ),

            markers:
            _buildMarkers(),

            mapType:
            MapType.normal,

            // ==================================================
            // LIVE GPS BLUE DOT
            // ==================================================

            myLocationEnabled:
            widget
                .myLocationEnabled,

            // Disabled because we are using
            // our own recenter button.
            myLocationButtonEnabled:
            false,

            // Disabled because we are using
            // custom + and - buttons.
            zoomControlsEnabled:
            false,

            compassEnabled:
            true,

            rotateGesturesEnabled:
            true,

            scrollGesturesEnabled:
            true,

            zoomGesturesEnabled:
            true,

            tiltGesturesEnabled:
            true,

            buildingsEnabled:
            true,

            trafficEnabled:
            false,

            // ==================================================
            // MAP CONTROLLER
            // ==================================================

            onMapCreated:
                (controller) {
              _mapController =
                  controller;
            },

            onCameraMove:
                (position) {
              _currentZoom =
                  position.zoom;
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
              mainAxisSize:
              MainAxisSize.min,
              children: [
                // ==============================================
                // RECENTER
                // ==============================================

                _buildMapButton(
                  icon:
                  Icons.my_location_rounded,
                  tooltip:
                  'My location',
                  onPressed: () {
                    _recenterToUser();
                  },
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==============================================
                // ZOOM IN
                // ==============================================

                _buildMapButton(
                  icon:
                  Icons.add_rounded,
                  tooltip:
                  'Zoom in',
                  onPressed: () {
                    _zoomIn();
                  },
                ),

                const SizedBox(
                  height: 6,
                ),

                // ==============================================
                // ZOOM OUT
                // ==============================================

                _buildMapButton(
                  icon:
                  Icons.remove_rounded,
                  tooltip:
                  'Zoom out',
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
              child: Center(
                child:
                CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();

    super.dispose();
  }
}

