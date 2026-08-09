/// Boundary for Google Maps operations.
///
/// Map SDK calls belong here so feature viewmodels remain platform-agnostic.
class GoogleMapService {
  const GoogleMapService();

  Future<Uri> directionsTo({required double latitude, required double longitude}) {
    return Future.value(Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'));
  }
}
