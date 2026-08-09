class NearbyArtisan {
  final String id;
  final String name;
  final String craftCategory;
  final String walkingTime;
  final String distance;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double mapXRatio; // Relative X position on map canvas (0.0 to 1.0)
  final double mapYRatio; // Relative Y position on map canvas (0.0 to 1.0)
  final bool isOpenNow;
  final String locationName;

  const NearbyArtisan({
    required this.id,
    required this.name,
    required this.craftCategory,
    required this.walkingTime,
    required this.distance,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.mapXRatio,
    required this.mapYRatio,
    this.isOpenNow = true,
    required this.locationName,
  });
}
