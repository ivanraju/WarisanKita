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
  });

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
    );
  }
}
