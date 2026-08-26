import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/domain/models/user.dart';

class SupabaseService {
  // Session Persistence Keys
  static const String _keyAuthUser = 'wk_last_auth_user';
  static const String _keyAuthEmail = 'wk_last_auth_email';
  static const String _keyActiveRole = 'wk_last_active_role';

  static Future<void> _saveAuthSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthEmail, user.email);
      await prefs.setString(_keyAuthUser, jsonEncode(user.toMap()));
      await prefs.setString(_keyActiveRole, user.role);
    } catch (e) {
      debugPrint('saveAuthSession note: $e');
    }
  }

  static Future<void> _clearAuthSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuthEmail);
      await prefs.remove(_keyAuthUser);
      await prefs.remove(_keyActiveRole);
    } catch (e) {
      debugPrint('clearAuthSession note: $e');
    }
  }

  // Generates standard UUID v4 for PostgreSQL uuid column compatibility
  static String _generateUuidV4() {
    final random = Random();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // UUID version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 10xx
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // CRITICAL: Safe getter for the client.
  // Returns the SupabaseClient if Supabase is initialized, otherwise null for offline/testing.
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory Database Store for verified offline/prototype and test accounts
  static final Map<String, Map<String, dynamic>> _userStore = {
    'tourist@warisankita.my': {
      'id': 'usr-tourist-001',
      'email': 'tourist@warisankita.my',
      'username': 'Aiman Haziq',
      'displayName': 'Aiman Haziq',
      'password': 'password123',
      'role': 'Tourist',
      'roles': ['Tourist'],
      'status': 'ACTIVE',
      'joinedDate': 'Jan 2026',
      'isSuspended': false,
    },
    'user@warisankita.my': {
      'id': 'usr-tourist-002',
      'email': 'user@warisankita.my',
      'username': 'Siti Explorer',
      'displayName': 'Siti Explorer',
      'password': 'password123',
      'role': 'Tourist',
      'roles': ['Tourist'],
      'status': 'ACTIVE',
      'joinedDate': 'Jan 2026',
      'isSuspended': false,
    },
    'artisan@warisankita.my': {
      'id': 'usr-artisan-001',
      'email': 'artisan@warisankita.my',
      'username': 'Pak Mat',
      'displayName': 'Master Pak Mat',
      'password': 'password123',
      'role': 'Artisan',
      'roles': ['Artisan'],
      'status': 'APPROVED',
      'studioName': 'Pak Mat Pottery Studio',
      'craftCategory': 'Pottery & Ceramics',
      'ssmNumber': 'SSM-TRG-2024-0981',
      'bio': 'Master Pak Mat has been hand-crafting traditional clay labu sayong and ceramic vessels for over 25 years in Kampung Morten.',
      'joinedDate': 'Nov 2025',
      'isSuspended': false,
    },
    'pending.artisan@warisankita.my': {
      'id': 'usr-artisan-pending-002',
      'email': 'pending.artisan@warisankita.my',
      'username': 'Tok Wan Songket',
      'displayName': 'Tok Wan Songket',
      'password': 'password123',
      'role': 'Artisan',
      'roles': ['Artisan'],
      'status': 'PENDING_APPROVAL',
      'studioName': 'KELANTAN SONGKET ATELIER',
      'craftCategory': 'Songket & Weaving',
      'ssmNumber': 'SSM-KLT-2026-1102',
      'bio': 'Master weaver applying for verification.',
      'joinedDate': 'Feb 2026',
      'isSuspended': false,
    },
    'suspended@warisankita.my': {
      'id': 'usr-suspended-001',
      'email': 'suspended@warisankita.my',
      'username': 'Suspended Account',
      'displayName': 'Suspended Account',
      'password': 'password123',
      'role': 'Tourist',
      'roles': ['Tourist'],
      'status': 'SUSPENDED',
      'joinedDate': 'Dec 2025',
      'isSuspended': true,
    },
    'admin@warisankita.my': {
      'id': 'a0000000-0000-0000-0000-000000000001',
      'email': 'admin@warisankita.my',
      'username': 'admin',
      'displayName': 'Super Admin Nadia',
      'password': 'password123',
      'role': 'Admin',
      'roles': ['Admin'],
      'status': 'ACTIVE',
      'joinedDate': 'Jan 2025',
      'isSuspended': false,
    },
    'artisan.sarah@warisankita.my': {
      'id': 'usr-artisan-002',
      'email': 'artisan.sarah@warisankita.my',
      'username': 'Sarah Chen',
      'displayName': 'Sarah Chen (Master Artisan)',
      'password': 'password123',
      'role': 'Artisan',
      'roles': ['Artisan'],
      'status': 'ACTIVE',
      'studioName': 'WARISAN CERAMICS & BATIK',
      'craftCategory': 'Pottery & Ceramics',
      'ssmNumber': 'SSM-PRK-2025-4421',
      'joinedDate': 'Aug 2025',
      'isSuspended': false,
    },
  };

  // Password reset tokens store: token -> {email, expiresAt, isUsed}
  static final Map<String, Map<String, dynamic>> _resetTokens = {};

  // --- Auth Services ---

  Future<bool> isUsernameAvailable(String username, {String? excludeEmail}) async {
    final cleanUsername = username.trim().toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
    if (cleanUsername.isEmpty) return false;

    // 1. Check local in-memory store for unique username/handle
    for (final entry in _userStore.entries) {
      if (excludeEmail != null && entry.key.toLowerCase() == excludeEmail.toLowerCase()) {
        continue;
      }
      final u = entry.value;
      final existingUsername = (u['username'] as String?)?.toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
      if (existingUsername != null && existingUsername.isNotEmpty && existingUsername == cleanUsername) {
        return false;
      }
    }

    // 2. Check Supabase public.users table if connected
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('users')
            .select('id, email')
            .ilike('username', cleanUsername)
            .maybeSingle();

        if (res != null) {
          if (excludeEmail != null &&
              (res['email'] as String?)?.toLowerCase() == excludeEmail.toLowerCase()) {
            return true;
          }
          return false;
        }
      } catch (e) {
        debugPrint('Supabase username uniqueness check note (username column may not exist yet): $e');
      }
    }

    return true;
  }

  Future<ExistingAccountCheck> checkExistingAccount(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return const ExistingAccountCheck(exists: false);
    }

    // 1. Check local prototype/in-memory store
    if (_userStore.containsKey(cleanEmail)) {
      final u = _userStore[cleanEmail]!;
      final role = (u['role'] ?? '').toString();
      final roles = (u['roles'] is List) ? List<String>.from(u['roles']) : <String>[role];
      final studioName = (u['studioName'] ?? u['studio_name']) as String?;
      final ssm = (u['ssmNumber'] ?? u['ssm_number']) as String?;

      final cleanRole = role.trim().toLowerCase();
      final rolesLower = roles.map((r) => r.trim().toLowerCase()).toList();

      final isDual = cleanRole.contains('artisan & tourist') ||
          cleanRole.contains('tourist & artisan') ||
          cleanRole.contains('artisan/tourist') ||
          cleanRole.contains('tourist/artisan') ||
          cleanRole.contains('artisan and tourist') ||
          (rolesLower.any((r) => r.contains('tourist')) && rolesLower.any((r) => r.contains('artisan')));

      final isArtisan = isDual ||
          cleanRole.contains('artisan') ||
          rolesLower.any((r) => r.contains('artisan')) ||
          (studioName != null && studioName.trim().isNotEmpty) ||
          (ssm != null && ssm.trim().isNotEmpty);

      final isTourist = isDual ||
          cleanRole.contains('tourist') ||
          rolesLower.any((r) => r.contains('tourist')) ||
          (!isArtisan);

      debugPrint('🔍 [checkExistingAccount] local found for $cleanEmail: isArtisan=$isArtisan, isTourist=$isTourist, isDual=$isDual, role=$role');

      return ExistingAccountCheck(
        exists: true,
        existingRole: role,
        existingRoles: roles,
        isTourist: isTourist,
        isArtisan: isArtisan,
        isDualRole: isDual,
        displayName: u['displayName'] ?? u['display_name'] ?? u['full_name'],
        username: u['username'],
        studioName: studioName,
        craftCategory: u['craftCategory'] ?? u['craft_category'],
      );
    }

    // 2. Check Supabase DB table & RPC helper
    final client = _client;
    if (client != null) {
      Map<String, dynamic>? res;
      try {
        final rpcRes = await client.rpc('check_account_by_email', params: {'p_email': cleanEmail});
        if (rpcRes is List && rpcRes.isNotEmpty) {
          res = Map<String, dynamic>.from(rpcRes.first);
        }
      } catch (_) {}

      if (res == null) {
        try {
          res = await client.from('users').select('*, artisan_profiles!artisan_profiles_user_id_fkey(*)').ilike('email', cleanEmail).maybeSingle();
        } catch (e) {
          try {
            res = await client.from('users').select('*, artisan_profiles(*)').ilike('email', cleanEmail).maybeSingle();
          } catch (_) {
            try {
              res = await client.from('users').select().ilike('email', cleanEmail).maybeSingle();
            } catch (e2) {
              debugPrint('Supabase checkExistingAccount note: $e2');
            }
          }
        }
      }

      if (res != null) {
        final role = (res['role'] ?? '').toString();
        final rawRoles = res['roles'];
        final roles = (rawRoles is List) ? List<String>.from(rawRoles) : <String>[role];

        Map<String, dynamic>? artisanMap;
        if (res['artisan_profiles'] is Map) {
          artisanMap = Map<String, dynamic>.from(res['artisan_profiles']);
        } else if (res['artisan_profiles'] is List && (res['artisan_profiles'] as List).isNotEmpty) {
          artisanMap = Map<String, dynamic>.from((res['artisan_profiles'] as List).first);
        }

        final studioName = (res['studio_name'] ?? res['studioName'] ?? artisanMap?['studio_name']) as String?;
        final ssm = (res['ssm_number'] ?? res['ssmNumber'] ?? artisanMap?['ssm_number']) as String?;
        final craftCat = (res['craft_category'] ?? res['craftCategory'] ?? artisanMap?['craft_category']) as String?;

        final cleanRole = role.trim().toLowerCase();
        final rolesLower = roles.map((r) => r.trim().toLowerCase()).toList();

        final isDual = cleanRole.contains('artisan & tourist') ||
            cleanRole.contains('tourist & artisan') ||
            cleanRole.contains('artisan/tourist') ||
            cleanRole.contains('tourist/artisan') ||
            cleanRole.contains('artisan and tourist') ||
            (rolesLower.any((r) => r.contains('tourist')) && rolesLower.any((r) => r.contains('artisan')));

        final isArtisan = isDual ||
            cleanRole.contains('artisan') ||
            rolesLower.any((r) => r.contains('artisan')) ||
            (studioName != null && studioName.trim().isNotEmpty) ||
            (ssm != null && ssm.trim().isNotEmpty);

        final isTourist = isDual ||
            cleanRole.contains('tourist') ||
            rolesLower.any((r) => r.contains('tourist')) ||
            (!isArtisan);

        debugPrint('🔍 [checkExistingAccount] DB found for $cleanEmail: isArtisan=$isArtisan, isTourist=$isTourist, isDual=$isDual, role=$role');

        return ExistingAccountCheck(
          exists: true,
          existingRole: role,
          existingRoles: roles,
          isTourist: isTourist,
          isArtisan: isArtisan,
          isDualRole: isDual,
          displayName: res['full_name'] ?? res['display_name'] ?? res['displayName'],
          username: res['username'],
          studioName: studioName,
          craftCategory: craftCat,
        );
      }
    }

    return const ExistingAccountCheck(exists: false);
  }
  
  Future<UserModel> signIn(String emailOrUsername, String password) async {
    final normInput = emailOrUsername.trim().toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
    final rawInput = emailOrUsername.trim().toLowerCase();
    
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 300));

    UserModel? authenticatedUser;

    // Fast-path: Dedicated Administrator Auth (Username 'admin', 'superadmin', 'adminnadia', or 'admin@warisankita.my')
    if (normInput == 'admin' ||
        normInput == 'superadmin' ||
        normInput == 'administrator' ||
        normInput == 'adminnadia' ||
        rawInput == 'admin@warisankita.my') {
      if (password == 'admin123' || password == 'password123' || password == _userStore['admin@warisankita.my']?['password']) {
        final adminData = _userStore['admin@warisankita.my'] ?? {
          'id': 'usr-admin-001',
          'email': 'admin@warisankita.my',
          'username': 'admin',
          'displayName': 'Super Admin Nadia',
          'role': 'Admin',
          'roles': ['Admin'],
          'status': 'ACTIVE',
          'joinedDate': 'Jan 2025',
          'isSuspended': false,
        };
        authenticatedUser = UserModel.fromMap(adminData);
        await _saveAuthSession(authenticatedUser);
        return authenticatedUser;
      } else {
        throw Exception('INVALID CREDENTIALS: Password incorrect.');
      }
    }

    // 1. Resolve email from in-memory store by exact email or current active username only
    String cleanEmail = rawInput;
    bool storeMatch = false;

    for (final entry in _userStore.entries) {
      final storedEmail = entry.key.toLowerCase();
      final u = entry.value;
      final uNameNorm = (u['username'] as String?)?.toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');

      if (storedEmail == rawInput || (uNameNorm != null && uNameNorm.isNotEmpty && uNameNorm == normInput)) {
        cleanEmail = entry.key;
        storeMatch = true;
        break;
      }
    }

    final client = _client;
    if (client != null) {
      // 2. If client connected and input does not contain '@', lookup email from Supabase users table by username only
      if (!rawInput.contains('@')) {
        bool emailFound = false;
        
        try {
          final userRow = await client
              .from('users')
              .select('email')
              .ilike('username', normInput)
              .maybeSingle();
          if (userRow != null && userRow['email'] != null) {
            cleanEmail = (userRow['email'] as String).toLowerCase();
            emailFound = true;
          }
        } catch (e) {
          debugPrint('Supabase username lookup note: $e');
        }

        if (!emailFound && !storeMatch) {
          throw Exception('INVALID CREDENTIALS: User account not found with username "@$emailOrUsername".');
        }
      }
    } else if (!storeMatch && !_userStore.containsKey(rawInput)) {
      throw Exception('INVALID CREDENTIALS: User account not found with identifier "$emailOrUsername".');
    }

    if (client != null) {
      try {
        final authRes = await client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (authRes.user != null) {
          Map<String, dynamic>? profileData;
          try {
            profileData = await client.from('users').select('*, artisan_profiles!artisan_profiles_user_id_fkey(*)').eq('id', authRes.user!.id).maybeSingle();
            profileData ??= await client.from('users').select('*, artisan_profiles!artisan_profiles_user_id_fkey(*)').ilike('email', cleanEmail).maybeSingle();
          } catch (e) {
            try {
              profileData = await client.from('users').select('*, artisan_profiles(*)').eq('id', authRes.user!.id).maybeSingle();
            } catch (_) {
              try {
                profileData = await client.from('users').select().eq('id', authRes.user!.id).maybeSingle();
              } catch (_) {}
            }
            debugPrint('Supabase table select note: $e');
          }

          if (profileData != null) {
            // Keep in-memory store in sync with database row
            _userStore[cleanEmail] = profileData;
            authenticatedUser = UserModel.fromMap(profileData);
            await _saveAuthSession(authenticatedUser);
            return authenticatedUser;
          }

          final meta = authRes.user!.userMetadata ?? {};
          final role = (meta['role'] as String?) ?? 'Tourist';
          final roles = meta['roles'] != null ? List<String>.from(meta['roles']) : [role];
          final status = (meta['status'] as String?) ?? 'ACTIVE';

          if (status == 'SUSPENDED') {
            throw Exception('ACCOUNT SUSPENDED BY ADMINISTRATOR: Contact support.');
          }

          authenticatedUser = UserModel(
            id: authRes.user!.id,
            email: authRes.user!.email ?? cleanEmail,
            username: meta['username'] as String?,
            displayName: (meta['display_name'] ?? meta['full_name'] ?? meta['username']) as String?,
            role: role,
            roles: roles,
            status: status,
            studioName: meta['studio_name'] as String?,
            craftCategory: meta['craft_category'] as String?,
            ssmNumber: meta['ssm_number'] as String?,
            bio: meta['bio'] as String?,
          );
          await _saveAuthSession(authenticatedUser);
          return authenticatedUser;
        }
      } catch (e) {
        final errString = e.toString();
        debugPrint('Supabase online signIn error/note: $errString');
        if (errString.contains('ACCOUNT SUSPENDED')) {
          rethrow;
        }
      }
    }

    // Local / Prototype / Offline Fallback Data Store:
    if (!_userStore.containsKey(cleanEmail)) {
      // UC001 - A2: Authentication failed
      throw Exception('INVALID CREDENTIALS: User not found in system.');
    }

    final userData = _userStore[cleanEmail]!;
    final storedPass = userData['password'];
    final isPasswordValid = storedPass == password ||
        (cleanEmail == 'admin@warisankita.my' && (password == 'admin123' || password == 'password123'));
    if (!isPasswordValid) {
      throw Exception('INVALID CREDENTIALS: Password incorrect.');
    }

    // Check account status
    if (userData['status'] == 'SUSPENDED' || userData['isSuspended'] == true) {
      // UC001 - A3: Account suspended
      throw Exception('ACCOUNT SUSPENDED BY ADMINISTRATOR: Contact support.');
    }

    authenticatedUser = UserModel.fromMap(userData);
    await _saveAuthSession(authenticatedUser);
    return authenticatedUser;
  }

  // --- Session & Current User Retrieval ---
  Future<UserModel?> getCurrentUser() async {
    final client = _client;
    if (client != null) {
      final session = client.auth.currentSession;
      final authUser = client.auth.currentUser;
      if (session != null && authUser != null) {
        final email = authUser.email?.toLowerCase();
        try {
          final profileData = await client
              .from('users')
              .select()
              .eq('id', authUser.id)
              .maybeSingle();
          if (profileData != null) {
            if (email != null) {
              _userStore[email] = profileData;
            }
            final u = UserModel.fromMap(profileData);
            await _saveAuthSession(u);
            return u;
          }
        } catch (e) {
          debugPrint('getCurrentUser DB lookup note: $e');
        }

        final meta = authUser.userMetadata ?? {};
        final role = (meta['role'] as String?) ?? 'Tourist';
        final roles = meta['roles'] != null ? List<String>.from(meta['roles']) : [role];
        final status = (meta['status'] as String?) ?? 'ACTIVE';

        final u = UserModel(
          id: authUser.id,
          email: authUser.email ?? '',
          username: meta['username'] as String?,
          displayName: (meta['display_name'] ?? meta['full_name'] ?? meta['username']) as String?,
          role: role,
          roles: roles,
          status: status,
          studioName: meta['studio_name'] as String?,
          craftCategory: meta['craft_category'] as String?,
          ssmNumber: meta['ssm_number'] as String?,
          bio: meta['bio'] as String?,
        );
        await _saveAuthSession(u);
        return u;
      }
    }

    // Local / Cached Session Fallback from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString(_keyAuthUser);
      if (rawUser != null && rawUser.isNotEmpty) {
        final map = jsonDecode(rawUser) as Map<String, dynamic>;
        final user = UserModel.fromMap(map);
        final email = user.email.toLowerCase();
        if (_userStore.containsKey(email)) {
          final storeData = _userStore[email]!;
          return UserModel.fromMap(storeData);
        }
        return user;
      }
    } catch (e) {
      debugPrint('getCurrentUser prefs fallback note: $e');
    }

    return null;
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String role,
    String? username,
    String? displayName,
    String? studioName,
    String? craftCategory,
    String? ssmNumber,
    String? ssmFileName,
    String? certFileName,
    List<String>? photos,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 600));

    // Account already exists check:
    if (_userStore.containsKey(cleanEmail)) {
      throw Exception('ACCOUNT ALREADY REGISTERED: An account is already registered with email "$email". Please sign in instead.');
    }

    final client = _client;
    if (client != null) {
      try {
        final existingOnline = await client.from('users').select('id').eq('email', cleanEmail).maybeSingle();
        if (existingOnline != null) {
          throw Exception('ACCOUNT ALREADY REGISTERED: An account is already registered with email "$email". Please sign in instead.');
        }
      } catch (e) {
        if (e.toString().contains('ACCOUNT ALREADY REGISTERED')) rethrow;
      }
    }

    final resolvedUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim().replaceAll('@', '')
        : cleanEmail.split('@')[0];

    final resolvedDisplayName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : ((username != null && username.trim().isNotEmpty)
            ? username.trim()
            : cleanEmail.split('@')[0]);

    // Enforce unique username constraint
    final isAvailable = await isUsernameAvailable(resolvedUsername);
    if (!isAvailable) {
      throw Exception('USERNAME ALREADY TAKEN: Please choose a unique username.');
    }

    final isDual = role == 'Artisan & Tourist' ||
        role == 'Tourist & Artisan' ||
        role == 'Artisan and Tourist' ||
        role == 'Dual Role';
    final isArtisan = isDual || role == 'Artisan' || role == 'Master Artisan';

    final bool isAdmin = role.toLowerCase().contains('admin');
    final String finalRole;
    final List<String> finalRoles;
    if (isAdmin) {
      finalRole = 'Admin';
      finalRoles = ['Admin'];
    } else if (isDual) {
      finalRole = 'Artisan & Tourist';
      finalRoles = ['Tourist', 'Artisan'];
    } else if (isArtisan) {
      finalRole = 'Artisan';
      finalRoles = ['Artisan'];
    } else {
      finalRole = 'Tourist';
      finalRoles = ['Tourist'];
    }

    final initialStatus = isArtisan ? 'PENDING_APPROVAL' : 'ACTIVE';

    final newUser = <String, dynamic>{
      'id': _generateUuidV4(),
      'email': cleanEmail,
      'username': resolvedUsername,
      'displayName': resolvedDisplayName,
      'full_name': resolvedDisplayName,
      'password': password,
      'role': finalRole,
      'roles': finalRoles,
      'status': initialStatus,
      'joinedDate': 'Feb 2026',
      'isSuspended': false,
      'studioName': studioName,
      'craftCategory': craftCategory,
      'ssmNumber': ssmNumber,
      'bio': isArtisan ? 'New applicant studio registered on Warisan Kita.' : null,
    };

    if (client != null) {
      try {
        final authRes = await client.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {
            'username': resolvedUsername,
            'display_name': resolvedDisplayName,
            'full_name': resolvedDisplayName,
            'role': finalRole,
            'roles': finalRoles,
            'status': initialStatus,
            'studio_name': studioName,
            'craft_category': craftCategory,
            'ssm_number': ssmNumber,
          },
        );

        if (authRes.user != null) {
          newUser['id'] = authRes.user!.id;
          
          // 1. Insert Core Identity into normalized public.users
          try {
            await client.from('users').upsert({
              'id': authRes.user!.id,
              'email': cleanEmail,
              'username': resolvedUsername,
              'full_name': resolvedDisplayName,
              'role': finalRole,
              'status': initialStatus,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (tableErr) {
            debugPrint('Supabase public.users table insert note: $tableErr');
          }

          // 2. If Artisan, insert professional details into public.artisan_profiles
          if (finalRole.contains('Artisan') || (studioName != null && studioName.trim().isNotEmpty)) {
            try {
              await client.from('artisan_profiles').upsert({
                'user_id': authRes.user!.id,
                'studio_name': studioName ?? resolvedDisplayName,
                'craft_category': craftCategory ?? 'Pottery & Ceramics',
                'ssm_number': ssmNumber,
                'bio': 'Master artisan dedicated to traditional Malaysian craft.',
                'address': 'Malaysia',
                'state': 'Melaka',
                'status': initialStatus,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            } catch (artisanErr) {
              debugPrint('Supabase public.artisan_profiles table insert note: $artisanErr');
            }
          }
        }
      } catch (e) {
        final errString = e.toString();
        debugPrint('Supabase online signUp note: $errString');
        if (errString.contains('user_already_exists') || errString.contains('User already registered') || errString.contains('already registered')) {
          // Attempt cross-role authentication with existing password
          try {
            final loginRes = await client.auth.signInWithPassword(
              email: cleanEmail,
              password: password,
            );

            if (loginRes.user != null) {
              // Retrieve existing user record from public.users table
              final existingRow = await client.from('users').select().ilike('email', cleanEmail).maybeSingle();
              final currentRole = (existingRow != null ? (existingRow['role'] ?? '') : '').toString().toLowerCase();

              final isTargetTourist = role == 'Tourist' || role == 'Cultural Tourist';
              final isTargetArtisan = role == 'Artisan' || role == 'Master Artisan' || role == 'Artisan & Tourist';

              if (currentRole.contains('artisan') && isTargetTourist) {
                // Upgrade Artisan to Dual Role immediately
                await client.from('users').update({
                  'role': 'Artisan & Tourist',
                  'updated_at': DateTime.now().toIso8601String(),
                }).ilike('email', cleanEmail);

                try {
                  await client.auth.updateUser(
                    UserAttributes(
                      data: {
                        'role': 'Artisan & Tourist',
                        'roles': ['Tourist', 'Artisan'],
                      },
                    ),
                  );
                } catch (_) {}

                final upgraded = <String, dynamic>{
                  ...?existingRow,
                  'email': cleanEmail,
                  'role': 'Artisan & Tourist',
                  'roles': ['Tourist', 'Artisan'],
                  'status': 'ACTIVE',
                };
                _userStore[cleanEmail] = upgraded;
                return UserModel.fromMap(upgraded);
              } else if (currentRole.contains('tourist') && isTargetArtisan) {
                // 1. Update users table (role & status only)
                await client.from('users').update({
                  'role': 'Artisan & Tourist',
                  'status': 'PENDING_APPROVAL',
                  'updated_at': DateTime.now().toIso8601String(),
                }).ilike('email', cleanEmail);

                // 2. Upsert artisan_profiles table
                final String? effectiveUid = existingRow?['id']?.toString() ?? loginRes.user?.id;
                if (effectiveUid != null) {
                  try {
                    await client.from('artisan_profiles').upsert({
                      'user_id': effectiveUid,
                      'studio_name': studioName ?? resolvedDisplayName,
                      'craft_category': craftCategory ?? 'Pottery & Ceramics',
                      'ssm_number': ssmNumber,
                      'bio': 'Master artisan dedicated to traditional Malaysian craft.',
                      'address': 'Malaysia',
                      'state': 'Melaka',
                      'status': 'PENDING_APPROVAL',
                      'created_at': DateTime.now().toIso8601String(),
                      'updated_at': DateTime.now().toIso8601String(),
                    });
                  } catch (apErr) {
                    debugPrint('Supabase link artisan_profiles note: $apErr');
                  }
                }

                try {
                  await client.auth.updateUser(
                    UserAttributes(
                      data: {
                        'role': 'Artisan & Tourist',
                        'roles': ['Tourist', 'Artisan'],
                        'status': 'PENDING_APPROVAL',
                        'studio_name': studioName,
                        'craft_category': craftCategory,
                        'ssm_number': ssmNumber,
                      },
                    ),
                  );
                } catch (_) {}

                final upgraded = <String, dynamic>{
                  ...?existingRow,
                  'email': cleanEmail,
                  'role': 'Artisan & Tourist',
                  'roles': ['Tourist', 'Artisan'],
                  'status': 'PENDING_APPROVAL',
                  'studioName': studioName,
                  'craftCategory': craftCategory,
                  'ssmNumber': ssmNumber,
                };
                _userStore[cleanEmail] = upgraded;
                return UserModel.fromMap(upgraded);
              }
            }
          } catch (authErr) {
            final authErrStr = authErr.toString().toLowerCase();
            if (authErrStr.contains('invalid') || authErrStr.contains('credentials') || authErrStr.contains('password')) {
              throw Exception('INCORRECT PASSWORD: The password entered does not match your existing account. Please enter your existing account password to link this profile.');
            }
          }
          throw Exception('ACCOUNT ALREADY REGISTERED: An account with this email already exists. Please sign in instead.');
        }

        // Direct table fallback if auth signup rate limited or offline
        try {
          await client.from('users').upsert({
            'id': newUser['id'],
            'email': cleanEmail,
            'username': resolvedUsername,
            'full_name': resolvedDisplayName,
            'role': finalRole,
            'status': initialStatus,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          try {
            await client.from('users').upsert({
              'id': newUser['id'],
              'email': cleanEmail,
              'full_name': resolvedDisplayName,
              'role': finalRole,
              'status': initialStatus,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (tableErr) {
            debugPrint('Supabase public.users fallback note: $tableErr');
          }
        }
      }
    }

    _userStore[cleanEmail] = newUser;
    return UserModel.fromMap(newUser);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 400));

    // Admin security policy: Admins cannot reset password via consumer self-service
    if (cleanEmail == 'admin@warisankita.my') {
      throw Exception('ADMIN SECURITY RESTRICTION: Administrator credentials cannot be reset via self-service. Please contact system security.');
    }

    // 1. Verify existence in local store or Supabase DB
    final accountCheck = await checkExistingAccount(cleanEmail);
    if (accountCheck.existingRole == 'Admin') {
      throw Exception('ADMIN SECURITY RESTRICTION: Administrator credentials cannot be reset via self-service. Please contact system security.');
    }
    final existsLocally = _userStore.containsKey(cleanEmail);
    final existsInDb = accountCheck.exists;

    final client = _client;

    if (!existsLocally && !existsInDb && client == null) {
      throw Exception('EMAIL NOT FOUND: No account registered with this email.');
    }

    // Populate local store if discovered via DB
    if (!existsLocally && existsInDb) {
      _userStore[cleanEmail] = {
        'id': 'usr-${DateTime.now().millisecondsSinceEpoch}',
        'email': cleanEmail,
        'username': accountCheck.username ?? cleanEmail.split('@').first,
        'displayName': accountCheck.displayName ?? cleanEmail.split('@').first,
        'password': 'password123',
        'role': accountCheck.existingRole ?? 'Tourist',
        'roles': accountCheck.existingRoles,
        'status': 'ACTIVE',
        'isSuspended': false,
      };
    }

    // UC003 - C1: Password reset tokens must expire after 15 minutes
    final token = 'TOKEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    _resetTokens[token] = {
      'email': cleanEmail,
      'expiresAt': expiresAt,
      'isUsed': false,
    };

    if (client != null) {
      try {
        await client.auth.resetPasswordForEmail(
          cleanEmail,
          redirectTo: 'io.supabase.warisankita://reset-callback',
        );
      } catch (e) {
        debugPrint('Supabase resetPasswordForEmail note: $e');
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('user not found') || errStr.contains('email not found')) {
          if (!existsLocally && !existsInDb) {
            throw Exception('EMAIL NOT FOUND: No account registered with this email.');
          }
        }
      }
    }

    debugPrint('Generated 15-min password reset token for $cleanEmail: $token (Expires: $expiresAt)');
  }

  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 500));

    // Validate email exists
    final accountCheck = await checkExistingAccount(cleanEmail);
    final existsLocally = _userStore.containsKey(cleanEmail);
    final existsInDb = accountCheck.exists;

    if (!existsLocally && !existsInDb && _client == null) {
      throw Exception('EMAIL NOT FOUND: Account does not exist.');
    }

    if (!existsLocally) {
      _userStore[cleanEmail] = {
        'id': 'usr-${DateTime.now().millisecondsSinceEpoch}',
        'email': cleanEmail,
        'username': accountCheck.username ?? cleanEmail.split('@').first,
        'displayName': accountCheck.displayName ?? cleanEmail.split('@').first,
        'password': newPassword,
        'role': accountCheck.existingRole ?? 'Tourist',
        'roles': accountCheck.existingRoles,
        'status': 'ACTIVE',
        'isSuspended': false,
      };
    } else {
      _userStore[cleanEmail]!['password'] = newPassword;
    }

    // UC003 - A4: Expired or invalid token check
    if (_resetTokens.containsKey(token)) {
      final tokenInfo = _resetTokens[token]!;
      if (tokenInfo['isUsed'] == true) {
        throw Exception('RESET LINK ALREADY USED: Please request a new link.');
      }
      final DateTime expiresAt = tokenInfo['expiresAt'] as DateTime;
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('RESET LINK EXPIRED: Token expired after 15 minutes.');
      }
      // UC003 - C4: Token single-use - invalidate immediately
      tokenInfo['isUsed'] = true;
    }

    final client = _client;
    if (client != null) {
      try {
        await client.auth.updateUser(UserAttributes(password: newPassword));
      } catch (e) {
        debugPrint('Supabase updateUser password note: $e');
      }
    }
  }

  Future<UserModel> linkArtisanRoleToTourist({
    required String email,
    required String studioName,
    required String craftCategory,
    required String ssmNumber,
    String? ssmFileName,
    String? certFileName,
    List<String>? photos,
  }) async {
    String cleanEmail = email.trim().toLowerCase();
    final client = _client;

    if (cleanEmail.isEmpty && client != null && client.auth.currentUser != null) {
      cleanEmail = client.auth.currentUser!.email?.toLowerCase() ?? '';
    }
    if (cleanEmail.isEmpty) {
      cleanEmail = 'tourist@warisankita.my';
    }

    await Future.delayed(const Duration(milliseconds: 300));

    Map<String, dynamic>? userRecord = _userStore[cleanEmail];

    // If not in local store, query Supabase public.users table
    if (userRecord == null && client != null) {
      try {
        final row = await client.from('users').select().ilike('email', cleanEmail).maybeSingle();
        if (row != null) {
          userRecord = Map<String, dynamic>.from(row);
          _userStore[cleanEmail] = userRecord;
        }
      } catch (e) {
        debugPrint('Supabase linkArtisan query note: $e');
      }
    }

    // Dynamic initialization if record is absent
    if (userRecord == null) {
      userRecord = {
        'id': 'usr-${DateTime.now().millisecondsSinceEpoch}',
        'email': cleanEmail,
        'username': cleanEmail.split('@').first,
        'displayName': cleanEmail.split('@').first,
        'role': 'Artisan & Tourist',
        'roles': ['Tourist', 'Artisan'],
        'status': 'PENDING_APPROVAL',
        'studioName': studioName,
        'craftCategory': craftCategory,
        'ssmNumber': ssmNumber,
        'joinedDate': 'Feb 2026',
        'isSuspended': false,
      };
      _userStore[cleanEmail] = userRecord;
    }

    // Update user record with pending artisan credentials
    userRecord['studioName'] = studioName;
    userRecord['craftCategory'] = craftCategory;
    userRecord['ssmNumber'] = ssmNumber;
    userRecord['status'] = 'PENDING_APPROVAL';
    userRecord['role'] = 'Artisan & Tourist';
    userRecord['roles'] = ['Tourist', 'Artisan'];

    if (client != null) {
      try {
        try {
          await client.auth.updateUser(
            UserAttributes(
              data: {
                'status': 'PENDING_APPROVAL',
                'role': 'Artisan & Tourist',
                'studio_name': studioName,
                'craft_category': craftCategory,
                'ssm_number': ssmNumber,
              },
            ),
          );
        } catch (_) {}

        final existing = await client.from('users').select('id').ilike('email', cleanEmail).maybeSingle();
        final String userId = existing?['id']?.toString() ?? client.auth.currentUser?.id ?? userRecord['id'] ?? '00000000-0000-4000-8000-000000000001';

        if (existing != null) {
          await client.from('users').update({
            'status': 'PENDING_APPROVAL',
            'role': 'Artisan & Tourist',
            'updated_at': DateTime.now().toIso8601String(),
          }).ilike('email', cleanEmail);
        } else {
          await client.from('users').insert({
            'id': userId,
            'email': cleanEmail,
            'username': userRecord['username'] ?? cleanEmail.split('@').first,
            'full_name': userRecord['displayName'] ?? studioName,
            'status': 'PENDING_APPROVAL',
            'role': 'Artisan & Tourist',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        // Upsert into artisan_profiles
        try {
          await client.from('artisan_profiles').upsert({
            'user_id': userId,
            'studio_name': studioName,
            'craft_category': craftCategory,
            'ssm_number': ssmNumber,
            'bio': 'Master artisan dedicated to traditional Malaysian craft.',
            'address': 'Malaysia',
            'state': 'Melaka',
            'status': 'PENDING_APPROVAL',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (apErr) {
          debugPrint(
            'Supabase linkArtisanRoleToTourist artisan_profiles note: $apErr',
          );
        }
      } catch (e) {
        debugPrint('Supabase linkArtisanRoleToTourist note: $e');
      }
    }

    return UserModel.fromMap(userRecord);
  }

  Future<UserModel> updateUserProfile({
    required String email,
    String? username,
    String? displayName,
    String? studioName,
    String? bio,
    String? phone,
    String? state,
    String? craftCategory,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 300));

    final userRecord = _userStore.containsKey(cleanEmail)
        ? _userStore[cleanEmail]!
        : <String, dynamic>{'email': cleanEmail, 'role': 'Tourist', 'roles': ['Tourist'], 'status': 'ACTIVE'};

    final roleStr = (userRecord['role'] ?? '').toString();
    final rolesList = userRecord['roles'] is List ? List<String>.from(userRecord['roles']) : <String>[];
    final isArtisanAccount = roleStr.toLowerCase().contains('artisan') || rolesList.any((r) => r.toLowerCase().contains('artisan'));

    // Uniqueness validation: Ensure newly chosen username is available and not registered by another account
    if (username != null && username.trim().isNotEmpty) {
      final currentUsername = (userRecord['username'] as String?)?.trim().toLowerCase().replaceAll('@', '');
      final candidateUsername = username.trim().toLowerCase().replaceAll('@', '');
      if (currentUsername != candidateUsername) {
        final isAvailable = await isUsernameAvailable(username, excludeEmail: cleanEmail);
        if (!isAvailable) {
          throw Exception('USERNAME ALREADY TAKEN: "@${username.replaceAll('@', '')}" is registered by another user. Please choose a different username.');
        }
      }
    }

    if (username != null && username.isNotEmpty) {
      final cleanHandle = username.trim().replaceAll('@', '');
      userRecord['username'] = cleanHandle;
      userRecord['displayName'] = displayName ?? cleanHandle;
      if (isArtisanAccount && (studioName == null || studioName.isEmpty)) {
        userRecord['studioName'] = cleanHandle;
      }
    }
    if (displayName != null && displayName.isNotEmpty) {
      userRecord['displayName'] = displayName.trim();
      userRecord['full_name'] = displayName.trim();
      if (isArtisanAccount && (studioName == null || studioName.isEmpty)) {
        userRecord['studioName'] = displayName.trim();
      }
    }
    if (studioName != null && studioName.isNotEmpty) {
      userRecord['studioName'] = studioName.trim();
      userRecord['studio_name'] = studioName.trim();
    }
    if (bio != null) userRecord['bio'] = bio;
    if (state != null) userRecord['state'] = state;
    if (craftCategory != null) userRecord['craftCategory'] = craftCategory;
    if (phone != null) userRecord['phone'] = phone;

    _userStore[cleanEmail] = userRecord;

    final client = _client;
    if (client != null) {
      try {
        final updateMap = <String, dynamic>{};
        if (username != null) {
          final cleanHandle = username.trim().replaceAll('@', '');
          updateMap['username'] = cleanHandle;
          updateMap['full_name'] = displayName ?? cleanHandle;
        }
        if (displayName != null) {
          updateMap['display_name'] = displayName.trim();
          updateMap['full_name'] = displayName.trim();
        }
        if (studioName != null) {
          updateMap['studio_name'] = studioName.trim();
        } else if (isArtisanAccount && (username != null || displayName != null)) {
          updateMap['studio_name'] = displayName ?? username;
        }
        if (bio != null) updateMap['bio'] = bio;
        if (state != null) updateMap['state'] = state;
        if (craftCategory != null) updateMap['craft_category'] = craftCategory;
        if (phone != null) updateMap['phone_number'] = phone;
        updateMap['updated_at'] = DateTime.now().toIso8601String();

        if (updateMap.isNotEmpty) {
          // 1. Update Supabase Postgres 'users' table (Core identity columns only)
          try {
            final userUpdates = <String, dynamic>{
              if (username != null) 'username': username.trim().replaceAll('@', ''),
              if (displayName != null || username != null) 'display_name': displayName ?? username,
              if (displayName != null || username != null) 'full_name': displayName ?? username,
              if (phone != null) 'phone_number': phone,
              'updated_at': DateTime.now().toIso8601String(),
            };
            if (userUpdates.length > 1) {
              await client.from('users').update(userUpdates).ilike('email', cleanEmail);
            }
          } catch (e) {
            debugPrint('Supabase updateUserProfile users table note: $e');
          }

          // 2. Update Supabase Postgres 'artisan_profiles' table (Professional columns only, by user_id)
          if (isArtisanAccount) {
            try {
              final userRow = await client.from('users').select('id').ilike('email', cleanEmail).maybeSingle();
              final String? effectiveUid = userRow?['id']?.toString() ?? client.auth.currentUser?.id;
              if (effectiveUid != null) {
                final artisanUpdates = <String, dynamic>{
                  if (studioName != null && studioName.trim().isNotEmpty) 'studio_name': studioName.trim(),
                  if (bio != null) 'bio': bio,
                  if (state != null) 'state': state,
                  if (craftCategory != null) 'craft_category': craftCategory,
                  'updated_at': DateTime.now().toIso8601String(),
                };
                if (artisanUpdates.length > 1) {
                  await client.from('artisan_profiles').update(artisanUpdates).eq('user_id', effectiveUid);
                }
              }
            } catch (e) {
              debugPrint('Supabase updateUserProfile artisan_profiles table note: $e');
            }
          }

          // 3. Update Supabase Auth User Metadata ONLY if real cloud session is active
          if (client.auth.currentUser != null) {
            try {
              await client.auth.updateUser(UserAttributes(data: updateMap));
            } catch (e) {
              debugPrint('Supabase updateUserProfile auth meta note: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Supabase online updateUserProfile note: $e');
      }
    }

    return UserModel.fromMap(userRecord);
  }

  Future<List<Map<String, dynamic>>> getPendingArtisans() async {
    final List<Map<String, dynamic>> results = [];
    final client = _client;
    if (client != null) {
      try {
        dynamic res;
        try {
          res = await client.from('users').select('*, artisan_profiles!artisan_profiles_user_id_fkey(*, artisan_documents(*))').ilike('status', '%PENDING%');
        } catch (_) {
          try {
            res = await client.from('users').select('*, artisan_profiles(*, artisan_documents(*))').ilike('status', '%PENDING%');
          } catch (_) {
            res = await client.from('users').select().ilike('status', '%PENDING%');
          }
        }
        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            final rowMap = Map<String, dynamic>.from(row);
            Map<String, dynamic>? ap;
            if (rowMap['artisan_profiles'] is Map) {
              ap = Map<String, dynamic>.from(rowMap['artisan_profiles']);
            } else if (rowMap['artisan_profiles'] is List && (rowMap['artisan_profiles'] as List).isNotEmpty) {
              ap = Map<String, dynamic>.from((rowMap['artisan_profiles'] as List).first);
            }
            
            if (ap != null) {
              rowMap['studio_name'] ??= ap['studio_name'];
              rowMap['craft_category'] ??= ap['craft_category'];
              rowMap['ssm_number'] ??= ap['ssm_number'];
              rowMap['bio'] ??= ap['bio'];

              // Extract documents if they exist
              if (ap['artisan_documents'] is List) {
                final docs = ap['artisan_documents'] as List;
                List<String> photos = [];
                String? ssmFileName;
                String? ssmFileUrl;
                String? certFileName;
                String? certFileUrl;
                String? avatarUrl;

                for (var d in docs) {
                  final doc = d as Map;
                  final type = doc['doc_type']?.toString();
                  final url = doc['file_url']?.toString();
                  final name = doc['file_name']?.toString();
                  
                  if (type == 'PORTFOLIO_IMAGE' || type == 'STUDIO_PHOTO') {
                    if (url != null) photos.add(url);
                  } else if (type == 'SSM_BUSINESS_CERT') {
                    if (name != null) ssmFileName = name;
                    if (url != null) ssmFileUrl = url;
                  } else if (type == 'KRAFTANGAN_MASTER_CERT') {
                    if (name != null) certFileName = name;
                    if (url != null) certFileUrl = url;
                  } else if (type == 'MYKAD_SCAN') {
                    if (url != null) avatarUrl = url;
                  }
                }
                
                if (photos.isNotEmpty) rowMap['photos'] = photos;
                if (ssmFileName != null) rowMap['ssm_file_name'] = ssmFileName;
                if (ssmFileUrl != null) rowMap['ssm_file_url'] = ssmFileUrl;
                if (certFileName != null) rowMap['cert_file_name'] = certFileName;
                if (certFileUrl != null) rowMap['cert_file_url'] = certFileUrl;
                
                // fallback the avatar if users.avatar_url is empty
                if ((rowMap['avatar_url'] == null || rowMap['avatar_url'].toString().isEmpty) && avatarUrl != null) {
                  rowMap['imageUrl'] = avatarUrl;
                }
              }
            }
            results.add(rowMap);
          }
        }
      } catch (e) {
        debugPrint('Supabase getPendingArtisans note: $e');
      }
    }

    // Merge with in-memory _userStore
    for (final entry in _userStore.entries) {
      final user = entry.value;
      final status = (user['status'] ?? '').toString().toUpperCase();
      if (status.contains('PENDING')) {
        final userEmail = (user['email'] ?? entry.key).toString().toLowerCase();
        if (!results.any((r) => (r['email'] ?? '').toString().toLowerCase() == userEmail)) {
          results.add(Map<String, dynamic>.from(user));
        }
      }
    }

    return results;
  }

  Future<List<ActiveArtisanMaster>> getActiveArtisans() async {
    final List<ActiveArtisanMaster> results = [];
    final client = _client;
    if (client != null) {
      try {
        dynamic res;
        try {
          res = await client
              .from('users')
              .select('*, artisan_profiles!artisan_profiles_user_id_fkey(*)')
              .ilike('role', '%Artisan%')
              .neq('status', 'PENDING_APPROVAL');
        } catch (_) {
          try {
            res = await client
                .from('users')
                .select('*, artisan_profiles(*)')
                .ilike('role', '%Artisan%')
                .neq('status', 'PENDING_APPROVAL');
          } catch (_) {
            res = await client.from('users').select().ilike('role', '%Artisan%').neq('status', 'PENDING_APPROVAL');
          }
        }

        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            results.add(ActiveArtisanMaster.fromMap(Map<String, dynamic>.from(row)));
          }
        }
      } catch (e) {
        debugPrint('Supabase getActiveArtisans note: $e');
      }
    }

    // Merge in-memory active artisans
    for (final entry in _userStore.entries) {
      final user = entry.value;
      final role = (user['role'] ?? '').toString();
      final status = (user['status'] ?? '').toString().toUpperCase();
      if (role.contains('Artisan') && !status.contains('PENDING')) {
        final email = (user['email'] ?? entry.key).toString().toLowerCase();
        if (!results.any((a) => a.email.toLowerCase() == email)) {
          results.add(ActiveArtisanMaster.fromMap(Map<String, dynamic>.from(user)));
        }
      }
    }

    return results;
  }

  Future<List<UserModel>> getAllUsers() async {
    final List<UserModel> results = [];
    final client = _client;
    if (client != null) {
      try {
        dynamic res;
        try {
          res = await client
              .from('users')
              .select('*, artisan_profiles!artisan_profiles_user_id_fkey(*)')
              .order('created_at', ascending: false);
        } catch (_) {
          try {
            res = await client
                .from('users')
                .select('*, artisan_profiles(*)')
                .order('created_at', ascending: false);
          } catch (_) {
            res = await client.from('users').select().order('created_at', ascending: false);
          }
        }

        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            results.add(UserModel.fromMap(Map<String, dynamic>.from(row)));
          }
        }
      } catch (e) {
        debugPrint('Supabase getAllUsers note: $e');
      }
    }

    // Merge in-memory users
    for (final entry in _userStore.entries) {
      final user = entry.value;
      final email = (user['email'] ?? entry.key).toString().toLowerCase();
      if (!results.any((u) => u.email.toLowerCase() == email)) {
        results.add(UserModel.fromMap(Map<String, dynamic>.from(user)));
      }
    }

    return results;
  }

  Future<void> updateArtisanStatusInDb({
    required String email,
    required String newStatus,
    required String newRole,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_userStore.containsKey(cleanEmail)) {
      _userStore[cleanEmail]!['status'] = newStatus;
      _userStore[cleanEmail]!['role'] = newRole;
      if (newRole == 'Artisan & Tourist') {
        _userStore[cleanEmail]!['roles'] = ['Tourist', 'Artisan'];
      } else if (newRole == 'Artisan') {
        _userStore[cleanEmail]!['roles'] = ['Artisan'];
      }
    }

    final client = _client;
    if (client != null) {
      // 1. Try invoking PostgreSQL SECURITY DEFINER RPC
      try {
        await client.rpc('admin_update_user_status', params: {
          'p_email': cleanEmail,
          'p_status': newStatus,
          'p_role': newRole,
        });
        debugPrint('Supabase RPC admin_update_user_status succeeded for $cleanEmail');
      } catch (rpcError) {
        debugPrint('Supabase RPC admin_update_user_status note: $rpcError');
      }

      // 2. Direct Table Updates Fallback
      try {
        final updatePayload = <String, dynamic>{
          'status': newStatus,
          'role': newRole,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await client
            .from('users')
            .update(updatePayload)
            .ilike('email', cleanEmail);

        // Update artisan_profiles status matching user_id
        final userRow = await client
            .from('users')
            .select('id')
            .ilike('email', cleanEmail)
            .maybeSingle();
        if (userRow != null && userRow['id'] != null) {
          final artisanProfileBeforeUpdate = await client
              .from('artisan_profiles')
              .select('id, status')
              .eq('user_id', userRow['id'])
              .maybeSingle();
          final artisanStatus =
              (newStatus.toUpperCase() == 'ACTIVE' ||
                  newStatus.toUpperCase() == 'APPROVED')
              ? 'APPROVED'
              : newStatus;
          await client
              .from('artisan_profiles')
              .update({
                'status': artisanStatus,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userRow['id']);

          final previousArtisanStatus = artisanProfileBeforeUpdate?['status']
              ?.toString()
              .toUpperCase();
          final isInitialApproval =
              artisanStatus == 'APPROVED' &&
              (previousArtisanStatus == 'PENDING_APPROVAL' ||
                  previousArtisanStatus == 'REJECTED');

          if (isInitialApproval && artisanProfileBeforeUpdate != null) {
            final artisanProfileId = artisanProfileBeforeUpdate['id']
                .toString();

            final questRows = List<Map<String, dynamic>>.from(
              await client
                  .from('quests')
                  .select('id')
                  .eq('artisan_id', artisanProfileId),
            );
            final questIds = questRows
                .map((row) => row['id']?.toString())
                .whereType<String>()
                .toList(growable: false);

            await client
                .from('quests')
                .update({'status': 'APPROVED'})
                .eq('artisan_id', artisanProfileId)
                .eq('status', 'PENDING_APPROVAL');

            if (questIds.isNotEmpty) {
              final reviewPayload = <String, dynamic>{
                'status': 'APPROVED',
                'rejection_reason': null,
                'reviewed_at': DateTime.now().toUtc().toIso8601String(),
                if (client.auth.currentUser != null)
                  'reviewed_by': client.auth.currentUser!.id,
              };

              await client
                  .from('heritage_tasks')
                  .update(reviewPayload)
                  .inFilter('quest_id', questIds)
                  .eq('title', 'Go to the workshop')
                  .eq('sort_order', 1)
                  .eq('status', 'PENDING_APPROVAL');

              await client
                  .from('heritage_tasks')
                  .update(reviewPayload)
                  .inFilter('quest_id', questIds)
                  .eq('title', 'Stay for 15 minutes')
                  .eq('sort_order', 2)
                  .eq('status', 'PENDING_APPROVAL');
            }
          }
        }
      } catch (e) {
        debugPrint('Supabase direct updateArtisanStatusInDb note: $e');
      }
    }
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _clearAuthSession();
    final client = _client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('Supabase signOut note: $e');
      }
    }
  }

  // --- Directory Services ---

  Future<List<ArtisanModel>> fetchArtisans() async {
    // Simulate network delay for "expensive" feel
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      ArtisanModel(
        id: '1',
        name: 'Master Zaid',
        craftType: 'Woodwork',
        state: 'Terengganu',
        description: 'A 5th generation master of the Cengal wood carving tradition. His intricate patterns represent the spiritual connection between nature and heritage.',
        imageUrl: 'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?w=800',
        rating: 4.9,
        experience: '35 Years',
        workshopCount: 12,
        tags: ['Heritage', 'Royal Craft'],
      ),
      ArtisanModel(
        id: '2',
        name: 'Tok Wan',
        craftType: 'Songket',
        state: 'Kelantan',
        description: 'Custodian of traditional "Bunga Dalam" weaving motifs. Each piece takes 3 months to complete using hand-spun silk and gold threads.',
        imageUrl: 'https://images.unsplash.com/photo-1590739225287-bd31519780c3?w=800',
        rating: 4.8,
        experience: '45 Years',
        workshopCount: 8,
        tags: ['Master', 'Weaving'],
      ),
      ArtisanModel(
        id: '3',
        name: 'Siti Rahmah',
        craftType: 'Batik',
        state: 'Terengganu',
        description: 'Specialist in hand-drawn chanting batik using natural dyes extracted from rainforest barks and local fruits.',
        imageUrl: 'https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=800',
        rating: 4.7,
        experience: '22 Years',
        workshopCount: 15,
        tags: ['Natural Dyes', 'Batik Tulis'],
      ),
      ArtisanModel(
        id: '4',
        name: 'Ahmad Fauzi',
        craftType: 'Keris',
        state: 'Melaka',
        description: 'Master blacksmith forging the soul of the Malay archipelago. His keris blades are renowned for their strength and symbolic beauty.',
        imageUrl: 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=800',
        rating: 4.9,
        experience: '30 Years',
        workshopCount: 4,
        tags: ['Blacksmith', 'Metalwork'],
      ),
    ];
  }

  // --- Forum Services ---

  static final List<ForumThread> _forumStore = [];
  static final Map<String, int> _sessionThreadVotes = {};
  static final Map<String, int> _sessionReplyVotes = {};
  static final List<Map<String, dynamic>> _localReportQueue = [];
  static final List<Map<String, dynamic>> _localModerationHistory = [];
  static final Set<String> _dismissedPostIds = {};
  static final Set<String> _dismissedReplyIds = {};

  String _threadVoteKey(String threadId) {
    final userId = _client?.auth.currentUser?.id ?? 'guest';
    return '$userId:$threadId';
  }

  String _replyVoteKey(String replyId) {
    final userId = _client?.auth.currentUser?.id ?? 'guest';
    return '$userId:$replyId';
  }

  Future<List<ForumThread>> fetchThreads() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final client = _client;
    if (client != null) {
      try {
        dynamic res;
        try {
          res = await client.from('forum_posts').select('*, users!forum_posts_user_id_fkey(id, email, full_name, username, avatar_url, role)');
        } catch (_) {
          try {
            res = await client.from('forum_posts').select('*, users(id, email, full_name, username, avatar_url, role)');
          } catch (_) {
            res = await client.from('forum_posts').select();
          }
        }

        // =====================================================
        // Load current user's persistent POST & REPLY votes
        // =====================================================
        final Map<String, int> persistedPostVotes = {};
        final Map<String, int> persistedReplyVotes = {};

        final String? currentUserId =
            client.auth.currentUser?.id;

        if (currentUserId != null) {
          try {
            final voteRows = await client
                .from('forum_post_votes')
                .select('post_id, vote')
                .eq('user_id', currentUserId);

            for (final row in voteRows) {
              final map = Map<String, dynamic>.from(row);
              final postId = map['post_id']?.toString();
              final vote = (map['vote'] as num?)?.toInt() ?? 0;
              if (postId != null) {
                persistedPostVotes[postId] = vote;
              }
            }
          } catch (e) {
            debugPrint('fetch post votes error: $e');
          }

          try {
            final replyVoteRows = await client
                .from('forum_reply_votes')
                .select('reply_id, vote')
                .eq('user_id', currentUserId);

            for (final row in replyVoteRows) {
              final map = Map<String, dynamic>.from(row);
              final replyId = map['reply_id']?.toString();
              final vote = (map['vote'] as num?)?.toInt() ?? 0;
              if (replyId != null) {
                persistedReplyVotes[replyId] = vote;
              }
            }
          } catch (e) {
            debugPrint('fetch reply votes error: $e');
          }
        }

        final List<ForumThread> remote = [];
        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            final threadMap = Map<String, dynamic>.from(row);
            final threadId = threadMap['id'].toString();

            final int persistedVote = persistedPostVotes[threadId] ?? _sessionThreadVotes[_threadVoteKey(threadId)] ?? (threadMap['user_vote'] as num?)?.toInt() ?? 0;

            // Keep session cache synchronized with database
            _sessionThreadVotes[_threadVoteKey(threadId)] = persistedVote;
            threadMap['userVote'] = persistedVote;

            // Check dismissed status
            if (_dismissedPostIds.contains(threadId)) {
              threadMap['is_reported'] = false;
              threadMap['report_reason'] = null;
              threadMap['report_notes'] = null;
            } else {
              // Preserve local report status if recorded
              final localPostReport = _localReportQueue.where((r) => r['postId'] == threadId && r['type'] == 'post').firstOrNull;
              if (localPostReport != null) {
                threadMap['is_reported'] = true;
                final rList = (localPostReport['reports'] as List?) ?? [];
                if (rList.isNotEmpty) {
                  threadMap['report_reason'] = rList.first['reason'];
                  threadMap['report_notes'] = rList.first['notes'];
                }
              }
            }

            final localMatch = _forumStore.where((l) => l.id == threadMap['id']).firstOrNull;

            try {
              dynamic repliesRes;
              try {
                repliesRes = await client
                    .from('forum_replies')
                    .select(
                  '*, users!forum_replies_user_id_fkey(id, email, full_name, username, avatar_url, role)',
                )
                    .eq('post_id', threadMap['id'])
                    .order('created_at', ascending: true);
              } catch (_) {
                try {
                  repliesRes = await client
                      .from('forum_replies')
                      .select(
                    '*, users(id, email, full_name, username, avatar_url, role)',
                  )
                      .eq('post_id', threadMap['id'])
                      .order('created_at', ascending: true);
                } catch (_) {
                  repliesRes = await client
                      .from('forum_replies')
                      .select()
                      .eq('post_id', threadMap['id'])
                      .order('created_at', ascending: true);
                }
              }

              final List<Map<String, dynamic>> processedReplies = [];
              if (repliesRes is List) {
                for (final r in repliesRes) {
                  final rMap = Map<String, dynamic>.from(r);
                  final replyId = rMap['id'].toString();
                  final int pReplyVote = persistedReplyVotes[replyId] ?? _sessionReplyVotes[_replyVoteKey(replyId)] ?? (rMap['user_vote'] as num?)?.toInt() ?? 0;
                  _sessionReplyVotes[_replyVoteKey(replyId)] = pReplyVote;
                  rMap['userVote'] = pReplyVote;

                  // Check dismissed status for reply
                  if (_dismissedReplyIds.contains(replyId)) {
                    rMap['is_reported'] = false;
                    rMap['report_reason'] = null;
                    rMap['report_notes'] = null;
                  } else {
                    // Preserve local reply report status if recorded
                    final localReplyReport = _localReportQueue.where((rep) => rep['replyId'] == replyId && rep['type'] == 'reply').firstOrNull;
                    if (localReplyReport != null) {
                      rMap['is_reported'] = true;
                      final rList = (localReplyReport['reports'] as List?) ?? [];
                      if (rList.isNotEmpty) {
                        rMap['report_reason'] = rList.first['reason'];
                        rMap['report_notes'] = rList.first['notes'];
                      }
                    }
                  }

                  processedReplies.add(rMap);
                }
              }
              // Always trust Supabase result, even when there are 0 replies.
              threadMap['replies'] = processedReplies;
            } catch (_) {
              if (localMatch != null && localMatch.replies.isNotEmpty) {
                threadMap['replies'] = localMatch.replies.map((r) => r.toMap()).toList();
              }
            }
            remote.add(ForumThread.fromMap(threadMap));
          }
        }
        _forumStore.clear();
        _forumStore.addAll(remote);
        return remote;
      } catch (e) {
        debugPrint('Supabase fetchThreads error: $e');
      }
    }
    return List.from(_forumStore);
  }

  Future<List<Map<String, dynamic>>> fetchForumReportQueue() async {
    final Map<String, Map<String, dynamic>> groupedReports = {};

    // 1. Add all from _localReportQueue (excluding dismissed)
    for (final item in _localReportQueue) {
      final String? postId = item['postId']?.toString();
      final String? replyId = item['replyId']?.toString();
      if (postId != null && _dismissedPostIds.contains(postId)) continue;
      if (replyId != null && _dismissedReplyIds.contains(replyId)) continue;
      final String key = postId != null ? 'post_$postId' : 'reply_$replyId';
      groupedReports[key] = Map<String, dynamic>.from(item);
    }

    // 2. Add reported items from _forumStore (excluding dismissed)
    for (final thread in _forumStore) {
      if (thread.isReported && !_dismissedPostIds.contains(thread.id)) {
        final key = 'post_${thread.id}';
        if (!groupedReports.containsKey(key)) {
          groupedReports[key] = {
            'type': 'post',
            'postId': thread.id,
            'reports': [
              {
                'reason': thread.reportReason ?? 'Inappropriate Content',
                'notes': thread.reportNotes ?? '',
                'created_at': thread.timestamp,
              }
            ],
            'reportsCount': 1,
          };
        }
      }
      for (final reply in thread.replies) {
        if (reply.isReported && !_dismissedReplyIds.contains(reply.id)) {
          final key = 'reply_${reply.id}';
          if (!groupedReports.containsKey(key)) {
            groupedReports[key] = {
              'type': 'reply',
              'postId': thread.id,
              'replyId': reply.id,
              'reports': [
                {
                  'reason': reply.reportReason ?? 'Inappropriate Content',
                  'notes': reply.reportNotes ?? '',
                  'created_at': reply.timestamp,
                }
              ],
              'reportsCount': 1,
            };
          }
        }
      }
    }

    // 3. Query Supabase if client is available
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('forum_reports')
            .select()
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        final reports = List<Map<String, dynamic>>.from(response);
        for (final report in reports) {
          final postId = report['post_id']?.toString();
          final replyId = report['reply_id']?.toString();
          if (postId != null && _dismissedPostIds.contains(postId)) continue;
          if (replyId != null && _dismissedReplyIds.contains(replyId)) continue;
          final String key;
          if (postId != null) {
            key = 'post_$postId';
          } else if (replyId != null) {
            key = 'reply_$replyId';
          } else {
            continue;
          }

          if (!groupedReports.containsKey(key)) {
            groupedReports[key] = {
              'type': postId != null ? 'post' : 'reply',
              'postId': postId,
              'replyId': replyId,
              'reports': <Map<String, dynamic>>[],
            };
          }

          final reportList = groupedReports[key]!['reports'] as List<Map<String, dynamic>>;
          reportList.add(report);
          groupedReports[key]!['reportsCount'] = reportList.length;
        }
      } catch (e) {
        debugPrint('fetchForumReportQueue Supabase note: $e');
      }
    }

    return groupedReports.values.toList();
  }

  Future<List<Map<String, dynamic>>> fetchForumModerationHistory() async {
    final List<Map<String, dynamic>> history = List.from(_localModerationHistory);
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('forum_reports')
            .select()
            .inFilter(
          'status',
          ['dismissed', 'actioned'],
        )
            .order(
          'resolved_at',
          ascending: false,
        );

        final remoteHistory = List<Map<String, dynamic>>.from(response);
        for (final item in remoteHistory) {
          final id = item['id']?.toString();
          if (id != null && !history.any((h) => h['id']?.toString() == id)) {
            history.add(item);
          }
        }
      } catch (e) {
        debugPrint('fetchForumModerationHistory Supabase note: $e');
      }
    }
    return history;
  }

  Future<void> createThread(ForumThread thread) async {
    _forumStore.insert(0, thread);
    _sessionThreadVotes[_threadVoteKey(thread.id)] = 0; // Initial neutral vote

    final client = _client;
    if (client != null) {
      final String? authUid = client.auth.currentUser?.id;
      final String? userStoreUid = _userStore[thread.authorEmail]?['id']?.toString();
      final String effectiveUid = thread.userId ?? authUid ?? userStoreUid ?? '00000000-0000-4000-8000-000000000001';
      final String postContent = thread.replies.isNotEmpty ? thread.replies.first.text : thread.title;
      final String tagValue = thread.community.replaceAll('c/', '');

      final Map<String, dynamic> verifiedDbMap = {
        'id': thread.id,
        'user_id': effectiveUid,
        'tag': tagValue,
        'community': thread.community,
        'title': thread.title,
        'content': postContent,
        'upvotes': thread.upvotes,
        'is_reported': thread.isReported,
        if (thread.reportReason != null) 'report_reason': thread.reportReason,
        if (thread.reportNotes != null) 'report_notes': thread.reportNotes,
      };

      try {
        await client.from('forum_posts').insert(verifiedDbMap);
      } catch (e) {
        debugPrint('Supabase createThread insert note: $e');
      }

      for (final reply in thread.replies) {
        _sessionReplyVotes[_replyVoteKey(reply.id)] = 0;
        try {
          await client.from('forum_replies').insert({
            'id': reply.id,
            'post_id': thread.id,
            'user_id': effectiveUid,
            'content': reply.text,
            'upvotes': reply.upvotes,
            'is_verified_answer': reply.isVerifiedAnswer,
            'is_edited': reply.isEdited,
          });
        } catch (re) {
          debugPrint('Supabase createThread initial reply note: $re');
        }
      }
    }
  }

  Future<void> postReply(String threadId, ThreadReply reply) async {
    final postVoteKey = _replyVoteKey(reply.id);
    _sessionReplyVotes[postVoteKey] = 0;

    final idx = _forumStore.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      final t = _forumStore[idx];
      final updatedReplies = List<ThreadReply>.from(t.replies)..add(reply);
      final bool nowSolved = t.isSolved || reply.isArtisan;
      _forumStore[idx] = t.copyWith(
        replies: updatedReplies,
        replyCount: updatedReplies.length,
        isSolved: nowSolved,
      );
    }
    final client = _client;
    if (client != null) {
      final String? authUid = client.auth.currentUser?.id;
      final String? userStoreUid = _userStore[reply.authorEmail]?['id']?.toString();
      final String effectiveUid = authUid ?? userStoreUid ?? '00000000-0000-4000-8000-000000000001';

      final Map<String, dynamic> verifiedReplyMap = {
        'id': reply.id,
        'post_id': threadId,
        'user_id': effectiveUid,
        'content': reply.text,
        'upvotes': reply.upvotes,
        'is_verified_answer': reply.isVerifiedAnswer,
        'is_edited': reply.isEdited,
        if (reply.parentReplyId != null)
          'parent_reply_id': reply.parentReplyId,
      };

      try {
        await client
            .from('forum_replies')
            .insert(verifiedReplyMap);

        // If a verified Artisan replies,
        // mark the thread as having a verified Artisan answer.
        if (reply.isArtisan) {
          await client
              .from('forum_posts')
              .update({
            'is_solved': true,
          })
              .eq('id', threadId);
        }

      } catch (e) {
        debugPrint('Supabase postReply insert/update note: $e');
      }
    }
  }

  Future<void> voteThread(
      String threadId,
      int voteDirection,
      ) async {
    if (voteDirection != 1 && voteDirection != -1) {
      return;
    }

    final int index = _forumStore.indexWhere((thread) => thread.id == threadId);
    if (index == -1) return;

    final ForumThread currentThread = _forumStore[index];
    final client = _client;
    final String? currentUserId = client?.auth.currentUser?.id;
    final String? currentUserEmail = client?.auth.currentUser?.email;

    // Self-vote prevention: Author cannot vote on their own thread
    final bool isAuthor = (currentUserId != null && currentThread.userId != null && currentThread.userId == currentUserId) ||
        (currentUserEmail != null && currentThread.authorEmail.isNotEmpty && currentThread.authorEmail.toLowerCase() == currentUserEmail.toLowerCase());
    if (isAuthor) {
      debugPrint('Self-vote prevention: Author cannot vote on their own thread');
      return;
    }

    final String voteKey = _threadVoteKey(threadId);
    final int currentVote = _sessionThreadVotes[voteKey] ?? currentThread.userVote;

    // Toggle off if same vote direction, else switch direction
    final int newVote = (currentVote == voteDirection) ? 0 : voteDirection;
    final int delta = newVote - currentVote;
    final int newUpvotes = currentThread.upvotes + delta;

    // Optimistic local update
    _sessionThreadVotes[voteKey] = newVote;
    _forumStore[index] = currentThread.copyWith(
      upvotes: newUpvotes,
      userVote: newVote,
    );

    if (client == null) return;

    try {
      final result = await client.rpc(
        'vote_forum_post',
        params: {
          'p_post_id': threadId,
          'p_vote': voteDirection,
        },
      );

      if (result is Map) {
        final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);
        final int rpcUpvotes = (resultMap['upvotes'] as num?)?.toInt() ?? newUpvotes;
        final int rpcUserVote = (resultMap['user_vote'] as num?)?.toInt() ?? newVote;

        _sessionThreadVotes[voteKey] = rpcUserVote;
        final int latestIndex = _forumStore.indexWhere((t) => t.id == threadId);
        if (latestIndex != -1) {
          _forumStore[latestIndex] = _forumStore[latestIndex].copyWith(
            upvotes: rpcUpvotes,
            userVote: rpcUserVote,
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('voteThread RPC note: $e, using direct table fallback');
    }

    // Direct table fallback if RPC is not available
    try {
      await client.from('forum_posts').update({'upvotes': newUpvotes}).eq('id', threadId);
      if (currentUserId != null) {
        if (newVote == 0) {
          await client.from('forum_post_votes').delete().match({
            'post_id': threadId,
            'user_id': currentUserId,
          });
        } else {
          await client.from('forum_post_votes').upsert({
            'post_id': threadId,
            'user_id': currentUserId,
            'vote': newVote,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (dbErr) {
      debugPrint('voteThread direct table fallback note: $dbErr');
    }
  }

  Future<void> voteReply(
      String threadId,
      String replyId,
      int voteDirection,
      ) async {
    if (voteDirection != 1 && voteDirection != -1) {
      return;
    }

    final int tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx == -1) return;

    final ForumThread thread = _forumStore[tIdx];
    final int rIdx = thread.replies.indexWhere((r) => r.id == replyId);
    if (rIdx == -1) return;

    final ThreadReply currentReply = thread.replies[rIdx];
    final client = _client;
    final String? currentUserId = client?.auth.currentUser?.id;
    final String? currentUserEmail = client?.auth.currentUser?.email;

    // Self-vote prevention: Author cannot vote on their own reply
    final bool isAuthor = (currentUserEmail != null && currentReply.authorEmail.isNotEmpty && currentReply.authorEmail.toLowerCase() == currentUserEmail.toLowerCase()) ||
        (currentReply.isMe && currentUserId != null);
    if (isAuthor) {
      debugPrint('Self-vote prevention: Author cannot vote on their own reply');
      return;
    }

    final String voteKey = _replyVoteKey(replyId);
    final int currentVote = _sessionReplyVotes[voteKey] ?? currentReply.userVote;

    // Toggle off if same direction, else switch
    final int newVote = (currentVote == voteDirection) ? 0 : voteDirection;
    final int delta = newVote - currentVote;
    final int newUpvotes = currentReply.upvotes + delta;

    // Optimistic local update
    _sessionReplyVotes[voteKey] = newVote;
    final List<ThreadReply> updatedReplies = List<ThreadReply>.from(thread.replies);
    updatedReplies[rIdx] = currentReply.copyWith(
      upvotes: newUpvotes,
      userVote: newVote,
    );
    _forumStore[tIdx] = thread.copyWith(replies: updatedReplies);

    if (client == null) return;

    try {
      final result = await client.rpc(
        'vote_forum_reply',
        params: {
          'p_reply_id': replyId,
          'p_vote': voteDirection,
        },
      );

      if (result is Map) {
        final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);
        final int rpcUpvotes = (resultMap['upvotes'] as num?)?.toInt() ?? newUpvotes;
        final int rpcUserVote = (resultMap['user_vote'] as num?)?.toInt() ?? newVote;

        _sessionReplyVotes[voteKey] = rpcUserVote;
        final int latestTIdx = _forumStore.indexWhere((t) => t.id == threadId);
        if (latestTIdx != -1) {
          final lThread = _forumStore[latestTIdx];
          final latestRIdx = lThread.replies.indexWhere((r) => r.id == replyId);
          if (latestRIdx != -1) {
            final lReplies = List<ThreadReply>.from(lThread.replies);
            lReplies[latestRIdx] = lReplies[latestRIdx].copyWith(
              upvotes: rpcUpvotes,
              userVote: rpcUserVote,
            );
            _forumStore[latestTIdx] = lThread.copyWith(replies: lReplies);
          }
        }
        return;
      }
    } catch (e) {
      debugPrint('voteReply RPC note: $e, using direct table fallback');
    }

    // Direct table fallback if RPC is not available
    try {
      await client.from('forum_replies').update({'upvotes': newUpvotes}).eq('id', replyId);
      if (currentUserId != null) {
        if (newVote == 0) {
          await client.from('forum_reply_votes').delete().match({
            'reply_id': replyId,
            'user_id': currentUserId,
          });
        } else {
          await client.from('forum_reply_votes').upsert({
            'reply_id': replyId,
            'user_id': currentUserId,
            'vote': newVote,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (dbErr) {
      debugPrint('voteReply direct table fallback note: $dbErr');
    }
  }



  Future<void> editThread(String threadId, String newTitle) async {
    final idx = _forumStore.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      _forumStore[idx] = _forumStore[idx].copyWith(
        title: newTitle,
        isEdited: true,
      );
    }
    final client = _client;
    if (client != null) {
      try {
        await client.from('forum_posts').update({
          'title': newTitle,
          'is_edited': true,
        }).eq('id', threadId);
      } catch (e) {
        try {
          await client.from('forum_posts').update({
            'title': newTitle,
          }).eq('id', threadId);
        } catch (e2) {
          debugPrint('Supabase editThread note: $e2');
        }
      }
    }
  }

  Future<void> deleteThread(String threadId) async {
    _forumStore.removeWhere((t) => t.id == threadId);
    final client = _client;
    if (client != null) {
      try {
        await client.from('forum_posts').delete().eq('id', threadId);
        try {
          await client.from('forum_replies').delete().eq('post_id', threadId);
        } catch (_) {}
      } catch (e) {
        debugPrint('Supabase deleteThread note: $e');
      }
    }
  }

  Future<void> adminDeleteForumPost(
      String postId,
      String deletionReason,
      ) async {
    // Remove deleted post from local forum state and report queue
    _forumStore.removeWhere(
      (thread) => thread.id == postId,
    );
    _dismissedPostIds.add(postId);
    _localReportQueue.removeWhere((r) => r['postId'] == postId && r['type'] == 'post');
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'post_id': postId,
      'status': 'actioned',
      'action_type': 'deleted',
      'resolution_notes': deletionReason,
      'resolved_at': DateTime.now().toIso8601String(),
    });

    final client = _client;
    if (client == null) return;

    try {
      final result = await client.rpc(
        'admin_delete_forum_content',
        params: {
          'p_post_id': postId,
          'p_reply_id': null,
          'p_deletion_reason': deletionReason,
        },
      );
      debugPrint('Admin deleted forum post RPC: $result');
    } catch (e) {
      debugPrint('adminDeleteForumPost RPC note: $e, using direct table fallback');
      try {
        await client.from('forum_reports').update({
          'status': 'actioned',
          'action_type': 'deleted',
          'resolution_notes': deletionReason,
          'resolved_at': DateTime.now().toIso8601String(),
        }).eq('post_id', postId);
        await client.from('forum_posts').delete().eq('id', postId);
      } catch (dbErr) {
        debugPrint('adminDeleteForumPost direct table error: $dbErr');
      }
    }
  }

  Future<void> adminDeleteForumReply(
      String threadId,
      String replyId,
      String deletionReason,
      ) async {
    // Remove deleted reply from local forum state and report queue
    for (int i = 0; i < _forumStore.length; i++) {
      final t = _forumStore[i];
      final rIdx = t.replies.indexWhere((r) => r.id == replyId);
      if (rIdx != -1) {
        final updatedReplies = List<ThreadReply>.from(t.replies)..removeAt(rIdx);
        _forumStore[i] = t.copyWith(replies: updatedReplies, replyCount: updatedReplies.length);
      }
    }
    _dismissedReplyIds.add(replyId);
    _localReportQueue.removeWhere((r) => r['replyId'] == replyId && r['type'] == 'reply');
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'reply_id': replyId,
      'status': 'actioned',
      'action_type': 'deleted',
      'resolution_notes': deletionReason,
      'resolved_at': DateTime.now().toIso8601String(),
    });

    final client = _client;
    if (client == null) return;

    try {
      final result = await client.rpc(
        'admin_delete_forum_content',
        params: {
          'p_post_id': null,
          'p_reply_id': replyId,
          'p_deletion_reason': deletionReason,
        },
      );
      debugPrint('Admin deleted forum reply RPC: $result');
    } catch (e) {
      debugPrint('adminDeleteForumReply RPC note: $e, using direct table fallback');
      try {
        await client.from('forum_reports').update({
          'status': 'actioned',
          'action_type': 'deleted',
          'resolution_notes': deletionReason,
          'resolved_at': DateTime.now().toIso8601String(),
        }).eq('reply_id', replyId);
        await client.from('forum_replies').delete().eq('id', replyId);
      } catch (dbErr) {
        debugPrint('adminDeleteForumReply direct table error: $dbErr');
      }
    }
  }

  Future<void> editReply(String threadId, String replyId, String newText) async {
    final tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      final t = _forumStore[tIdx];
      final rIdx = t.replies.indexWhere((r) => r.id == replyId);
      if (rIdx != -1) {
        final updatedReply = t.replies[rIdx].copyWith(text: newText, isEdited: true);
        final updatedReplies = List<ThreadReply>.from(t.replies)..[rIdx] = updatedReply;
        _forumStore[tIdx] = t.copyWith(replies: updatedReplies);
      }
    }
    final client = _client;
    if (client != null) {
      try {
        await client.from('forum_replies').update({
          'content': newText,
          'is_edited': true,
        }).eq('id', replyId);
      } catch (e) {
        debugPrint('Supabase editReply note: $e');
      }
    }
  }

  Future<void> deleteReply(String threadId, String replyId) async {
    final tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      final t = _forumStore[tIdx];
      final updatedReplies = List<ThreadReply>.from(t.replies)..removeWhere((r) => r.id == replyId);
      _forumStore[tIdx] = t.copyWith(replies: updatedReplies, replyCount: updatedReplies.length);
    }
    final client = _client;
    if (client != null) {
      try {
        await client.from('forum_replies').delete().eq('id', replyId);
      } catch (e) {
        debugPrint('Supabase deleteReply note: $e');
      }
    }
  }

  Future<Map<String, dynamic>> reportReply(
      String threadId,
      String replyId,
      String reason,
      String notes,
      ) async {
    // 1. Unmark dismissed if reported anew
    _dismissedReplyIds.remove(replyId);

    // 2. Update local store
    for (int i = 0; i < _forumStore.length; i++) {
      final t = _forumStore[i];
      final rIdx = t.replies.indexWhere((r) => r.id == replyId);
      if (rIdx != -1) {
        final updatedReply = t.replies[rIdx].copyWith(
          isReported: true,
          reportReason: reason,
          reportNotes: notes,
        );
        final updatedReplies = List<ThreadReply>.from(t.replies);
        updatedReplies[rIdx] = updatedReply;
        _forumStore[i] = t.copyWith(replies: updatedReplies);
      }
    }

    // 3. Add to _localReportQueue
    final existingIdx = _localReportQueue.indexWhere((r) => r['replyId'] == replyId && r['type'] == 'reply');
    final newReportItem = {
      'reason': reason,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (existingIdx != -1) {
      final existingReports = List<Map<String, dynamic>>.from(_localReportQueue[existingIdx]['reports'] ?? []);
      existingReports.add(newReportItem);
      _localReportQueue[existingIdx]['reports'] = existingReports;
      _localReportQueue[existingIdx]['reportsCount'] = existingReports.length;
    } else {
      _localReportQueue.add({
        'type': 'reply',
        'postId': threadId,
        'replyId': replyId,
        'reports': [newReportItem],
        'reportsCount': 1,
      });
    }

    final client = _client;
    if (client == null) {
      return {'success': true, 'already_reported': false};
    }

    final String? currentUserId = client.auth.currentUser?.id;

    try {
      final result = await client.rpc(
        'report_forum_reply',
        params: {
          'p_reply_id': replyId,
          'p_reason': reason,
          'p_notes': notes,
        },
      );

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'success': true, 'already_reported': false};
    } catch (e) {
      final error = e.toString();
      if (error.contains('23505') || error.toLowerCase().contains('duplicate key')) {
        return {'success': false, 'already_reported': true};
      }
      debugPrint('reportReply RPC note: $e, using direct table fallback');
      try {
        await client.from('forum_reports').insert({
          'reply_id': replyId,
          if (currentUserId != null) 'reporter_id': currentUserId,
          'reason': reason,
          'notes': notes,
          'status': 'pending',
        });
        await client.from('forum_replies').update({
          'is_reported': true,
          'report_reason': reason,
          'report_notes': notes,
        }).eq('id', replyId);
        return {'success': true, 'already_reported': false};
      } catch (dbErr) {
        debugPrint('reportReply direct fallback note: $dbErr');
        return {'success': true, 'already_reported': false};
      }
    }
  }

  Future<void> dismissReplyReport(
      String threadId,
      String replyId,
      ) async {
    for (int i = 0; i < _forumStore.length; i++) {
      final t = _forumStore[i];
      final rIdx = t.replies.indexWhere((r) => r.id == replyId);
      if (rIdx != -1) {
        final updatedReplies = List<ThreadReply>.from(t.replies);
        updatedReplies[rIdx] = updatedReplies[rIdx].copyWith(
          isReported: false,
          reportReason: null,
          reportNotes: null,
        );
        _forumStore[i] = t.copyWith(replies: updatedReplies);
      }
    }

    _dismissedReplyIds.add(replyId);
    _localReportQueue.removeWhere((r) => r['replyId'] == replyId && r['type'] == 'reply');
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'reply_id': replyId,
      'status': 'dismissed',
      'resolved_at': DateTime.now().toIso8601String(),
    });

    final client = _client;
    if (client == null) return;

    try {
      await client.rpc(
        'dismiss_forum_reports',
        params: {
          'p_post_id': null,
          'p_reply_id': replyId,
        },
      );
    } catch (e) {
      debugPrint('dismissReplyReport RPC note: $e, using direct table fallback');
      try {
        await client.from('forum_reports').update({
          'status': 'dismissed',
          'resolved_at': DateTime.now().toIso8601String(),
        }).eq('reply_id', replyId);
        await client.from('forum_replies').update({
          'is_reported': false,
          'report_reason': null,
          'report_notes': null,
        }).eq('id', replyId);
      } catch (dbErr) {
        debugPrint('dismissReplyReport direct fallback note: $dbErr');
      }
    }
  }

  Future<Map<String, dynamic>> reportThread(
      String threadId,
      String reason,
      String notes,
      ) async {
    _dismissedPostIds.remove(threadId);

    final tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      _forumStore[tIdx] = _forumStore[tIdx].copyWith(
        isReported: true,
        reportReason: reason,
        reportNotes: notes,
      );
    }

    final existingIdx = _localReportQueue.indexWhere((r) => r['postId'] == threadId && r['type'] == 'post');
    final newReportItem = {
      'reason': reason,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (existingIdx != -1) {
      final existingReports = List<Map<String, dynamic>>.from(_localReportQueue[existingIdx]['reports'] ?? []);
      existingReports.add(newReportItem);
      _localReportQueue[existingIdx]['reports'] = existingReports;
      _localReportQueue[existingIdx]['reportsCount'] = existingReports.length;
    } else {
      _localReportQueue.add({
        'type': 'post',
        'postId': threadId,
        'reports': [newReportItem],
        'reportsCount': 1,
      });
    }

    final client = _client;
    if (client == null) {
      return {'success': true, 'already_reported': false};
    }

    final String? currentUserId = client.auth.currentUser?.id;

    try {
      final result = await client.rpc(
        'report_forum_post',
        params: {
          'p_post_id': threadId,
          'p_reason': reason,
          'p_notes': notes,
        },
      );

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'success': true, 'already_reported': false};
    } catch (e) {
      final error = e.toString();
      if (error.contains('23505') || error.toLowerCase().contains('duplicate key')) {
        return {'success': false, 'already_reported': true};
      }
      debugPrint('reportThread RPC note: $e, using direct table fallback');
      try {
        await client.from('forum_reports').insert({
          'post_id': threadId,
          if (currentUserId != null) 'reporter_id': currentUserId,
          'reason': reason,
          'notes': notes,
          'status': 'pending',
        });
        await client.from('forum_posts').update({
          'is_reported': true,
          'report_reason': reason,
          'report_notes': notes,
        }).eq('id', threadId);
        return {'success': true, 'already_reported': false};
      } catch (dbErr) {
        debugPrint('reportThread direct fallback note: $dbErr');
        return {'success': true, 'already_reported': false};
      }
    }
  }

  Future<void> dismissReport(String threadId) async {
    final idx = _forumStore.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      _forumStore[idx] = _forumStore[idx].copyWith(
        isReported: false,
        reportReason: null,
        reportNotes: null,
      );
    }

    _dismissedPostIds.add(threadId);
    _localReportQueue.removeWhere((r) => r['postId'] == threadId && r['type'] == 'post');
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'post_id': threadId,
      'status': 'dismissed',
      'resolved_at': DateTime.now().toIso8601String(),
    });

    final client = _client;
    if (client == null) return;

    try {
      await client.rpc(
        'dismiss_forum_reports',
        params: {
          'p_post_id': threadId,
          'p_reply_id': null,
        },
      );
    } catch (e) {
      debugPrint('dismissReport RPC note: $e, using direct table fallback');
      try {
        await client.from('forum_reports').update({
          'status': 'dismissed',
          'resolved_at': DateTime.now().toIso8601String(),
        }).eq('post_id', threadId);
        await client.from('forum_posts').update({
          'is_reported': false,
          'report_reason': null,
          'report_notes': null,
        }).eq('id', threadId);
      } catch (dbErr) {
        debugPrint('dismissReport direct fallback note: $dbErr');
      }
    }
  }

  // --- Gamification Services ---

  Future<List<HeritageStamp>> fetchUserStamps(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      HeritageStamp(
        id: 's1',
        title: 'Batik Apprentice',
        iconUrl: 'https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=200',
        isUnlocked: true,
        description: 'Earned for visiting a master batik chanting workshop.',
      ),
      HeritageStamp(
        id: 's2',
        title: 'Wood Guardian',
        iconUrl: 'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?w=200',
        isUnlocked: true,
        description: 'Earned for identifying three royal Cengal carving motifs.',
      ),
    ];
  }

  Future<List<Map<String, dynamic>>> fetchApprovedQuestsForArtisan(
    String artisanProfileId,
  ) async {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final response = await client
        .from('quests')
        .select(
          'id, artisan_id, title, description, category, '
          'geofence_radius_meters, stamp_title, stamp_image_url, status, '
          'created_at',
        )
        .eq('artisan_id', artisanProfileId)
        .eq('status', 'APPROVED')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> fetchCurrentArtisanQuestProfile() async {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final authenticatedUser = client.auth.currentUser;
    if (authenticatedUser == null) {
      throw StateError('You must be signed in to manage cultural quests.');
    }

    return client
        .from('artisan_profiles')
        .select('id, user_id, studio_name, status')
        .eq('user_id', authenticatedUser.id)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> fetchQuestsForArtisan(
    String artisanProfileId,
  ) async {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final response = await client
        .from('quests')
        .select(
          'id, artisan_id, title, description, category, '
          'geofence_radius_meters, stamp_title, stamp_image_url, status, '
          'created_at',
        )
        .eq('artisan_id', artisanProfileId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> updateCurrentArtisanQuest({
    required String questId,
    required String title,
    required String description,
    required String category,
  }) async {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to edit your cultural quest.');
    }

    final artisanProfile = await fetchCurrentArtisanQuestProfile();
    if (artisanProfile == null) {
      throw StateError(
        'No artisan profile is linked to this signed-in account.',
      );
    }

    return client
        .from('quests')
        .update({
          'title': title.trim(),
          'description': description.trim(),
          'category': category.trim(),
          'status': 'PENDING_APPROVAL',
        })
        .eq('id', questId)
        .eq('artisan_id', artisanProfile['id'])
        .select(
          'id, artisan_id, title, description, category, '
          'geofence_radius_meters, stamp_title, stamp_image_url, status, '
          'created_at',
        )
        .single();
  }

  Future<Map<String, dynamic>> insertHeritageTask({
    required String questId,
    required String title,
    required bool isRequired,
    required int xpReward,
    required int sortOrder,
  }) async {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to add a heritage activity.');
    }

    return client
        .from('heritage_tasks')
        .insert({
          'quest_id': questId,
          'title': title.trim(),
          'is_required': isRequired,
          'xp_reward': xpReward,
          'sort_order': sortOrder,
          'status': 'PENDING_APPROVAL',
          'is_system_task': false,
          'is_archived': false,
        })
        .select(
          'id, quest_id, title, is_required, xp_reward, sort_order, created_at, '
          'status, rejection_reason, reviewed_at, reviewed_by, is_system_task, '
          'is_archived',
        )
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchHeritageTasks(
    String questId, {
    required bool approvedOnly,
    required bool includeInactive,
  }) async {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    var query = client
        .from('heritage_tasks')
        .select(
          'id, quest_id, title, is_required, xp_reward, sort_order, '
          'created_at, status, rejection_reason, reviewed_at, reviewed_by, '
          'is_system_task, is_archived',
        )
        .eq('quest_id', questId);

    if (approvedOnly) {
      query = query.eq('status', 'APPROVED');
    }
    if (!includeInactive) {
      query = query.eq('is_archived', false);
    }

    final response = await query
        .order('sort_order', ascending: true, nullsFirst: false)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> fetchCurrentQuestProgressStatus(String questId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to view quest progress.');
    }

    final row = await client
        .from('quest_progress')
        .select('status')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .maybeSingle();

    final status = row?['status'];
    return status is String && status.trim().isNotEmpty ? status : null;
  }

  Future<String> startQuest({
    required String questId,
    required List<String> taskIds,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to start a quest.');
    }

    await client
        .from('quest_progress')
        .upsert(
          {'user_id': user.id, 'quest_id': questId, 'status': 'IN_PROGRESS'},
          onConflict: 'user_id,quest_id',
          ignoreDuplicates: true,
        );

    if (taskIds.isNotEmpty) {
      await client
          .from('task_progress')
          .upsert(
            taskIds
                .map(
                  (taskId) => {
                    'user_id': user.id,
                    'task_id': taskId,
                    'is_completed': false,
                  },
                )
                .toList(growable: false),
            onConflict: 'user_id,task_id',
            ignoreDuplicates: true,
          );
    }

    return await fetchCurrentQuestProgressStatus(questId) ?? 'IN_PROGRESS';
  }

  Future<Map<String, dynamic>> updateUnapprovedHeritageTask({
    required String taskId,
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to update a task submission.');
    }

    return client
        .from('heritage_tasks')
        .update({
          'title': title.trim(),
          'is_required': isRequired,
          'xp_reward': xpReward,
          'status': 'PENDING_APPROVAL',
          'rejection_reason': null,
          'reviewed_at': null,
          'reviewed_by': null,
          'is_archived': false,
        })
        .eq('id', taskId)
        .eq('is_system_task', false)
        .inFilter('status', ['PENDING_APPROVAL', 'REJECTED'])
        .select(
          'id, quest_id, title, is_required, xp_reward, sort_order, created_at, '
          'status, rejection_reason, reviewed_at, reviewed_by, is_system_task, '
          'is_archived',
        )
        .single();
  }

  Future<void> deleteUnapprovedHeritageTask(String taskId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to cancel a task submission.');
    }

    await client
        .from('heritage_tasks')
        .delete()
        .eq('id', taskId)
        .eq('is_system_task', false)
        .inFilter('status', ['PENDING_APPROVAL', 'REJECTED']);
  }

  Future<List<Map<String, dynamic>>> fetchHeritageTaskChangeRequests(
    List<String> taskIds,
  ) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (taskIds.isEmpty) return [];

    final response = await client
        .from('heritage_task_change_requests')
        .select(
          'id, task_id, request_type, proposed_title, proposed_is_required, '
          'proposed_xp_reward, status, rejection_reason, submitted_at, '
          'reviewed_at, reviewed_by',
        )
        .inFilter('task_id', taskIds)
        .order('submitted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> insertHeritageTaskChangeRequest({
    required String taskId,
    required String requestType,
    String? proposedTitle,
    bool? proposedIsRequired,
    int? proposedXpReward,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to request task changes.');
    }

    return client
        .from('heritage_task_change_requests')
        .insert({
          'task_id': taskId,
          'request_type': requestType,
          'proposed_title': proposedTitle?.trim(),
          'proposed_is_required': proposedIsRequired,
          'proposed_xp_reward': proposedXpReward,
          'status': 'PENDING_APPROVAL',
        })
        .select(
          'id, task_id, request_type, proposed_title, proposed_is_required, '
          'proposed_xp_reward, status, rejection_reason, submitted_at, '
          'reviewed_at, reviewed_by',
        )
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchWorkshopLocations() async {
    final client = _client;

    if (client == null) {
      return [];
    }

    try {
      final response = await client
          .from('artisan_profiles')
          .select(
        'id, studio_name, craft_category, address, state, latitude, longitude',
      )
          .eq('status', 'APPROVED')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase fetchWorkshopLocations error: $e');
      return [];
    }
  }
}
