import 'dart:async';

import 'package:flutter/material.dart';

import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/location_repository.dart';

import 'package:warisan_kita/domain/models/nearby_artisan.dart';
import 'package:warisan_kita/domain/models/user_location.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';

class MapViewModel extends ChangeNotifier {
  final ArtisanRepository _artisanRepository;
  final LocationRepository _locationRepository;

  MapViewModel({
    required ArtisanRepository artisanRepository,
    required LocationRepository locationRepository,
  })  : _artisanRepository = artisanRepository,
        _locationRepository = locationRepository {
    loadWorkshops();
  }

  // ============================================================
  // WORKSHOP STATE
  // ============================================================

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<WorkshopLocation> _workshops = [];
  List<WorkshopLocation> get workshops => _workshops;

  List<NearbyArtisan> _nearbyArtisans = [];
  List<NearbyArtisan> get nearbyArtisans => _nearbyArtisans;

  WorkshopLocation? _selectedWorkshop;
  WorkshopLocation? get selectedWorkshop => _selectedWorkshop;

  // ============================================================
  // SEARCH RADIUS STATE
  // ============================================================

  static const double defaultNearbyRadiusMeters = 5000;
  static const List<double> radiusSteps = [5000, 10000, 20000, 50000];

  double _nearbyRadiusMeters = defaultNearbyRadiusMeters;
  double get nearbyRadiusMeters => _nearbyRadiusMeters;

  // ============================================================
  // LIVE GPS STATE
  // ============================================================

  UserLocation? _userLocation;
  UserLocation? get userLocation => _userLocation;

  bool _hasLocationPermission = false;
  bool get hasLocationPermission => _hasLocationPermission;

  bool _isTrackingLocation = false;
  bool get isTrackingLocation => _isTrackingLocation;

  String? _locationError;
  String? get locationError => _locationError;

  StreamSubscription<UserLocation>? _locationSubscription;

  // ============================================================
  // LOAD WORKSHOPS (ASYNC SYNC CASE A & B)
  // ============================================================

  Future<void> loadWorkshops() async {
    _isLoading = true;
    notifyListeners();

    try {
      _workshops = await _artisanRepository.getWorkshopLocations();

      debugPrint('Loaded workshops: ${_workshops.length}');

      // Synchronisation: Recalculate nearby artisans if GPS was already available
      _updateNearbyArtisans();
    } catch (e) {
      debugPrint('MapViewModel loadWorkshops error: $e');
      _workshops = [];
      _nearbyArtisans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // START LIVE GPS (ASYNC SYNC CASE A & B)
  // ============================================================

  Future<void> startLocationTracking() async {
    // Prevent multiple stream subscriptions.
    if (_isTrackingLocation) {
      return;
    }

    _locationError = null;

    try {
      await _locationRepository.requestLocationAccess();

      _hasLocationPermission = true;
      _isTrackingLocation = true;
      notifyListeners();

      // 1. Get an immediate position first.
      _userLocation = await _locationRepository.getCurrentLocation();

      debugPrint(
        'Initial GPS position: '
            '${_userLocation!.latitude}, ${_userLocation!.longitude}',
      );

      // Recalculate immediately with the initial GPS position.
      _updateNearbyArtisans();
      notifyListeners();

      // 2. Continue listening for live movement updates.
      _locationSubscription = _locationRepository.watchLocation().listen(
            (location) {
          _userLocation = location;

          debugPrint(
            'GPS stream update: '
                '${location.latitude}, ${location.longitude}',
          );

          _updateNearbyArtisans();
          notifyListeners();
        },
        onError: (error) {
          _locationError = error.toString();
          debugPrint('GPS stream error: $error');
          notifyListeners();
        },
      );
    } catch (e) {
      _hasLocationPermission = false;
      _isTrackingLocation = false;
      _locationError = e.toString();

      debugPrint('Location error: $e');
      notifyListeners();
    }
  }

  // ============================================================
  // DISTANCE CALCULATION & NEARBY FILTERING
  // ============================================================

  void _updateNearbyArtisans() {
    final location = _userLocation;

    if (location == null || _workshops.isEmpty) {
      _nearbyArtisans = [];
      return;
    }

    debugPrint('========================================');
    debugPrint('User GPS:');
    debugPrint('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
    debugPrint('Search radius:');
    debugPrint('${_nearbyRadiusMeters.toStringAsFixed(0)} m');

    final results = <NearbyArtisan>[];

    for (final workshop in _workshops) {
      final distance = _locationRepository.calculateDistance(
        startLatitude: location.latitude,
        startLongitude: location.longitude,
        endLatitude: workshop.latitude,
        endLongitude: workshop.longitude,
      );

      final isNearby = distance <= _nearbyRadiusMeters;

      debugPrint('Workshop:');
      debugPrint(workshop.name);
      debugPrint('Distance:');
      debugPrint('${distance.toStringAsFixed(1)} m');
      debugPrint('Nearby result:');
      debugPrint(isNearby ? 'TRUE' : 'FALSE');

      if (isNearby) {
        results.add(
          NearbyArtisan.fromWorkshop(
            workshop: workshop,
            distanceMeters: distance,
          ),
        );
      }
    }

    // Sort nearest → farthest
    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    _nearbyArtisans = results;

    debugPrint('Nearby artisans:');
    debugPrint('${_nearbyArtisans.length}');
    debugPrint('========================================');
  }

  // ============================================================
  // SEARCH RADIUS CONTROLS
  // ============================================================

  /// Expands search radius through progression: 5km -> 10km -> 20km -> 50km.
  void expandNearbyRadius() {
    for (final step in radiusSteps) {
      if (step > _nearbyRadiusMeters) {
        _nearbyRadiusMeters = step;
        _updateNearbyArtisans();
        notifyListeners();
        return;
      }
    }
    // Already at max radius (50 km); recalculate in case data changed.
    _updateNearbyArtisans();
    notifyListeners();
  }

  /// Sets custom search radius in metres.
  void setNearbyRadius(double radiusMeters) {
    _nearbyRadiusMeters = radiusMeters;
    _updateNearbyArtisans();
    notifyListeners();
  }

  /// Resets search radius back to default (5000 metres).
  void resetNearbyRadius() {
    _nearbyRadiusMeters = defaultNearbyRadiusMeters;
    _updateNearbyArtisans();
    notifyListeners();
  }

  // ============================================================
  // SELECT WORKSHOP
  // ============================================================

  void selectWorkshop(WorkshopLocation? workshop) {
    if (_selectedWorkshop?.id == workshop?.id) {
      _selectedWorkshop = null;
    } else {
      _selectedWorkshop = workshop;
    }

    notifyListeners();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshWorkshops() async {
    await loadWorkshops();
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTrackingLocation = false;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}