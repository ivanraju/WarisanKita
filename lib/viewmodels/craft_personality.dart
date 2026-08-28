class CraftPersonality {
  final String title;
  final String description;
  final String tagline;
  final List<String> matchingCrafts;
  final String primaryCategory;
  final List<String> preferenceTags;
  final String? experienceType;
  final String? environment;
  final String? material;
  final String? region;
  final String? badgeIconName;
  final DateTime? completedAt;

  CraftPersonality({
    required this.title,
    required this.description,
    this.tagline = '',
    required this.matchingCrafts,
    this.primaryCategory = 'All Crafts',
    this.preferenceTags = const [],
    this.experienceType,
    this.environment,
    this.material,
    this.region,
    this.badgeIconName,
    this.completedAt,
  });

  CraftPersonality copyWith({
    String? title,
    String? description,
    String? tagline,
    List<String>? matchingCrafts,
    String? primaryCategory,
    List<String>? preferenceTags,
    String? experienceType,
    String? environment,
    String? material,
    String? region,
    String? badgeIconName,
    DateTime? completedAt,
  }) {
    return CraftPersonality(
      title: title ?? this.title,
      description: description ?? this.description,
      tagline: tagline ?? this.tagline,
      matchingCrafts: matchingCrafts ?? this.matchingCrafts,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      preferenceTags: preferenceTags ?? this.preferenceTags,
      experienceType: experienceType ?? this.experienceType,
      environment: environment ?? this.environment,
      material: material ?? this.material,
      region: region ?? this.region,
      badgeIconName: badgeIconName ?? this.badgeIconName,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'tagline': tagline,
      'matchingCrafts': matchingCrafts,
      'primaryCategory': primaryCategory,
      'preferenceTags': preferenceTags,
      'experienceType': experienceType,
      'environment': environment,
      'material': material,
      'region': region,
      'badgeIconName': badgeIconName,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory CraftPersonality.fromMap(Map<String, dynamic> map) {
    return CraftPersonality(
      title: map['title'] as String? ?? 'The Heritage Explorer',
      description: map['description'] as String? ??
          'You possess an innate appreciation for traditional Malaysian arts and crafts.',
      tagline: map['tagline'] as String? ?? '',
      matchingCrafts: (map['matchingCrafts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Batik', 'Pottery'],
      primaryCategory: map['primaryCategory'] as String? ?? 'All Crafts',
      preferenceTags: (map['preferenceTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      experienceType: map['experienceType'] as String?,
      environment: map['environment'] as String?,
      material: map['material'] as String?,
      region: map['region'] as String?,
      badgeIconName: map['badgeIconName'] as String?,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
    );
  }
}
