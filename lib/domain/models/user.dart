class UserModel {
  final String id;
  final String email;
  final String? username;
  final String role; // Primary role: 'Tourist', 'Artisan', 'Admin'
  final List<String> roles; // All associated roles for multi-role accounts (e.g. ['Tourist', 'Artisan'])
  final String status; // 'ACTIVE', 'PENDING_APPROVAL', 'APPROVED', 'SUSPENDED', 'REJECTED'
  final String? displayName;
  final String? avatarUrl;
  final String joinedDate;
  final bool isSuspended;

  // Master Artisan profile metadata (if applicable)
  final String? studioName;
  final String? ssmNumber;
  final String? craftCategory;
  final String? bio;
  final String? address;
  final String? state;
  final String? phone;
  final List<Map<String, dynamic>> artisanDocuments;

  const UserModel({
    required this.id,
    required this.email,
    this.username,
    required this.role,
    this.roles = const [],
    this.status = 'ACTIVE',
    this.displayName,
    this.avatarUrl,
    this.joinedDate = 'Jan 2026',
    this.isSuspended = false,
    this.studioName,
    this.ssmNumber,
    this.craftCategory,
    this.bio,
    this.address,
    this.state,
    this.phone,
    this.artisanDocuments = const [],
  });

  bool get isDualRole =>
      role == 'Artisan & Tourist' ||
      role == 'Artisan/Tourist' ||
      role == 'Tourist & Artisan' ||
      role == 'Tourist/Artisan' ||
      role == 'Artisan and Tourist' ||
      (roles.contains('Artisan') && roles.contains('Tourist')) ||
      (roles.contains('Master Artisan') && roles.contains('Tourist'));

  bool get isArtisan =>
      role == 'Artisan' ||
      role == 'Master Artisan' ||
      isDualRole ||
      roles.contains('Artisan') ||
      roles.contains('Master Artisan');

  bool get isTourist =>
      role == 'Tourist' ||
      isDualRole ||
      roles.contains('Tourist');

  bool get isAdmin =>
      role.toLowerCase().contains('admin') ||
      roles.any((r) => r.toLowerCase().contains('admin'));

  bool get hasMultipleRoles =>
      isDualRole ||
      roles.length > 1;

  bool get isApproved => status == 'ACTIVE' || status == 'APPROVED';
  bool get isPendingApproval => status == 'PENDING_APPROVAL' || status == 'PENDING';

  bool get isApprovedArtisan =>
      (role == 'Artisan' ||
       role == 'Master Artisan' ||
       roles.contains('Artisan') ||
       roles.contains('Master Artisan')) &&
      isApproved;

  bool get isPendingArtisan =>
      isPendingApproval ||
      (studioName != null && studioName!.trim().isNotEmpty && !isApprovedArtisan);

  String get handle {
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim().replaceAll('@', '');
    }
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return 'user';
  }

  String get effectiveUsername {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim().replaceAll('@', '');
    }
    if (studioName != null && studioName!.trim().isNotEmpty) {
      return studioName!.trim();
    }
    if (email.contains('@')) {
      final handle = email.split('@')[0];
      return handle.replaceAll('.', ' ').split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
    }
    return email;
  }

  String get initials {
    final name = effectiveUsername;
    if (name.isEmpty) return 'WK';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? role,
    List<String>? roles,
    String? status,
    String? displayName,
    String? avatarUrl,
    String? joinedDate,
    bool? isSuspended,
    String? studioName,
    String? ssmNumber,
    String? craftCategory,
    String? bio,
    String? address,
    String? state,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      isSuspended: isSuspended ?? this.isSuspended,
      studioName: studioName ?? this.studioName,
      ssmNumber: ssmNumber ?? this.ssmNumber,
      craftCategory: craftCategory ?? this.craftCategory,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      state: state ?? this.state,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'roles': roles,
      'status': status,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'joinedDate': joinedDate,
      'isSuspended': isSuspended,
      'studioName': studioName,
      'ssmNumber': ssmNumber,
      'craftCategory': craftCategory,
      'bio': bio,
      'address': address,
      'state': state,
      'phone': phone,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final List<String> roleList = map['roles'] != null
        ? List<String>.from(map['roles'])
        : (map['role'] != null ? [map['role'] as String] : ['Tourist']);

    Map<String, dynamic>? artisanMap;
    List<Map<String, dynamic>> docs = [];
    if (map['artisan_profiles'] is Map) {
      artisanMap = Map<String, dynamic>.from(map['artisan_profiles']);
    } else if (map['artisan_profiles'] is List && (map['artisan_profiles'] as List).isNotEmpty) {
      artisanMap = Map<String, dynamic>.from((map['artisan_profiles'] as List).first);
    }
    
    if (artisanMap != null && artisanMap['artisan_documents'] != null) {
      docs = List<Map<String, dynamic>>.from(artisanMap['artisan_documents']);
    }

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? map['user_name'],
      role: map['role'] ?? 'Tourist',
      roles: roleList,
      status: map['status'] ?? 'ACTIVE',
      displayName: map['displayName'] ?? map['display_name'] ?? map['full_name'],
      avatarUrl: map['avatarUrl'] ?? map['avatar_url'],
      joinedDate: map['joinedDate'] ?? 'Jan 2026',
      isSuspended: map['isSuspended'] ?? (map['status'] == 'SUSPENDED'),
      studioName: map['studioName'] ?? map['studio_name'] ?? artisanMap?['studio_name'],
      ssmNumber: map['ssmNumber'] ?? map['ssm_number'] ?? artisanMap?['ssm_number'],
      craftCategory: map['craftCategory'] ?? map['craft_category'] ?? artisanMap?['craft_category'],
      bio: map['bio'] ?? artisanMap?['bio'],
      address: map['address'] ?? artisanMap?['address'],
      state: map['state'] ?? artisanMap?['state'],
      phone: map['phone'] ?? map['phone_number'],
      artisanDocuments: docs,
    );
  }
}

class ExistingAccountCheck {
  final bool exists;
  final String? existingRole;
  final List<String> existingRoles;
  final bool isTourist;
  final bool isArtisan;
  final bool isDualRole;
  final String? displayName;
  final String? username;
  final String? studioName;
  final String? craftCategory;

  const ExistingAccountCheck({
    required this.exists,
    this.existingRole,
    this.existingRoles = const [],
    this.isTourist = false,
    this.isArtisan = false,
    this.isDualRole = false,
    this.displayName,
    this.username,
    this.studioName,
    this.craftCategory,
  });
}

