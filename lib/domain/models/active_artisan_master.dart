class ActiveArtisanMaster {
  final String id;
  final String name;
  final String email;
  final String category;
  final String state;
  final String experience;
  final int plaques;
  final bool isLiveOpen;
  final String licenseNo;
  final String verifiedDate;
  final String imageUrl;
  final String bio;
  final String phone;
  final bool isDualRole;
  final bool isSuspended;
  final String? premiseType;

  const ActiveArtisanMaster({
    required this.id,
    required this.name,
    required this.email,
    required this.category,
    required this.state,
    required this.experience,
    required this.plaques,
    required this.isLiveOpen,
    required this.licenseNo,
    required this.verifiedDate,
    required this.imageUrl,
    required this.bio,
    required this.phone,
    this.isDualRole = false,
    this.isSuspended = false,
    this.premiseType,
  });

  bool get isVillageWorkshop =>
      premiseType != null &&
      (premiseType!.contains('Village') ||
          premiseType!.contains('Desa') ||
          premiseType!.contains('Home') ||
          premiseType!.contains('Kediaman'));

  String get premiseTypeDisplay =>
      isVillageWorkshop ? 'Home / Village Workshop' : 'Commercial Studio';

  String get statusText => isSuspended
      ? '⛔ SUSPENDED (HIDDEN)'
      : (isLiveOpen ? '🟢 OPEN FOR DEMOS' : '🔴 IN SESSION (PAUSED)');

  ActiveArtisanMaster copyWith({
    String? name,
    String? category,
    String? state,
    String? experience,
    int? plaques,
    bool? isLiveOpen,
    String? licenseNo,
    String? verifiedDate,
    String? imageUrl,
    String? bio,
    String? phone,
    bool? isDualRole,
    bool? isSuspended,
    String? premiseType,
  }) {
    return ActiveArtisanMaster(
      id: id,
      name: name ?? this.name,
      email: email,
      category: category ?? this.category,
      state: state ?? this.state,
      experience: experience ?? this.experience,
      plaques: plaques ?? this.plaques,
      isLiveOpen: isLiveOpen ?? this.isLiveOpen,
      licenseNo: licenseNo ?? this.licenseNo,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      isDualRole: isDualRole ?? this.isDualRole,
      isSuspended: isSuspended ?? this.isSuspended,
      premiseType: premiseType ?? this.premiseType,
    );
  }

  factory ActiveArtisanMaster.fromMap(Map<String, dynamic> map) {
    final ap = (map['artisan_profiles'] is Map)
        ? Map<String, dynamic>.from(map['artisan_profiles'])
        : ((map['artisan_profiles'] is List && (map['artisan_profiles'] as List).isNotEmpty)
            ? Map<String, dynamic>.from((map['artisan_profiles'] as List).first)
            : null);

    final String name = (ap?['studio_name'] ?? map['studio_name'] ?? map['studioName'] ?? map['full_name'] ?? map['display_name'] ?? map['displayName'] ?? map['username'] ?? 'Artisan Studio').toString();
    final String category = (ap?['craft_category'] ?? map['craft_category'] ?? map['craftCategory'] ?? 'Handicraft & Heritage').toString();
    final String state = (ap?['state'] ?? map['state'] ?? 'Malaysia').toString();
    final rawExp = (ap != null && ap['experience'] != null && ap['experience'].toString().trim().isNotEmpty)
        ? ap['experience'].toString().trim()
        : (map['experience'] != null && map['experience'].toString().trim().isNotEmpty
            ? map['experience'].toString().trim()
            : (ap != null && ap['years_experience'] != null && (ap['years_experience'] as num) > 1
                ? '${ap['years_experience']} Years'
                : 'Verified Studio'));
    final String exp = RegExp(r'^\d+$').hasMatch(rawExp) ? '$rawExp Years' : rawExp;
    final String license = (ap?['ssm_number'] ?? map['ssm_number'] ?? map['ssmNumber'] ?? 'SSM Verified').toString();
    final String bio = (ap?['bio'] ?? map['bio'] ?? 'Master artisan dedicated to traditional Malaysian craft.').toString();
    final String phone = (map['phone_number'] ?? map['phone'] ?? ap?['phone_number'] ?? ap?['phone'] ?? '').toString();
    final String verifiedDate = (ap?['verified_at'] ?? map['created_at'] ?? '2026-01-01').toString().split('T').first;
    final String status = (map['status'] ?? '').toString().toUpperCase();
    final String artisanStatus = (map['artisan_status'] ?? map['artisanStatus'] ?? ap?['status'] ?? '').toString().toUpperCase();
    final bool isSuspended = status == 'SUSPENDED' ||
        artisanStatus == 'SUSPENDED' ||
        map['is_suspended'] == true ||
        map['isSuspended'] == true;
    const bool isDual = false;
    final String? premiseType = (ap?['premise_type'] ?? ap?['premiseType'] ?? map['premise_type'] ?? map['premiseType'])?.toString();

    return ActiveArtisanMaster(
      id: (map['id'] ?? ap?['id'] ?? '').toString(),
      name: name,
      email: (map['email'] ?? '').toString(),
      category: category,
      state: state,
      experience: exp,
      plaques: (map['plaques'] as int?) ?? (ap?['workshop_count'] as int?) ?? 1,
      isLiveOpen: map['is_live_open'] ??
          (ap != null && ap['tags'] is List && (ap['tags'] as List).contains('__LIVE_DEMO_CLOSED__') ? false : true),
      licenseNo: license,
      verifiedDate: verifiedDate,
      imageUrl: (map['avatar_url'] ?? map['imageUrl'] ?? 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600').toString(),
      bio: bio,
      phone: phone,
      isDualRole: isDual,
      isSuspended: isSuspended,
      premiseType: premiseType,
    );
  }
}
