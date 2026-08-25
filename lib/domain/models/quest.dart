class Quest {
  final String id;
  final String artisanId;
  final String title;
  final String description;
  final String category;
  final int geofenceRadiusMeters;
  final String stampTitle;
  final String stampImageUrl;
  final String status;
  final DateTime? createdAt;

  const Quest({
    required this.id,
    required this.artisanId,
    required this.title,
    required this.description,
    required this.category,
    required this.geofenceRadiusMeters,
    required this.stampTitle,
    required this.stampImageUrl,
    required this.status,
    required this.createdAt,
  });

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: _requiredString(map, 'id'),
      artisanId: _requiredString(map, 'artisan_id'),
      title: _requiredString(map, 'title'),
      description: _requiredString(map, 'description'),
      category: _requiredString(map, 'category'),
      geofenceRadiusMeters: _requiredInt(map, 'geofence_radius_meters'),
      stampTitle: _requiredString(map, 'stamp_title'),
      stampImageUrl: _requiredString(map, 'stamp_image_url'),
      status: _requiredString(map, 'status'),
      createdAt: _optionalDateTime(map['created_at']),
    );
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Quest field "$key" is missing or invalid.');
    }

    return value;
  }

  static int _requiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is num) {
      return value.toInt();
    }

    throw FormatException('Quest field "$key" is missing or invalid.');
  }

  static DateTime? _optionalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
