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
  final List<String> images;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isLiveOpen;
  final String? ssmNumber;
  final List<Map<String, dynamic>> documents;

  ArtisanModel({
    required this.id,
    required this.name,
    required this.craftType,
    required this.state,
    required this.description,
    required this.imageUrl,
    this.rating = 0.0,
    this.experience = '',
    this.workshopCount = 0,
    this.tags = const [],
    this.images = const [],
    this.address,
    this.latitude,
    this.longitude,
    this.isLiveOpen = true,
    this.ssmNumber,
    this.documents = const [],
  });

  factory ArtisanModel.fromMap(Map<String, dynamic> map) {
    // Extract a nice image from the artisan_documents or users if available
    String extractedImageUrl =
        'https://placehold.co/800x600/004D40/FFFFFF.png?text=Artisan+Studio';
    List<String> allImages = [];

    if (map['artisan_documents'] != null) {
      final docs = List<Map<String, dynamic>>.from(map['artisan_documents']);
      final photos = docs
          .where(
            (d) =>
                d['doc_type'] == 'STUDIO_PHOTO' ||
                d['doc_type'] == 'PORTFOLIO_IMAGE',
          )
          .toList();

      for (var photo in photos) {
        if (photo['file_url'] != null) {
          allImages.add(photo['file_url']);
        }
      }

      if (allImages.isNotEmpty) {
        extractedImageUrl = allImages.first;
      }
    }

    if (allImages.isEmpty &&
        map['users'] != null &&
        map['users']['avatar_url'] != null) {
      extractedImageUrl = map['users']['avatar_url'];
      allImages.add(extractedImageUrl);
    }

    if (allImages.isEmpty) {
      allImages.add(extractedImageUrl);
    }

    double? lat;
    if (map['latitude'] != null) {
      if (map['latitude'] is num) {
        lat = (map['latitude'] as num).toDouble();
      } else {
        lat = double.tryParse(map['latitude'].toString());
      }
    }

    double? lng;
    if (map['longitude'] != null) {
      if (map['longitude'] is num) {
        lng = (map['longitude'] as num).toDouble();
      } else {
        lng = double.tryParse(map['longitude'].toString());
      }
    }

    final bool isLive =
        map['is_live_open'] ??
        map['isLiveOpen'] ??
        (map['users'] != null ? map['users']['is_live_open'] : null) ??
        true;

    final String? ssm =
        (map['ssm_number'] ??
                map['ssmNumber'] ??
                (map['users'] != null ? map['users']['ssm_number'] : null))
            ?.toString();

    List<Map<String, dynamic>> docsList = [];
    if (map['artisan_documents'] != null) {
      docsList = List<Map<String, dynamic>>.from(map['artisan_documents']);
    } else if (map['documents'] != null) {
      docsList = List<Map<String, dynamic>>.from(map['documents']);
    }

    return ArtisanModel(
      id: map['id'] ?? '',
      name: map['studio_name'] ?? 'Unknown Studio',
      craftType: map['craft_category'] ?? 'Craft',
      state: map['state'] ?? 'Unknown State',
      description: map['bio'] ?? '',
      imageUrl: extractedImageUrl,
      rating: map['rating'] is num
          ? (map['rating'] as num).toDouble()
          : double.tryParse(map['rating']?.toString() ?? '') ?? 0.0,
      experience:
          (map['experience'] != null &&
              map['experience'].toString().trim().isNotEmpty)
          ? map['experience'].toString().trim()
          : (map['years_experience'] is num &&
                    (map['years_experience'] as num) > 0
                ? '${(map['years_experience'] as num).toInt()} Years'
                : ''),
      workshopCount:
          (map['workshop_count'] as num?)?.toInt() ??
          (map['workshops_hosted'] as num?)?.toInt() ??
          (map['workshopCount'] as num?)?.toInt() ??
          0,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : const [],
      images: allImages,
      address: map['address'] as String?,
      latitude: lat,
      longitude: lng,
      isLiveOpen: isLive,
      ssmNumber: ssm,
      documents: docsList,
    );
  }
}
