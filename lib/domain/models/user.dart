import 'dart:convert';
import 'package:flutter/widgets.dart';

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
  final String? suspensionReason;

  // Master Artisan profile metadata (if applicable)
  final String? studioName;
  final String? ssmNumber;
  final String? craftCategory;
  final String? bio;
  final String? address;
  final String? state;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? experience;
  final String? artisanProfileId;
  final String? artisanStatus;
  final List<Map<String, dynamic>> artisanDocuments;
  final List<String> tags;
  final String? pendingRelocationAddress;
  final String? pendingRelocationState;
  final double? pendingRelocationLatitude;
  final double? pendingRelocationLongitude;
  final String? pendingRelocationReason;
  final String? pendingRelocationDate;
  final String? rejectionReason;
  final bool isLiveOpen;
  final int? workshopCount;

  const UserModel({
    required this.id,
    required this.email,
    this.username,
    required this.role,
    this.roles = const [],
    this.status = 'ACTIVE',
    this.displayName,
    this.avatarUrl,
    this.joinedDate = '',
    this.isSuspended = false,
    this.suspensionReason,
    this.studioName,
    this.ssmNumber,
    this.craftCategory,
    this.bio,
    this.address,
    this.state,
    this.latitude,
    this.longitude,
    this.phone,
    this.experience,
    this.artisanProfileId,
    this.artisanStatus,
    this.artisanDocuments = const [],
    this.tags = const [],
    this.pendingRelocationAddress,
    this.pendingRelocationState,
    this.pendingRelocationLatitude,
    this.pendingRelocationLongitude,
    this.pendingRelocationReason,
    this.pendingRelocationDate,
    this.rejectionReason,
    this.isLiveOpen = true,
    this.workshopCount,
  });

  bool get hasPendingRelocation =>
      pendingRelocationAddress != null && pendingRelocationAddress!.trim().isNotEmpty;

  bool get isDualRole => false;

  bool get isArtisan =>
      role == 'Artisan' ||
      role == 'Master Artisan' ||
      roles.contains('Artisan') ||
      roles.contains('Master Artisan');

  bool get isTourist =>
      role == 'Tourist' ||
      roles.contains('Tourist');

  bool get isAdmin => role == 'Admin' || roles.contains('Admin');

  bool get hasMultipleRoles => false;

  bool get isApproved => status == 'ACTIVE' || status == 'APPROVED';
  bool get isPendingApproval => status == 'PENDING_APPROVAL' || status == 'PENDING';

  bool get isArtisanStudioSuspended =>
      artisanStatus?.toUpperCase() == 'SUSPENDED';

  bool get isApprovedArtisan {
    if (artisanStatus?.toUpperCase() == 'CLOSED') return false;
    if (role == 'Tourist' && artisanStatus?.toUpperCase() != 'APPROVED') return false;
    return (role == 'Artisan' ||
        role == 'Master Artisan' ||
        roles.contains('Artisan') ||
        roles.contains('Master Artisan') ||
        artisanStatus?.toUpperCase() == 'APPROVED') &&
       isApproved &&
       !isArtisanStudioSuspended;
  }

  bool get isRejectedArtisan {
    if (artisanStatus?.toUpperCase() == 'CLOSED') return false;
    if (isApprovedArtisan) return false;
    final artStatus = artisanStatus?.toUpperCase();
    if (artStatus == 'PENDING_APPROVAL' || artStatus == 'PENDING') return false;
    if (status.toUpperCase() == 'PENDING_APPROVAL' || status.toUpperCase() == 'PENDING') return false;
    return artStatus == 'REJECTED' ||
        (status.toUpperCase() == 'REJECTED' && artStatus == null);
  }

  bool get isPendingArtisan =>
      !isApprovedArtisan &&
      !isRejectedArtisan &&
      artisanStatus?.toUpperCase() != 'CLOSED' &&
      (artisanStatus?.toUpperCase() == 'PENDING_APPROVAL' ||
       artisanStatus?.toUpperCase() == 'PENDING' ||
       (isPendingApproval && role != 'Tourist') ||
       (role != 'Tourist' && studioName != null && studioName!.trim().isNotEmpty)) &&
      !isArtisanStudioSuspended;

  String? get ssmFileUrl {
    for (final d in artisanDocuments) {
      final type = d['doc_type']?.toString();
      if (type == 'SSM_BUSINESS_CERT' || type == 'SSM_CERT' || type == 'SSM') {
        final url = d['file_url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  String? get ssmFileName {
    for (final d in artisanDocuments) {
      final type = d['doc_type']?.toString();
      if (type == 'SSM_BUSINESS_CERT' || type == 'SSM_CERT' || type == 'SSM') {
        final name = d['file_name']?.toString();
        if (name != null && name.isNotEmpty) return name;
        final url = d['file_url']?.toString();
        if (url != null && url.isNotEmpty) return url.split('/').last;
      }
    }
    return null;
  }

  String? get certFileUrl {
    for (final d in artisanDocuments) {
      final type = d['doc_type']?.toString();
      if (type == 'KRAFTANGAN_MASTER_CERT' ||
          type == 'KRAFTANGAN_CERT' ||
          type == 'CERT') {
        final url = d['file_url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  String? get certFileName {
    for (final d in artisanDocuments) {
      final type = d['doc_type']?.toString();
      if (type == 'KRAFTANGAN_MASTER_CERT' ||
          type == 'KRAFTANGAN_CERT' ||
          type == 'CERT') {
        final name = d['file_name']?.toString();
        if (name != null && name.isNotEmpty) return name;
        final url = d['file_url']?.toString();
        if (url != null && url.isNotEmpty) return url.split('/').last;
      }
    }
    return null;
  }

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

  ImageProvider? get avatarImageProvider {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) return null;
    final url = avatarUrl!.trim();
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Data = url.substring(commaIdx + 1);
          final bytes = base64Decode(base64Data);
          return MemoryImage(bytes);
        }
      } catch (_) {
        return null;
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return null;
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
    double? latitude,
    double? longitude,
    String? phone,
    String? experience,
    String? artisanProfileId,
    String? artisanStatus,
    List<Map<String, dynamic>>? artisanDocuments,
    List<String>? tags,
    String? suspensionReason,
    bool clearSuspensionReason = false,
    String? pendingRelocationAddress,
    String? pendingRelocationState,
    double? pendingRelocationLatitude,
    double? pendingRelocationLongitude,
    String? pendingRelocationReason,
    String? pendingRelocationDate,
    bool clearPendingRelocation = false,
    String? rejectionReason,
    bool clearRejectionReason = false,
    bool? isLiveOpen,
    int? workshopCount,
    bool clearStudioDetails = false,
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
      suspensionReason: clearSuspensionReason ? null : (suspensionReason ?? this.suspensionReason),
      studioName: clearStudioDetails ? null : (studioName ?? this.studioName),
      ssmNumber: clearStudioDetails ? null : (ssmNumber ?? this.ssmNumber),
      craftCategory: clearStudioDetails ? null : (craftCategory ?? this.craftCategory),
      bio: clearStudioDetails ? null : (bio ?? this.bio),
      address: address ?? this.address,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      experience: experience ?? this.experience,
      artisanProfileId: clearStudioDetails ? null : (artisanProfileId ?? this.artisanProfileId),
      artisanStatus: artisanStatus ?? this.artisanStatus,
      artisanDocuments: clearStudioDetails ? const [] : (artisanDocuments ?? this.artisanDocuments),
      tags: clearStudioDetails ? const [] : (tags ?? this.tags),
      pendingRelocationAddress: clearPendingRelocation ? null : (pendingRelocationAddress ?? this.pendingRelocationAddress),
      pendingRelocationState: clearPendingRelocation ? null : (pendingRelocationState ?? this.pendingRelocationState),
      pendingRelocationLatitude: clearPendingRelocation ? null : (pendingRelocationLatitude ?? this.pendingRelocationLatitude),
      pendingRelocationLongitude: clearPendingRelocation ? null : (pendingRelocationLongitude ?? this.pendingRelocationLongitude),
      pendingRelocationReason: clearPendingRelocation ? null : (pendingRelocationReason ?? this.pendingRelocationReason),
      pendingRelocationDate: clearPendingRelocation ? null : (pendingRelocationDate ?? this.pendingRelocationDate),
      rejectionReason: clearRejectionReason ? null : (rejectionReason ?? this.rejectionReason),
      isLiveOpen: isLiveOpen ?? this.isLiveOpen,
      workshopCount: workshopCount ?? this.workshopCount,
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
      'joined_date': joinedDate,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'suspension_reason': suspensionReason,
      'studioName': studioName,
      'ssmNumber': ssmNumber,
      'craftCategory': craftCategory,
      'bio': bio,
      'address': address,
      'state': state,
      'phone': phone,
      'experience': experience,
      'artisanProfileId': artisanProfileId,
      'artisanStatus': artisanStatus,
      'latitude': latitude,
      'longitude': longitude,
      'artisan_documents': artisanDocuments,
      'artisanDocuments': artisanDocuments,
      'tags': tags,
      'pending_relocation_address': pendingRelocationAddress,
      'pending_relocation_state': pendingRelocationState,
      'pending_relocation_lat': pendingRelocationLatitude,
      'pending_relocation_lng': pendingRelocationLongitude,
      'pending_relocation_reason': pendingRelocationReason,
      'pending_relocation_date': pendingRelocationDate,
      'rejectionReason': rejectionReason,
      'rejection_reason': rejectionReason,
      'is_live_open': isLiveOpen,
      'isLiveOpen': isLiveOpen,
      'workshop_count': workshopCount,
      'workshopCount': workshopCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawEmail = (map['email'] ?? '').toString().trim().toLowerCase();
    final rawUsername = (map['username'] ?? map['user_name'] ?? '').toString().trim().toLowerCase();
    final bool isDedicatedAdmin = rawEmail == 'admin@warisankita.my' ||
        rawUsername == 'admin' ||
        (map['role'] != null && (map['role'] as String).toLowerCase().contains('admin')) ||
        (map['roles'] is List && (map['roles'] as List).any((r) => r.toString().toLowerCase().contains('admin')));

    final List<String> roleList = map['roles'] != null
        ? List<String>.from(map['roles'])
        : (map['role'] != null
            ? [map['role'] as String]
            : (isDedicatedAdmin ? ['Admin'] : ['Tourist']));
    if (isDedicatedAdmin && !roleList.any((r) => r.toLowerCase().contains('admin'))) {
      roleList.add('Admin');
    }

    Map<String, dynamic>? artisanMap;
    List<Map<String, dynamic>> docs = [];
    if (map['artisan_profiles'] is Map) {
      artisanMap = Map<String, dynamic>.from(map['artisan_profiles']);
    } else if (map['artisan_profiles'] is List && (map['artisan_profiles'] as List).isNotEmpty) {
      artisanMap = Map<String, dynamic>.from((map['artisan_profiles'] as List).first);
    }
    
    if (artisanMap != null && artisanMap['artisan_documents'] != null) {
      docs = (artisanMap['artisan_documents'] as List)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();
    } else if (map['artisan_documents'] != null) {
      docs = (map['artisan_documents'] as List)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();
    } else if (map['artisanDocuments'] != null) {
      docs = (map['artisanDocuments'] as List)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();
    }

    final rawTags = artisanMap?['tags'] ?? map['tags'];
    final tagsList = rawTags is List
        ? List<String>.from(rawTags.map((t) => t.toString()))
        : const <String>[];

    // Parse lat/lon
    final latRaw = artisanMap?['latitude'] ?? map['latitude'];
    final double? lat = latRaw is num ? latRaw.toDouble() : (latRaw != null ? double.tryParse(latRaw.toString()) : null);
    
    final lonRaw = artisanMap?['longitude'] ?? map['longitude'];
    final double? lon = lonRaw is num ? lonRaw.toDouble() : (lonRaw != null ? double.tryParse(lonRaw.toString()) : null);

    final pLatRaw = artisanMap?['pending_relocation_lat'] ?? map['pending_relocation_lat'] ?? map['pendingRelocationLatitude'];
    final double? pLat = pLatRaw is num ? pLatRaw.toDouble() : (pLatRaw != null ? double.tryParse(pLatRaw.toString()) : null);

    final pLonRaw = artisanMap?['pending_relocation_lng'] ?? map['pending_relocation_lng'] ?? map['pendingRelocationLongitude'];
    final double? pLon = pLonRaw is num ? pLonRaw.toDouble() : (pLonRaw != null ? double.tryParse(pLonRaw.toString()) : null);

    final rawJoined = map['created_at'] ?? map['createdAt'] ?? map['joined_date'] ?? map['joinedDate'];
    String resolvedJoinedDate = '';
    if (rawJoined != null) {
      final str = rawJoined.toString().trim();
      if (str.isNotEmpty) {
        final parsed = DateTime.tryParse(str);
        if (parsed != null) {
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          resolvedJoinedDate = '${months[parsed.month - 1]} ${parsed.year}';
        } else {
          resolvedJoinedDate = str;
        }
      }
    }
    if (resolvedJoinedDate.isEmpty) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final now = DateTime.now();
      resolvedJoinedDate = '${months[now.month - 1]} ${now.year}';
    }

    final artisanExp = artisanMap?['experience']?.toString().trim();
    final artisanYears = artisanMap?['years_experience'];
    final String? resolvedExp = (map['experience'] != null && map['experience'].toString().trim().isNotEmpty)
        ? map['experience'].toString().trim()
        : ((artisanExp != null && artisanExp.isNotEmpty)
            ? artisanExp
            : (artisanYears != null && (artisanYears as num) > 1
                ? '$artisanYears Years'
                : null));

    final rawWorkshops = map['workshop_count'] ??
        map['workshops_hosted'] ??
        map['workshopCount'] ??
        artisanMap?['workshop_count'] ??
        artisanMap?['workshops_hosted'];
    final int? resolvedWorkshops = rawWorkshops is num
        ? rawWorkshops.toInt()
        : (rawWorkshops != null ? int.tryParse(rawWorkshops.toString()) : null);

    final rawArtisanStatus = artisanMap?['status'] ?? map['artisanStatus'] ?? map['artisan_status'];
    final String? resolvedArtisanStatus = rawArtisanStatus?.toString();
    final bool isApprovedArtisanStatus = resolvedArtisanStatus?.toUpperCase() == 'APPROVED';

    final String resolvedRole;
    final List<String> resolvedRoles;
    if (isDedicatedAdmin) {
      resolvedRole = (map['role'] != null && (map['role'] as String).toLowerCase().contains('admin'))
          ? map['role'] as String
          : 'Admin';
      resolvedRoles = roleList;
    } else if (isApprovedArtisanStatus) {
      resolvedRole = 'Artisan';
      resolvedRoles = const ['Artisan'];
    } else {
      resolvedRole = (map['role'] ?? 'Tourist').toString();
      resolvedRoles = roleList;
    }

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? map['user_name'],
      role: resolvedRole,
      roles: resolvedRoles,
      status: map['status'] ?? 'ACTIVE',
      displayName: map['displayName'] ?? map['display_name'] ?? map['full_name'],
      avatarUrl: map['avatarUrl'] ?? map['avatar_url'],
      joinedDate: resolvedJoinedDate,
      isSuspended: map['isSuspended'] ?? (map['status'] == 'SUSPENDED'),
      suspensionReason: map['suspensionReason'] ?? map['suspension_reason'],
      studioName: map['studioName'] ?? map['studio_name'] ?? artisanMap?['studio_name'],
      ssmNumber: map['ssmNumber'] ?? map['ssm_number'] ?? artisanMap?['ssm_number'],
      craftCategory: map['craftCategory'] ?? map['craft_category'] ?? artisanMap?['craft_category'],
      bio: map['bio'] ?? artisanMap?['bio'],
      address: map['address'] ?? artisanMap?['address'],
      state: map['state'] ?? artisanMap?['state'],
      latitude: lat,
      longitude: lon,
      phone: map['phone'] ?? map['phone_number'] ?? artisanMap?['phone'],
      experience: resolvedExp,
      artisanProfileId: artisanMap?['id'],
      artisanStatus: artisanMap?['status'] ?? map['artisanStatus'] ?? map['artisan_status'],
      artisanDocuments: docs,
      tags: tagsList,
      pendingRelocationAddress: map['pending_relocation_address'] ?? map['pendingRelocationAddress'] ?? artisanMap?['pending_relocation_address'],
      pendingRelocationState: map['pending_relocation_state'] ?? map['pendingRelocationState'] ?? artisanMap?['pending_relocation_state'],
      pendingRelocationLatitude: pLat,
      pendingRelocationLongitude: pLon,
      pendingRelocationReason: map['pending_relocation_reason'] ?? map['pendingRelocationReason'] ?? artisanMap?['pending_relocation_reason'],
      pendingRelocationDate: map['pending_relocation_date'] ?? map['pendingRelocationDate'] ?? artisanMap?['pending_relocation_date'],
      rejectionReason: map['rejectionReason'] ?? map['rejection_reason'] ?? artisanMap?['rejection_reason'],
      isLiveOpen: map['is_live_open'] ?? map['isLiveOpen'] ?? artisanMap?['is_live_open'] ?? true,
      workshopCount: resolvedWorkshops,
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
