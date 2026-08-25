import 'package:warisan_kita/data/services/location_service.dart';
import 'package:warisan_kita/domain/models/user_location.dart';

class LocationRepository {
  final LocationService _service;

  LocationRepository({
    LocationService? service,
  }) : _service =
      service ?? const LocationService();

  Future<void> requestLocationAccess() {
    return _service.ensureLocationPermission();
  }

  Stream<UserLocation> watchLocation() {
    return _service.getPositionStream().map(
          (position) {
        return UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          heading: position.heading,
        );
      },
    );
  }

  Future<UserLocation> getCurrentLocation() async {
    final position =
    await _service.getCurrentPosition();

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      heading: position.heading,
    );
  }

  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return _service.distanceBetween(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    );
  }

  Future<bool> openLocationSettings() {
    return _service.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return _service.openAppSettings();
  }
}
