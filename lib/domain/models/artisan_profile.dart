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
  final String? phone;
  final String? premiseType;
  final int? questPotentialXp;
  final String? craftingPhotoUrl;

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
    this.phone,
    this.premiseType,
    this.questPotentialXp,
    this.craftingPhotoUrl,
  });

  bool get isVillageWorkshop =>
      premiseType?.toLowerCase().contains('village') == true ||
      premiseType?.toLowerCase().contains('desa') == true ||
      premiseType?.toLowerCase().contains('kediaman') == true ||
      premiseType?.toLowerCase().contains('home') == true ||
      ssmNumber == 'VILLAGE_EXEMPT' ||
      (ssmNumber != null && ssmNumber!.toLowerCase().contains('exempt')) ||
      (ssmNumber != null && ssmNumber!.toLowerCase().contains('village'));

  String get premiseTypeDisplay =>
      isVillageWorkshop ? 'Home / Village Workshop' : 'Commercial Studio';

  String get artisanTitle =>
      isVillageWorkshop ? 'Heritage Village Crafter' : 'Master Artisan';

  List<String> get toolsAndMaterials => tags
      .where((t) =>
          !t.startsWith('doc_') &&
          !t.startsWith('premise:') &&
          !t.startsWith('__'))
      .toList();

  ArtisanModel copyWith({
    String? id,
    String? name,
    String? craftType,
    String? state,
    String? description,
    String? imageUrl,
    double? rating,
    String? experience,
    int? workshopCount,
    List<String>? tags,
    List<String>? images,
    String? address,
    double? latitude,
    double? longitude,
    bool? isLiveOpen,
    String? ssmNumber,
    List<Map<String, dynamic>>? documents,
    String? phone,
    String? premiseType,
    int? questPotentialXp,
    String? craftingPhotoUrl,
  }) {
    return ArtisanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      craftType: craftType ?? this.craftType,
      state: state ?? this.state,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      workshopCount: workshopCount ?? this.workshopCount,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLiveOpen: isLiveOpen ?? this.isLiveOpen,
      ssmNumber: ssmNumber ?? this.ssmNumber,
      documents: documents ?? this.documents,
      phone: phone ?? this.phone,
      premiseType: premiseType ?? this.premiseType,
      questPotentialXp: questPotentialXp ?? this.questPotentialXp,
      craftingPhotoUrl: craftingPhotoUrl ?? this.craftingPhotoUrl,
    );
  }

  factory ArtisanModel.fromMap(Map<String, dynamic> map) {
    final List<String> rawTags = map['tags'] != null
        ? List<String>.from(map['tags'])
        : [map['craft_category']?.toString() ?? 'Heritage'];
    final bool isClosedTag = rawTags.contains('__LIVE_DEMO_CLOSED__');

    // 1. Resolve administrative crafting proof photo (NEVER leaked into portfolio images)
    String? resolvedCraftingPhoto;
    final rawDocs = map['artisan_documents'] ?? map['documents'];
    if (rawDocs != null) {
      final docs = List<Map<String, dynamic>>.from(rawDocs);
      for (final d in docs) {
        final docType = d['doc_type']?.toString();
        if (docType == 'CRAFTING_PHOTO' ||
            docType == 'VILLAGE_CRAFTING_PHOTO' ||
            docType == 'STUDIO_PHOTO') {
          final url = d['file_url']?.toString();
          if (url != null && url.isNotEmpty) {
            resolvedCraftingPhoto = url;
            break;
          }
        }
      }
    }

    if (resolvedCraftingPhoto == null || resolvedCraftingPhoto.isEmpty) {
      for (final t in rawTags) {
        if (t.startsWith('doc_crafting_photo_url:')) {
          final u = t.substring('doc_crafting_photo_url:'.length).trim();
          if (u.isNotEmpty) {
            resolvedCraftingPhoto = u;
            break;
          }
        }
        if (t.startsWith('doc_studio_photo:')) {
          final u = t.substring('doc_studio_photo:'.length).trim();
          if (u.isNotEmpty) {
            resolvedCraftingPhoto = u;
            break;
          }
        }
      }
    }

    // 2. Resolve portfolio images (ONLY actual portfolio showcase images, no proof photos)
    final List<String> portfolioImages = [];
    if (rawDocs != null) {
      final docs = List<Map<String, dynamic>>.from(rawDocs);
      for (final d in docs) {
        if (d['doc_type'] == 'PORTFOLIO_IMAGE') {
          final url = d['file_url']?.toString();
          if (url != null &&
              url.isNotEmpty &&
              !portfolioImages.contains(url)) {
            portfolioImages.add(url);
          }
        }
      }
    }

    // 3. Resolve display/cover image (portfolio first, then avatar, then cover photo, fallback to heritage craft photo)
    String extractedImageUrl;
    if (portfolioImages.isNotEmpty) {
      extractedImageUrl = portfolioImages.first;
    } else if (map['users'] != null &&
        map['users']['avatar_url'] != null &&
        map['users']['avatar_url'].toString().isNotEmpty) {
      extractedImageUrl = map['users']['avatar_url'].toString();
    } else if (map['avatar_url'] != null &&
        map['avatar_url'].toString().isNotEmpty) {
      extractedImageUrl = map['avatar_url'].toString();
    } else if (map['cover_photo'] != null &&
        map['cover_photo'].toString().isNotEmpty) {
      extractedImageUrl = map['cover_photo'].toString();
    } else {
      extractedImageUrl =
          'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80';
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
        !isClosedTag;

    final String? ssm =
        (map['ssm_number'] ??
                map['ssmNumber'] ??
                (map['users'] != null ? map['users']['ssm_number'] : null))
            ?.toString();

    final String? phone =
        (map['phone'] ??
                map['phone_number'] ??
                map['phoneNumber'] ??
                (map['users'] != null
                    ? (map['users']['phone_number'] ?? map['users']['phone'])
                    : null))
            ?.toString();

    final String? rawPremiseType =
        (map['premise_type'] ??
                map['premiseType'] ??
                (map['users'] != null ? map['users']['premise_type'] : null))
            ?.toString();

    final String? premiseType = (rawPremiseType != null && rawPremiseType.isNotEmpty)
        ? rawPremiseType
        : ((ssm == 'VILLAGE_EXEMPT' || (ssm != null && ssm.toLowerCase().contains('exempt')))
            ? 'Home / Village Workshop (Bengkel Kediaman / Desa)'
            : null);

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
      tags: rawTags
          .where((t) =>
              !t.startsWith('__') &&
              !t.startsWith('doc_') &&
              !t.startsWith('premise:'))
          .toList(),
      images: portfolioImages,
      craftingPhotoUrl: resolvedCraftingPhoto,
      address: map['address'] as String?,
      latitude: lat,
      longitude: lng,
      isLiveOpen: isLive,
      ssmNumber: ssm,
      documents: docsList,
      phone: phone,
      premiseType: premiseType,
      questPotentialXp: (map['quest_potential_xp'] as num?)?.toInt(),
    );
  }
}
