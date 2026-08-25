class ArtisanQuestProfile {
  final String id;
  final String userId;
  final String studioName;
  final String status;

  const ArtisanQuestProfile({
    required this.id,
    required this.userId,
    required this.studioName,
    required this.status,
  });

  bool get isApproved => status.toUpperCase() == 'APPROVED';

  factory ArtisanQuestProfile.fromMap(Map<String, dynamic> map) {
    return ArtisanQuestProfile(
      id: _requiredString(map, 'id'),
      userId: _requiredString(map, 'user_id'),
      studioName: _requiredString(map, 'studio_name'),
      status: _requiredString(map, 'status'),
    );
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Artisan profile field "$key" is missing or invalid.',
      );
    }

    return value;
  }
}
