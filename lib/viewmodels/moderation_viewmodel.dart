import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';

class ModerationViewModel extends ChangeNotifier {
  final UserRepository _repository;

  ModerationViewModel({UserRepository? repository, SupabaseService? service})
      : _repository = repository ?? UserRepository(service: service) {
    _loadTodayStats();
    refreshAllData();
  }

  String _activeTab = 'Pending Approvals';
  String get activeTab => _activeTab;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

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

  // Active Verified Master Artisans State
  final List<ActiveArtisanMaster> _activeArtisanMasters = [];

  List<ActiveArtisanMaster> get activeArtisanMasters => _activeArtisanMasters;

  List<ActiveArtisanMaster> get filteredActiveArtisans {
    return _activeArtisanMasters.where((artisan) {
      final matchesSearch = _searchQuery.isEmpty ||
          artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.licenseNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All Categories' ||
          artisan.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
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
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final targetName = studioName ?? displayName ?? username;

    final userIdx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == cleanEmail);
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
      );
    }

    final artisanIdx = _activeArtisanMasters.indexWhere((a) => a.email.toLowerCase() == cleanEmail);
    if (artisanIdx != -1) {
      final artisan = _activeArtisanMasters[artisanIdx];
      _activeArtisanMasters[artisanIdx] = artisan.copyWith(
        name: targetName ?? artisan.name,
        category: craftCategory ?? artisan.category,
        state: state ?? artisan.state,
        phone: phone ?? artisan.phone,
        bio: bio ?? artisan.bio,
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
      .where((u) =>
          u.status.toUpperCase() != 'DELETED' &&
          !u.email.toLowerCase().startsWith('deleted_'))
      .toList();

  List<UserModel> get filteredUsers {
    return _registeredUsers.where((user) {
      if (user.status.toUpperCase() == 'DELETED' ||
          user.email.toLowerCase().startsWith('deleted_')) {
        return false;
      }

      final matchesSearch = _userSearchQuery.isEmpty ||
          (user.displayName ?? '').toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          (user.username ?? '').toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());

      final r = user.role.toLowerCase();
      final matchesRole = _userRoleFilter == 'All Roles' ||
          ((_userRoleFilter == 'Tourist' || _userRoleFilter == 'Cultural Tourist') && (r.contains('tourist') || user.isTourist)) ||
          ((_userRoleFilter == 'Artisan' || _userRoleFilter == 'Master Artisan') && (r.contains('artisan') || user.isArtisan)) ||
          (_userRoleFilter == 'Admin' && r.contains('admin'));

      final matchesStatus = _userStatusFilter == 'All Statuses' ||
          (_userStatusFilter == 'Active' && !user.isSuspended && user.status.toUpperCase() != 'SUSPENDED') ||
          (_userStatusFilter == 'Suspended' && (user.isSuspended || user.status.toUpperCase() == 'SUSPENDED'));

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  void removeUserByEmailOrId({String? email, String? id}) {
    _registeredUsers.removeWhere((u) =>
        (email != null && u.email.toLowerCase() == email.toLowerCase()) ||
        (id != null && u.id == id));
    _activeArtisanMasters.removeWhere((a) =>
        (email != null && a.email.toLowerCase() == email.toLowerCase()) ||
        (id != null && a.id == id));
    _pendingArtisans.removeWhere((p) =>
        (email != null && p.email.toLowerCase() == email.toLowerCase()) ||
        (id != null && p.id == id));
    notifyListeners();
  }

  List<PendingArtisanProfile> get filteredArtisans {
    return _pendingArtisans.where((artisan) {
      final matchesSearch = _searchQuery.isEmpty ||
          artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.craftCategory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All Categories' ||
          artisan.craftCategory == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<PendingArtisanProfile> get pendingArtisans => List.unmodifiable(_pendingArtisans);
  int get totalPendingCount => _pendingArtisans.length;

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

  Future<void> _recordApproval(DateTime? submittedDate) async {
    _sessionApprovedToday++;
    if (submittedDate != null) {
      final diff = DateTime.now().difference(submittedDate);
      _reviewDurations.add(diff.isNegative ? const Duration(minutes: 30) : diff);
    } else {
      _reviewDurations.add(const Duration(minutes: 45));
    }
    notifyListeners();
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
    if (raw.toLowerCase().contains('today') || raw.toLowerCase().contains('just')) {
      return DateTime.now();
    }
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
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
    final todayIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final activeToday = _activeArtisanMasters.where((a) {
      final vd = a.verifiedDate.toLowerCase();
      return vd.contains(todayIso) || vd.contains('today') || vd.contains('just approved');
    }).length;
    return activeToday > _sessionApprovedToday ? activeToday : _sessionApprovedToday;
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
      final List<Map<String, dynamic>> dbPending = await _repository.getPendingArtisans();

      final List<PendingArtisanProfile> fetched = [];

      for (final raw in dbPending) {
        final email = (raw['email'] ?? '').toString();
        if (email.isEmpty) continue;

        final id = raw['id']?.toString() ?? 'p_${email.hashCode}';
        final name = (raw['studio_name'] ?? raw['studioName'] ?? raw['full_name'] ?? raw['displayName'] ?? raw['username'] ?? 'Artisan Studio').toString();
        final craft = (raw['craft_category'] ?? raw['craftCategory'] ?? 'Handicraft & Heritage').toString();
        final state = (raw['state'] ?? 'Malaysia').toString();
        final role = (raw['role'] ?? '').toString();
        final isUpgrade = role.contains('Tourist') || role.contains('Both');

        // Resolve the avatar/image URL from the DB row
        final resolvedImageUrl = (raw['imageUrl'] ?? raw['avatar_url'] ?? 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600').toString();
        
        // Resolve photos - must be actual URLs, not filenames
        List<String> resolvedPhotos;
        if (raw['photos'] is List && (raw['photos'] as List).isNotEmpty) {
          resolvedPhotos = List<String>.from(raw['photos']);
        } else {
          // Fallback: use the user's avatar as a portfolio image if available
          resolvedPhotos = [resolvedImageUrl];
        }

        final newProfile = PendingArtisanProfile(
          id: id,
          name: name,
          craftCategory: craft,
          state: state,
          dateSubmitted: raw['dateSubmitted']?.toString() ?? raw['created_at']?.toString() ?? 'Today',
          imageUrl: resolvedImageUrl,
          email: email,
          experience: (raw['experience'] ?? 'Verified Studio').toString(),
          phone: (raw['phone'] ?? raw['phone_number'] ?? '+60 12-345 6789').toString(),
          ssmNumber: (raw['ssm_number'] ?? raw['ssmNumber'] ?? '202601004821 (SSM Verified)').toString(),
          ssmFileName: (raw['ssm_file'] ?? raw['ssm_file_name'] ?? raw['ssmFileName'] ?? 'SSM_Registration_Cert.pdf').toString(),
          ssmFileUrl: raw['ssm_file_url']?.toString() ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          certFileName: (raw['cert_file'] ?? raw['cert_file_name'] ?? raw['certFileName'] ?? 'Kraftangan_Master_Cert.pdf').toString(),
          certFileUrl: raw['cert_file_url']?.toString() ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          photos: resolvedPhotos,
          bio: raw['bio']?.toString(),
          isUpgradeFromTourist: isUpgrade,
        );

        fetched.add(newProfile);
      }

      // Preserve any pending relocation requests added in this session
      final localRelocations = _pendingArtisans.where((p) => p.isRelocationRequest).toList();
      _pendingArtisans.clear();
      _pendingArtisans.addAll(fetched);
      for (final rel in localRelocations) {
        if (!_pendingArtisans.any((p) => p.email.toLowerCase() == rel.email.toLowerCase() && p.isRelocationRequest)) {
          _pendingArtisans.insert(0, rel);
        }
      }
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
  }

  void addPendingArtisan(PendingArtisanProfile profile) {
    _pendingArtisans.removeWhere((p) => p.email.toLowerCase() == profile.email.toLowerCase());
    _pendingArtisans.insert(0, profile);
    notifyListeners();
  }

  void addRelocationRequest(PendingArtisanProfile profile) {
    _pendingArtisans.removeWhere((p) => p.email.toLowerCase() == profile.email.toLowerCase() && p.isRelocationRequest);
    _pendingArtisans.insert(0, profile);
    notifyListeners();
  }

  Future<void> approveArtisan(String id) async {
    final idx = _pendingArtisans.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final artisan = _pendingArtisans[idx];
      _pendingArtisans.removeAt(idx);
      final submittedDate = _parseSubmissionDate(artisan.dateSubmitted);
      _recordApproval(submittedDate);

      if (artisan.isRelocationRequest) {
        await _repository.approveRelocationRequest(email: artisan.email);
        final userIdx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == artisan.email.toLowerCase());
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
        final aIdx = _activeArtisanMasters.indexWhere((a) => a.email.toLowerCase() == artisan.email.toLowerCase());
        if (aIdx != -1) {
          final a = _activeArtisanMasters[aIdx];
          _activeArtisanMasters[aIdx] = a.copyWith(
            state: artisan.proposedState ?? a.state,
          );
        }
        notifyListeners();
        return;
      }

      // Determine target role
      final userIdx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == artisan.email.toLowerCase());
      final isUpgrade = userIdx != -1 || artisan.isUpgradeFromTourist;
      const targetRole = 'Artisan';

      if (isUpgrade) {
        if (userIdx != -1) {
          _registeredUsers[userIdx] = _registeredUsers[userIdx].copyWith(
            role: targetRole,
            roles: ['Artisan'],
            status: 'ACTIVE',
            studioName: artisan.name,
            craftCategory: artisan.craftCategory,
            ssmNumber: artisan.ssmNumber,
          );
        } else {
          _registeredUsers.add(UserModel(
            id: 'u_${DateTime.now().millisecondsSinceEpoch}',
            email: artisan.email,
            displayName: artisan.name,
            role: targetRole,
            roles: const ['Artisan'],
            status: 'ACTIVE',
            studioName: artisan.name,
            craftCategory: artisan.craftCategory,
            ssmNumber: artisan.ssmNumber,
            state: artisan.state,
          ));
        }
      } else {
        // Purely new Artisan
        _registeredUsers.add(UserModel(
          id: 'u_${DateTime.now().millisecondsSinceEpoch}',
          email: artisan.email,
          displayName: artisan.name,
          role: 'Artisan',
          roles: const ['Artisan'],
          status: 'ACTIVE',
          studioName: artisan.name,
          craftCategory: artisan.craftCategory,
          ssmNumber: artisan.ssmNumber,
          state: artisan.state,
        ));
      }

      // Insert into Active Verified Masters
      _activeArtisanMasters.removeWhere((a) => a.email.toLowerCase() == artisan.email.toLowerCase());
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
          bio: artisan.bio ?? 'Verified heritage master preserving traditional ${artisan.craftCategory}.',
          phone: artisan.phone,
          isDualRole: isUpgrade,
          isSuspended: false,
        ),
      );

      // Persist to DB
      await _repository.updateArtisanStatus(
        email: artisan.email,
        newStatus: 'ACTIVE',
        newRole: targetRole,
      );

      notifyListeners();
    }
  }

  void toggleActiveArtisanLiveStatus(String id) {
    final idx = _activeArtisanMasters.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final current = _activeArtisanMasters[idx];
      _activeArtisanMasters[idx] = current.copyWith(isLiveOpen: !current.isLiveOpen);
      notifyListeners();
    }
  }

  Future<void> suspendActiveArtisan(String id) async {
    final idx = _activeArtisanMasters.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final artisan = _activeArtisanMasters[idx];
      _activeArtisanMasters[idx] = artisan.copyWith(isSuspended: true, isLiveOpen: false);

      // Suspend only the Artisan Studio Profile in DB; user account remains ACTIVE as Tourist
      await _repository.updateArtisanStatus(
        email: artisan.email,
        newStatus: 'SUSPENDED',
        newRole: 'Artisan & Tourist',
        updateArtisanProfileOnly: true,
      );

      final uIdx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == artisan.email.toLowerCase());
      if (uIdx != -1) {
        _registeredUsers[uIdx] = _registeredUsers[uIdx].copyWith(
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
      _activeArtisanMasters[idx] = artisan.copyWith(isSuspended: false, isLiveOpen: true);

      await _repository.updateArtisanStatus(
        email: artisan.email,
        newStatus: 'APPROVED',
        newRole: 'Artisan & Tourist',
        updateArtisanProfileOnly: true,
      );

      final uIdx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == artisan.email.toLowerCase());
      if (uIdx != -1) {
        _registeredUsers[uIdx] = _registeredUsers[uIdx].copyWith(
          artisanStatus: 'APPROVED',
        );
      }

      notifyListeners();
    }
  }

  Future<void> rejectArtisan(String id, {String? reason}) async {
    final idx = _pendingArtisans.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final artisan = _pendingArtisans[idx];
      _pendingArtisans.removeAt(idx);
      final submittedDate = _parseSubmissionDate(artisan.dateSubmitted);
      if (submittedDate != null) {
        final diff = DateTime.now().difference(submittedDate);
        _reviewDurations.add(diff.isNegative ? const Duration(minutes: 30) : diff);
      }

      if (artisan.isRelocationRequest) {
        await _repository.rejectRelocationRequest(email: artisan.email);
        final userIdx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == artisan.email.toLowerCase());
        if (userIdx != -1) {
          _registeredUsers[userIdx] = _registeredUsers[userIdx].copyWith(
            clearPendingRelocation: true,
          );
        }
        notifyListeners();
        return;
      }

      final userIdx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == artisan.email.toLowerCase());
      if (userIdx != -1) {
        _registeredUsers[userIdx] = _registeredUsers[userIdx].copyWith(
          status: 'REJECTED',
        );
      }

      await _repository.updateArtisanStatus(
        email: artisan.email,
        newStatus: 'REJECTED',
        newRole: 'Artisan',
      );

      notifyListeners();
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
      final trimmedReason = (reason != null && reason.trim().isNotEmpty) ? reason.trim() : null;
      _registeredUsers[idx] = user.copyWith(
        isSuspended: true,
        status: 'SUSPENDED',
        suspensionReason: trimmedReason,
      );

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
