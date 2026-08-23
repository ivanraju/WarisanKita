import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<void> ensureLocationPermission() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
            'Please enable it in app settings.',
      );
    }
  }

  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,

      // Send an update when the tourist moves
      // at least 10 metres.
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }

  Future<Position> getCurrentPosition() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    return Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
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