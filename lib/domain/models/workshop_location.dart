class WorkshopLocation {
  final String id;
  final String name;
  final String craftCategory;
  final String address;
  final String state;
  final double latitude;
  final double longitude;
  final String primaryImageUrl;
  final bool isLiveOpen;

  const WorkshopLocation({
    required this.id,
    required this.name,
    required this.craftCategory,
    required this.address,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.primaryImageUrl = '',
    this.isLiveOpen = true,
  });

  String get locationName => '$address, $state';

  WorkshopLocation copyWith({bool? isLiveOpen}) {
    return WorkshopLocation(
      id: id,
      name: name,
      craftCategory: craftCategory,
      address: address,
      state: state,
      latitude: latitude,
      longitude: longitude,
      primaryImageUrl: primaryImageUrl,
      isLiveOpen: isLiveOpen ?? this.isLiveOpen,
    );
  }
}
