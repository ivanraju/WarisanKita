import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';

class ModerationViewModel extends ChangeNotifier {
  final UserRepository _repository;

  ModerationViewModel({UserRepository? repository, SupabaseService? service})
      : _repository = repository ?? UserRepository(service: service) {
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

  final List<PendingArtisanProfile> _pendingArtisans = [
    const PendingArtisanProfile(
      id: 'p1',
      name: 'Ahmad Razak Ceramic',
      craftCategory: 'Pottery & Ceramics',
      state: 'Melaka',
      dateSubmitted: 'Aug 4, 2026',
      imageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
      email: 'ahmad.razak@example.com',
      experience: '12 Years',
      phone: '+60 12-345 6789',
      ssmNumber: '202601004821 (SSM Verified)',
      ssmFileName: 'SSM_Registration_Cert_Melaka.pdf',
      certFileName: 'Kraftangan_Master_Ceramics_Cert.pdf',
      photos: [
        'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
        'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600',
      ],
      bio: 'Master ceramicist with 12 years preserving traditional Melaka pottery techniques.',
      isUpgradeFromTourist: false,
    ),
    const PendingArtisanProfile(
      id: 'p2',
      name: 'Siti Nurhaliza Batik Studio',
      craftCategory: 'Batik Weaving',
      state: 'Terengganu',
      dateSubmitted: 'Aug 3, 2026',
      imageUrl: 'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
      email: 'siti.batik@example.com',
      experience: '8 Years',
      phone: '+60 19-876 5432',
      ssmNumber: 'KT-TRG-99482',
      ssmFileName: 'SSM_Terengganu_Batik.pdf',
      certFileName: 'Kraftangan_National_Award_Batik.pdf',
      photos: [
        'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600',
        'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600',
      ],
      bio: 'Award-winning hand-drawn batik block printing master from Kuala Terengganu.',
      isUpgradeFromTourist: false,
    ),
    const PendingArtisanProfile(
      id: 'p3',
      name: 'Master Wong Woodcraft',
      craftCategory: 'Wood Carving',
      state: 'Perak',
      dateSubmitted: 'Aug 2, 2026',
      imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
      email: 'wong.wood@example.com',
      experience: '25 Years',
      phone: '+60 17-234 5678',
      ssmNumber: 'PRK-WOOD-8831',
      ssmFileName: 'SSM_Woodcarving_Perak.pdf',
      certFileName: 'Kraftangan_Master_Woodcarver.pdf',
      photos: [
        'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600',
      ],
      bio: 'Heritage Malay-Nyonya floral and relief architectural woodcarver with 25 years of mastery.',
      isUpgradeFromTourist: false,
    ),
    const PendingArtisanProfile(
      id: 'p4',
      name: 'Che Minah Heritage Songket',
      craftCategory: 'Songket Weaving',
      state: 'Kelantan',
      dateSubmitted: 'Aug 1, 2026',
      imageUrl: 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600&auto=format&fit=crop&q=80',
      email: 'minah.songket@example.com',
      experience: '15 Years',
      phone: '+60 13-456 7890',
      ssmNumber: 'KT-KEL-19948',
      ssmFileName: 'SSM_Songket_Kelantan.pdf',
      certFileName: 'Kraftangan_Gold_Songket_Certificate.pdf',
      photos: [
        'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600',
      ],
      bio: 'Traditional Kelantanese gold-thread songket weaver keeping Royal Court patterns alive.',
      isUpgradeFromTourist: false,
    ),
    const PendingArtisanProfile(
      id: 'p5',
      name: 'Aiman Haziq Woodcraft Studio',
      craftCategory: 'Wood Carving',
      state: 'Terengganu',
      dateSubmitted: 'Aug 16, 2026',
      imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
      email: 'tourist@warisankita.my',
      experience: '5 Years',
      phone: '+60 11-2345 6789',
      ssmNumber: '202601004821 (SSM Verified)',
      ssmFileName: 'SSM_Registration_Cert_2026.pdf',
      certFileName: 'Kraftangan_Master_Certificate.pdf',
      photos: [
        'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600',
      ],
      bio: 'Existing Cultural Explorer applying for studio registration in ukiran kayu warisan.',
      isUpgradeFromTourist: true,
    ),
  ];

  // Active Verified Master Artisans State
  final List<ActiveArtisanMaster> _activeArtisanMasters = [
    const ActiveArtisanMaster(
      id: 'a1',
      name: 'Pak Mat Pottery Studio',
      email: 'pakmat.clay@example.com',
      category: 'Pottery & Ceramics',
      state: 'Melaka',
      experience: '25+ Years',
      plaques: 28,
      isLiveOpen: true,
      licenseNo: 'KFG-2024-889',
      verifiedDate: 'Jan 10, 2024',
      imageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
      bio: 'Renowned ceramic master specializing in traditional Melaka clay vessels and porcelain glazes.',
      phone: '+60 12-345 6789',
      isDualRole: false,
      isSuspended: false,
    ),
    const ActiveArtisanMaster(
      id: 'a2',
      name: 'Tok Guru Crafts',
      email: 'tokguru.wood@example.com',
      category: 'Wood Carving',
      state: 'Kelantan',
      experience: '30+ Years',
      plaques: 42,
      isLiveOpen: false,
      licenseNo: 'KFG-2023-112',
      verifiedDate: 'Mar 15, 2023',
      imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
      bio: 'National heritage wood carver preserving Kelantanese architectural wood reliefs.',
      phone: '+60 19-876 5432',
      isDualRole: false,
      isSuspended: false,
    ),
    const ActiveArtisanMaster(
      id: 'a3',
      name: 'Kak Lina Silk Batik',
      email: 'kaklina.silk@example.com',
      category: 'Batik Weaving',
      state: 'Terengganu',
      experience: '18 Years',
      plaques: 19,
      isLiveOpen: true,
      licenseNo: 'KFG-2024-405',
      verifiedDate: 'Feb 20, 2024',
      imageUrl: 'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
      bio: 'East Coast silk batik artisan creating hand-painted floral canting masterpieces.',
      phone: '+60 17-234 5678',
      isDualRole: true,
      isSuspended: false,
    ),
    const ActiveArtisanMaster(
      id: 'a4',
      name: 'Sayong Black Clay Master',
      email: 'sayong.black@example.com',
      category: 'Pottery & Ceramics',
      state: 'Perak',
      experience: '22 Years',
      plaques: 35,
      isLiveOpen: true,
      licenseNo: 'KFG-2023-774',
      verifiedDate: 'Nov 12, 2023',
      imageUrl: 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600&auto=format&fit=crop&q=80',
      bio: 'Kuala Kangsar master of authentic Labu Sayong pit-firing and natural black finishes.',
      phone: '+60 13-987 6543',
      isDualRole: false,
      isSuspended: false,
    ),
    const ActiveArtisanMaster(
      id: 'a5',
      name: 'Mah Meri Heritage Woodcraft',
      email: 'mahmeri.wood@example.com',
      category: 'Wood Carving',
      state: 'Selangor',
      experience: '20 Years',
      plaques: 24,
      isLiveOpen: true,
      licenseNo: 'KFG-2024-512',
      verifiedDate: 'May 05, 2024',
      imageUrl: 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=600&auto=format&fit=crop&q=80',
      bio: 'Indigenous Mah Meri master carver preserving spiritual masks and Nyireh Batu timber figurines.',
      phone: '+60 11-3456 7890',
      isDualRole: false,
      isSuspended: false,
    ),
  ];

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
  final List<UserModel> _registeredUsers = [
    const UserModel(
      id: 'u1',
      email: 'aiman.haziq@example.com',
      displayName: 'Aiman Haziq',
      role: 'Tourist',
      joinedDate: 'Jan 15, 2026',
      isSuspended: false,
    ),
    const UserModel(
      id: 'u2',
      email: 'pakmat.clay@example.com',
      displayName: 'Pak Mat Ceramic Studio',
      role: 'Artisan',
      joinedDate: 'Feb 02, 2026',
      isSuspended: false,
    ),
    const UserModel(
      id: 'u3',
      email: 'mei.ling@example.com',
      displayName: 'Tan Mei Ling',
      role: 'Tourist',
      joinedDate: 'Mar 20, 2026',
      isSuspended: true,
    ),
    const UserModel(
      id: 'u4',
      email: 'kaklina.silk@example.com',
      displayName: 'Kak Lina Silk Batik',
      role: 'Artisan',
      joinedDate: 'Apr 10, 2026',
      isSuspended: false,
    ),
  ];

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

  List<UserModel> get registeredUsers => _registeredUsers;

  List<UserModel> get filteredUsers {
    return _registeredUsers.where((user) {
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

      for (final raw in dbPending) {
        final email = (raw['email'] ?? '').toString();
        if (email.isEmpty) continue;

        final id = raw['id']?.toString() ?? 'p_${email.hashCode}';
        final name = (raw['studio_name'] ?? raw['studioName'] ?? raw['full_name'] ?? raw['displayName'] ?? raw['username'] ?? 'Artisan Studio').toString();
        final craft = (raw['craft_category'] ?? raw['craftCategory'] ?? 'Handicraft & Heritage').toString();
        final state = (raw['state'] ?? 'Malaysia').toString();
        final role = (raw['role'] ?? '').toString();
        final isUpgrade = role.contains('Tourist') || role.contains('Both');

        final existingIdx = _pendingArtisans.indexWhere((p) => p.email.toLowerCase() == email.toLowerCase());
        
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
          dateSubmitted: 'Today',
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

        if (existingIdx == -1) {
          _pendingArtisans.insert(0, newProfile);
        } else {
          _pendingArtisans[existingIdx] = newProfile;
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
      if (dbArtisans.isNotEmpty) {
        for (final art in dbArtisans) {
          final idx = _activeArtisanMasters.indexWhere(
            (a) => a.email.toLowerCase() == art.email.toLowerCase() ||
                   a.id == art.id ||
                   a.name.toLowerCase() == art.name.toLowerCase(),
          );
          if (idx == -1) {
            _activeArtisanMasters.insert(0, art);
          } else {
            _activeArtisanMasters[idx] = art;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching active artisans: $e');
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final dbUsers = await _repository.getAllUsers();
      if (dbUsers.isNotEmpty) {
        for (final u in dbUsers) {
          final idx = _registeredUsers.indexWhere(
            (existing) => existing.email.toLowerCase() == u.email.toLowerCase() ||
                          existing.id == u.id,
          );
          if (idx == -1) {
            _registeredUsers.insert(0, u);
          } else {
            _registeredUsers[idx] = u;
          }
        }
        notifyListeners();
      }
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

  Future<void> approveArtisan(String id) async {
    final idx = _pendingArtisans.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final artisan = _pendingArtisans[idx];
      _pendingArtisans.removeAt(idx);

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
      if (user.role.toLowerCase().contains('admin') || user.isAdmin) {
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
