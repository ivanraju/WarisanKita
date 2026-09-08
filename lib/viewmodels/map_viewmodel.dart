import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/repositories/location_repository.dart';

import 'package:warisan_kita/domain/models/nearby_artisan.dart';
import 'package:warisan_kita/domain/models/user_location.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';

class MapViewModel extends ChangeNotifier {
  final ArtisanRepository _artisanRepository;
  final GamificationRepository _gamificationRepository;
  final LocationRepository _locationRepository;

  MapViewModel({
    required ArtisanRepository artisanRepository,
    required GamificationRepository gamificationRepository,
    required LocationRepository locationRepository,
  }) : _artisanRepository = artisanRepository,
       _gamificationRepository = gamificationRepository,
       _locationRepository = locationRepository {
    loadWorkshops();
    loadJourneyData();
    _watchWorkshopUpdates();
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

  TouristJourneySnapshot _journeySnapshot = TouristJourneySnapshot.empty;
  TouristJourneySnapshot get journeySnapshot => _journeySnapshot;

  bool _isLoadingJourneys = false;
  bool get isLoadingJourneys => _isLoadingJourneys;

  String? _journeyError;
  String? get journeyError => _journeyError;

  Map<String, WorkshopQuestJourney> get journeysByWorkshopId =>
      _journeySnapshot.journeysByWorkshopId;
  int get totalXp => _journeySnapshot.totalXp;
  int get earnedStampCount => _journeySnapshot.earnedStampCount;

  WorkshopQuestJourney? journeyForWorkshop(String workshopId) =>
      _journeySnapshot.journeysByWorkshopId[workshopId];

  int get nearbyQuestCount => _nearbyArtisans
      .where(
        (artisan) =>
            artisan.journey != null &&
            artisan.distanceMeters <= _questInteractionRadiusMeters,
      )
      .length;

  // ============================================================
  // PROXIMITY RADII
  // ============================================================

  // Fixed discovery classification radius.
  static const double nearbySearchRadiusMeters = 5000.0;

  // Application-defined gameplay radius. This is independent from both the
  // nearby-workshop search radius and GPS accuracy.
  static const double _questInteractionRadiusMeters = 50.0;
  double get questInteractionRadiusMeters => _questInteractionRadiusMeters;

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
  StreamSubscription<double>? _headingSubscription;
  StreamSubscription<List<WorkshopLocation>>? _workshopSubscription;
  double? _compassHeading;

  // ============================================================
  // LOAD WORKSHOPS (ASYNC SYNC CASE A & B)
  // ============================================================

  Future<void> loadWorkshops() async {
    _isLoading = true;
    notifyListeners();

    try {
      _workshops = await _artisanRepository.getWorkshopLocations();

      if (_selectedWorkshop != null &&
          !_workshops.any((item) => item.id == _selectedWorkshop!.id)) {
        _selectedWorkshop = null;
      }

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

  Future<void> loadJourneyData() async {
    _isLoadingJourneys = true;
    _journeyError = null;
    notifyListeners();

    try {
      _journeySnapshot = await _gamificationRepository
          .getTouristJourneySnapshot();
      _updateArtisanDistances();
    } catch (error) {
      _journeyError = 'Quest journey information is temporarily unavailable.';
      debugPrint('MapViewModel loadJourneyData error: $error');
    } finally {
      _isLoadingJourneys = false;
      notifyListeners();
    }
  }

  void _watchWorkshopUpdates() {
    _workshopSubscription?.cancel();
    _workshopSubscription = _artisanRepository.watchWorkshopLocations().listen(
      (workshops) {
        _workshops = workshops;
        if (_selectedWorkshop != null &&
            !_workshops.any((item) => item.id == _selectedWorkshop!.id)) {
          _selectedWorkshop = null;
        }
        _updateArtisanDistances();
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Workshop realtime subscription error: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
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
      _userLocation = _withReliableHeading(
        await _locationRepository.getCurrentLocation(),
      );

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
          _userLocation = _withReliableHeading(location);

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

      // Compass events update independently from GPS, allowing the tourist
      // arrow to turn immediately even while the user is standing still.
      try {
        _headingSubscription = _locationRepository.watchHeading().listen(
          _applyCompassHeading,
          onError: (error) {
            debugPrint('Compass stream error: $error');
          },
        );
      } catch (headingErr) {
        debugPrint('Compass subscription setup note: $headingErr');
      }
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
      _userLocation = _withReliableHeading(
        await _locationRepository.getCurrentLocation(),
      );
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

  UserLocation _withReliableHeading(UserLocation next) {
    final previous = _userLocation;
    var heading =
        _compassHeading ??
        (_validHeading(next.heading)
            ? _normalizeHeading(next.heading)
            : previous?.heading ?? 0.0);

    if (previous != null) {
      final movementMeters = _locationRepository.calculateDistance(
        startLatitude: previous.latitude,
        startLongitude: previous.longitude,
        endLatitude: next.latitude,
        endLongitude: next.longitude,
      );

      // GPS heading is commonly unavailable or reported as zero at walking
      // speed. Once movement is meaningful, the coordinate bearing is a more
      // dependable direction for the tourist arrow.
      if (_compassHeading == null && movementMeters >= 1.5) {
        heading = _bearingBetween(previous, next);
      }
    }

    return UserLocation(
      latitude: next.latitude,
      longitude: next.longitude,
      accuracy: next.accuracy,
      heading: heading,
    );
  }

  void _applyCompassHeading(double rawHeading) {
    // Some Android sensor implementations expose azimuth as -180..180 even
    // though compass packages document 0..360. Accept every finite compass
    // angle and normalize it so the marker can complete a full rotation.
    if (!rawHeading.isFinite) return;

    final previousHeading = _compassHeading;
    final targetHeading = _normalizeHeading(rawHeading);
    final heading = previousHeading == null
        ? targetHeading
        : _smoothCompassHeading(previousHeading, targetHeading);
    _compassHeading = heading;

    final location = _userLocation;
    if (location == null) return;

    if (previousHeading != null &&
        _smallestHeadingDifference(previousHeading, heading) < 0.35) {
      return;
    }

    _userLocation = UserLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      heading: heading,
    );
    notifyListeners();
  }

  double _smallestHeadingDifference(double first, double second) =>
      ((second - first + 540) % 360 - 180).abs();

  double _smoothCompassHeading(double current, double target) {
    final signedDelta = (target - current + 540) % 360 - 180;
    final turnSize = signedDelta.abs();

    // Small changes receive stronger filtering to suppress magnetometer
    // jitter. Intentional large turns catch up faster, similar to navigation
    // map direction indicators.
    final smoothingFactor = switch (turnSize) {
      >= 90 => 0.72,
      >= 45 => 0.58,
      >= 15 => 0.42,
      _ => 0.26,
    };

    return _normalizeHeading(current + signedDelta * smoothingFactor);
  }

  bool _validHeading(double heading) =>
      heading.isFinite && heading >= 0 && heading < 360;

  double _normalizeHeading(double heading) => (heading % 360 + 360) % 360;

  double _bearingBetween(UserLocation start, UserLocation end) {
    final startLatitude = start.latitude * math.pi / 180;
    final endLatitude = end.latitude * math.pi / 180;
    final longitudeDelta = (end.longitude - start.longitude) * math.pi / 180;
    final y = math.sin(longitudeDelta) * math.cos(endLatitude);
    final x =
        math.cos(startLatitude) * math.sin(endLatitude) -
        math.sin(startLatitude) *
            math.cos(endLatitude) *
            math.cos(longitudeDelta);
    return _normalizeHeading(math.atan2(y, x) * 180 / math.pi);
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
    return distance != null && distance <= _questInteractionRadiusMeters;
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
    debugPrint(
      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
    );
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
        journey: journeyForWorkshop(workshop.id),
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

  void focusWorkshop(WorkshopLocation workshop) {
    if (_selectedWorkshop?.id == workshop.id) return;
    _selectedWorkshop = workshop;
    notifyListeners();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshWorkshops() async {
    await Future.wait([loadWorkshops(), loadJourneyData()]);
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    await _headingSubscription?.cancel();
    _locationSubscription = null;
    _headingSubscription = null;
    _compassHeading = null;
    _isTrackingLocation = false;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _headingSubscription?.cancel();
    _workshopSubscription?.cancel();
    super.dispose();
  }
}
