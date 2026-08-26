class CraftPersonality {
  final String title;
  final String tagline;
  final String description;
  final String culturalLore;
  final List<String> matchingCrafts;
  final List<String> recommendedCraftCategories;
  final String accentColorHex;
  final int iconCodePoint;
  final List<String> preferenceTags;

  const CraftPersonality({
    required this.title,
    this.tagline = 'Heritage Cultural Artisan Archetype',
    required this.description,
    this.culturalLore = 'A timeless Malaysian heritage tradition passed down across generations.',
    required this.matchingCrafts,
    this.recommendedCraftCategories = const [],
    this.accentColorHex = '#004D40',
    this.iconCodePoint = 0xe0e8, // auto_awesome
    this.preferenceTags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'tagline': tagline,
      'description': description,
      'culturalLore': culturalLore,
      'matchingCrafts': matchingCrafts,
      'recommendedCraftCategories': recommendedCraftCategories,
      'accentColorHex': accentColorHex,
      'iconCodePoint': iconCodePoint,
      'preferenceTags': preferenceTags,
    };
  }

  factory CraftPersonality.fromMap(Map<String, dynamic> map) {
    return CraftPersonality(
      title: map['title'] ?? 'The Weaver of Dreams',
      tagline: map['tagline'] ?? 'Master of Royal Symmetry & Threads',
      description: map['description'] ?? 'You possess a patient spirit and an eye for intricate royal symmetry.',
      culturalLore: map['culturalLore'] ?? 'Rooted in the royal courts of Terengganu and Kelantan.',
      matchingCrafts: (map['matchingCrafts'] is List)
          ? List<String>.from(map['matchingCrafts'])
          : const ['Songket', 'Batik'],
      recommendedCraftCategories: (map['recommendedCraftCategories'] is List)
          ? List<String>.from(map['recommendedCraftCategories'])
          : const ['Batik & Songket Textiles', 'Songket Gold Weaving', 'Batik Wax Painting'],
      accentColorHex: map['accentColorHex'] ?? '#8B5CF6',
      iconCodePoint: map['iconCodePoint'] ?? 0xe0e8,
      preferenceTags: (map['preferenceTags'] is List)
          ? List<String>.from(map['preferenceTags'])
          : const [],
    );
  }
}
