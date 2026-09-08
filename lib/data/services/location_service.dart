import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class LocationService {
  const LocationService();

  Future<void> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it in app settings.',
      );
    }
  }

  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,

      // Keep the directional tourist marker responsive while walking without
      // requesting an update for every small GPS fluctuation.
      distanceFilter: 2,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Stream<double> getHeadingStream() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const Stream<double>.empty();
    }

    try {
      final events = FlutterCompass.events;
      if (events == null) return const Stream<double>.empty();

      return events
          .handleError((error) {
            debugPrint('FlutterCompass platform stream error: $error');
          })
          .map((event) => event.heading)
          .where((heading) => heading != null && heading.isFinite)
          .cast<double>();
    } catch (e) {
      debugPrint('FlutterCompass initialization error: $e');
      return const Stream<double>.empty();
    }
  }

  Future<Position> getCurrentPosition() {
    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high);

    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }
}
