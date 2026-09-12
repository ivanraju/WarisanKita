import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/approval_history_record.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';

class ModerationViewModel extends ChangeNotifier {
  final UserRepository _repository;

  ModerationViewModel({UserRepository? repository, SupabaseService? service})
    : _repository = repository ?? UserRepository(service: service) {
    _loadTodayStats();
    loadApprovalHistory();
    refreshAllData();
  }

  String _activeTab = 'Pending Approvals';
  String get activeTab => _activeTab;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _applicationTypeFilter = 'All'; // 'All', 'New Profiles', 'Relocations'
  String get applicationTypeFilter => _applicationTypeFilter;

  String _selectedCategory = 'All Categories';
  String get selectedCategory => _selectedCategory;

  final List<String> categories = const [
    'All Categories',
    'Pottery & Ceramics',
    'Batik Weaving',
    'Wood Carving',
    'Songket Weaving',
    'Pewter Craft',
  ];

  // Pending Artisan Approvals State
  final List<PendingArtisanProfile> _pendingArtisans = [];

  String? _artisanApprovalError;
  String? get artisanApprovalError => _artisanApprovalError;

  String? _approvingArtisanId;
  bool isApprovingArtisan(String id) => _approvingArtisanId == id;

  // Active Verified Master Artisans State
  final List<ActiveArtisanMaster> _activeArtisanMasters = [];

  List<ActiveArtisanMaster> get activeArtisanMasters => _activeArtisanMasters;

