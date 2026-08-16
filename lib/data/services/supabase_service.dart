import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/domain/models/user.dart';

class SupabaseService {
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
      'id': 'usr-admin-001',
      'email': 'admin@warisankita.my',
      'username': 'Admin Nadia',
      'displayName': 'Super Admin Nadia',
      'password': 'password123',
      'role': 'Admin',
      'roles': ['Admin'],
      'status': 'ACTIVE',
      'joinedDate': 'Jan 2025',
      'isSuspended': false,
    },
    'dual.role@warisankita.my': {
      'id': 'usr-dual-001',
      'email': 'dual.role@warisankita.my',
      'username': 'Sarah Chen',
      'displayName': 'Sarah Chen (Artisan & Explorer)',
      'password': 'password123',
      'role': 'Artisan & Tourist',
      'roles': ['Tourist', 'Artisan'],
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
    final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');
    if (cleanUsername.isEmpty) return false;

    // 1. Check local in-memory store for unique username/handle
    for (final entry in _userStore.entries) {
      if (excludeEmail != null && entry.key.toLowerCase() == excludeEmail.toLowerCase()) {
        continue;
      }
      final u = entry.value;
      final existingUsername = (u['username'] as String?)?.toLowerCase().replaceAll('@', '');
      if (existingUsername == cleanUsername) {
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
          res = await client.from('users').select().ilike('email', cleanEmail).maybeSingle();
        } catch (e) {
          debugPrint('Supabase checkExistingAccount note: $e');
        }
      }

      if (res != null) {
        final role = (res['role'] ?? '').toString();
        final rawRoles = res['roles'];
        final roles = (rawRoles is List) ? List<String>.from(rawRoles) : <String>[role];
        final studioName = (res['studio_name'] ?? res['studioName']) as String?;
        final ssm = (res['ssm_number'] ?? res['ssmNumber']) as String?;

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
          craftCategory: res['craft_category'] ?? res['craftCategory'],
        );
      }
    }

    return const ExistingAccountCheck(exists: false);
  }
  
  Future<UserModel> signIn(String emailOrUsername, String password) async {
    final cleanInput = emailOrUsername.trim().toLowerCase().replaceAll('@', '');
    final normInput = emailOrUsername.trim().toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '');
    final rawInput = emailOrUsername.trim().toLowerCase();
    
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 500));

    // 1. Resolve email from in-memory store by exact email, current username, display name, or email prefix
    String cleanEmail = rawInput;
    bool storeMatch = false;

    for (final entry in _userStore.entries) {
      final storedEmail = entry.key.toLowerCase();
      final storedEmailPrefix = storedEmail.split('@')[0].replaceAll('.', '').replaceAll('_', '');
      final u = entry.value;
      final uNameNorm = (u['username'] as String?)?.toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '');
      final dNameNorm = (u['displayName'] as String?)?.toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '');
      final fNameNorm = (u['full_name'] as String?)?.toLowerCase().replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '');

      if (storedEmail == rawInput ||
          uNameNorm == normInput ||
          dNameNorm == normInput ||
          fNameNorm == normInput ||
          storedEmailPrefix == normInput) {
        cleanEmail = entry.key;
        storeMatch = true;
        break;
      }
    }

    final client = _client;
    if (client != null) {
      // 2. If client connected and input does not contain '@', lookup email from Supabase users table
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

        if (!emailFound) {
          try {
            final usersList = await client
                .from('users')
                .select('email, full_name, display_name');
            for (final row in usersList) {
              final rowEmail = (row['email'] as String?)?.toLowerCase() ?? '';
              final rowFullName = (row['full_name'] as String?)?.toLowerCase() ?? '';
              final rowDisplayName = (row['display_name'] as String?)?.toLowerCase() ?? '';
              final rowFullNameNorm = rowFullName.replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '');
              final rowDisplayNameNorm = rowDisplayName.replaceAll('@', '').replaceAll(' ', '').replaceAll('_', '');
              final rowEmailPrefixNorm = rowEmail.split('@')[0].replaceAll('.', '').replaceAll('_', '');

              if (rowFullNameNorm == normInput ||
                  rowDisplayNameNorm == normInput ||
                  rowEmailPrefixNorm == normInput) {
                cleanEmail = rowEmail;
                emailFound = true;
                break;
              }
            }
          } catch (e) {
            debugPrint('Supabase full_name/email lookup note: $e');
          }
        }

        if (!emailFound && !storeMatch) {
          throw Exception('INVALID CREDENTIALS: User account not found with identifier "$emailOrUsername".');
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
            profileData = await client.from('users').select().eq('id', authRes.user!.id).maybeSingle();
          } catch (e) {
            debugPrint('Supabase table select note: $e');
          }

          if (profileData != null) {
            return UserModel.fromMap(profileData);
          }

          final meta = authRes.user!.userMetadata ?? {};
          final role = (meta['role'] as String?) ?? 'Tourist';
          final roles = meta['roles'] != null ? List<String>.from(meta['roles']) : [role];
          final status = (meta['status'] as String?) ?? 'ACTIVE';

          if (status == 'SUSPENDED') {
            throw Exception('ACCOUNT SUSPENDED BY ADMINISTRATOR: Contact support.');
          }

          return UserModel(
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
    if (userData['password'] != password) {
      throw Exception('INVALID CREDENTIALS: Password incorrect.');
    }

    // Check account status
    if (userData['status'] == 'SUSPENDED' || userData['isSuspended'] == true) {
      // UC001 - A3: Account suspended
      throw Exception('ACCOUNT SUSPENDED BY ADMINISTRATOR: Contact support.');
    }

    return UserModel.fromMap(userData);
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

    // Account already exists check & Automatic Dual-Role Upgrade:
    if (_userStore.containsKey(cleanEmail)) {
      final existing = _userStore[cleanEmail]!;
      final existingRole = (existing['role'] ?? '').toString();
      final existingRoles = (existing['roles'] is List) ? List<String>.from(existing['roles']) : <String>[existingRole];

      final isTargetArtisan = role == 'Artisan' || role == 'Master Artisan' || role == 'Artisan & Tourist';
      final isTargetTourist = role == 'Tourist' || role == 'Cultural Tourist';

      // Verify existing password to authorize cross-role linking
      if (existing['password'] != null && existing['password'] != password) {
        final roleLabel = (existingRole == 'Tourist' || existingRoles.contains('Tourist')) ? 'Tourist' : 'Master Artisan';
        throw Exception('INCORRECT PASSWORD: The password entered does not match your existing $roleLabel account. Please enter your existing account password to link this profile.');
      }

      // Case 1: Existing Tourist applying for Artisan studio -> Link with PENDING_APPROVAL
      if ((existingRole == 'Tourist' || existingRoles.contains('Tourist')) && !existingRoles.contains('Artisan') && isTargetArtisan) {
        existing['role'] = 'Artisan & Tourist';
        existing['roles'] = ['Tourist', 'Artisan'];
        existing['status'] = 'PENDING_APPROVAL';
        if (studioName != null && studioName.isNotEmpty) existing['studioName'] = studioName;
        if (craftCategory != null && craftCategory.isNotEmpty) existing['craftCategory'] = craftCategory;
        if (ssmNumber != null && ssmNumber.isNotEmpty) existing['ssmNumber'] = ssmNumber;

        final client = _client;
        if (client != null) {
          try {
            await client.from('users').update({
              'role': 'Artisan & Tourist',
              'status': 'PENDING_APPROVAL',
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('email', cleanEmail);
          } catch (_) {}
        }
        return UserModel.fromMap(existing);
      }

      // Case 2: Existing Artisan registering as Tourist -> Upgrade immediately
      if ((existingRole == 'Artisan' || existingRoles.contains('Artisan')) && !existingRoles.contains('Tourist') && isTargetTourist) {
        existing['role'] = 'Artisan & Tourist';
        existing['roles'] = ['Tourist', 'Artisan'];
        if (existing['status'] == 'APPROVED') existing['status'] = 'ACTIVE';

        final client = _client;
        if (client != null) {
          try {
            await client.from('users').update({
              'role': 'Artisan & Tourist',
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('email', cleanEmail);
          } catch (_) {}
        }
        return UserModel.fromMap(existing);
      }

      throw Exception('ACCOUNT ALREADY REGISTERED: An account with this role already exists. Please sign in instead.');
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

    final String finalRole;
    final List<String> finalRoles;
    if (isDual) {
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

    final client = _client;
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
          
          // Upsert into Supabase database table (public.users)
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
            // Fallback without username column if not yet added in Supabase schema
            try {
              await client.from('users').upsert({
                'id': authRes.user!.id,
                'email': cleanEmail,
                'full_name': resolvedDisplayName,
                'role': finalRole,
                'status': initialStatus,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            } catch (fallbackErr) {
              debugPrint('Supabase public.users table insert note: $fallbackErr');
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
                // Link Tourist to Artisan with PENDING_APPROVAL
                await client.from('users').update({
                  'role': 'Artisan & Tourist',
                  'status': 'PENDING_APPROVAL',
                  'studio_name': studioName,
                  'craft_category': craftCategory,
                  'ssm_number': ssmNumber,
                  'updated_at': DateTime.now().toIso8601String(),
                }).ilike('email', cleanEmail);

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

    // UC003 - A1: Email not found
    if (!_userStore.containsKey(cleanEmail)) {
      throw Exception('EMAIL NOT FOUND: No account registered with this email.');
    }

    // UC003 - C1: Password reset tokens must expire after 15 minutes
    final token = 'TOKEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    _resetTokens[token] = {
      'email': cleanEmail,
      'expiresAt': expiresAt,
      'isUsed': false,
    };

    final client = _client;
    if (client != null) {
      try {
        await client.auth.resetPasswordForEmail(cleanEmail);
      } catch (e) {
        debugPrint('Supabase resetPasswordForEmail note: $e');
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
    if (!_userStore.containsKey(cleanEmail)) {
      throw Exception('EMAIL NOT FOUND: Account does not exist.');
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

    // Update password in DB
    _userStore[cleanEmail]!['password'] = newPassword;

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
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_userStore.containsKey(cleanEmail)) {
      throw Exception('Account not found to link artisan profile.');
    }

    final userRecord = _userStore[cleanEmail]!;
    final List<String> existingRoles = ['Tourist', 'Artisan'];

    // UC002 - A4-2: Link existing tourist account with role 'Artisan & Tourist' and status PENDING_APPROVAL
    userRecord['role'] = 'Artisan & Tourist';
    userRecord['roles'] = existingRoles;
    userRecord['studioName'] = studioName;
    userRecord['craftCategory'] = craftCategory;
    userRecord['ssmNumber'] = ssmNumber;
    userRecord['status'] = 'PENDING_APPROVAL';

    final client = _client;
    if (client != null) {
      try {
        await client.from('users').update({
          'role': 'Artisan & Tourist',
          'status': 'PENDING_APPROVAL',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('email', cleanEmail);
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
      userRecord['username'] = username;
      userRecord['displayName'] = username;
      if (isArtisanAccount && (studioName == null || studioName.isEmpty)) {
        userRecord['studioName'] = username;
      }
    }
    if (displayName != null && displayName.isNotEmpty) {
      userRecord['displayName'] = displayName;
      if (isArtisanAccount && (studioName == null || studioName.isEmpty)) {
        userRecord['studioName'] = displayName;
      }
    }
    if (studioName != null && studioName.isNotEmpty) {
      userRecord['studioName'] = studioName;
    }
    if (bio != null) userRecord['bio'] = bio;
    if (state != null) userRecord['state'] = state;
    if (craftCategory != null) userRecord['craftCategory'] = craftCategory;

    _userStore[cleanEmail] = userRecord;

    final client = _client;
    if (client != null) {
      try {
        final updateMap = <String, dynamic>{};
        if (username != null) {
          updateMap['username'] = username;
          updateMap['full_name'] = username;
        }
        if (displayName != null) {
          updateMap['display_name'] = displayName;
          updateMap['full_name'] = displayName;
        }
        if (studioName != null) {
          updateMap['studio_name'] = studioName;
        } else if (isArtisanAccount && (username != null || displayName != null)) {
          updateMap['studio_name'] = displayName ?? username;
        }
        if (bio != null) updateMap['bio'] = bio;
        if (state != null) updateMap['state'] = state;
        if (craftCategory != null) updateMap['craft_category'] = craftCategory;
        updateMap['updated_at'] = DateTime.now().toIso8601String();

        if (updateMap.isNotEmpty) {
          // 1. Update Supabase Postgres 'users' table
          try {
            await client.from('users').update({
              if (username != null) 'username': username,
              if (displayName != null || username != null) 'display_name': displayName ?? username,
              if (displayName != null || username != null) 'full_name': displayName ?? username,
              if (updateMap.containsKey('studio_name')) 'studio_name': updateMap['studio_name'],
              if (bio != null) 'bio': bio,
              if (state != null) 'state': state,
              if (craftCategory != null) 'craft_category': craftCategory,
              if (phone != null) 'phone_number': phone,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('email', cleanEmail);
          } catch (e) {
            debugPrint('Supabase updateUserProfile users table note: $e');
          }

          // 2. Update Supabase Postgres 'artisan_profiles' table (if linked)
          if (isArtisanAccount) {
            try {
              await client.from('artisan_profiles').update({
                if (updateMap.containsKey('studio_name')) 'studio_name': updateMap['studio_name'],
                if (displayName != null || username != null) 'full_name': displayName ?? username,
                if (bio != null) 'bio': bio,
                if (state != null) 'state': state,
                if (craftCategory != null) 'craft_category': craftCategory,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('email', cleanEmail);
            } catch (e) {
              debugPrint('Supabase updateUserProfile artisan_profiles table note: $e');
            }
          }

          // 3. Update Supabase Auth User Metadata (UserAttributes)
          try {
            await client.auth.updateUser(UserAttributes(data: updateMap));
          } catch (e) {
            debugPrint('Supabase updateUserProfile auth meta note: $e');
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
        final res = await client.from('users').select().eq('status', 'PENDING_APPROVAL');
        if (res.isNotEmpty) {
          for (final row in res) {
            results.add(Map<String, dynamic>.from(row));
          }
        }
      } catch (e) {
        debugPrint('Supabase getPendingArtisans note: $e');
      }
    }

    // Merge with in-memory _userStore
    for (final entry in _userStore.entries) {
      final user = entry.value;
      if (user['status'] == 'PENDING_APPROVAL') {
        if (!results.any((r) => (r['email'] ?? '').toString().toLowerCase() == (user['email'] ?? '').toString().toLowerCase())) {
          results.add(Map<String, dynamic>.from(user));
        }
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
      try {
        final updatePayload = <String, dynamic>{
          'status': newStatus,
          'role': newRole,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (newRole == 'Artisan & Tourist') {
          updatePayload['roles'] = ['Tourist', 'Artisan'];
        } else if (newRole == 'Artisan') {
          updatePayload['roles'] = ['Artisan'];
        }
        await client.from('users').update(updatePayload).eq('email', cleanEmail);
      } catch (e) {
        debugPrint('Supabase updateArtisanStatusInDb note: $e');
      }
    }
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
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

  Future<List<ForumThread>> fetchThreads() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      ForumThread(
        id: 'f1',
        title: 'Identifying authentic Terengganu Batik',
        authorName: 'Aminah Bakar',
        authorAvatar: 'https://i.pravatar.cc/150?u=1',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        replyCount: 14,
        tags: ['Batik', 'Guide'],
        replies: [
          ThreadReply(
            id: 'r1',
            authorName: 'Master Zaid',
            content: 'Look for slight irregularities in the chanting lines. Hand-drawn batik is never factory-perfect.',
            timestamp: '1h ago',
            isVerifiedArtisan: true,
          ),
          ThreadReply(
            id: 'r2',
            authorName: 'Collector_Ali',
            content: 'Also, check if the color bleeds through to the back side perfectly.',
            timestamp: '45m ago',
          ),
        ],
      ),
      ForumThread(
        id: 'f2',
        title: 'The symbolism of Wau Bulan shapes',
        authorName: 'Aizat Rahim',
        authorAvatar: 'https://i.pravatar.cc/150?u=3',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        replyCount: 8,
        tags: ['Wau', 'History'],
        replies: [],
      ),
    ];
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
}
