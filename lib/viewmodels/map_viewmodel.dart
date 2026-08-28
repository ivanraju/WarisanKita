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

  List<NearbyArtisan> _otherArtisans = [];
  List<NearbyArtisan> get otherArtisans => _otherArtisans;

  WorkshopLocation? _selectedWorkshop;
  WorkshopLocation? get selectedWorkshop => _selectedWorkshop;

  // ============================================================
  // PROXIMITY RADII
  // ============================================================

  // Fixed discovery classification radius.
  static const double nearbySearchRadiusMeters = 5000.0;

  // Application-defined gameplay radius. This is independent from both the
  // nearby-workshop search radius and GPS accuracy.
  static const double _questInteractionRadiusMeters = 50.0;
  double get questInteractionRadiusMeters =>
      _questInteractionRadiusMeters;

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

      // Recalculate both groups if GPS was already available.
      _updateArtisanDistances();
    } catch (e) {
      debugPrint('MapViewModel loadWorkshops error: $e');
      _workshops = [];
      _nearbyArtisans = [];
      _otherArtisans = [];
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
      _updateArtisanDistances();
      notifyListeners();

      // 2. Continue listening for live movement updates.
      _locationSubscription = _locationRepository.watchLocation().listen(
            (location) {
          _userLocation = location;

          debugPrint(
            'GPS stream update: '
                '${location.latitude}, ${location.longitude}',
          );

          _updateArtisanDistances();
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

  Future<bool> refreshCurrentLocation() async {
    try {
      _userLocation = await _locationRepository.getCurrentLocation();
      _locationError = null;
      _updateArtisanDistances();
      notifyListeners();
      return true;
    } catch (error) {
      _locationError = error.toString();
      debugPrint('Location refresh error: $error');
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // DISTANCE CALCULATION & WORKSHOP CLASSIFICATION
  // ============================================================

  /// Returns the straight-line geographic distance from the tourist to a
  /// workshop, or null while a live GPS position is unavailable.
  double? getDistanceToWorkshop(WorkshopLocation workshop) {
    final location = _userLocation;

    if (location == null) {
      return null;
    }

    return _locationRepository.calculateDistance(
      startLatitude: location.latitude,
      startLongitude: location.longitude,
      endLatitude: workshop.latitude,
      endLongitude: workshop.longitude,
    );
  }

  /// Whether the workshop is inside the real quest interaction radius.
  bool isWorkshopWithinInteractionRange(WorkshopLocation workshop) {
    final distance = getDistanceToWorkshop(workshop);
    return distance != null &&
        distance <= _questInteractionRadiusMeters;
  }

  void _updateArtisanDistances() {
    final location = _userLocation;

    if (location == null || _workshops.isEmpty) {
      _nearbyArtisans = [];
      _otherArtisans = [];
      return;
    }

    debugPrint('========================================');
    debugPrint('User GPS:');
    debugPrint('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
    debugPrint('Nearby radius:');
    debugPrint('${nearbySearchRadiusMeters.toStringAsFixed(0)} m');
    debugPrint('Quest interaction radius:');
    debugPrint('${_questInteractionRadiusMeters.toStringAsFixed(0)} m');

    final nearby = <NearbyArtisan>[];
    final others = <NearbyArtisan>[];

    for (final workshop in _workshops) {
      final distance = getDistanceToWorkshop(workshop)!;
      final artisan = NearbyArtisan.fromWorkshop(
        workshop: workshop,
        distanceMeters: distance,
      );

      if (distance <= nearbySearchRadiusMeters) {
        nearby.add(artisan);
      } else {
        others.add(artisan);
      }
    }

    nearby.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    others.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    _nearbyArtisans = nearby;
    _otherArtisans = others;

    debugPrint('Total workshops: ${_workshops.length}');
    debugPrint('Nearby: ${_nearbyArtisans.length}');
    debugPrint('Other: ${_otherArtisans.length}');
    debugPrint('========================================');
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
