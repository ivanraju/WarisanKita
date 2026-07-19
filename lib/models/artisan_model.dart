class ArtisanModel {
  final String id;
  final String name;
  final String craftType;
  final String state;
  final String description;
  final String imageUrl;
  final double rating;
  final String experience;
  final int workshopCount;
  final List<String> tags;

  ArtisanModel({
    required this.id,
    required this.name,
    required this.craftType,
    required this.state,
    required this.description,
    required this.imageUrl,
    this.rating = 0.0,
    this.experience = '10+ Years',
    this.workshopCount = 0,
    this.tags = const [],
  });

  // TODO: Add fromMap and toMap for Supabase integration
}
