class CraftPersonality {
  final String title;
  final String description;
  final String tagline;
  final List<String> matchingCrafts;
  final String primaryCategory;
  final String? secondaryCategory;
  final List<String> preferenceTags;
  final String? experienceType;
  final String? environment;
  final String? material;
  final String? region;
  final String? badgeIconName;
  final DateTime? completedAt;
  final Map<String, int> craftScores;
  final Map<String, int> traitScores;
  final String? topTrait;
  final bool isBlended;
  final List<String> blendedCategories;

  CraftPersonality({
    required this.title,
    required this.description,
    this.tagline = '',
    required this.matchingCrafts,
    this.primaryCategory = 'All Crafts',
    this.secondaryCategory,
    this.preferenceTags = const [],
    this.experienceType,
    this.environment,
    this.material,
    this.region,
    this.badgeIconName,
    this.completedAt,
    this.craftScores = const {},
    this.traitScores = const {},
    this.topTrait,
    this.isBlended = false,
    this.blendedCategories = const [],
  });

  CraftPersonality copyWith({
    String? title,
    String? description,
    String? tagline,
    List<String>? matchingCrafts,
    String? primaryCategory,
    String? secondaryCategory,
    List<String>? preferenceTags,
    String? experienceType,
    String? environment,
    String? material,
    String? region,
    String? badgeIconName,
    DateTime? completedAt,
    Map<String, int>? craftScores,
    Map<String, int>? traitScores,
    String? topTrait,
    bool? isBlended,
    List<String>? blendedCategories,
  }) {
    return CraftPersonality(
      title: title ?? this.title,
      description: description ?? this.description,
      tagline: tagline ?? this.tagline,
      matchingCrafts: matchingCrafts ?? this.matchingCrafts,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      secondaryCategory: secondaryCategory ?? this.secondaryCategory,
      preferenceTags: preferenceTags ?? this.preferenceTags,
      experienceType: experienceType ?? this.experienceType,
      environment: environment ?? this.environment,
      material: material ?? this.material,
      region: region ?? this.region,
      badgeIconName: badgeIconName ?? this.badgeIconName,
      completedAt: completedAt ?? this.completedAt,
      craftScores: craftScores ?? this.craftScores,
      traitScores: traitScores ?? this.traitScores,
      topTrait: topTrait ?? this.topTrait,
      isBlended: isBlended ?? this.isBlended,
      blendedCategories: blendedCategories ?? this.blendedCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'tagline': tagline,
      'matchingCrafts': matchingCrafts,
      'primaryCategory': primaryCategory,
      'secondaryCategory': secondaryCategory,
      'preferenceTags': preferenceTags,
      'experienceType': experienceType,
      'environment': environment,
      'material': material,
      'region': region,
      'badgeIconName': badgeIconName,
      'completedAt': completedAt?.toIso8601String(),
      'craftScores': craftScores,
      'traitScores': traitScores,
      'topTrait': topTrait,
      'isBlended': isBlended,
      'blendedCategories': blendedCategories,
    };
  }

  factory CraftPersonality.fromMap(Map<String, dynamic> map) {
    Map<String, int> parseScoreMap(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : (int.tryParse(v.toString()) ?? 0)));
      }
      return const {};
    }

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
      secondaryCategory: map['secondaryCategory'] as String?,
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
      craftScores: parseScoreMap(map['craftScores']),
      traitScores: parseScoreMap(map['traitScores']),
      topTrait: map['topTrait'] as String?,
      isBlended: map['isBlended'] as bool? ?? false,
      blendedCategories: (map['blendedCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
