import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';

class NearbyArtisan {
  final String id;
  final String name;
  final String craftCategory;
  final String distance;
  final double distanceMeters;
  final String? walkingTime;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  final double latitude;
  final double longitude;

  final bool isOpenNow;
  final String locationName;
  final WorkshopLocation? workshop;
  final WorkshopQuestJourney? journey;

  const NearbyArtisan({
    required this.id,
    required this.name,
    required this.craftCategory,
    required this.distance,
    required this.distanceMeters,
    this.walkingTime,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    this.isOpenNow = true,
    required this.locationName,
    this.workshop,
    this.journey,
  });

  /// Factory constructor to create a [NearbyArtisan] from a verified [WorkshopLocation] and calculated GPS distance.
  factory NearbyArtisan.fromWorkshop({
    required WorkshopLocation workshop,
    required double distanceMeters,
    String? imageUrl,
    double rating = 4.9,
    int reviewCount = 12,
    bool isOpenNow = true,
    WorkshopQuestJourney? journey,
  }) {
    // Format distance: < 1000m -> "350 m", >= 1000m -> "2.4 km"
    final String formattedDistance = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    // Straight-line walking estimate (~80 meters/min, approx 4.8 km/h walking speed)
    final int estimatedMinutes = (distanceMeters / 80).ceil();
    final String estimatedWalkingTime = estimatedMinutes <= 1
        ? '~1 min walk (est.)'
        : '~$estimatedMinutes mins walk (est.)';

    return NearbyArtisan(
      id: workshop.id,
      name: workshop.name,
      craftCategory: workshop.craftCategory,
      distance: formattedDistance,
      distanceMeters: distanceMeters,
      walkingTime: estimatedWalkingTime,
      imageUrl: imageUrl ?? workshop.primaryImageUrl,
      rating: rating,
      reviewCount: reviewCount,
      latitude: workshop.latitude,
      longitude: workshop.longitude,
      isOpenNow: isOpenNow,
      locationName: workshop.locationName,
      workshop: workshop,
      journey: journey,
    );
  }
}
