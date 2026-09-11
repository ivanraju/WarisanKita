class UserLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double heading;
  final DateTime? recordedAt;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.heading = 0.0,
    this.recordedAt,
  });
}
