class PendingArtisanProfile {
  final String id;
  final String name;
  final String craftCategory;
  final String state;
  final String dateSubmitted;
  final String imageUrl;
  final String email;
  final String experience;
  final String phone;
  final String? ssmNumber;
  final String? ssmFileName;
  final String? ssmFileUrl;
  final String? certFileName;
  final String? certFileUrl;
  final List<String> photos;
  final String? bio;
  final bool isUpgradeFromTourist;

  const PendingArtisanProfile({
    required this.id,
    required this.name,
    required this.craftCategory,
    required this.state,
    required this.dateSubmitted,
    required this.imageUrl,
    required this.email,
    required this.experience,
    required this.phone,
    this.ssmNumber,
    this.ssmFileName,
    this.ssmFileUrl,
    this.certFileName,
    this.certFileUrl,
    this.photos = const [],
    this.bio,
    this.isUpgradeFromTourist = false,
  });
}

