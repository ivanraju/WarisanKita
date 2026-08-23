class WorkshopLocation {
  final String id;
  final String name;
  final String craftCategory;
  final String address;
  final String state;
  final double latitude;
  final double longitude;

  const WorkshopLocation({
    required this.id,
    required this.name,
    required this.craftCategory,
    required this.address,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  String get locationName => '$address, $state';
}