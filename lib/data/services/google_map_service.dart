/// Boundary for Google Maps operations.
///
/// Map SDK calls belong here so feature viewmodels remain platform-agnostic.
class GoogleMapService {
  const GoogleMapService();

  Future<Uri> directionsTo({required double latitude, required double longitude}) {
    return Future.value(Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'));
  }

  // Night palette based on Warisan Kita's deep emerald, bronze, and gold
  // identity. Business clutter stays hidden while cultural attractions retain
  // a restrained gold treatment.
  static const String darkHeritageMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#101c19"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#c8bda8"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#101c19"}]},
    {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#56645d"}]},
    {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#263b35"}]},
    {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#3e574f"}]},
    {"featureType":"poi.attraction","elementType":"labels.text.fill","stylers":[{"color":"#d5a928"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#28483a"}]},
    {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9caf9d"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#786950"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#4d4639"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#e4dac5"}]},
    {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#2b2923"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#a58a59"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#5c4c35"}]},
    {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#394a43"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#123e43"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#8eafb0"}]}
  ]
  ''';
}