  List<ActiveArtisanMaster> get filteredActiveArtisans {
    return _activeArtisanMasters.where((artisan) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.licenseNo.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          artisan.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          artisan.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Approval History State
  final List<ApprovalHistoryRecord> _approvalHistory = [];
  List<ApprovalHistoryRecord> get approvalHistory =>
      List.unmodifiable(_approvalHistory);

  String _historySearchQuery = '';
  String get historySearchQuery => _historySearchQuery;

  String _historyTypeFilter = 'All Types';
  String get historyTypeFilter => _historyTypeFilter;

  final List<String> historyTypeFilters = const [
    'All Types',
    'Artisan Profiles',
    'Premise Relocations',
  ];

  void setHistorySearchQuery(String query) {
    _historySearchQuery = query;
    notifyListeners();
  }

  void setHistoryTypeFilter(String filter) {
    _historyTypeFilter = filter;
    notifyListeners();
  }

  List<ApprovalHistoryRecord> get filteredApprovalHistory {
    return _approvalHistory.where((record) {
      final matchesSearch = _historySearchQuery.isEmpty ||
          record.targetName.toLowerCase().contains(_historySearchQuery.toLowerCase()) ||
          record.targetEmail.toLowerCase().contains(_historySearchQuery.toLowerCase()) ||
          record.craftCategory.toLowerCase().contains(_historySearchQuery.toLowerCase()) ||
          record.state.toLowerCase().contains(_historySearchQuery.toLowerCase()) ||
          (record.ssmNumber?.toLowerCase().contains(_historySearchQuery.toLowerCase()) ?? false) ||
          (record.previousPremise?.toLowerCase().contains(_historySearchQuery.toLowerCase()) ?? false) ||
          (record.newPremise?.toLowerCase().contains(_historySearchQuery.toLowerCase()) ?? false);

      final matchesType = _historyTypeFilter == 'All Types' ||
          (_historyTypeFilter == 'Artisan Profiles' && !record.isRelocation) ||
          (_historyTypeFilter == 'Premise Relocations' && record.isRelocation);

      return matchesSearch && matchesType;
    }).toList();
  }

  int get totalApprovalHistoryCount => _approvalHistory.length;
  int get profileApprovalCount =>
      _approvalHistory.where((r) => !r.isRelocation).length;
  int get relocationApprovalCount =>
      _approvalHistory.where((r) => r.isRelocation).length;
  int get todayApprovalHistoryCount {
    final now = DateTime.now();
    return _approvalHistory.where((r) {
      return r.approvedAt.year == now.year &&
          r.approvedAt.month == now.month &&
          r.approvedAt.day == now.day;
    }).length;
  }

  static const String _approvalHistoryKey = 'wk_admin_approval_history';

  Future<void> loadApprovalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_approvalHistoryKey);
      final List<ApprovalHistoryRecord> loaded = [];

      if (rawJson != null && rawJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawJson) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              loaded.add(ApprovalHistoryRecord.fromMap(item));
            } else if (item is Map) {
              loaded.add(
                ApprovalHistoryRecord.fromMap(Map<String, dynamic>.from(item)),
              );
            }
          }
        } catch (e) {
          debugPrint('Error parsing saved approval history: $e');
        }
      }

      // Merge verified active masters so historical records are visible
      for (final artisan in _activeArtisanMasters) {
        final alreadyLogged = loaded.any(
          (r) =>
              r.targetEmail.toLowerCase() == artisan.email.toLowerCase() &&
              !r.isRelocation,
        );
        if (!alreadyLogged) {
          DateTime approvedDate;
          try {
            approvedDate =
                DateTime.tryParse(artisan.verifiedDate) ??
                _parseSubmissionDate(artisan.verifiedDate) ??
                DateTime(2026, 1, 15);
          } catch (_) {
            approvedDate = DateTime(2026, 1, 15);
          }

          loaded.add(
            ApprovalHistoryRecord(
              id: 'hist_${artisan.id}',
              title: 'Master Artisan Profile Approved',
              targetName: artisan.name,
              targetEmail: artisan.email,
              approvalType: 'Artisan Profile',
              craftCategory: artisan.category,
              state: artisan.state,
              details:
                  'SSM License: ${artisan.licenseNo} • Experience: ${artisan.experience}',
              newPremise: '${artisan.name} Studio (${artisan.state})',
              ssmNumber: artisan.licenseNo,
              approvedAt: approvedDate,
              approvedBy: 'Admin Moderator',
              status: 'APPROVED',
            ),
          );
        }
      }

      loaded.sort((a, b) => b.approvedAt.compareTo(a.approvedAt));
      _approvalHistory.clear();
      _approvalHistory.addAll(loaded);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading approval history: $e');
    }
  }

  Future<void> _recordApprovalHistory({
    required String title,
    required String targetName,
    required String targetEmail,
    required String approvalType,
    required String craftCategory,
    required String state,
    required String details,
    String? previousPremise,
    String? newPremise,
    String? ssmNumber,
    String approvedBy = 'Admin Moderator',
  }) async {
    try {
      final newRecord = ApprovalHistoryRecord(
        id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        targetName: targetName,
        targetEmail: targetEmail,
        approvalType: approvalType,
        craftCategory: craftCategory,
        state: state,
        details: details,
        previousPremise: previousPremise,
        newPremise: newPremise,
        ssmNumber: ssmNumber,
        approvedAt: DateTime.now(),
        approvedBy: approvedBy,
        status: 'APPROVED',
      );

      _approvalHistory.removeWhere((r) => r.id == newRecord.id);
      _approvalHistory.insert(0, newRecord);

      final prefs = await SharedPreferences.getInstance();
      final listMap = _approvalHistory.map((r) => r.toMap()).toList();
      await prefs.setString(_approvalHistoryKey, jsonEncode(listMap));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save approval history record: $e');
    }
  }

  // User Management State
  final List<UserModel> _registeredUsers = [];

  void updateUserProfileInState({
    required String email,
    String? username,
    String? displayName,
    String? studioName,
    String? craftCategory,
    String? state,
    String? phone,
    String? bio,
    String? experience,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final targetName = studioName ?? displayName ?? username;

    final userIdx = _registeredUsers.indexWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
    );
    if (userIdx != -1) {
      final user = _registeredUsers[userIdx];
      _registeredUsers[userIdx] = user.copyWith(
        username: username ?? user.username,
        displayName: displayName ?? username ?? user.displayName,
        studioName: targetName ?? user.studioName,
        craftCategory: craftCategory ?? user.craftCategory,
        state: state ?? user.state,
        phone: phone ?? user.phone,
        bio: bio ?? user.bio,
        experience: experience ?? user.experience,
      );
    }

    final artisanIdx = _activeArtisanMasters.indexWhere(
      (a) => a.email.toLowerCase() == cleanEmail,
    );
    if (artisanIdx != -1) {
      final artisan = _activeArtisanMasters[artisanIdx];
      _activeArtisanMasters[artisanIdx] = artisan.copyWith(
        name: targetName ?? artisan.name,
        category: craftCategory ?? artisan.category,
        state: state ?? artisan.state,
        phone: phone ?? artisan.phone,
        bio: bio ?? artisan.bio,
        experience: experience ?? artisan.experience,
      );
    }

    notifyListeners();
  }

  String _userSearchQuery = '';
  String get userSearchQuery => _userSearchQuery;

  String _userRoleFilter = 'All Roles';
  String get userRoleFilter => _userRoleFilter;

  String _userStatusFilter = 'All Statuses';
  String get userStatusFilter => _userStatusFilter;

  final List<String> userRoles = const [
    'All Roles',
    'Tourist',
    'Artisan',
    'Admin',
  ];

  final List<String> userStatuses = const [
    'All Statuses',
    'Active',
    'Suspended',
  ];

  List<UserModel> get registeredUsers => _registeredUsers
      .where(
        (u) =>
            u.status.toUpperCase() != 'DELETED' &&
            !u.email.toLowerCase().startsWith('deleted_'),
      )
      .toList();

  List<UserModel> get filteredUsers {
    return _registeredUsers.where((user) {
      if (user.status.toUpperCase() == 'DELETED' ||
          user.email.toLowerCase().startsWith('deleted_')) {
        return false;
      }

      final matchesSearch =
          _userSearchQuery.isEmpty ||
          (user.displayName ?? '').toLowerCase().contains(
            _userSearchQuery.toLowerCase(),
          ) ||
          (user.username ?? '').toLowerCase().contains(
            _userSearchQuery.toLowerCase(),
          ) ||
          user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());

      final r = user.role.toLowerCase();
      final matchesRole =
          _userRoleFilter == 'All Roles' ||
          ((_userRoleFilter == 'Tourist' ||
                  _userRoleFilter == 'Cultural Tourist') &&
              (r.contains('tourist') || user.isTourist)) ||
          ((_userRoleFilter == 'Artisan' ||
                  _userRoleFilter == 'Master Artisan') &&
              (r.contains('artisan') || user.isArtisan)) ||
          (_userRoleFilter == 'Admin' && r.contains('admin'));

      final matchesStatus =
          _userStatusFilter == 'All Statuses' ||
          (_userStatusFilter == 'Active' &&
              !user.isSuspended &&
              user.status.toUpperCase() != 'SUSPENDED') ||
          (_userStatusFilter == 'Suspended' &&
              (user.isSuspended || user.status.toUpperCase() == 'SUSPENDED'));

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  void removeUserByEmailOrId({String? email, String? id}) {
    _registeredUsers.removeWhere(
      (u) =>
          (email != null && u.email.toLowerCase() == email.toLowerCase()) ||
          (id != null && u.id == id),
    );
    _activeArtisanMasters.removeWhere(
      (a) =>
          (email != null && a.email.toLowerCase() == email.toLowerCase()) ||
          (id != null && a.id == id),
    );
    _pendingArtisans.removeWhere(
      (p) =>
          (email != null && p.email.toLowerCase() == email.toLowerCase()) ||
          (id != null && p.id == id),
    );
    notifyListeners();
  }

  List<PendingArtisanProfile> get filteredArtisans {
    return _pendingArtisans.where((artisan) {
      final matchingUsers = _registeredUsers.where(
        (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      if (matchingUsers.isNotEmpty) {
        final registeredUser = matchingUsers.first;
        final artisanStatus = registeredUser.artisanStatus?.toUpperCase();
        if (registeredUser.status.toUpperCase() == 'REJECTED' ||
            artisanStatus == 'REJECTED' ||
            (!artisan.isRelocationRequest && artisanStatus == 'APPROVED')) {
          return false;
        }
      }

      final matchesSearch =
          _searchQuery.isEmpty ||
          artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.craftCategory.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          artisan.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (artisan.currentAddress?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (artisan.proposedAddress?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (artisan.proposedState?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          artisan.craftCategory == _selectedCategory;

      final matchesType =
          _applicationTypeFilter == 'All' ||
          (_applicationTypeFilter == 'New Profiles' &&
              !artisan.isRelocationRequest) ||
          (_applicationTypeFilter == 'Relocations' &&
              artisan.isRelocationRequest);

      return matchesSearch && matchesCategory && matchesType;
    }).toList();
  }

  List<PendingArtisanProfile> get filteredPendingProfiles {
    return _pendingArtisans.where((artisan) {
      if (artisan.isRelocationRequest) return false;

      final matchingUsers = _registeredUsers.where(
        (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      if (matchingUsers.isNotEmpty) {
        final registeredUser = matchingUsers.first;
        final artisanStatus = registeredUser.artisanStatus?.toUpperCase();
        if (registeredUser.status.toUpperCase() == 'REJECTED' ||
            artisanStatus == 'REJECTED' ||
            artisanStatus == 'APPROVED') {
          return false;
        }
      }

      final matchesSearch =
          _searchQuery.isEmpty ||
          artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.craftCategory.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          artisan.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          artisan.craftCategory == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<PendingArtisanProfile> get filteredRelocations {
    return _pendingArtisans.where((artisan) {
      if (!artisan.isRelocationRequest) return false;

      final matchingUsers = _registeredUsers.where(
        (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      if (matchingUsers.isNotEmpty) {
        final registeredUser = matchingUsers.first;
        final artisanStatus = registeredUser.artisanStatus?.toUpperCase();
        if (registeredUser.status.toUpperCase() == 'REJECTED' ||
            artisanStatus == 'REJECTED' ||
            registeredUser.isSuspended) {
          return false;
        }
      }

      final matchesSearch =
          _searchQuery.isEmpty ||
          artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.craftCategory.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          artisan.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (artisan.currentAddress?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (artisan.proposedAddress?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (artisan.proposedState?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          artisan.craftCategory == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<PendingArtisanProfile> get pendingArtisans =>
      List.unmodifiable(_pendingArtisans);
  int get totalPendingCount => _pendingArtisans.length;
  int get pendingRelocationCount =>
      _pendingArtisans.where((p) => p.isRelocationRequest).length;
  int get pendingNewProfilesCount =>
      _pendingArtisans.where((p) => !p.isRelocationRequest).length;

  int _sessionApprovedToday = 0;
  final List<Duration> _reviewDurations = [];

  Future<void> _loadTodayStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = 'wk_admin_approved_${now.year}_${now.month}_${now.day}';
      final savedCount = prefs.getInt(todayKey) ?? 0;
      if (savedCount > _sessionApprovedToday) {
        _sessionApprovedToday = savedCount;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _recordApproval(DateTime? submittedDate) {
    _sessionApprovedToday++;
    if (submittedDate != null) {
      final diff = DateTime.now().difference(submittedDate);
      _reviewDurations.add(
        diff.isNegative ? const Duration(minutes: 30) : diff,
      );
    } else {
      _reviewDurations.add(const Duration(minutes: 45));
    }
    notifyListeners();
  }

  Future<void> _persistApprovalCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = 'wk_admin_approved_${now.year}_${now.month}_${now.day}';
      await prefs.setInt(todayKey, _sessionApprovedToday);
    } catch (_) {}
  }

  DateTime? _parseSubmissionDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    if (raw.toLowerCase().contains('today') ||
        raw.toLowerCase().contains('just')) {
      return DateTime.now();
    }
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      const months = [
        'jan',
        'feb',
        'mar',
        'apr',
        'may',
        'jun',
        'jul',
        'aug',
        'sep',
        'oct',
        'nov',
        'dec',
      ];
      final monthIdx = months.indexOf(parts[1].toLowerCase());
      final year = int.tryParse(parts[2]);
      if (day != null && monthIdx != -1 && year != null) {
        return DateTime(year, monthIdx + 1, day);
      }
    }
    return null;
  }

  int get approvedTodayCount {
    final now = DateTime.now();
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final activeToday = _activeArtisanMasters.where((a) {
      final vd = a.verifiedDate.toLowerCase();
      return vd.contains(todayIso) ||
          vd.contains('today') ||
          vd.contains('just approved');
    }).length;
    return activeToday > _sessionApprovedToday
        ? activeToday
        : _sessionApprovedToday;
  }

  String get approvedTodaySubtitle {
    final count = approvedTodayCount;
    if (count == 0) {
      return 'No reviews completed today';
    } else if (count == 1) {
      return '1 studio approved today';
    } else {
      return '$count studios approved today';
    }
  }

  String get averageReviewTime {
    final List<Duration> durations = List.from(_reviewDurations);

    // If there are pending applications waiting, factor in their turnaround/wait time
    for (final pending in _pendingArtisans) {
      final submitted = _parseSubmissionDate(pending.dateSubmitted);
      if (submitted != null) {
        final diff = DateTime.now().difference(submitted);
        if (!diff.isNegative) {
          durations.add(diff);
        }
      }
    }

    if (durations.isEmpty) {
      return '< 1 day';
    }

    final totalMinutes = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    final avgMinutes = totalMinutes / durations.length;
    final avgHours = avgMinutes / 60.0;

    if (avgHours < 1) {
      return '< 1 hr';
    } else if (avgHours < 24) {
      return '${avgHours.toStringAsFixed(1)} hrs';
    } else {
      final avgDays = avgHours / 24.0;
      return '${avgDays.toStringAsFixed(1)} days';
    }
  }

  String get averageReviewTimeSubtitle {
    if (_pendingArtisans.isEmpty && approvedTodayCount == 0) {
      return 'Target: < 2.0 days • Queue clear';
    }
    return 'Target: < 2.0 days';
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setApplicationTypeFilter(String filter) {
    _applicationTypeFilter = filter;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setUserSearchQuery(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  void setUserRoleFilter(String role) {
    _userRoleFilter = role;
    notifyListeners();
  }

  void setUserStatusFilter(String status) {
    _userStatusFilter = status;
    notifyListeners();
  }

  Future<void> fetchPendingArtisans() async {
    try {
      final List<Map<String, dynamic>> dbPending = await _repository
          .getPendingArtisans();

      final List<PendingArtisanProfile> fetched = [];

      for (final raw in dbPending) {
        final email = (raw['email'] ?? '').toString();
        if (email.isEmpty) continue;

        final rawStatus = (raw['status'] ?? '').toString().toUpperCase();
        final rawArtisanStatus =
            (raw['artisan_status'] ?? raw['artisanStatus'] ?? '')
                .toString()
                .toUpperCase();
        Map<String, dynamic>? artisanProfile;
        if (raw['artisan_profiles'] is Map) {
          artisanProfile = Map<String, dynamic>.from(raw['artisan_profiles']);
        } else if (raw['artisan_profiles'] is List &&
            (raw['artisan_profiles'] as List).isNotEmpty) {
          artisanProfile = Map<String, dynamic>.from(
            (raw['artisan_profiles'] as List).first,
          );
        }
        final profileStatus = (artisanProfile?['status'] ?? '')
            .toString()
            .toUpperCase();
        const terminalStatuses = {'REJECTED', 'APPROVED', 'CLOSED'};
        final bool isExplicitlyPending = rawArtisanStatus == 'PENDING_APPROVAL' ||
            rawArtisanStatus == 'PENDING' ||
            rawStatus == 'PENDING_APPROVAL' ||
            rawStatus == 'PENDING';

        if (!isExplicitlyPending) {
          if (rawStatus == 'REJECTED' ||
              terminalStatuses.contains(rawArtisanStatus) ||
              terminalStatuses.contains(profileStatus)) {
            continue;
          }

          final matchingRegistered = _registeredUsers.where(
            (u) => u.email.toLowerCase() == email.toLowerCase(),
          );
          if (matchingRegistered.isNotEmpty) {
            final existingUser = matchingRegistered.first;
            final existingArtisanStatus = existingUser.artisanStatus
                ?.toUpperCase();
            if (existingUser.status.toUpperCase() == 'REJECTED' ||
                existingArtisanStatus == 'REJECTED' ||
                existingArtisanStatus == 'APPROVED') {
              continue;
            }
          }
        } else {
          final regIdx = _registeredUsers.indexWhere(
            (u) => u.email.toLowerCase() == email.toLowerCase(),
          );
          if (regIdx != -1) {
            _registeredUsers[regIdx] = _registeredUsers[regIdx].copyWith(
              status: 'PENDING_APPROVAL',
              artisanStatus: 'PENDING_APPROVAL',
              role: 'Tourist',
              roles: const ['Tourist'],
            );
          }
        }

        final id = raw['id']?.toString() ?? 'p_${email.hashCode}';
        final name =
            (raw['studio_name'] ??
                    raw['studioName'] ??
                    raw['full_name'] ??
                    raw['displayName'] ??
                    raw['username'] ??
                    'Artisan Studio')
                .toString();
        final craft =
            (raw['craft_category'] ??
                    raw['craftCategory'] ??
                    'Handicraft & Heritage')
                .toString();
        final state = (raw['state'] ?? 'Malaysia').toString();
        final role = (raw['role'] ?? '').toString();
        final isUpgrade = role.contains('Tourist') || role.contains('Both');

        // Resolve the avatar/image URL from the DB row
        final resolvedImageUrl =
            (raw['imageUrl'] ??
                    raw['avatar_url'] ??
                    'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600')
                .toString();

        // Resolve photos - must be actual URLs, not filenames
        final List<String> resolvedPhotos = [];
        if (raw['photos'] is List && (raw['photos'] as List).isNotEmpty) {
          for (final p in (raw['photos'] as List)) {
            final str = p?.toString();
            if (str != null && str.isNotEmpty && !resolvedPhotos.contains(str)) {
              resolvedPhotos.add(str);
            }
          }
        }

        String? resolvedSsmUrl = raw['ssm_file_url']?.toString();
        String? resolvedSsmName =
            (raw['ssm_file'] ?? raw['ssm_file_name'] ?? raw['ssmFileName'])
                ?.toString();
        String? resolvedCertUrl = raw['cert_file_url']?.toString();
        String? resolvedCertName =
            (raw['cert_file'] ?? raw['cert_file_name'] ?? raw['certFileName'])
                ?.toString();

        final rawDocs = (artisanProfile?['artisan_documents'] is List)
            ? artisanProfile!['artisan_documents'] as List
            : (raw['artisan_documents'] is List
                ? raw['artisan_documents'] as List
                : const []);
        for (final d in rawDocs) {
          if (d is Map) {
            final type = d['doc_type']?.toString();
            final url = d['file_url']?.toString();
            final name = d['file_name']?.toString();
            if (type == 'SSM_BUSINESS_CERT' ||
                type == 'SSM_CERT' ||
                type == 'SSM') {
              resolvedSsmUrl ??= url;
              resolvedSsmName ??= name ?? url?.split('/').last;
            } else if (type == 'KRAFTANGAN_MASTER_CERT' ||
                type == 'KRAFTANGAN_CERT' ||
                type == 'CERT') {
              resolvedCertUrl ??= url;
              resolvedCertName ??= name ?? url?.split('/').last;
            } else if (type == 'STUDIO_PHOTO' || type == 'PORTFOLIO_IMAGE') {
              if (url != null && url.isNotEmpty && !resolvedPhotos.contains(url)) {
                resolvedPhotos.add(url);
              }
            }
          }
        }

        // Resolve experience
        final rawExp = raw['experience'] ??
            raw['years_experience'] ??
            artisanProfile?['experience'] ??
            artisanProfile?['years_experience'];
        String resolvedExperience;
        if (rawExp != null) {
          final expStr = rawExp.toString().trim();
          final numMatch = RegExp(r'^\d+$').firstMatch(expStr);
          if (numMatch != null) {
            final val = int.tryParse(numMatch.group(0)!);
            resolvedExperience = '$val Year${val == 1 ? '' : 's'}';
          } else if (expStr.isNotEmpty) {
            resolvedExperience = expStr;
          } else {
            resolvedExperience = 'Verified Studio';
          }
        } else {
          resolvedExperience = 'Verified Studio';
        }

        // Resolve phone
        final rawPhone = raw['phone'] ??
            raw['phone_number'] ??
            artisanProfile?['phone'] ??
            artisanProfile?['phone_number'];
        final resolvedPhone = (rawPhone != null && rawPhone.toString().trim().isNotEmpty)
            ? rawPhone.toString().trim()
            : '+60 12-345 6789';

        final newProfile = PendingArtisanProfile(
          id: id,
          name: name,
          craftCategory: craft,
          state: state,
          dateSubmitted:
              raw['dateSubmitted']?.toString() ??
              raw['created_at']?.toString() ??
              'Today',
          imageUrl: resolvedImageUrl,
          email: email,
          experience: resolvedExperience,
          phone: resolvedPhone,
          ssmNumber:
              (raw['ssm_number'] ??
                      raw['ssmNumber'] ??
                      '202601004821 (SSM Verified)')
                  .toString(),
          ssmFileName: resolvedSsmName,
          ssmFileUrl: resolvedSsmUrl,
          certFileName: resolvedCertName,
          certFileUrl: resolvedCertUrl,
          photos: resolvedPhotos,
          bio: raw['bio']?.toString() ?? artisanProfile?['bio']?.toString(),
          isUpgradeFromTourist: isUpgrade,
        );

        fetched.add(newProfile);
      }

      // Also query users with pending relocation from repository
      try {
        final allUsers = await _repository.getAllUsers();
        for (final u in allUsers) {
          if (u.isPendingArtisan) {
            if (!fetched.any(
              (p) =>
                  p.email.toLowerCase() == u.email.toLowerCase() &&
                  !p.isRelocationRequest,
            )) {
              final photos = u.artisanDocuments
                  .where(
                    (d) =>
                        d['doc_type'] == 'PORTFOLIO_IMAGE' ||
                        d['doc_type'] == 'STUDIO_PHOTO',
                  )
                  .map((d) => (d['file_url'] ?? '').toString())
                  .where((url) => url.isNotEmpty)
                  .toList();
              fetched.add(
                PendingArtisanProfile(
                  id: u.id,
                  name: u.studioName ?? u.displayName ?? 'Artisan Studio',
                  craftCategory: u.craftCategory ?? 'Handicraft & Heritage',
                  state: u.state ?? 'Melaka',
                  dateSubmitted: u.joinedDate.isNotEmpty ? u.joinedDate : 'Today',
                  imageUrl:
                      u.avatarUrl ??
                      'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600',
                  email: u.email,
                  experience:
                      (u.experience?.trim().isNotEmpty == true)
                      ? (RegExp(r'^\d+$').hasMatch(u.experience!.trim())
                          ? '${u.experience!.trim()} Years'
                          : u.experience!)
                      : 'Verified Studio',
                  phone: (u.phone != null && u.phone!.trim().isNotEmpty)
                      ? u.phone!
                      : '+60 12-345 6789',
                  ssmNumber: u.ssmNumber ?? 'Pending Document Verification',
                  ssmFileName: u.ssmFileName,
                  ssmFileUrl: u.ssmFileUrl,
                  certFileName: u.certFileName,
                  certFileUrl: u.certFileUrl,
                  bio: u.bio,
                  isUpgradeFromTourist: u.role == 'Tourist',
                  photos: photos,
                ),
              );
            }
          }

          if (u.hasPendingRelocation) {
            final relocId = 'reloc_${u.id}';
            if (!fetched.any(
              (p) =>
                  p.email.toLowerCase() == u.email.toLowerCase() &&
                  p.isRelocationRequest,
            )) {
              fetched.insert(
                0,
                PendingArtisanProfile(
                  id: relocId,
                  name: u.studioName ?? u.displayName ?? 'Artisan Studio',
                  craftCategory: u.craftCategory ?? 'Handicraft & Heritage',
                  state: u.state ?? 'Melaka',
                  dateSubmitted: u.pendingRelocationDate ?? 'Recent',
                  imageUrl:
                      u.avatarUrl ??
                      'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600',
                  email: u.email,
                  experience:
                      (u.experience != null && u.experience!.trim().isNotEmpty)
                      ? u.experience!
                      : 'Accredited Studio',
                  phone: u.phone ?? '+60 12-345 6789',
                  ssmNumber: u.ssmNumber ?? 'Verified Studio',
                  bio: u.bio,
                  isUpgradeFromTourist: false,
                  isRelocationRequest: true,
                  currentAddress: u.address,
                  proposedAddress: u.pendingRelocationAddress,
                  proposedLatitude: u.pendingRelocationLatitude,
                  proposedLongitude: u.pendingRelocationLongitude,
                  proposedState: u.pendingRelocationState,
                  relocationReason: u.pendingRelocationReason,
                  ssmFileName: u.pendingRelocationCertName ?? u.ssmFileName,
                  ssmFileUrl: u.pendingRelocationCertUrl ?? u.ssmFileUrl,
                  certFileName: u.pendingRelocationCertName ?? u.certFileName,
                  certFileUrl: u.pendingRelocationCertUrl ?? u.certFileUrl,
                  relocationCertFileName: u.pendingRelocationCertName,
                  relocationCertFileUrl: u.pendingRelocationCertUrl,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching relocation requests: $e');
      }

      _pendingArtisans.clear();
      _pendingArtisans.addAll(fetched);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching pending artisans: $e');
    }
  }

  Future<void> fetchActiveArtisans() async {
    try {
      final dbArtisans = await _repository.getActiveArtisans();
      _activeArtisanMasters.clear();
      _activeArtisanMasters.addAll(dbArtisans);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching active artisans: $e');
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final dbUsers = await _repository.getAllUsers();
      _registeredUsers.clear();
      _registeredUsers.addAll(dbUsers);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
    }
  }

  Future<void> refreshAllData() async {
    await Future.wait([
      fetchPendingArtisans(),
      fetchActiveArtisans(),
      fetchAllUsers(),
    ]);
    await loadApprovalHistory();
  }

  void addPendingArtisan(PendingArtisanProfile profile) {
    _pendingArtisans.removeWhere(
      (p) => p.email.toLowerCase() == profile.email.toLowerCase(),
    );
    _pendingArtisans.insert(0, profile);
    final userIdx = _registeredUsers.indexWhere(
      (u) => u.email.toLowerCase() == profile.email.toLowerCase(),
    );
    if (userIdx != -1) {
      _registeredUsers[userIdx] = _registeredUsers[userIdx].copyWith(
        status: 'PENDING_APPROVAL',
        artisanStatus: 'PENDING_APPROVAL',
        role: 'Tourist',
        roles: const ['Tourist'],
        studioName: profile.name,
        craftCategory: profile.craftCategory,
        state: profile.state,
        phone: profile.phone,
        bio: profile.bio,
        experience: profile.experience,
      );
    }
    notifyListeners();
  }

  void addRelocationRequest(PendingArtisanProfile profile) {
    _pendingArtisans.removeWhere(
      (p) =>
          p.email.toLowerCase() == profile.email.toLowerCase() &&
          p.isRelocationRequest,
    );
    _pendingArtisans.insert(0, profile);
    notifyListeners();
  }

  void addUserForTesting(UserModel user) {
    _registeredUsers.removeWhere(
      (u) => u.email.toLowerCase() == user.email.toLowerCase() || u.id == user.id,
    );
    _registeredUsers.add(user);
    notifyListeners();
  }

  Future<bool> approveArtisan(String id) async {
    if (_approvingArtisanId != null) return false;
    final idx = _pendingArtisans.indexWhere((item) => item.id == id);
    if (idx == -1) return false;

    final artisan = _pendingArtisans[idx];
    final submittedDate = _parseSubmissionDate(artisan.dateSubmitted);
    final previousApprovalCount = _sessionApprovedToday;
    final previousReviewDurationCount = _reviewDurations.length;
    _recordApproval(submittedDate);
    _approvingArtisanId = id;
    _artisanApprovalError = null;
    notifyListeners();

    try {
      if (artisan.isRelocationRequest) {
        await _repository.approveRelocationRequest(
          email: artisan.email,
          newAddress: artisan.proposedAddress,
          newState: artisan.proposedState,
          newLat: artisan.proposedLatitude,
          newLng: artisan.proposedLongitude,
        );
        _pendingArtisans.removeWhere(
          (p) =>
              p.email.toLowerCase() == artisan.email.toLowerCase() &&
              p.isRelocationRequest,
        );
        final userIdx = _registeredUsers.indexWhere(
          (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
        );
        if (userIdx != -1) {
          final u = _registeredUsers[userIdx];
          _registeredUsers[userIdx] = u.copyWith(
            address: artisan.proposedAddress ?? u.address,
            state: artisan.proposedState ?? u.state,
            latitude: artisan.proposedLatitude ?? u.latitude,
            longitude: artisan.proposedLongitude ?? u.longitude,
            clearPendingRelocation: true,
          );
        }
        final aIdx = _activeArtisanMasters.indexWhere(
          (a) => a.email.toLowerCase() == artisan.email.toLowerCase(),
        );
        if (aIdx != -1) {
          final a = _activeArtisanMasters[aIdx];
          _activeArtisanMasters[aIdx] = a.copyWith(
            state: artisan.proposedState ?? a.state,
          );
        }
        await _persistApprovalCount();
        _recordApprovalHistory(
          title: 'Workshop Premise Relocation Approved',
          targetName: artisan.name,
          targetEmail: artisan.email,
          approvalType: 'Premise Relocation',
          craftCategory: artisan.craftCategory,
          state: artisan.proposedState ?? artisan.state,
          details:
              'Relocated from ${artisan.currentAddress ?? artisan.state} to ${artisan.proposedAddress ?? artisan.proposedState}',
          previousPremise: artisan.currentAddress ?? artisan.state,
          newPremise: artisan.proposedAddress ?? artisan.proposedState,
          ssmNumber: artisan.ssmNumber,
        );
        notifyListeners();
        return true;
      }

      // Determine target role
      final userIdx = _registeredUsers.indexWhere(
        (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      final isUpgrade = userIdx != -1 || artisan.isUpgradeFromTourist;
      const targetRole = 'Artisan';

      // Persist first. The repository guarantees that the artisan's usable
      // quest has both canonical system tasks before approval can succeed.
      try {
        await _repository.updateArtisanStatus(
          email: artisan.email,
          newStatus: 'ACTIVE',
          newRole: targetRole,
          ensureSystemTasks: true,
        );
      } catch (error) {
        final isLegacyUpgradeWithoutProfile =
            isUpgrade &&
            error.toString().toLowerCase().contains(
              'artisan profile could not be found',
            );
        if (!isLegacyUpgradeWithoutProfile) rethrow;
        await _repository.updateArtisanStatus(
          email: artisan.email,
          newStatus: 'ACTIVE',
          newRole: targetRole,
        );
      }

      _pendingArtisans.removeAt(idx);
      await _persistApprovalCount();

      if (isUpgrade) {
        if (userIdx != -1) {
          _registeredUsers[userIdx] = _registeredUsers[userIdx].copyWith(
            role: targetRole,
            roles: ['Artisan'],
            status: 'ACTIVE',
            artisanStatus: 'APPROVED',
            studioName: artisan.name,
            craftCategory: artisan.craftCategory,
            ssmNumber: artisan.ssmNumber,
            experience: artisan.experience,
          );
        } else {
          _registeredUsers.add(
            UserModel(
              id: 'u_${DateTime.now().millisecondsSinceEpoch}',
              email: artisan.email,
              displayName: artisan.name,
              role: targetRole,
              roles: const ['Artisan'],
              status: 'ACTIVE',
              artisanStatus: 'APPROVED',
              studioName: artisan.name,
              craftCategory: artisan.craftCategory,
              ssmNumber: artisan.ssmNumber,
              state: artisan.state,
              experience: artisan.experience,
            ),
          );
        }
      } else {
        // Purely new Artisan
        _registeredUsers.add(
          UserModel(
            id: 'u_${DateTime.now().millisecondsSinceEpoch}',
            email: artisan.email,
            displayName: artisan.name,
            role: 'Artisan',
            roles: const ['Artisan'],
            status: 'ACTIVE',
            artisanStatus: 'APPROVED',
            studioName: artisan.name,
            craftCategory: artisan.craftCategory,
            ssmNumber: artisan.ssmNumber,
            state: artisan.state,
            experience: artisan.experience,
          ),
        );
      }

      // Insert into Active Verified Masters
      _activeArtisanMasters.removeWhere(
        (a) => a.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      _activeArtisanMasters.insert(
        0,
        ActiveArtisanMaster(
          id: artisan.id,
          name: artisan.name,
          email: artisan.email,
          category: artisan.craftCategory,
          state: artisan.state,
          experience: artisan.experience,
          plaques: 1,
          isLiveOpen: true,
          licenseNo: artisan.ssmNumber ?? '202601004821 (SSM Verified)',
          verifiedDate: 'Just Approved',
          imageUrl: artisan.imageUrl,
          bio:
              artisan.bio ??
              'Verified heritage master preserving traditional ${artisan.craftCategory}.',
          phone: artisan.phone,
          isDualRole: false,
          isSuspended: false,
        ),
      );

      _recordApprovalHistory(
        title: isUpgrade
            ? 'Tourist Upgraded to Master Artisan'
            : 'Master Artisan Profile Approved',
        targetName: artisan.name,
        targetEmail: artisan.email,
        approvalType: 'Artisan Profile',
        craftCategory: artisan.craftCategory,
        state: artisan.state,
        details:
            'Approved with SSM license ${artisan.ssmNumber ?? 'Verified'} • Experience: ${artisan.experience}',
        ssmNumber: artisan.ssmNumber,
        previousPremise: isUpgrade ? 'Tourist Account' : null,
        newPremise: '${artisan.name} Studio (${artisan.state})',
      );

      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _sessionApprovedToday = previousApprovalCount;
      if (_reviewDurations.length > previousReviewDurationCount) {
        _reviewDurations.removeRange(
          previousReviewDurationCount,
          _reviewDurations.length,
        );
      }
      await _persistApprovalCount();
      debugPrint('Artisan approval failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanApprovalError = _friendlyApprovalError(error);
      return false;
    } finally {
      _approvingArtisanId = null;
      notifyListeners();
    }
  }

  String _friendlyApprovalError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '')
        .trim();
    return message.isEmpty
        ? 'The artisan could not be approved. Please try again.'
        : message;
  }

  void toggleActiveArtisanLiveStatus(String id) {
    final idx = _activeArtisanMasters.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final current = _activeArtisanMasters[idx];
      _activeArtisanMasters[idx] = current.copyWith(
        isLiveOpen: !current.isLiveOpen,
      );
      notifyListeners();
    }
  }

  Future<void> suspendActiveArtisan(String id) async {
    final idx = _activeArtisanMasters.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final artisan = _activeArtisanMasters[idx];
      _activeArtisanMasters[idx] = artisan.copyWith(
        isSuspended: true,
        isLiveOpen: false,
      );

      // Suspend only the Artisan Studio Profile in DB; user account remains ACTIVE as Tourist
      await _repository.updateArtisanStatus(
        email: artisan.email,
        newStatus: 'SUSPENDED',
        newRole: 'Tourist',
        updateArtisanProfileOnly: true,
      );

      final uIdx = _registeredUsers.indexWhere(
        (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      if (uIdx != -1) {
        _registeredUsers[uIdx] = _registeredUsers[uIdx].copyWith(
          role: 'Tourist',
          roles: const ['Tourist'],
          artisanStatus: 'SUSPENDED',
        );
      }

      notifyListeners();
    }
  }

  Future<void> reactivateActiveArtisan(String id) async {
    final idx = _activeArtisanMasters.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final artisan = _activeArtisanMasters[idx];
      _activeArtisanMasters[idx] = artisan.copyWith(
        isSuspended: false,
        isLiveOpen: true,
      );

      await _repository.updateArtisanStatus(
        email: artisan.email,
        newStatus: 'APPROVED',
        newRole: 'Artisan',
        updateArtisanProfileOnly: true,
      );

      final uIdx = _registeredUsers.indexWhere(
        (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      if (uIdx != -1) {
        _registeredUsers[uIdx] = _registeredUsers[uIdx].copyWith(
          role: 'Artisan',
          roles: const ['Artisan'],
          artisanStatus: 'APPROVED',
        );
      }

      notifyListeners();
    }
  }

  Future<void> rejectArtisan(String id, {String? reason}) async {
    int idx = _pendingArtisans.indexWhere((item) => item.id == id);
    if (idx == -1) {
      idx = _pendingArtisans.indexWhere(
        (item) => item.email.toLowerCase() == id.toLowerCase(),
      );
    }

    if (idx != -1) {
      final artisan = _pendingArtisans[idx];
      _pendingArtisans.removeWhere(
        (p) =>
            p.id == id || p.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      final submittedDate = _parseSubmissionDate(artisan.dateSubmitted);
      if (submittedDate != null) {
        final diff = DateTime.now().difference(submittedDate);
        _reviewDurations.add(
          diff.isNegative ? const Duration(minutes: 30) : diff,
        );
      }

      if (artisan.isRelocationRequest) {
        await _repository.rejectRelocationRequest(email: artisan.email);
        _pendingArtisans.removeWhere(
          (p) =>
              p.email.toLowerCase() == artisan.email.toLowerCase() &&
              p.isRelocationRequest,
        );
        final userIdx = _registeredUsers.indexWhere(
          (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
        );
        if (userIdx != -1) {
          _registeredUsers[userIdx] = _registeredUsers[userIdx].copyWith(
            clearPendingRelocation: true,
          );
        }
        notifyListeners();
        return;
      }

      final userIdx = _registeredUsers.indexWhere(
        (u) => u.email.toLowerCase() == artisan.email.toLowerCase(),
      );
      final isExistingTourist = userIdx != -1 || artisan.isUpgradeFromTourist;

      if (userIdx != -1) {
        final existingUser = _registeredUsers[userIdx];
        if (isExistingTourist) {
          _registeredUsers[userIdx] = existingUser.copyWith(
            role: 'Tourist',
            roles: const ['Tourist'],
            status: 'ACTIVE',
            artisanStatus: 'REJECTED',
            rejectionReason: reason,
            studioName: artisan.name.isNotEmpty
                ? artisan.name
                : existingUser.studioName,
            craftCategory: artisan.craftCategory.isNotEmpty
                ? artisan.craftCategory
                : existingUser.craftCategory,
            ssmNumber:
                artisan.ssmNumber != null && artisan.ssmNumber!.isNotEmpty
                ? artisan.ssmNumber
                : existingUser.ssmNumber,
          );
        } else {
          _registeredUsers[userIdx] = existingUser.copyWith(
            status: 'REJECTED',
            artisanStatus: 'REJECTED',
            rejectionReason: reason,
            studioName: artisan.name.isNotEmpty
                ? artisan.name
                : existingUser.studioName,
            craftCategory: artisan.craftCategory.isNotEmpty
                ? artisan.craftCategory
                : existingUser.craftCategory,
            ssmNumber:
                artisan.ssmNumber != null && artisan.ssmNumber!.isNotEmpty
                ? artisan.ssmNumber
                : existingUser.ssmNumber,
          );
        }
      }

      await _repository.updateArtisanStatus(
        email: artisan.email,
        newStatus: 'REJECTED',
        newRole: isExistingTourist ? 'Tourist' : 'Artisan',
        updateArtisanProfileOnly: isExistingTourist,
        rejectionReason: reason,
      );

      _pendingArtisans.removeWhere(
        (p) =>
            p.id == id || p.email.toLowerCase() == artisan.email.toLowerCase(),
      );

      notifyListeners();
    } else {
      final userIdx = _registeredUsers.indexWhere(
        (u) => u.id == id || u.email.toLowerCase() == id.toLowerCase(),
      );
      if (userIdx != -1) {
        final existingUser = _registeredUsers[userIdx];
        final isTourist = existingUser.role.toLowerCase().contains('tourist');
        _registeredUsers[userIdx] = existingUser.copyWith(
          role: isTourist ? 'Tourist' : existingUser.role,
          roles: isTourist ? const ['Tourist'] : existingUser.roles,
          status: isTourist ? 'ACTIVE' : 'REJECTED',
          artisanStatus: 'REJECTED',
          rejectionReason: reason,
        );
        await _repository.updateArtisanStatus(
          email: existingUser.email,
          newStatus: 'REJECTED',
          newRole: isTourist ? 'Tourist' : 'Artisan',
          updateArtisanProfileOnly: isTourist,
          rejectionReason: reason,
        );
        _pendingArtisans.removeWhere(
          (p) =>
              p.id == id ||
              p.email.toLowerCase() == existingUser.email.toLowerCase(),
        );
        notifyListeners();
      }
    }
  }

  Future<void> suspendUser(String id, {String? reason}) async {
    final idx = _registeredUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      final user = _registeredUsers[idx];
      if (user.isAdmin ||
          user.role.toLowerCase().contains('admin') ||
          user.email.toLowerCase() == 'admin@warisankita.my' ||
          user.username?.toLowerCase() == 'admin') {
        debugPrint('Cannot suspend an Administrator account.');
        return;
      }
      final trimmedReason = (reason != null && reason.trim().isNotEmpty)
          ? reason.trim()
          : null;
      _registeredUsers[idx] = user.copyWith(
        isSuspended: true,
        status: 'SUSPENDED',
        suspensionReason: trimmedReason,
      );

      final artisanIdx = _activeArtisanMasters.indexWhere(
        (a) => a.id == id || a.email.toLowerCase() == user.email.toLowerCase(),
      );
      if (artisanIdx != -1) {
        final artisan = _activeArtisanMasters[artisanIdx];
        _activeArtisanMasters[artisanIdx] = artisan.copyWith(
          isSuspended: true,
          isLiveOpen: false,
        );
      }

      await _repository.updateArtisanStatus(
        email: user.email,
        newStatus: 'SUSPENDED',
        newRole: user.role,
        suspensionReason: trimmedReason,
      );

      notifyListeners();
    }
  }

  Future<void> reactivateUser(String id) async {
    final idx = _registeredUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      final user = _registeredUsers[idx];
      _registeredUsers[idx] = user.copyWith(
        isSuspended: false,
        status: 'ACTIVE',
        clearSuspensionReason: true,
      );

      final artisanIdx = _activeArtisanMasters.indexWhere(
        (a) => a.id == id || a.email.toLowerCase() == user.email.toLowerCase(),
      );
      if (artisanIdx != -1) {
        final artisan = _activeArtisanMasters[artisanIdx];
        _activeArtisanMasters[artisanIdx] = artisan.copyWith(
          isSuspended: false,
          isLiveOpen: true,
        );
      }

      await _repository.updateArtisanStatus(
        email: user.email,
        newStatus: 'ACTIVE',
        newRole: user.role,
        suspensionReason: null,
      );

      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
    }
  }
}
