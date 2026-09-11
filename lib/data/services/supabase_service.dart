import 'dart:convert';
import 'dart:async';
import 'dart:io' as io;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/ssm_validator.dart';

class EmailVerificationRequired extends AuthException {
  final String email;
  const EmailVerificationRequired(this.email) : super('Email not confirmed');
}

class SupabaseService {
  final SupabaseClient? _injectedClient;

  SupabaseService({SupabaseClient? client}) : _injectedClient = client;

  String? _recoveryAccessToken;
  bool _resetInProgress = false;

  // Called only for Supabase's authenticated passwordRecovery event.
  void acceptPasswordRecovery(Session session) {
    if (_client?.auth.currentSession?.accessToken == session.accessToken) {
      _recoveryAccessToken = session.accessToken;
    }
  }

  SupabaseClient get _authClient => _client ??
      (throw StateError('Authentication is unavailable. Please reconnect and try again.'));

  // Session Persistence Keys
  static const String _keyAuthUser = 'wk_last_auth_user';
  static const String _keyAuthEmail = 'wk_last_auth_email';
  static const String _keyActiveRole = 'wk_last_active_role';
  static const String _keyDeletedAccounts = 'wk_deleted_accounts';
  static const String _keyDeletedUsernames = 'wk_deleted_usernames';
  static final Set<String> _deletedAccounts = {};
  static final Set<String> _deletedUsernames = {};

  static String _cleanUsernameKey(String username) {
    return username
        .trim()
        .toLowerCase()
        .replaceAll('@', '')
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');
  }

  static Future<void> _recordDeletedAccount(String email) async {
    final clean = email.trim().toLowerCase();
    _deletedAccounts.add(clean);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyDeletedAccounts) ?? [];
      if (!list.contains(clean)) {
        list.add(clean);
        await prefs.setStringList(_keyDeletedAccounts, list);
      }
    } catch (_) {}
  }

  static Future<void> _unrecordDeletedAccount(String email) async {
    final clean = email.trim().toLowerCase();
    _deletedAccounts.remove(clean);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyDeletedAccounts) ?? [];
      if (list.contains(clean)) {
        list.remove(clean);
        await prefs.setStringList(_keyDeletedAccounts, list);
      }
    } catch (_) {}
  }

  static Future<void> _recordDeletedUsername(String username) async {
    final clean = _cleanUsernameKey(username);
    if (clean.isEmpty) return;
    _deletedUsernames.add(clean);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyDeletedUsernames) ?? [];
      if (!list.contains(clean)) {
        list.add(clean);
        await prefs.setStringList(_keyDeletedUsernames, list);
      }
    } catch (_) {}
  }

  static Future<void> _unrecordDeletedUsername(String username) async {
    final clean = _cleanUsernameKey(username);
    if (clean.isEmpty) return;
    _deletedUsernames.remove(clean);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyDeletedUsernames) ?? [];
      if (list.contains(clean)) {
        list.remove(clean);
        await prefs.setStringList(_keyDeletedUsernames, list);
      }
    } catch (_) {}
  }

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

  SupabaseClient? get _client {
    if (_injectedClient != null) return _injectedClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String _formatMonthYear(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  // Profile cache only: never stores passwords or authenticates a user.
  static final Map<String, Map<String, dynamic>> _userStore = {};

  // Pending relocation requests store: cleanEmail -> {pending_relocation_address, ...}
  static final Map<String, Map<String, dynamic>> _pendingRelocationsStore = {};
  static const String _keyPendingRelocPrefix = 'pending_reloc_';

  static Future<void> _savePendingRelocation(String email, Map<String, dynamic> data) async {
    final cleanEmail = email.trim().toLowerCase();
    _pendingRelocationsStore[cleanEmail] = Map<String, dynamic>.from(data);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPendingRelocPrefix$cleanEmail', jsonEncode(data));
    } catch (e) {
      debugPrint('savePendingRelocation note: $e');
    }
  }

  static Future<void> _clearPendingRelocation(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    _pendingRelocationsStore.remove(cleanEmail);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPendingRelocPrefix$cleanEmail');
    } catch (e) {
      debugPrint('clearPendingRelocation note: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getPendingRelocation(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_pendingRelocationsStore.containsKey(cleanEmail)) {
      return _pendingRelocationsStore[cleanEmail];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPendingRelocPrefix$cleanEmail');
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _pendingRelocationsStore[cleanEmail] = data;
        return data;
      }
    } catch (_) {}
    return null;
  }

  // Helper to merge pending relocation fields into a UserModel if exists
  static Future<UserModel> _enrichUserWithPendingRelocation(UserModel user) async {
    final email = user.email.trim().toLowerCase();
    if (email.isEmpty) return user;
    final reloc = await _getPendingRelocation(email);
    if (reloc != null) {
      final proposedAddress = (reloc['pending_relocation_address'] ?? reloc['address'])?.toString();
      // If the user's verified address in the database has already been updated to the proposed address,
      // the relocation has been officially approved! Clear the local pending relocation cache.
      if (proposedAddress != null && proposedAddress.isNotEmpty && user.address == proposedAddress) {
        await _clearPendingRelocation(email);
        return user.copyWith(clearPendingRelocation: true);
      }
      final pLat = reloc['pending_relocation_lat'] ?? reloc['latitude'];
      final pLng = reloc['pending_relocation_lng'] ?? reloc['longitude'];
      return user.copyWith(
        pendingRelocationAddress: proposedAddress,
        pendingRelocationState: (reloc['pending_relocation_state'] ?? reloc['state'])?.toString(),
        pendingRelocationLatitude: pLat is num ? pLat.toDouble() : (pLat != null ? double.tryParse(pLat.toString()) : null),
        pendingRelocationLongitude: pLng is num ? pLng.toDouble() : (pLng != null ? double.tryParse(pLng.toString()) : null),
        pendingRelocationReason: (reloc['pending_relocation_reason'] ?? reloc['reason'])?.toString(),
        pendingRelocationDate: (reloc['pending_relocation_date'] ?? reloc['date'])?.toString(),
      );
    } else if (user.hasPendingRelocation &&
        user.address != null &&
        user.pendingRelocationAddress != null &&
        user.pendingRelocationAddress!.trim().toLowerCase() == user.address!.trim().toLowerCase()) {
      return user.copyWith(clearPendingRelocation: true);
    }
    return user;
  }

  // --- Auth Services ---

  static String _literalLookupPattern(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('_', r'\_')
      .replaceAll('%', r'\%');

  Future<bool> isUsernameAvailable(
    String username, {
    String? excludeEmail,
  }) async {
    final cleanUsername = username.trim().replaceAll('@', '');
    if (cleanUsername.isEmpty) return false;

    // Use the deployed core columns. Local caches and deleted-account markers
    // cannot establish availability after another device changes an account.
    final rows = await _authClient
        .from('users')
        .select('email, status')
        .ilike('username', _literalLookupPattern(cleanUsername))
        .timeout(const Duration(seconds: 10));
    return !rows.any((row) =>
        (row['status'] ?? '').toString().toUpperCase() != 'DELETED' &&
        (excludeEmail == null ||
            row['email'].toString().toLowerCase() !=
                excludeEmail.trim().toLowerCase()));
  }

  Future<bool> isSsmRegistered(
    String ssmNumber, {
    String? excludeEmail,
    String? excludeUserId,
  }) async {
    final clean = ssmNumber.trim();
    if (clean.isEmpty) return false;
    final normalized = SsmValidator.normalize(clean);
    final noSpaces = clean.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    // 1. Check local in-memory store
    for (final entry in _userStore.entries) {
      if (excludeEmail != null &&
          entry.key.toLowerCase() == excludeEmail.toLowerCase()) {
        continue;
      }
      final u = entry.value;
      if (excludeUserId != null && u['id'] == excludeUserId) {
        continue;
      }
      final existingSsm = (u['ssmNumber'] ?? u['ssm_number']) as String?;
      if (existingSsm != null && existingSsm.trim().isNotEmpty) {
        final existingNorm = SsmValidator.normalize(existingSsm);
        final existingNoSpaces = existingSsm
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();
        if (existingNorm == normalized || existingNoSpaces == noSpaces) {
          return true;
        }
      }
    }

    // 2. Check Supabase artisan_profiles table
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('artisan_profiles')
            .select('id, user_id, ssm_number')
            .or('ssm_number.ilike.$normalized,ssm_number.ilike.$noSpaces')
            .maybeSingle();

        if (res != null) {
          final matchedUserId = res['user_id']?.toString();
          if (excludeUserId != null && matchedUserId == excludeUserId) {
            return false;
          }
          return true;
        }
      } catch (e) {
        debugPrint('Supabase SSM uniqueness check note: $e');
      }
    }

    return false;
  }

  Future<ExistingAccountCheck> checkExistingAccount(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return const ExistingAccountCheck(exists: false);
    }

    // The registration check needs only core identity fields, not a join to
    // artisan tables or optional suspension columns. Propagate lookup failures.
    final rows = await _authClient
        .from('users')
        .select('id, email, username, full_name, display_name, role, status')
        .ilike('email', _literalLookupPattern(cleanEmail))
        .timeout(const Duration(seconds: 10));
    final activeRows = rows.where(
      (row) => (row['status'] ?? '').toString().toUpperCase() != 'DELETED',
    );
    if (activeRows.isEmpty) return const ExistingAccountCheck(exists: false);
    final row = activeRows.first;
    final role = (row['role'] ?? 'Tourist').toString();
    final lowerRole = role.toLowerCase();
    final isArtisan = lowerRole.contains('artisan');
    final isTourist = lowerRole.contains('tourist');
    return ExistingAccountCheck(
      exists: true,
      existingRole: role,
      existingRoles: [role],
      isArtisan: isArtisan,
      isTourist: isTourist,
      isDualRole: isArtisan && isTourist,
      displayName: row['display_name'] ?? row['full_name'],
      username: row['username'],
    );
  }

  Future<UserModel> _loadAuthenticatedProfile() async {
    final client = _authClient;
    final verified = await client.auth.getUser();
    final authUser = verified.user;
    if (authUser == null || authUser.emailConfirmedAt == null) {
      throw const AuthException('Email not confirmed');
    }
    // Roles and account status must come from the database, not editable
    // authentication metadata or a cached profile.
    final row = await client.from('users').select()
        .eq('id', authUser.id).maybeSingle();
    if (row == null) {
      throw const AuthException('Account profile is unavailable. Please contact support.');
    }
    final user = UserModel.fromMap(row);
    if (user.status.toUpperCase() == 'DELETED' ||
        user.suspensionReason == 'ACCOUNT_DELETED') {
      throw const AuthException('ACCOUNT DELETED: Please contact support.');
    }
    // Load professional details independently of the core identity query.
    // Always attempt to fetch artisan_profiles and attached documents so portfolio pictures
    // and bio are never dropped even if users.role is not yet synced.
    try {
      final artisan = await client
          .from('artisan_profiles')
          .select('*, artisan_documents(*)')
          .eq('user_id', authUser.id)
          .maybeSingle();
      if (artisan != null) {
        final artisanStatus = (artisan['status'] ?? '').toString().toUpperCase();
        row['artisan_status'] = artisanStatus;

        if (artisanStatus == 'APPROVED' && row['artisan_status'] != 'CLOSED' && row['role'] != 'Tourist') {
          row['role'] = 'Artisan';
          row['roles'] = ['Artisan'];
          row['artisan_profiles'] = artisan;
          if (artisan['bio'] != null && (artisan['bio'] as String).trim().isNotEmpty) {
            row['bio'] = artisan['bio'];
          }
          if (artisan['studio_name'] != null && (artisan['studio_name'] as String).trim().isNotEmpty) {
            row['studio_name'] = artisan['studio_name'];
          }
          if (artisan['craft_category'] != null && (artisan['craft_category'] as String).trim().isNotEmpty) {
            row['craft_category'] = artisan['craft_category'];
          }
          if (artisan['address'] != null && (artisan['address'] as String).trim().isNotEmpty) {
            row['address'] = artisan['address'];
          }
          if (artisan['state'] != null && (artisan['state'] as String).trim().isNotEmpty) {
            row['state'] = artisan['state'];
          }
          if (artisan['latitude'] != null) {
            row['latitude'] = artisan['latitude'];
          }
          if (artisan['longitude'] != null) {
            row['longitude'] = artisan['longitude'];
          }
          if (artisan['tags'] != null) {
            row['tags'] = artisan['tags'];
          }
          if (artisan['artisan_documents'] != null) {
            row['artisan_documents'] = artisan['artisan_documents'];
          }
          if (artisan['experience'] != null && artisan['experience'].toString().trim().isNotEmpty) {
            row['experience'] = artisan['experience'].toString().trim();
          } else if (artisan['years_experience'] != null && (artisan['years_experience'] as num) > 1) {
            row['experience'] = '${artisan['years_experience']} Years';
          }
          final prefs = await SharedPreferences.getInstance();
          final savedLive = prefs.getBool('artisan_live_open_${artisan['id']}') ??
              prefs.getBool('artisan_live_open_${row['id']}');
          row['is_live_open'] = savedLive ?? artisan['is_live_open'] ?? true;
        } else if (artisanStatus == 'REJECTED' ||
            artisanStatus == 'PENDING_APPROVAL' ||
            artisanStatus == 'PENDING') {
          row['artisan_profiles'] = artisan;
          if (artisan['studio_name'] != null && (artisan['studio_name'] as String).trim().isNotEmpty) {
            row['studio_name'] = artisan['studio_name'];
          }
          if (artisan['craft_category'] != null && (artisan['craft_category'] as String).trim().isNotEmpty) {
            row['craft_category'] = artisan['craft_category'];
          }
          if (artisan['ssm_number'] != null && (artisan['ssm_number'] as String).trim().isNotEmpty) {
            row['ssm_number'] = artisan['ssm_number'];
          }
        } else {
          // Studio is closed or user reverted to Tourist
          row['role'] = 'Tourist';
          row['roles'] = ['Tourist'];
          row['artisan_status'] = 'CLOSED';
          row['artisan_profiles'] = null;
          row['studio_name'] = null;
          row['craft_category'] = null;
          row['ssm_number'] = null;
        }
      } else if (row['artisan_status'] == 'CLOSED' || row['role'] == 'Tourist') {
        row['role'] = 'Tourist';
        row['roles'] = ['Tourist'];
        row['artisan_profiles'] = null;
        row['studio_name'] = null;
        row['craft_category'] = null;
        row['ssm_number'] = null;
      }
    } catch (e) {
      debugPrint('Error loading artisan_profiles join: $e');
      try {
        final artisan = await client
            .from('artisan_profiles')
            .select()
            .eq('user_id', authUser.id)
            .maybeSingle();
        if (artisan != null) {
          final artisanStatus = (artisan['status'] ?? '').toString().toUpperCase();
          row['artisan_status'] = artisanStatus;
          final currentRole = (row['role'] ?? '').toString();

          if (artisanStatus == 'APPROVED' && row['artisan_status'] != 'CLOSED' && currentRole != 'Tourist') {
            try {
              final docs = await client
                  .from('artisan_documents')
                  .select()
                  .eq('artisan_id', artisan['id']);
              artisan['artisan_documents'] = docs;
            } catch (docErr) {
              debugPrint('Error loading artisan_documents fallback: $docErr');
            }
            row['artisan_profiles'] = artisan;
            if (artisan['bio'] != null && (artisan['bio'] as String).trim().isNotEmpty) {
              row['bio'] = artisan['bio'];
            }
            if (artisan['studio_name'] != null && (artisan['studio_name'] as String).trim().isNotEmpty) {
              row['studio_name'] = artisan['studio_name'];
            }
            if (artisan['craft_category'] != null && (artisan['craft_category'] as String).trim().isNotEmpty) {
              row['craft_category'] = artisan['craft_category'];
            }
            if (artisan['address'] != null && (artisan['address'] as String).trim().isNotEmpty) {
              row['address'] = artisan['address'];
            }
            if (artisan['state'] != null && (artisan['state'] as String).trim().isNotEmpty) {
              row['state'] = artisan['state'];
            }
            if (artisan['latitude'] != null) row['latitude'] = artisan['latitude'];
            if (artisan['longitude'] != null) row['longitude'] = artisan['longitude'];
            if (artisan['tags'] != null) row['tags'] = artisan['tags'];
            if (artisan['artisan_documents'] != null) row['artisan_documents'] = artisan['artisan_documents'];
            if (artisan['experience'] != null && artisan['experience'].toString().trim().isNotEmpty) {
              row['experience'] = artisan['experience'].toString().trim();
            } else if (artisan['years_experience'] != null && (artisan['years_experience'] as num) > 1) {
              row['experience'] = '${artisan['years_experience']} Years';
            }
            final prefs = await SharedPreferences.getInstance();
            final savedLive = prefs.getBool('artisan_live_open_${artisan['id']}') ??
                prefs.getBool('artisan_live_open_${row['id']}');
            row['is_live_open'] = savedLive ?? artisan['is_live_open'] ?? true;
            if (currentRole.isEmpty) {
              row['role'] = 'Artisan';
            }
          } else if (artisanStatus == 'REJECTED' ||
              artisanStatus == 'PENDING_APPROVAL' ||
              artisanStatus == 'PENDING') {
            row['artisan_profiles'] = artisan;
            if (artisan['studio_name'] != null && (artisan['studio_name'] as String).trim().isNotEmpty) {
              row['studio_name'] = artisan['studio_name'];
            }
            if (artisan['craft_category'] != null && (artisan['craft_category'] as String).trim().isNotEmpty) {
              row['craft_category'] = artisan['craft_category'];
            }
            if (artisan['ssm_number'] != null && (artisan['ssm_number'] as String).trim().isNotEmpty) {
              row['ssm_number'] = artisan['ssm_number'];
            }
          } else {
            row['role'] = 'Tourist';
            row['roles'] = ['Tourist'];
            row['artisan_status'] = 'CLOSED';
            row['artisan_profiles'] = null;
            row['studio_name'] = null;
            row['craft_category'] = null;
            row['ssm_number'] = null;
          }
        }
      } catch (profileErr) {
        debugPrint('Error loading artisan_profiles fallback: $profileErr');
      }
    }

    final cleanEmail = authUser.email?.toLowerCase() ?? '';

    // Fallback for artisan_status, studio_name, craft_category, ssm_number, and experience
    // when user is a Tourist who applied for artisan role (or remote query missed it).
    if (row['artisan_status'] == null || (row['artisan_status'] as String).isEmpty) {
      final meta = authUser.userMetadata;
      if (meta != null && meta['artisan_status'] != null && meta['artisan_status'].toString().isNotEmpty) {
        row['artisan_status'] = meta['artisan_status'].toString().toUpperCase();
      }
      if ((row['artisan_status'] == null || (row['artisan_status'] as String).isEmpty) && _userStore.containsKey(cleanEmail)) {
        final cached = _userStore[cleanEmail];
        final st = cached?['artisan_status'] ?? cached?['artisanStatus'];
        if (st != null && st.toString().isNotEmpty) {
          row['artisan_status'] = st.toString().toUpperCase();
        }
      }
    }

    if (row['studio_name'] == null || (row['studio_name'] as String).isEmpty) {
      final meta = authUser.userMetadata;
      if (meta != null && meta['studio_name'] != null && meta['studio_name'].toString().isNotEmpty) {
        row['studio_name'] = meta['studio_name'];
      }
      if ((row['studio_name'] == null || (row['studio_name'] as String).isEmpty) && _userStore.containsKey(cleanEmail)) {
        final cached = _userStore[cleanEmail];
        final sn = cached?['studio_name'] ?? cached?['studioName'];
        if (sn != null && sn.toString().isNotEmpty) {
          row['studio_name'] = sn;
        }
      }
    }

    if (row['craft_category'] == null || (row['craft_category'] as String).isEmpty) {
      final meta = authUser.userMetadata;
      if (meta != null && meta['craft_category'] != null && meta['craft_category'].toString().isNotEmpty) {
        row['craft_category'] = meta['craft_category'];
      }
      if ((row['craft_category'] == null || (row['craft_category'] as String).isEmpty) && _userStore.containsKey(cleanEmail)) {
        final cached = _userStore[cleanEmail];
        final cc = cached?['craft_category'] ?? cached?['craftCategory'];
        if (cc != null && cc.toString().isNotEmpty) {
          row['craft_category'] = cc;
        }
      }
    }

    if (row['ssm_number'] == null || (row['ssm_number'] as String).isEmpty) {
      final meta = authUser.userMetadata;
      if (meta != null && meta['ssm_number'] != null && meta['ssm_number'].toString().isNotEmpty) {
        row['ssm_number'] = meta['ssm_number'];
      }
      if ((row['ssm_number'] == null || (row['ssm_number'] as String).isEmpty) && _userStore.containsKey(cleanEmail)) {
        final cached = _userStore[cleanEmail];
        final ssm = cached?['ssm_number'] ?? cached?['ssmNumber'];
        if (ssm != null && ssm.toString().isNotEmpty) {
          row['ssm_number'] = ssm;
        }
      }
    }

    if (row['experience'] == null && _userStore.containsKey(cleanEmail)) {
      final cached = _userStore[cleanEmail];
      if (cached?['experience'] != null && cached!['experience'].toString().trim().isNotEmpty) {
        row['experience'] = cached['experience'].toString().trim();
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString(_keyAuthUser);
      if (rawUser != null && rawUser.isNotEmpty) {
        final cachedUser = jsonDecode(rawUser) as Map<String, dynamic>;
        final cachedEmail = cachedUser['email']?.toString().toLowerCase();
        final cachedId = cachedUser['id']?.toString();
        if (cachedId == authUser.id || cachedEmail == cleanEmail) {
          if (row['artisan_status'] == null || (row['artisan_status'] as String).isEmpty) {
            final st = cachedUser['artisan_status'] ?? cachedUser['artisanStatus'];
            if (st != null && st.toString().isNotEmpty) {
              row['artisan_status'] = st.toString().toUpperCase();
            }
          }
          if (row['studio_name'] == null || (row['studio_name'] as String).isEmpty) {
            final sn = cachedUser['studio_name'] ?? cachedUser['studioName'];
            if (sn != null && sn.toString().isNotEmpty) {
              row['studio_name'] = sn;
            }
          }
          if (row['craft_category'] == null || (row['craft_category'] as String).isEmpty) {
            final cc = cachedUser['craft_category'] ?? cachedUser['craftCategory'];
            if (cc != null && cc.toString().isNotEmpty) {
              row['craft_category'] = cc;
            }
          }
          if (row['ssm_number'] == null || (row['ssm_number'] as String).isEmpty) {
            final ssm = cachedUser['ssm_number'] ?? cachedUser['ssmNumber'];
            if (ssm != null && ssm.toString().isNotEmpty) {
              row['ssm_number'] = ssm;
            }
          }
          if (row['experience'] == null &&
              cachedUser['experience'] != null &&
              cachedUser['experience'].toString().trim().isNotEmpty) {
            row['experience'] = cachedUser['experience'].toString().trim();
          }
        }
      }
    } catch (_) {}

    var profile = UserModel.fromMap(row);
    profile = await _enrichUserWithPendingRelocation(profile);
    _userStore[profile.email.toLowerCase()] = row;
    await _saveAuthSession(profile);
    return profile;
  }

  Future<UserModel> signIn(String emailOrUsername, String password) async {
    final client = _authClient;
    await signOut();
    final input = emailOrUsername.trim().toLowerCase();
    String email = input;
    if (!input.contains('@') || input.startsWith('@')) {
      final username = input.startsWith('@') ? input.substring(1) : input;
      // Escape LIKE wildcards: underscore is a literal, valid username character.
      final pattern = username.replaceAll(r'\', r'\\')
          .replaceAll('_', r'\_').replaceAll('%', r'\%');
      final row = await client.from('users').select('email')
          .ilike('username', pattern).maybeSingle();
      if (row == null) throw const AuthException('INVALID CREDENTIALS: Account not found.');
      email = row['email'] as String;
    }
    try {
      final response = await client.auth.signInWithPassword(email: email, password: password);
      if (response.session == null) {
        throw const AuthException('Sign in did not create a valid session.');
      }
      final profile = await _loadAuthenticatedProfile();
      if (profile.status.toUpperCase() == 'SUSPENDED' || profile.isSuspended) {
        await signOut();
        throw const AuthException('ACCOUNT SUSPENDED BY ADMINISTRATOR: Contact support.');
      }
      return profile;
    } catch (error) {
      await signOut();
      if (error is AuthException &&
          (error.code == 'email_not_confirmed' ||
           error.message.toLowerCase().contains('email not confirmed'))) {
        throw EmailVerificationRequired(email);
      }
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final client = _client;
    if (client != null) {
      if (client.auth.currentSession == null) {
        await _clearAuthSession();
        return null;
      }
      try {
        return await _loadAuthenticatedProfile();
      } catch (_) {
        await signOut();
        rethrow;
      }
    }

    // Fallback when client == null (offline or unit test without injected Supabase client)
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString(_keyAuthUser);
      if (rawUser != null && rawUser.isNotEmpty) {
        final map = jsonDecode(rawUser) as Map<String, dynamic>;
        UserModel user = await _enrichUserWithPendingRelocation(UserModel.fromMap(map));
        final email = user.email.toLowerCase();
        if (user.status.toUpperCase() == 'DELETED' ||
            _deletedAccounts.contains(email)) {
          await _clearAuthSession();
          _userStore.remove(email);
          return null;
        }
        if (_userStore.containsKey(email)) {
          final storeData = _userStore[email]!;
          final storeStatus =
              (storeData['status'] ?? '').toString().toUpperCase();
          final isSuspended = storeData['isSuspended'] == true;
          final reason = (storeData['suspensionReason'] ?? '').toString();
          if (storeStatus == 'DELETED' ||
              (isSuspended && reason == 'ACCOUNT_DELETED')) {
            await _clearAuthSession();
            _userStore.remove(email);
            return null;
          }
          final fromStore = await _enrichUserWithPendingRelocation(UserModel.fromMap(storeData));
          return fromStore;
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
    final client = _authClient;
    final cleanEmail = email.trim().toLowerCase();
    final isArtisan = const ['Artisan', 'Master Artisan'].contains(role);
    if (!isArtisan && role != 'Tourist') {
      throw const AuthException('This role cannot be created through registration.');
    }
    final finalRole = isArtisan ? 'Artisan' : 'Tourist';
    final status = isArtisan ? 'PENDING_APPROVAL' : 'ACTIVE';
    final handle = (username?.trim().isNotEmpty == true
        ? username!.trim().replaceAll('@', '') : cleanEmail.split('@').first);
    if (!await isUsernameAvailable(handle)) {
      throw const AuthException('USERNAME ALREADY TAKEN: Please choose a unique username.');
    }
    if (isArtisan) {
      final error = SsmValidator.validate(ssmNumber);
      if (error != null) throw AuthException('INVALID SSM: $error');
      if (await isSsmRegistered(ssmNumber!)) {
        throw const AuthException('DUPLICATE SSM: This studio is already registered.');
      }
    }
    await signOut();
    final response = await client.auth.signUp(
      email: cleanEmail, password: password,
      data: {
        'username': handle, 'full_name': displayName ?? handle,
        'display_name': displayName ?? handle, 'role': finalRole,
        'roles': [finalRole], 'status': status, 'studio_name': studioName,
        'craft_category': craftCategory, 'ssm_number': ssmNumber,
      },
    );
    final user = response.user;
    if (user == null || user.identities?.isEmpty == true) {
      throw const AuthException('Account could not be created. If already registered, please sign in.');
    }
    await _unrecordDeletedAccount(cleanEmail);
    await _unrecordDeletedUsername(handle);
    // The auth.users trigger creates the profile atomically. Do not insert
    // a substitute identity when signup fails or before email confirmation.
    return UserModel(id: user.id, email: cleanEmail, username: handle,
      displayName: displayName ?? handle, role: finalRole, roles: [finalRole],
      status: status, studioName: studioName, craftCategory: craftCategory,
      ssmNumber: ssmNumber);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final client = _authClient;
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == 'admin@warisankita.my' ||
        cleanEmail.startsWith('admin@') ||
        cleanEmail.startsWith('clqadmin@')) {
      throw const AuthException(
        'ADMINISTRATOR ACCOUNT PROTECTED: Administrator credentials cannot be reset via self-service. Contact support.',
      );
    }
    final account = await client.from('users').select('role, username')
        .eq('email', cleanEmail).maybeSingle();
    if (account == null) {
      throw const AuthException(
        'EMAIL NOT FOUND: No account is registered with this email address.',
      );
    }
    final role = (account['role'] ?? '').toString().toLowerCase();
    final username = (account['username'] ?? '').toString().toLowerCase();
    if (role.contains('admin') || username == 'admin' || username == 'clqadmin') {
      throw const AuthException(
        'ADMINISTRATOR ACCOUNT PROTECTED: Administrator credentials cannot be reset via self-service. Contact support.',
      );
    }
    await client.auth.resetPasswordForEmail(cleanEmail,
      redirectTo: kIsWeb ? Uri.base.resolve('/forgot-password').toString()
          : 'io.supabase.warisankita://reset-callback');
  }

  Future<void> resetPasswordWithToken({
    required String email, required String token, required String newPassword,
  }) async {
    if (_resetInProgress) throw const AuthException('Password reset is already in progress.');
    final client = _authClient;
    _resetInProgress = true;
    try {
      final session = client.auth.currentSession;
      // The UI enters this flow through a recovery link validated by Supabase.
      // An arbitrary token or an ordinary signed-in session is not recovery proof.
      if (token.isNotEmpty || session == null || session.isExpired ||
          _recoveryAccessToken != session.accessToken ||
          session.user.email?.toLowerCase() != email.trim().toLowerCase()) {
        throw const AuthException('Invalid or expired recovery session. Please open a new password reset link.');
      }
      final profile = await _loadAuthenticatedProfile();
      final pEmail = profile.email.toLowerCase().trim();
      final pRole = profile.role.toLowerCase();
      final pUsername = (profile.username ?? '').toLowerCase().trim();
      if (profile.isAdmin ||
          pRole.contains('admin') ||
          pEmail == 'admin@warisankita.my' ||
          pEmail.startsWith('admin@') ||
          pEmail.startsWith('clqadmin@') ||
          pUsername == 'admin' ||
          pUsername == 'clqadmin') {
        throw const AuthException(
          'ADMINISTRATOR ACCOUNT PROTECTED: Administrator credentials cannot be reset via self-service. Contact support.',
        );
      }
      try {
        await client.auth.updateUser(UserAttributes(password: newPassword));
      } on AuthException catch (e) {
        final errStr = e.message.toLowerCase();
        if (errStr.contains('should be different') ||
            errStr.contains('same as old') ||
            errStr.contains('cannot be the same') ||
            errStr.contains('same password') ||
            e.code == 'same_password') {
          throw const AuthException(
            'NEW PASSWORD CANNOT BE THE SAME AS YOUR CURRENT PASSWORD: New password should be different from your old password. Please choose a completely new password, not just a change in uppercase or lowercase.',
          );
        }
        rethrow;
      }
      _recoveryAccessToken = null;
      await signOut();
    } finally {
      _resetInProgress = false;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = _authClient;
    final currentUser = client.auth.currentUser;
    final session = client.auth.currentSession;
    if (currentUser == null || session == null || session.isExpired) {
      throw const AuthException('No active session. Please sign in again.');
    }

    final cleanCurrent = currentPassword.trim();
    final cleanNew = newPassword.trim();

    if (cleanCurrent.toLowerCase() == cleanNew.toLowerCase()) {
      throw const AuthException(
        'NEW PASSWORD IS TOO SIMILAR TO YOUR CURRENT PASSWORD: Please choose a completely new password, not just a change in uppercase or lowercase.',
      );
    }

    final email = currentUser.email;
    if (email == null || email.isEmpty) {
      throw const AuthException('User email not found. Please sign in again.');
    }

    try {
      await client.auth.signInWithPassword(email: email, password: cleanCurrent);
    } on AuthException catch (_) {
      throw const AuthException(
        'INCORRECT CURRENT PASSWORD: The current password you entered does not match our records.',
      );
    }

    try {
      await client.auth.updateUser(UserAttributes(password: cleanNew));
    } on AuthException catch (e) {
      final errStr = e.message.toLowerCase();
      if (errStr.contains('should be different') ||
          errStr.contains('same as old') ||
          errStr.contains('cannot be the same') ||
          errStr.contains('same password') ||
          e.code == 'same_password') {
        throw const AuthException(
          'NEW PASSWORD CANNOT BE THE SAME AS YOUR CURRENT PASSWORD: New password should be different from your old password. Please choose a completely new password, not just a change in uppercase or lowercase.',
        );
      }
      rethrow;
    }
  }

  Future<UserModel> verifyEmailOtp({required String email, required String token}) async {
    final client = _authClient;
    final response = await client.auth.verifyOTP(
      email: email.trim().toLowerCase(), token: token.trim(), type: OtpType.signup);
    if (response.session == null) throw const AuthException('Email verification failed.');
    try {
      return await _loadAuthenticatedProfile();
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  Future<void> resendVerificationOtp({required String email}) async {
    await _authClient.auth.resend(type: OtpType.signup, email: email.trim().toLowerCase());
  }

  Future<UserModel> linkArtisanRoleToTourist({
    required String email,
    required String studioName,
    required String craftCategory,
    required String ssmNumber,
    String? experience,
    String? bio,
    String? phone,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    List<String> toolsAndMaterials = const [],
    PlatformFile? ssmFile,
    PlatformFile? certFile,
    List<PlatformFile>? photos,
  }) async {
    String cleanEmail = email.trim().toLowerCase();
    final client = _client;

    if (cleanEmail.isEmpty &&
        client != null &&
        client.auth.currentUser != null) {
      cleanEmail = client.auth.currentUser!.email?.toLowerCase() ?? '';
    }

    if (cleanEmail.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedEmail = prefs.getString(_keyAuthEmail)?.trim().toLowerCase();
        if (storedEmail != null && storedEmail.isNotEmpty) {
          cleanEmail = storedEmail;
        }
        if (cleanEmail.isEmpty) {
          final rawUser = prefs.getString(_keyAuthUser);
          if (rawUser != null && rawUser.isNotEmpty) {
            final map = jsonDecode(rawUser) as Map<String, dynamic>;
            final e = (map['email'] ?? '').toString().trim().toLowerCase();
            if (e.isNotEmpty) cleanEmail = e;
          }
        }
      } catch (_) {}
    }

    if (cleanEmail.isEmpty) {
      throw Exception('User email is required to submit artisan application. Please ensure you are signed in.');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    Map<String, dynamic>? userRecord = _userStore[cleanEmail];

    // If not in local store, query Supabase public.users table
    if (userRecord == null && client != null) {
      try {
        final row = await client
            .from('users')
            .select()
            .ilike('email', cleanEmail)
            .maybeSingle();
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
        'role': 'Tourist',
        'roles': ['Tourist'],
        'status': 'ACTIVE',
        'artisanStatus': 'PENDING_APPROVAL',
        'artisan_status': 'PENDING_APPROVAL',
        'studioName': studioName,
        'craftCategory': craftCategory,
        'joinedDate': _formatMonthYear(DateTime.now()),
        'created_at': DateTime.now().toIso8601String(),
        'isSuspended': false,
      };
      _userStore[cleanEmail] = userRecord;
    }

    final cleanSsm = ssmNumber.trim();
    final ssmErr = SsmValidator.validate(cleanSsm);
    if (ssmErr != null) {
      throw Exception('INVALID_SSM: $ssmErr');
    }
    final isTaken = await isSsmRegistered(
      cleanSsm,
      excludeEmail: cleanEmail,
      excludeUserId: userRecord['id'],
    );
    if (isTaken) {
      throw Exception(
        'DUPLICATE_SSM: An artisan studio is already registered with SSM number "$cleanSsm".',
      );
    }

    // Update user record with pending artisan credentials while preserving Tourist account
    userRecord['studioName'] = studioName;
    userRecord['craftCategory'] = craftCategory;
    userRecord['ssmNumber'] = ssmNumber;
    userRecord['ssm_number'] = ssmNumber;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userRecord['id']?.toString() ?? '';
      if (uid.isNotEmpty) {
        await prefs.setString('artisan_ssm_$uid', ssmNumber);
      }
    } catch (_) {}
    if (experience != null) userRecord['experience'] = experience;
    if (ssmFile != null) userRecord['ssm_file_name'] = ssmFile.name;
    if (certFile != null) userRecord['cert_file_name'] = certFile.name;
    if (address != null) userRecord['address'] = address;
    if (state != null) userRecord['state'] = state;
    userRecord['status'] = 'PENDING_APPROVAL';
    userRecord['artisanStatus'] = 'PENDING_APPROVAL';
    userRecord['artisan_status'] = 'PENDING_APPROVAL';
    userRecord['role'] = 'Tourist';
    userRecord['roles'] = ['Tourist'];

    // In-memory document preservation & type-safe merging for local session:
    final List<Map<String, dynamic>> existingLocalDocs = [];
    if (userRecord['artisan_documents'] is List) {
      existingLocalDocs.addAll(
        List<Map<String, dynamic>>.from(userRecord['artisan_documents'] as List),
      );
    } else if (userRecord['artisanDocuments'] is List) {
      existingLocalDocs.addAll(
        List<Map<String, dynamic>>.from(userRecord['artisanDocuments'] as List),
      );
    }

    final List<Map<String, dynamic>> newLocalDocs = [];
    if (ssmFile != null) {
      newLocalDocs.add({
        'artisan_id': userRecord['id'],
        'doc_type': 'SSM_BUSINESS_CERT',
        'file_url': 'local://ssm/${ssmFile.name}',
        'file_name': ssmFile.name,
      });
    }
    if (certFile != null) {
      newLocalDocs.add({
        'artisan_id': userRecord['id'],
        'doc_type': 'KRAFTANGAN_MASTER_CERT',
        'file_url': 'local://cert/${certFile.name}',
        'file_name': certFile.name,
      });
    }
    if (photos != null && photos.isNotEmpty) {
      for (var p in photos) {
        newLocalDocs.add({
          'artisan_id': userRecord['id'],
          'doc_type': 'STUDIO_PHOTO',
          'file_url': 'local://studio/${p.name}',
          'file_name': p.name,
        });
      }
    }

    if (newLocalDocs.isNotEmpty) {
      final replacedTypes = newLocalDocs.map((d) => d['doc_type'] as String).toSet();
      final mergedLocalDocs = [
        ...existingLocalDocs.where((d) => !replacedTypes.contains(d['doc_type'])),
        ...newLocalDocs,
      ];
      userRecord['artisan_documents'] = mergedLocalDocs;
      userRecord['artisanDocuments'] = mergedLocalDocs;
    } else if (existingLocalDocs.isNotEmpty) {
      userRecord['artisan_documents'] = existingLocalDocs;
      userRecord['artisanDocuments'] = existingLocalDocs;
    }

    if (client != null) {
      try {
        try {
          await client.auth.updateUser(
            UserAttributes(
              data: {
                'status': 'PENDING_APPROVAL',
                'role': 'Tourist',
                'artisan_status': 'PENDING_APPROVAL',
                'studio_name': studioName,
                'craft_category': craftCategory,
                'ssm_number': ssmNumber,
              },
            ),
          );
        } catch (_) {}

        final existing = await client
            .from('users')
            .select('id')
            .ilike('email', cleanEmail)
            .maybeSingle();
        final String userId =
            existing?['id']?.toString() ??
            client.auth.currentUser?.id ??
            userRecord['id'] ??
            '00000000-0000-4000-8000-000000000001';

        if (existing != null) {
          // Note: users table only has: id, email, full_name, phone_number,
          // avatar_url, role, status, artisan_status, username, display_name.
          // It does NOT have studio_name, craft_category, ssm_number columns.
          try {
            await client
                .from('users')
                .update({
                  'status': 'PENDING_APPROVAL',
                  'role': 'Tourist',
                  'artisan_status': 'PENDING_APPROVAL',
                  if (phone != null) 'phone_number': phone,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', userId);
          } catch (userUpdateErr) {
            debugPrint('linkArtisanRoleToTourist users update note: $userUpdateErr');
            try {
              await client
                  .from('users')
                  .update({
                    'status': 'PENDING_APPROVAL',
                    'role': 'Tourist',
                    'artisan_status': 'PENDING_APPROVAL',
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', userId);
            } catch (err) {
              debugPrint('linkArtisanRoleToTourist users minimal update note: $err');
            }
          }
        } else {
          await client.from('users').insert({
            'id': userId,
            'email': cleanEmail,
            'username': userRecord['username'] ?? cleanEmail.split('@').first,
            'full_name': userRecord['displayName'] ?? studioName,
            'status': 'PENDING_APPROVAL',
            'role': 'Tourist',
            'artisan_status': 'PENDING_APPROVAL',
            if (phone != null) 'phone_number': phone,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        try {
          dynamic profileRes = await client
              .from('artisan_profiles')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

          final profileData = <String, dynamic>{
            'studio_name': studioName,
            'craft_category': craftCategory,
            'ssm_number': ssmNumber,
            // artisan_profiles has 'years_experience' but NOT 'experience' column
            if (experience != null && experience.trim().isNotEmpty)
              if (RegExp(r'\d+').firstMatch(experience) != null)
                'years_experience': int.tryParse(RegExp(r'\d+').firstMatch(experience)!.group(0)!),
            'bio':
                bio ??
                'Master artisan dedicated to traditional Malaysian craft.',
            'address': address ?? state ?? 'Malaysia',
            'state': state ?? 'Malaysia',
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            'status': 'PENDING_APPROVAL',
            'tags': toolsAndMaterials,
            'updated_at': DateTime.now().toIso8601String(),
          };

          if (profileRes != null) {
            await client
                .from('artisan_profiles')
                .update(profileData)
                .eq('user_id', userId);
          } else {
            profileData['user_id'] = userId;
            profileData['created_at'] = DateTime.now().toIso8601String();
            profileRes = await client
                .from('artisan_profiles')
                .insert(profileData)
                .select('id')
                .maybeSingle();
          }

          if (profileRes != null) {
            final artisanId = profileRes is Map
                ? profileRes['id']
                : (profileRes is List && profileRes.isNotEmpty && profileRes.first is Map
                    ? profileRes.first['id']
                    : null);

            Future<Map<String, String>?> uploadDoc(
              PlatformFile? file,
              String bucket,
              String folder,
            ) async {
              if (file == null) return null;
              try {
                Uint8List bytes = await file.readAsBytes();
                if (bytes.isEmpty) return null;

                final fileName =
                    '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
                String finalFileName = fileName;
                String mimeType = 'application/octet-stream';

                final lcName = file.name.toLowerCase();
                if (lcName.endsWith('.pdf')) {
                  mimeType = 'application/pdf';
                } else if (lcName.endsWith('.png') ||
                    lcName.endsWith('.jpg') ||
                    lcName.endsWith('.jpeg')) {
                  try {
                    final compressed =
                        await FlutterImageCompress.compressWithList(
                          bytes,
                          format: CompressFormat.webp,
                          quality: 85,
                        );

                    if (compressed.isNotEmpty) {
                      bytes = compressed;
                      mimeType = 'image/webp';
                      final lastDot = finalFileName.lastIndexOf('.');
                      if (lastDot != -1) {
                        finalFileName =
                            finalFileName.substring(0, lastDot) + '.webp';
                      } else {
                        finalFileName += '.webp';
                      }
                    } else {
                      if (lcName.endsWith('.png'))
                        mimeType = 'image/png';
                      else
                        mimeType = 'image/jpeg';
                    }
                  } catch (e) {
                    debugPrint('WebP conversion failed: $e');
                    if (lcName.endsWith('.png'))
                      mimeType = 'image/png';
                    else
                      mimeType = 'image/jpeg';
                  }
                }

                final path = '$folder/$finalFileName';

                await client.storage
                    .from(bucket)
                    .uploadBinary(
                      path,
                      bytes,
                      fileOptions: FileOptions(contentType: mimeType),
                    );
                final url = client.storage.from(bucket).getPublicUrl(path);
                return {'url': url, 'name': finalFileName};
              } catch (e) {
                debugPrint('Upload error: $e');
                return null;
              }
            }

            try {
              // 1. Fetch backup of existing artisan documents BEFORE any mutation
              final List<Map<String, dynamic>> backupDocs = [];
              try {
                final existingRes = await client
                    .from('artisan_documents')
                    .select()
                    .eq('artisan_id', artisanId);
                for (final item in existingRes) {
                  backupDocs.add(Map<String, dynamic>.from(item));
                }
              } catch (backupErr) {
                debugPrint('Supabase backup existing artisan_documents note: $backupErr');
              }

              final ssmUpload = await uploadDoc(
                ssmFile,
                'artisan_private_docs',
                'ssm',
              );
              final certUpload = await uploadDoc(
                certFile,
                'artisan_private_docs',
                'cert',
              );

              final List<Map<String, dynamic>> docsToInsert = [];

              if (ssmUpload != null) {
                docsToInsert.add({
                  'artisan_id': artisanId,
                  'doc_type': 'SSM_BUSINESS_CERT',
                  'file_url': ssmUpload['url'],
                  'file_name': ssmUpload['name'],
                });
              }

              if (certUpload != null) {
                docsToInsert.add({
                  'artisan_id': artisanId,
                  'doc_type': 'KRAFTANGAN_MASTER_CERT',
                  'file_url': certUpload['url'],
                  'file_name': certUpload['name'],
                });
              }

              if (photos != null && photos.isNotEmpty) {
                for (var p in photos) {
                  final pUpload = await uploadDoc(
                    p,
                    'artisan_public_media',
                    'studio',
                  );
                  if (pUpload != null) {
                    docsToInsert.add({
                      'artisan_id': artisanId,
                      'doc_type': 'STUDIO_PHOTO',
                      'file_url': pUpload['url'],
                      'file_name': pUpload['name'],
                    });
                  }
                }
              }

              // 2. Only delete and replace the document types that have valid new uploads ready
              if (docsToInsert.isNotEmpty) {
                final Set<String> typesToReplace = docsToInsert
                    .map((d) => d['doc_type'] as String)
                    .toSet();

                // Keep track of which documents are about to be replaced for rollback
                final deletedBackup = backupDocs
                    .where((d) => typesToReplace.contains(d['doc_type']))
                    .toList();

                try {
                  // Selectively delete only the document types being replaced
                  for (final type in typesToReplace) {
                    await client
                        .from('artisan_documents')
                        .delete()
                        .eq('artisan_id', artisanId)
                        .eq('doc_type', type);
                  }

                  // Insert new documents
                  await client.from('artisan_documents').insert(docsToInsert);
                } catch (insertErr) {
                  debugPrint(
                    'Supabase insert failed, initiating rollback: $insertErr',
                  );
                  // ROLLBACK: restore previous documents from deletedBackup
                  if (deletedBackup.isNotEmpty) {
                    try {
                      final restoreList = deletedBackup.map((d) {
                        final copy = Map<String, dynamic>.from(d);
                        copy.remove('id');
                        return copy;
                      }).toList();
                      await client.from('artisan_documents').insert(restoreList);
                      debugPrint('Supabase rollback succeeded: restored previous documents.');
                    } catch (rollbackErr) {
                      debugPrint('Supabase rollback failed: $rollbackErr');
                    }
                  }
                  rethrow;
                }
              }
            } catch (docErr) {
              debugPrint(
                'Supabase linkArtisanRoleToTourist artisan_documents note: $docErr',
              );
            }
          }
        } catch (apErr) {
          debugPrint(
            'Supabase linkArtisanRoleToTourist artisan_profiles note: $apErr',
          );
        }
      } catch (e) {
        debugPrint('Supabase linkArtisanRoleToTourist note: $e');
      }
    }

    final profile = UserModel.fromMap(userRecord);
    _userStore[cleanEmail] = userRecord;
    await _saveAuthSession(profile);
    return profile;
  }

  Future<UserModel> updateUserProfile({
    required String email,
    String? username,
    String? displayName,
    String? studioName,
    String? bio,
    String? experience,
    String? phone,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    String? craftCategory,
    List<String>? toolsAndMaterials,
    String? avatarUrl,
    bool? isLiveOpen,
    int? workshopCount,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 300));

    final userRecord = _userStore.containsKey(cleanEmail)
        ? _userStore[cleanEmail]!
        : <String, dynamic>{
            'email': cleanEmail,
            'role': 'Tourist',
            'roles': ['Tourist'],
            'status': 'ACTIVE',
          };

    if (avatarUrl != null) {
      userRecord['avatarUrl'] = avatarUrl;
      userRecord['avatar_url'] = avatarUrl;
    }

    final roleStr = (userRecord['role'] ?? '').toString();
    final rolesList = userRecord['roles'] is List
        ? List<String>.from(userRecord['roles'])
        : <String>[];
    final isArtisanAccount =
        roleStr.toLowerCase().contains('artisan') ||
        rolesList.any((r) => r.toLowerCase().contains('artisan'));

    // Uniqueness validation: Ensure newly chosen username is available and not registered by another account
    if (username != null && username.trim().isNotEmpty) {
      final currentUsername = (userRecord['username'] as String?)
          ?.trim()
          .toLowerCase()
          .replaceAll('@', '');
      final candidateUsername = username.trim().toLowerCase().replaceAll(
        '@',
        '',
      );
      if (currentUsername != candidateUsername) {
        if (_client != null) {
          final isAvailable = await isUsernameAvailable(
            username,
            excludeEmail: cleanEmail,
          );
          if (!isAvailable) {
            throw Exception(
              'USERNAME ALREADY TAKEN: "@${username.replaceAll('@', '')}" is registered by another user. Please choose a different username.',
            );
          }
        } else {
          final candidate = _cleanUsernameKey(candidateUsername);
          for (final entry in _userStore.entries) {
            if (entry.key.toLowerCase() == cleanEmail) continue;
            final existing = (entry.value['username'] as String?)?.trim().toLowerCase();
            if (existing != null && _cleanUsernameKey(existing) == candidate) {
              throw Exception(
                'USERNAME ALREADY TAKEN: "@${username.replaceAll('@', '')}" is registered by another user. Please choose a different username.',
              );
            }
          }
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
    if (address != null) userRecord['address'] = address;
    if (latitude != null) userRecord['latitude'] = latitude;
    if (longitude != null) userRecord['longitude'] = longitude;
    if (craftCategory != null) {
      userRecord['craftCategory'] = craftCategory;
      userRecord['craft_category'] = craftCategory;
    }
    if (phone != null) userRecord['phone'] = phone;
    if (experience != null) userRecord['experience'] = experience;
    if (toolsAndMaterials != null) userRecord['tags'] = toolsAndMaterials;
    if (isLiveOpen != null) {
      userRecord['is_live_open'] = isLiveOpen;
      userRecord['isLiveOpen'] = isLiveOpen;
      try {
        final prefs = await SharedPreferences.getInstance();
        final artisanId = userRecord['id']?.toString() ?? userRecord['user_id']?.toString();
        if (artisanId != null && artisanId.isNotEmpty) {
          await prefs.setBool('artisan_live_open_$artisanId', isLiveOpen);
        }
        final uid = userRecord['id']?.toString() ?? userRecord['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) {
          await prefs.setBool('artisan_live_open_$uid', isLiveOpen);
        }
      } catch (e) {
        debugPrint('Note saving artisan_live_open to SharedPreferences: $e');
      }
    }

    if (workshopCount != null) {
      userRecord['workshop_count'] = workshopCount;
      userRecord['workshopCount'] = workshopCount;
      try {
        final prefs = await SharedPreferences.getInstance();
        final artisanId = userRecord['id']?.toString() ?? userRecord['user_id']?.toString();
        if (artisanId != null && artisanId.isNotEmpty) {
          await prefs.setInt('artisan_workshop_count_$artisanId', workshopCount);
        }
        final uid = userRecord['id']?.toString() ?? userRecord['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) {
          await prefs.setInt('artisan_workshop_count_$uid', workshopCount);
        }
      } catch (e) {
        debugPrint('Note saving artisan_workshop_count to SharedPreferences: $e');
      }
    }

    Map<String, dynamic> apMap;
    if (userRecord['artisan_profiles'] is Map) {
      apMap = Map<String, dynamic>.from(userRecord['artisan_profiles'] as Map);
    } else {
      apMap = <String, dynamic>{};
    }
    if (workshopCount != null) {
      apMap['workshop_count'] = workshopCount;
    }
    if (studioName != null && studioName.trim().isNotEmpty) {
      apMap['studio_name'] = studioName.trim();
    }
    if (bio != null) apMap['bio'] = bio;
    if (experience != null) {
      apMap['experience'] = experience;
      final match = RegExp(r'\d+').firstMatch(experience);
      if (match != null) {
        apMap['years_experience'] = int.tryParse(match.group(0)!);
      }
    }
    if (state != null) apMap['state'] = state;
    if (address != null) apMap['address'] = address;
    if (latitude != null) apMap['latitude'] = latitude;
    if (longitude != null) apMap['longitude'] = longitude;
    if (craftCategory != null) apMap['craft_category'] = craftCategory;
    if (toolsAndMaterials != null) apMap['tags'] = toolsAndMaterials;
    if (isLiveOpen != null) apMap['is_live_open'] = isLiveOpen;
    userRecord['artisan_profiles'] = apMap;

    if (isArtisanAccount || studioName != null || craftCategory != null) {
      userRecord['role'] = 'Artisan';
      userRecord['roles'] = <String>{
        ...List<String>.from(userRecord['roles'] ?? <String>[]),
        'Artisan'
      }.toList();
    }

    _userStore[cleanEmail] = userRecord;

    final client = _client;
    if (client != null) {
      try {
        final updateMap = <String, dynamic>{};
        if (username != null) {
          updateMap['username'] = username.trim().replaceAll('@', '');
        }
        if (displayName != null) {
          updateMap['display_name'] = displayName.trim();
          updateMap['full_name'] = displayName.trim();
        }
        if (studioName != null) {
          updateMap['studio_name'] = studioName.trim();
        } else if (isArtisanAccount &&
            (username != null || displayName != null)) {
          updateMap['studio_name'] = displayName ?? username;
        }
        if (bio != null) updateMap['bio'] = bio;
        if (state != null) updateMap['state'] = state;
        if (address != null) updateMap['address'] = address;
        if (latitude != null) updateMap['latitude'] = latitude;
        if (longitude != null) updateMap['longitude'] = longitude;
        if (craftCategory != null) updateMap['craft_category'] = craftCategory;
        if (phone != null) updateMap['phone_number'] = phone;
        updateMap['updated_at'] = DateTime.now().toIso8601String();

        if (updateMap.isNotEmpty) {
          // 1. Update Supabase Postgres 'users' table (Core identity columns only)
          try {
            final userUpdates = <String, dynamic>{
              if (username != null)
                'username': username.trim().replaceAll('@', ''),
              if (displayName != null || username != null)
                'display_name': displayName ?? username,
              if (displayName != null || username != null)
                'full_name': displayName ?? username,
              if (phone != null) 'phone_number': phone,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
              'updated_at': DateTime.now().toIso8601String(),
            };
            if (isArtisanAccount) {
              userUpdates['role'] = 'Artisan';
            }
            if (userUpdates.length > 1) {
              await client
                  .from('users')
                  .update(userUpdates)
                  .ilike('email', cleanEmail);
            }
          } catch (e) {
            debugPrint('Supabase updateUserProfile users table note: $e');
          }

          // 2. Update or Insert Supabase Postgres 'artisan_profiles' table (Professional columns only, by user_id)
          if (isArtisanAccount || studioName != null || bio != null || craftCategory != null || toolsAndMaterials != null || experience != null) {
            try {
              final userRow = await client
                  .from('users')
                  .select('id, full_name, username')
                  .ilike('email', cleanEmail)
                  .maybeSingle();
              final String? effectiveUid =
                  userRow?['id']?.toString() ?? client.auth.currentUser?.id;
              if (effectiveUid != null) {
                final artisanUpdates = <String, dynamic>{
                  if (studioName != null && studioName.trim().isNotEmpty)
                    'studio_name': studioName.trim(),
                  if (bio != null) 'bio': bio,
                  if (experience != null && experience.trim().isNotEmpty) ...{
                    'experience': experience.trim(),
                    if (RegExp(r'\d+').firstMatch(experience) != null)
                      'years_experience': int.tryParse(RegExp(r'\d+').firstMatch(experience)!.group(0)!),
                  },
                  if (state != null) 'state': state,
                  if (address != null) 'address': address,
                  if (latitude != null) 'latitude': latitude,
                  if (longitude != null) 'longitude': longitude,
                  if (craftCategory != null) 'craft_category': craftCategory,
                  if (toolsAndMaterials != null) 'tags': toolsAndMaterials,
                  if (workshopCount != null) 'workshop_count': workshopCount,
                  'updated_at': DateTime.now().toIso8601String(),
                };
                if (artisanUpdates.isNotEmpty) {
                  final existingProfile = await client
                      .from('artisan_profiles')
                      .select('id, status')
                      .eq('user_id', effectiveUid)
                      .maybeSingle();

                  if (existingProfile != null) {
                    try {
                      await client
                          .from('artisan_profiles')
                          .update(artisanUpdates)
                          .eq('user_id', effectiveUid);
                    } catch (artisanErr) {
                      debugPrint('Direct artisan_profiles update note: $artisanErr');
                      if (artisanUpdates.containsKey('experience') || artisanUpdates.containsKey('workshop_count')) {
                        try {
                          final fallbackUpdates = Map<String, dynamic>.from(artisanUpdates)
                            ..remove('experience')
                            ..remove('workshop_count');
                          await client
                              .from('artisan_profiles')
                              .update(fallbackUpdates)
                              .eq('user_id', effectiveUid);
                        } catch (fallbackErr) {
                          debugPrint('Fallback artisan_profiles update note: $fallbackErr');
                        }
                      }
                    }
                  } else {
                    // CRITICAL FIX: The artisan_profiles row was missing!
                    // Insert new record so artisan data is NEVER silently dropped.
                    final newProfile = Map<String, dynamic>.from(artisanUpdates);
                    newProfile['user_id'] = effectiveUid;
                    newProfile['created_at'] = DateTime.now().toIso8601String();
                    newProfile['studio_name'] ??= studioName ?? displayName ?? username ?? userRow?['full_name'] ?? 'Artisan Studio';
                    newProfile['craft_category'] ??= craftCategory ?? 'Traditional Crafts';
                    newProfile['bio'] ??= bio ?? 'Master artisan dedicated to traditional Malaysian craft.';
                    newProfile['experience'] ??= experience ?? '10+ Years';
                    newProfile['address'] ??= address ?? state ?? 'Malaysia';
                    newProfile['state'] ??= state ?? 'Malaysia';
                    newProfile['status'] = 'APPROVED';
                    if (latitude != null) newProfile['latitude'] = latitude;
                    if (longitude != null) newProfile['longitude'] = longitude;
                    if (toolsAndMaterials != null) newProfile['tags'] = toolsAndMaterials;
                    if (workshopCount != null) newProfile['workshop_count'] = workshopCount;

                    try {
                      await client.from('artisan_profiles').insert(newProfile);
                    } catch (insertErr) {
                      debugPrint('Direct artisan_profiles insert note: $insertErr');
                      if (newProfile.containsKey('experience') || newProfile.containsKey('workshop_count')) {
                        try {
                          final fallbackProfile = Map<String, dynamic>.from(newProfile)
                            ..remove('experience')
                            ..remove('workshop_count');
                          await client.from('artisan_profiles').insert(fallbackProfile);
                        } catch (fallbackInsertErr) {
                          debugPrint('Fallback artisan_profiles insert note: $fallbackInsertErr');
                        }
                      }
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint(
                'Supabase updateUserProfile artisan_profiles table note: $e',
              );
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

    final updatedProfile = UserModel.fromMap(userRecord);
    await _saveAuthSession(updatedProfile);
    return updatedProfile;
  }

  Future<UserModel> submitRelocationRequest({
    required String email,
    required String address,
    required String state,
    required double latitude,
    required double longitude,
    required String reason,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 200));

    final relocData = <String, dynamic>{
      'pending_relocation_address': address.trim(),
      'pending_relocation_state': state.trim(),
      'pending_relocation_lat': latitude,
      'pending_relocation_lng': longitude,
      'pending_relocation_reason': reason.trim(),
      'pending_relocation_date': DateTime.now().toIso8601String(),
    };

    await _savePendingRelocation(cleanEmail, relocData);

    final userRecord = _userStore[cleanEmail] ?? <String, dynamic>{'email': cleanEmail};
    userRecord.addAll(relocData);
    _userStore[cleanEmail] = userRecord;

    final client = _client;
    if (client != null) {
      try {
        final uRow = await client
            .from('users')
            .select('id')
            .ilike('email', cleanEmail)
            .maybeSingle();
        final userId = uRow?['id']?.toString() ?? userRecord['id']?.toString();
        if (userId != null) {
          try {
            await client.from('artisan_profiles').update({
              'pending_relocation_address': address.trim(),
              'pending_relocation_state': state.trim(),
              'pending_relocation_lat': latitude,
              'pending_relocation_lng': longitude,
              'pending_relocation_reason': reason.trim(),
              'pending_relocation_date': relocData['pending_relocation_date'],
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('user_id', userId);
          } catch (e) {
            debugPrint('Supabase submitRelocationRequest table note: $e');
          }
          try {
            await client.from('users').update({
              'pending_relocation_address': address.trim(),
              'pending_relocation_state': state.trim(),
              'pending_relocation_lat': latitude,
              'pending_relocation_lng': longitude,
              'pending_relocation_reason': reason.trim(),
              'pending_relocation_date': relocData['pending_relocation_date'],
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', userId);
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Supabase submitRelocationRequest note: $e');
      }
    }

    final updatedModel = UserModel.fromMap(userRecord).copyWith(
      pendingRelocationAddress: address.trim(),
      pendingRelocationState: state.trim(),
      pendingRelocationLatitude: latitude,
      pendingRelocationLongitude: longitude,
      pendingRelocationReason: reason.trim(),
      pendingRelocationDate: relocData['pending_relocation_date'],
    );
    await _saveAuthSession(updatedModel);
    return updatedModel;
  }

  Future<UserModel> cancelRelocationRequest({required String email}) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 100));

    await _clearPendingRelocation(cleanEmail);

    final userRecord = _userStore[cleanEmail] ?? <String, dynamic>{'email': cleanEmail};
    userRecord.remove('pending_relocation_address');
    userRecord.remove('pending_relocation_state');
    userRecord.remove('pending_relocation_lat');
    userRecord.remove('pending_relocation_lng');
    userRecord.remove('pending_relocation_reason');
    userRecord.remove('pending_relocation_date');
    userRecord.remove('pendingRelocationAddress');
    userRecord.remove('pendingRelocationState');
    userRecord.remove('pendingRelocationLatitude');
    userRecord.remove('pendingRelocationLongitude');
    userRecord.remove('pendingRelocationReason');
    userRecord.remove('pendingRelocationDate');

    _userStore[cleanEmail] = userRecord;

    final client = _client;
    if (client != null) {
      try {
        final uRow = await client
            .from('users')
            .select('id')
            .ilike('email', cleanEmail)
            .maybeSingle();
        final userId = uRow?['id']?.toString() ?? userRecord['id']?.toString();
        if (userId != null) {
          try {
            await client.from('artisan_profiles').update({
              'pending_relocation_address': null,
              'pending_relocation_state': null,
              'pending_relocation_lat': null,
              'pending_relocation_lng': null,
              'pending_relocation_reason': null,
              'pending_relocation_date': null,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('user_id', userId);
          } catch (e) {
            debugPrint('Supabase cancelRelocationRequest table note: $e');
          }
          try {
            await client.from('users').update({
              'pending_relocation_address': null,
              'pending_relocation_state': null,
              'pending_relocation_lat': null,
              'pending_relocation_lng': null,
              'pending_relocation_reason': null,
              'pending_relocation_date': null,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', userId);
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Supabase cancelRelocationRequest note: $e');
      }
    }

    final updatedModel = UserModel.fromMap(userRecord).copyWith(
      clearPendingRelocation: true,
    );
    await _saveAuthSession(updatedModel);
    return updatedModel;
  }

  Future<UserModel> approveRelocationRequest({
    required String email,
    String? proposedAddress,
    String? proposedState,
    double? proposedLat,
    double? proposedLng,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 200));

    final relocData = await _getPendingRelocation(cleanEmail);
    final userRecord = _userStore[cleanEmail] ?? <String, dynamic>{'email': cleanEmail};
    String? newAddress = proposedAddress ?? relocData?['pending_relocation_address'] ?? userRecord['pending_relocation_address'] ?? userRecord['pendingRelocationAddress'];
    String? newState = proposedState ?? relocData?['pending_relocation_state'] ?? userRecord['pending_relocation_state'] ?? userRecord['pendingRelocationState'];
    dynamic newLat = proposedLat ?? relocData?['pending_relocation_lat'] ?? userRecord['pending_relocation_lat'] ?? userRecord['pendingRelocationLatitude'];
    dynamic newLng = proposedLng ?? relocData?['pending_relocation_lng'] ?? userRecord['pending_relocation_lng'] ?? userRecord['pendingRelocationLongitude'];

    final client = _client;
    String? resolvedUserId = userRecord['id']?.toString();

    // If newAddress is still null or userId not resolved, look up in Supabase directly
    if (client != null && (newAddress == null || resolvedUserId == null)) {
      try {
        final profileRes = await client
            .from('users')
            .select('id, address, state, artisan_profiles(*)')
            .ilike('email', cleanEmail)
            .maybeSingle();
        if (profileRes != null) {
          resolvedUserId ??= profileRes['id']?.toString();
          Map<String, dynamic>? ap;
          if (profileRes['artisan_profiles'] is Map) {
            ap = Map<String, dynamic>.from(profileRes['artisan_profiles']);
          } else if (profileRes['artisan_profiles'] is List && (profileRes['artisan_profiles'] as List).isNotEmpty) {
            ap = Map<String, dynamic>.from((profileRes['artisan_profiles'] as List).first);
          }
          newAddress ??= ap?['pending_relocation_address']?.toString() ?? profileRes['pending_relocation_address']?.toString();
          newState ??= ap?['pending_relocation_state']?.toString() ?? profileRes['pending_relocation_state']?.toString();
          newLat ??= ap?['pending_relocation_lat'] ?? profileRes['pending_relocation_lat'];
          newLng ??= ap?['pending_relocation_lng'] ?? profileRes['pending_relocation_lng'];
        }
      } catch (e) {
        debugPrint('Supabase pending relocation lookup note: $e');
      }
    }

    if (newAddress != null) userRecord['address'] = newAddress;
    if (newState != null) userRecord['state'] = newState;
    if (newLat != null) userRecord['latitude'] = newLat;
    if (newLng != null) userRecord['longitude'] = newLng;

    await _clearPendingRelocation(cleanEmail);

    userRecord.remove('pending_relocation_address');
    userRecord.remove('pending_relocation_state');
    userRecord.remove('pending_relocation_lat');
    userRecord.remove('pending_relocation_lng');
    userRecord.remove('pending_relocation_reason');
    userRecord.remove('pending_relocation_date');
    userRecord.remove('pendingRelocationAddress');
    userRecord.remove('pendingRelocationState');
    userRecord.remove('pendingRelocationLatitude');
    userRecord.remove('pendingRelocationLongitude');
    userRecord.remove('pendingRelocationReason');
    userRecord.remove('pendingRelocationDate');

    _userStore[cleanEmail] = userRecord;

    if (client != null) {
      try {
        if (resolvedUserId == null) {
          final uRow = await client
              .from('users')
              .select('id')
              .ilike('email', cleanEmail)
              .maybeSingle();
          resolvedUserId = uRow?['id']?.toString();
        }
        if (resolvedUserId != null) {
          final artisanUpdates = <String, dynamic>{
            if (newAddress != null) 'address': newAddress,
            if (newState != null) 'state': newState,
            if (newLat != null) 'latitude': newLat is num ? newLat : double.tryParse(newLat.toString()),
            if (newLng != null) 'longitude': newLng is num ? newLng : double.tryParse(newLng.toString()),
            'pending_relocation_address': null,
            'pending_relocation_state': null,
            'pending_relocation_lat': null,
            'pending_relocation_lng': null,
            'pending_relocation_reason': null,
            'pending_relocation_date': null,
            'updated_at': DateTime.now().toIso8601String(),
          };
          try {
            await client.from('artisan_profiles').update(artisanUpdates).eq('user_id', resolvedUserId);
          } catch (e) {
            debugPrint('artisan_profiles update note: $e');
            try {
              await client.from('artisan_profiles').update({
                if (newAddress != null) 'address': newAddress,
                if (newState != null) 'state': newState,
                if (newLat != null) 'latitude': newLat is num ? newLat : double.tryParse(newLat.toString()),
                if (newLng != null) 'longitude': newLng is num ? newLng : double.tryParse(newLng.toString()),
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('user_id', resolvedUserId);
            } catch (_) {}
          }

          // Also update public.users table
          final userUpdates = <String, dynamic>{
            if (newAddress != null) 'address': newAddress,
            if (newState != null) 'state': newState,
            'pending_relocation_address': null,
            'pending_relocation_state': null,
            'pending_relocation_lat': null,
            'pending_relocation_lng': null,
            'pending_relocation_reason': null,
            'pending_relocation_date': null,
            'updated_at': DateTime.now().toIso8601String(),
          };
          try {
            await client.from('users').update(userUpdates).eq('id', resolvedUserId);
          } catch (e) {
            try {
              await client.from('users').update({
                if (newAddress != null) 'address': newAddress,
                if (newState != null) 'state': newState,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', resolvedUserId);
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Supabase approveRelocationRequest note: $e');
      }
    }

    final updatedModel = UserModel.fromMap(userRecord).copyWith(
      address: newAddress,
      state: newState,
      latitude: newLat is num ? newLat.toDouble() : (newLat != null ? double.tryParse(newLat.toString()) : null),
      longitude: newLng is num ? newLng.toDouble() : (newLng != null ? double.tryParse(newLng.toString()) : null),
      clearPendingRelocation: true,
    );
    await _saveAuthSession(updatedModel);
    return updatedModel;
  }

  Future<UserModel> rejectRelocationRequest({required String email, String? feedback}) async {
    return cancelRelocationRequest(email: email);
  }

  Future<List<Map<String, dynamic>>> getPendingArtisans() async {
    final List<Map<String, dynamic>> results = [];
    final client = _client;
    if (client != null) {
      try {
        dynamic res;
        try {
          res = await client
              .from('users')
              .select(
                '*, artisan_profiles!artisan_profiles_user_id_fkey(*, artisan_documents(*))',
              )
              .ilike('status', '%PENDING%');
        } catch (_) {
          try {
            res = await client
                .from('users')
                .select('*, artisan_profiles(*, artisan_documents(*))')
                .ilike('status', '%PENDING%');
          } catch (_) {
            res = await client
                .from('users')
                .select()
                .ilike('status', '%PENDING%');
          }
        }
        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            final rowMap = Map<String, dynamic>.from(row);
            Map<String, dynamic>? ap;
            if (rowMap['artisan_profiles'] is Map) {
              ap = Map<String, dynamic>.from(rowMap['artisan_profiles']);
            } else if (rowMap['artisan_profiles'] is List &&
                (rowMap['artisan_profiles'] as List).isNotEmpty) {
              ap = Map<String, dynamic>.from(
                (rowMap['artisan_profiles'] as List).first,
              );
            }

            if (ap != null) {
              rowMap['studio_name'] ??= ap['studio_name'];
              rowMap['craft_category'] ??= ap['craft_category'];
              rowMap['ssm_number'] ??= ap['ssm_number'];
              rowMap['bio'] ??= ap['bio'];
              rowMap['state'] ??= ap['state'] ?? ap['address'];
              rowMap['experience'] ??= (ap['experience'] != null && ap['experience'].toString().trim().isNotEmpty)
                  ? ap['experience'].toString().trim()
                  : (ap['years_experience'] != null && (ap['years_experience'] as num) > 1
                      ? '${ap['years_experience']} years experience'
                      : null);

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
                if (certFileName != null)
                  rowMap['cert_file_name'] = certFileName;
                if (certFileUrl != null) rowMap['cert_file_url'] = certFileUrl;

                // fallback the avatar if users.avatar_url is empty
                if ((rowMap['avatar_url'] == null ||
                        rowMap['avatar_url'].toString().isEmpty) &&
                    avatarUrl != null) {
                  rowMap['imageUrl'] = avatarUrl;
                }
              }
            }

            final userStatus = (rowMap['status'] ?? '').toString().toUpperCase();
            // Use artisan_profiles.status as the authoritative source for artisan state.
            // users.artisan_status can lag (e.g. admin cache set it to REJECTED but
            // user has since re-applied and artisan_profiles is now PENDING_APPROVAL).
            final apStatus = (ap?['status'] ?? '').toString().toUpperCase();

            // Strictly exclude any rejected, approved, or closed applications
            // but trust artisan_profiles.status over users.artisan_status.
            if (userStatus == 'REJECTED' ||
                apStatus == 'REJECTED' ||
                apStatus == 'APPROVED' ||
                apStatus == 'CLOSED') {
              continue;
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
      final artisanStatus = (user['artisan_status'] ?? user['artisanStatus'] ?? '').toString().toUpperCase();

      if (status == 'REJECTED' ||
          artisanStatus == 'REJECTED' ||
          artisanStatus == 'APPROVED' ||
          artisanStatus == 'CLOSED') {
        continue;
      }

      if (status.contains('PENDING') || artisanStatus.contains('PENDING')) {
        final userEmail = (user['email'] ?? entry.key).toString().toLowerCase();
        if (!results.any(
          (r) => (r['email'] ?? '').toString().toLowerCase() == userEmail,
        )) {
          results.add(Map<String, dynamic>.from(user));
        }
      }
    }

    // Note: Do NOT purge based on _userStore here. The DB query already
    // filters to users WHERE status ILIKE '%PENDING%', so any row that
    // came from the DB is authoritative. The _userStore may be stale
    // (e.g. admin's cache still shows REJECTED for a user who has since
    // re-applied), which would incorrectly exclude legitimate re-applications.

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
              .neq('status', 'PENDING_APPROVAL')
              .neq('status', 'DELETED');
        } catch (_) {
          try {
            res = await client
                .from('users')
                .select('*, artisan_profiles(*)')
                .ilike('role', '%Artisan%')
                .neq('status', 'PENDING_APPROVAL')
                .neq('status', 'DELETED');
          } catch (_) {
            res = await client
                .from('users')
                .select()
                .ilike('role', '%Artisan%')
                .neq('status', 'PENDING_APPROVAL')
                .neq('status', 'DELETED');
          }
        }

        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            final rowMap = Map<String, dynamic>.from(row);
            final rowStatus = (rowMap['status'] ?? '').toString().toUpperCase();
            if (rowStatus == 'DELETED') continue;

            if (rowMap['artisan_profiles'] == null ||
                (rowMap['artisan_profiles'] is List && (rowMap['artisan_profiles'] as List).isEmpty)) {
              try {
                final ap = await client
                    .from('artisan_profiles')
                    .select()
                    .eq('user_id', rowMap['id'])
                    .maybeSingle();
                if (ap != null) rowMap['artisan_profiles'] = ap;
              } catch (_) {}
            }

            final a = ActiveArtisanMaster.fromMap(rowMap);
            if (a.email.toLowerCase().startsWith('deleted_')) continue;
            if (_deletedAccounts.contains(a.email.toLowerCase())) continue;
            results.add(a);
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
      final isSuspended = user['isSuspended'] == true;
      final reason = (user['suspensionReason'] ?? '').toString();
      if (status == 'DELETED' || (isSuspended && reason == 'ACCOUNT_DELETED')) {
        continue;
      }
      final email = (user['email'] ?? entry.key).toString().toLowerCase();
      if (_deletedAccounts.contains(email) || email.startsWith('deleted_')) {
        continue;
      }
      final existingIdx = results.indexWhere((a) => a.email.toLowerCase() == email);
      if (role.contains('Artisan') && !status.contains('PENDING')) {
        if (existingIdx == -1) {
          results.add(
            ActiveArtisanMaster.fromMap(Map<String, dynamic>.from(user)),
          );
        } else {
          final existing = results[existingIdx];
          if ((existing.experience == 'Verified Studio' || existing.experience.isEmpty) &&
              user['experience'] != null &&
              user['experience'].toString().trim().isNotEmpty) {
            results[existingIdx] = existing.copyWith(
              experience: user['experience'].toString().trim(),
            );
          }
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
              .select('*, artisan_profiles!artisan_profiles_user_id_fkey(*, artisan_documents(*))')
              .neq('status', 'DELETED')
              .order('created_at', ascending: false);
        } catch (_) {
          try {
            res = await client
                .from('users')
                .select('*, artisan_profiles(*, artisan_documents(*))')
                .neq('status', 'DELETED')
                .order('created_at', ascending: false);
          } catch (_) {
            res = await client
                .from('users')
                .select()
                .neq('status', 'DELETED')
                .order('created_at', ascending: false);
          }
        }

        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            final rowMap = Map<String, dynamic>.from(row);
            if (rowMap['artisan_profiles'] == null ||
                (rowMap['artisan_profiles'] is List && (rowMap['artisan_profiles'] as List).isEmpty)) {
              try {
                final ap = await client
                    .from('artisan_profiles')
                    .select('*, artisan_documents(*)')
                    .eq('user_id', rowMap['id'])
                    .maybeSingle();
                if (ap != null) rowMap['artisan_profiles'] = ap;
              } catch (_) {}
            }

            final u = UserModel.fromMap(rowMap);
            if (u.status.toUpperCase() == 'DELETED') continue;
            if (u.email.toLowerCase().startsWith('deleted_')) continue;
            if (_deletedAccounts.contains(u.email.toLowerCase())) continue;
            results.add(u);
          }
        }
      } catch (e) {
        debugPrint('Supabase getAllUsers note: $e');
      }
    }

    // Merge in-memory users
    for (final entry in _userStore.entries) {
      final user = entry.value;
      final status = (user['status'] ?? '').toString().toUpperCase();
      final isSuspended = user['isSuspended'] == true;
      final reason = (user['suspensionReason'] ?? '').toString();
      if (status == 'DELETED' || (isSuspended && reason == 'ACCOUNT_DELETED')) {
        continue;
      }
      final email = (user['email'] ?? entry.key).toString().toLowerCase();
      if (_deletedAccounts.contains(email) || email.startsWith('deleted_')) {
        continue;
      }
      final existingIdx = results.indexWhere((u) => u.email.toLowerCase() == email);
      if (existingIdx == -1) {
        results.add(UserModel.fromMap(Map<String, dynamic>.from(user)));
      } else {
        final existing = results[existingIdx];
        if (existing.experience == null && user['experience'] != null) {
          results[existingIdx] = existing.copyWith(
            experience: user['experience'].toString().trim(),
          );
        }
      }
    }

    // Merge pending relocations into results
    for (int i = 0; i < results.length; i++) {
      results[i] = await _enrichUserWithPendingRelocation(results[i]);
    }

    return results;
  }

  Future<void> updateArtisanStatusInDb({
    required String email,
    required String newStatus,
    required String newRole,
    bool updateArtisanProfileOnly = false,
    String? suspensionReason,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final resolvedArtisanStatus = (newStatus.toUpperCase() == 'ACTIVE' ||
            newStatus.toUpperCase() == 'APPROVED')
        ? 'APPROVED'
        : newStatus;
    if (_userStore.containsKey(cleanEmail)) {
      if (updateArtisanProfileOnly) {
        _userStore[cleanEmail]!['artisanStatus'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['artisan_status'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['status'] = 'ACTIVE';
        _userStore[cleanEmail]!['isSuspended'] = false;
        _userStore[cleanEmail]!['suspensionReason'] = null;
        _userStore[cleanEmail]!['suspension_reason'] = null;
        if (newRole.isNotEmpty) {
          _userStore[cleanEmail]!['role'] = newRole;
        }
      } else {
        _userStore[cleanEmail]!['status'] = newStatus;
        _userStore[cleanEmail]!['artisanStatus'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['artisan_status'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['role'] = newRole;
        _userStore[cleanEmail]!['isSuspended'] = (newStatus == 'SUSPENDED');
        if (newStatus == 'SUSPENDED') {
          _userStore[cleanEmail]!['suspensionReason'] = suspensionReason;
          _userStore[cleanEmail]!['suspension_reason'] = suspensionReason;
        } else {
          _userStore[cleanEmail]!['suspensionReason'] = null;
          _userStore[cleanEmail]!['suspension_reason'] = null;
        }
        if (newRole == 'Artisan') {
          _userStore[cleanEmail]!['roles'] = ['Artisan'];
        } else if (newRole == 'Tourist') {
          _userStore[cleanEmail]!['roles'] = ['Tourist'];
        }
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final rawUser = prefs.getString(_keyAuthUser);
        if (rawUser != null && rawUser.isNotEmpty) {
          final map = jsonDecode(rawUser) as Map<String, dynamic>;
          if ((map['email'] as String?)?.toLowerCase() == cleanEmail) {
            if (updateArtisanProfileOnly) {
              map['artisanStatus'] = resolvedArtisanStatus;
              map['artisan_status'] = resolvedArtisanStatus;
              map['status'] = 'ACTIVE';
              map['isSuspended'] = false;
              map['suspensionReason'] = null;
              map['suspension_reason'] = null;
              if (newRole.isNotEmpty) {
                map['role'] = newRole;
              }
            } else {
              map['status'] = newStatus;
              map['artisanStatus'] = resolvedArtisanStatus;
              map['artisan_status'] = resolvedArtisanStatus;
              map['isSuspended'] = (newStatus == 'SUSPENDED');
              if (newStatus == 'SUSPENDED') {
                map['suspensionReason'] = suspensionReason;
                map['suspension_reason'] = suspensionReason;
              } else {
                map['suspensionReason'] = null;
                map['suspension_reason'] = null;
              }
              if (newRole.isNotEmpty) {
                map['role'] = newRole;
              }
            }
            await prefs.setString(_keyAuthUser, jsonEncode(map));
          }
        }
      } catch (e) {
        debugPrint('updateArtisanStatusInDb local sync note: $e');
      }
    }

    final client = _client;
    if (client != null) {
      // Always call the SECURITY DEFINER RPC – it bypasses RLS and can upsert
      // artisan_profiles rows even when the authenticated user is a Tourist.
      // For tourist-upgrade rejections (updateArtisanProfileOnly=true), we
      // pass p_status as the artisan_status value ('REJECTED') but keep the
      // user's DB role as Tourist and their account status as ACTIVE via the
      // direct table update below.
      try {
        final rpcStatus = updateArtisanProfileOnly ? newStatus : newStatus;
        final rpcRole = updateArtisanProfileOnly ? newRole : newRole;
        // Fetch cached studio info to seed the artisan_profiles upsert
        final cached = _userStore[cleanEmail];
        final studioName = cached?['studioName'] ?? cached?['studio_name'];
        final craftCategory = cached?['craftCategory'] ?? cached?['craft_category'];
        final ssmNumber = cached?['ssmNumber'] ?? cached?['ssm_number'];
        final rpcParams = <String, dynamic>{
          'p_email': cleanEmail,
          'p_status': rpcStatus,
          'p_role': rpcRole,
          'p_studio_name': studioName,
          'p_craft_category': craftCategory,
          'p_ssm_number': ssmNumber,
        };
        await client.rpc('admin_update_user_status', params: rpcParams);
        debugPrint('Supabase RPC admin_update_user_status succeeded for $cleanEmail');
        // For tourist-upgrade rejections the RPC sets users.status=REJECTED
        // which would lock out the tourist account. Fix it back to ACTIVE now.
        if (updateArtisanProfileOnly) {
          try {
            await client
                .from('users')
                .update({
                  'status': 'ACTIVE',
                  'role': newRole,
                  'artisan_status': newStatus,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .ilike('email', cleanEmail);
          } catch (fixErr) {
            debugPrint('Tourist status fix note: $fixErr');
          }
        }
      } catch (rpcError) {
        debugPrint('Supabase RPC admin_update_user_status note: $rpcError');
      }

      // 2. Direct Table Updates Fallback
      try {
        if (!updateArtisanProfileOnly) {
          final updatePayload = <String, dynamic>{
            'status': newStatus,
            'role': newRole,
            'artisan_status': resolvedArtisanStatus,
            'updated_at': DateTime.now().toIso8601String(),
          };
          try {
            await client
                .from('users')
                .update(updatePayload)
                .ilike('email', cleanEmail);
          } catch (updateErr) {
            debugPrint('Direct user table update note: $updateErr');
          }
        } else {
          // When updateArtisanProfileOnly is true (e.g. tourist whose artisan request was rejected),
          // ensure users.status is ACTIVE and users.role is updated (e.g. Tourist) so they don't remain PENDING_APPROVAL
          final userUpdate = <String, dynamic>{
            'status': 'ACTIVE',
            'updated_at': DateTime.now().toIso8601String(),
          };
          if (newRole.isNotEmpty) {
            userUpdate['role'] = newRole;
          }
          final resolvedUserArtisanStatus = (newStatus.toUpperCase() == 'ACTIVE' ||
                  newStatus.toUpperCase() == 'APPROVED')
              ? 'APPROVED'
              : newStatus;
          try {
            await client
                .from('users')
                .update({
                  ...userUpdate,
                  'artisan_status': resolvedUserArtisanStatus,
                })
                .ilike('email', cleanEmail);
          } catch (_) {
            try {
              await client
                  .from('users')
                  .update(userUpdate)
                  .ilike('email', cleanEmail);
            } catch (err) {
              debugPrint('Direct user table active sync note: $err');
            }
          }
        }

        // Update artisan_profiles status matching user_id
        final userRow = await client
            .from('users')
            .select('id')
            .ilike('email', cleanEmail)
            .maybeSingle();
        if (userRow != null && userRow['id'] != null) {
          final artisanProfileBeforeUpdate = await client
              .from('artisan_profiles')
              .select('id, status, studio_name, craft_category')
              .eq('user_id', userRow['id'])
              .maybeSingle();
          final artisanStatus =
              (newStatus.toUpperCase() == 'ACTIVE' ||
                  newStatus.toUpperCase() == 'APPROVED')
              ? 'APPROVED'
              : newStatus;
          if (artisanProfileBeforeUpdate != null) {
            try {
              await client
                  .from('artisan_profiles')
                  .update({
                    'status': artisanStatus,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('user_id', userRow['id']);
            } catch (updErr) {
              debugPrint('Direct artisan_profiles update note: $updErr');
            }
          } else {
            try {
              final cached = _userStore[cleanEmail];
              await client.from('artisan_profiles').insert({
                'user_id': userRow['id'],
                'status': artisanStatus,
                'studio_name': cached?['studioName'] ?? cached?['studio_name'] ?? 'Heritage Studio',
                'craft_category': cached?['craftCategory'] ?? cached?['craft_category'] ?? 'Traditional Craft',
                if (cached?['ssmNumber'] != null || cached?['ssm_number'] != null)
                  'ssm_number': cached?['ssmNumber'] ?? cached?['ssm_number'],
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            } catch (insErr) {
              debugPrint('Direct artisan_profiles insert note (RLS): $insErr');
            }
          }

          // The RPC above may already have changed the profile to APPROVED.
          // Always reconcile the quest and its system tasks when approving so
          // the flow is idempotent: artisan -> quest -> default tasks.
          if (artisanStatus == 'APPROVED' &&
              artisanProfileBeforeUpdate != null) {
            final artisanProfileId = artisanProfileBeforeUpdate['id']
                .toString();
            final studioName =
                artisanProfileBeforeUpdate['studio_name']?.toString().trim() ??
                'Heritage Workshop';
            final craftCategory =
                artisanProfileBeforeUpdate['craft_category']
                    ?.toString()
                    .trim() ??
                'Malaysian craft';

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
                .update({
                  'title': '$studioName Quest',
                  'category': 'Demonstration & Lore',
                  'description':
                      'Visit $studioName and experience the heritage of $craftCategory.',
                  'status': 'APPROVED',
                })
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

              for (final questId in questIds) {
                final existingSystemTasks = List<Map<String, dynamic>>.from(
                  await client
                      .from('heritage_tasks')
                      .select('id, title, sort_order, is_system_task')
                      .eq('quest_id', questId)
                      .inFilter('sort_order', const [1, 2]),
                );

                final defaultTasks = <Map<String, dynamic>>[
                  {
                    'title': 'Go to the workshop',
                    'sort_order': 1,
                    'xp_reward': 50,
                  },
                  {
                    'title': 'Stay for 15 minutes',
                    'sort_order': 2,
                    'xp_reward': 50,
                  },
                ];

                for (final defaultTask in defaultTasks) {
                  final sortOrder = defaultTask['sort_order'] as int;
                  final matchingTasks = existingSystemTasks.where(
                    (task) =>
                        task['title'] == defaultTask['title'] ||
                        (task['is_system_task'] == true &&
                            task['sort_order'] == sortOrder),
                  );

                  if (matchingTasks.isEmpty) {
                    await client.from('heritage_tasks').insert({
                      'quest_id': questId,
                      'title': defaultTask['title'],
                      'is_required': true,
                      'xp_reward': defaultTask['xp_reward'],
                      'sort_order': sortOrder,
                      'status': 'APPROVED',
                      'is_system_task': true,
                      'is_archived': false,
                      ...reviewPayload,
                    });
                  } else {
                    for (final task in matchingTasks) {
                      await client
                          .from('heritage_tasks')
                          .update({
                            'title': defaultTask['title'],
                            'is_required': true,
                            'xp_reward': defaultTask['xp_reward'],
                            'sort_order': sortOrder,
                            'is_system_task': true,
                            'is_archived': false,
                            ...reviewPayload,
                          })
                          .eq('id', task['id']);
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Supabase direct updateArtisanStatusInDb note: $e');
      }
    }
  }

  Future<void> signOut() async {
    _recoveryAccessToken = null;
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

  Future<UserModel> deactivateArtisanStudio() async {
    final client = _client;
    if (client != null) {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw const AuthException('No active user session found. Please sign in again.');
      }
      final userId = currentUser.id;
      final email = currentUser.email?.toLowerCase() ?? '';

      // 1. Try dedicated PostgreSQL RPC if available
      try {
        await client.rpc('deactivate_artisan_studio', params: {'p_user_id': userId});
      } catch (rpcErr) {
        debugPrint('deactivate_artisan_studio RPC note: $rpcErr');
      }

      // 2. Query artisan_profiles ID for attached records cleanup
      String? artisanProfileId;
      try {
        final apRow = await client
            .from('artisan_profiles')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        artisanProfileId = apRow?['id']?.toString();
      } catch (e) {
        debugPrint('deactivateArtisanStudio apRow lookup note: $e');
      }

      // 3. Clean up attached documents and retire quests
      if (artisanProfileId != null) {
        try {
          await client.from('artisan_documents').delete().eq('artisan_id', artisanProfileId);
        } catch (e) {
          debugPrint('deactivateArtisanStudio artisan_documents note: $e');
        }
        try {
          await client.from('quests').update({'status': 'RETIRED'}).eq('artisan_id', artisanProfileId);
        } catch (e) {
          debugPrint('deactivateArtisanStudio quests retire note: $e');
        }
      }

      // 4. Mark artisan_profiles as CLOSED and attempt delete
      try {
        await client.from('artisan_profiles').update({
          'status': 'CLOSED',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      } catch (e) {
        debugPrint('deactivateArtisanStudio artisan_profiles status update note: $e');
      }
      try {
        await client.from('artisan_profiles').delete().eq('user_id', userId);
      } catch (e) {
        debugPrint('deactivateArtisanStudio artisan_profiles delete note: $e');
      }

      // 5. Demote user role in public.users to Tourist and clear artisan_status
      final updateMap = {
        'role': 'Tourist',
        'artisan_status': 'CLOSED',
        'status': 'ACTIVE',
        'updated_at': DateTime.now().toIso8601String(),
      };
      try {
        await client.from('users').update(updateMap).eq('id', userId);
      } catch (e) {
        debugPrint('deactivateArtisanStudio public.users update note: $e');
      }

      // 6. Invoke admin_update_user_status RPC to sync role securely
      try {
        await client.rpc('admin_update_user_status', params: {
          'p_email': email,
          'p_status': 'ACTIVE',
          'p_role': 'Tourist',
          'p_studio_name': null,
          'p_craft_category': null,
          'p_ssm_number': null,
        });
      } catch (rpcErr) {
        debugPrint('deactivateArtisanStudio admin_update_user_status RPC note: $rpcErr');
      }

      // 7. Update auth metadata
      try {
        await client.auth.updateUser(
          UserAttributes(
            data: {
              'role': 'Tourist',
              'roles': ['Tourist'],
              'artisan_status': 'CLOSED',
              'status': 'ACTIVE',
            },
          ),
        );
      } catch (e) {
        debugPrint('deactivateArtisanStudio auth.updateUser note: $e');
      }

      // 8. Update in-memory user store if present
      if (_userStore.containsKey(email)) {
        _userStore[email]!['role'] = 'Tourist';
        _userStore[email]!['roles'] = ['Tourist'];
        _userStore[email]!['studio_name'] = null;
        _userStore[email]!['craft_category'] = null;
        _userStore[email]!['ssm_number'] = null;
        _userStore[email]!['is_approved_artisan'] = false;
        _userStore[email]!['artisan_status'] = 'CLOSED';
        _userStore[email]!['is_live_open'] = false;
      }

      // 9. Reload and save updated authenticated profile
      var updatedUser = await _loadAuthenticatedProfile();
      updatedUser = updatedUser.copyWith(
        role: 'Tourist',
        roles: const ['Tourist'],
        status: 'ACTIVE',
        artisanStatus: 'CLOSED',
        clearStudioDetails: true,
      );
      await _saveAuthSession(updatedUser);
      return updatedUser;
    }

    // Offline / unit test branch
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_keyAuthUser);
    if (rawUser != null && rawUser.isNotEmpty) {
      final map = jsonDecode(rawUser) as Map<String, dynamic>;
      map['role'] = 'Tourist';
      map['roles'] = ['Tourist'];
      map['status'] = 'ACTIVE';
      map['studio_name'] = null;
      map['craft_category'] = null;
      map['ssm_number'] = null;
      map['bio'] = null;
      map['artisan_profiles'] = null;
      map['is_approved_artisan'] = false;
      map['artisan_status'] = 'CLOSED';
      map['is_live_open'] = false;
      final email = (map['email'] ?? '').toString().toLowerCase();
      if (_userStore.containsKey(email)) {
        _userStore[email]!['role'] = 'Tourist';
        _userStore[email]!['roles'] = ['Tourist'];
        _userStore[email]!['status'] = 'ACTIVE';
        _userStore[email]!['studio_name'] = null;
        _userStore[email]!['craft_category'] = null;
        _userStore[email]!['ssm_number'] = null;
        _userStore[email]!['bio'] = null;
        _userStore[email]!['artisan_profiles'] = null;
        _userStore[email]!['is_approved_artisan'] = false;
        _userStore[email]!['artisan_status'] = 'CLOSED';
        _userStore[email]!['is_live_open'] = false;
      }
      final updated = UserModel.fromMap(map);
      await _saveAuthSession(updated);
      return updated;
    }
    throw const AuthException('No local authenticated session to update.');
  }

  Future<void> deleteAccount({
    required String userId,
    required String email,
    String? username,
    String? password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanEmail = email.trim().toLowerCase();

    // 0. If password is provided, verify credentials with Supabase
    final client = _client;
    if (client != null && password != null && password.trim().isNotEmpty) {
      try {
        await client.auth.signInWithPassword(
          email: cleanEmail,
          password: password.trim(),
        );
      } on AuthException catch (_) {
        throw const AuthException(
          'Incorrect password. Please check your password and try again.',
        );
      }
    }

    // 1. Delete or deactivate in Supabase if connected
    if (client != null) {
      final effectiveUserId = userId.isNotEmpty
          ? userId
          : (client.auth.currentUser?.id ?? '');

      try {
        // Query username from database if not known
        if (username == null || username.trim().isEmpty) {
          try {
            final row = await client
                .from('users')
                .select('username')
                .eq('id', effectiveUserId)
                .maybeSingle();
            final dbUname = (row?['username'] as String?)?.trim();
            if (dbUname != null && dbUname.isNotEmpty) {
              await _recordDeletedUsername(dbUname);
            }
          } catch (_) {}
        }

        // A. Try admin_update_user_status RPC (SECURITY DEFINER, updates users & auth.users metadata)
        try {
          await client.rpc('admin_update_user_status', params: {
            'p_email': cleanEmail,
            'p_status': 'DELETED',
          });
        } catch (rpcErr) {
          debugPrint('admin_update_user_status RPC note: $rpcErr');
        }

        // B. Try delete_user_account RPC if present
        bool rpcDeleted = false;
        if (effectiveUserId.isNotEmpty) {
          try {
            final rpcRes = await client.rpc(
              'delete_user_account',
              params: {'p_user_id': effectiveUserId},
            );
            if (rpcRes is Map && rpcRes['success'] == true) {
              rpcDeleted = true;
            }
          } catch (rpcErr) {
            debugPrint('delete_user_account RPC note: $rpcErr');
          }
        }

        // C. Clean up artisan profile record
        if (effectiveUserId.isNotEmpty) {
          try {
            await client
                .from('artisan_profiles')
                .delete()
                .eq('user_id', effectiveUserId);
          } catch (e) {
            debugPrint('deleteAccount artisan_profiles note: $e');
          }
        }

        // D. Try direct DELETE on public.users table if not already deleted by RPC
        bool usersDeleted = false;
        if (!rpcDeleted && effectiveUserId.isNotEmpty) {
          try {
            await client
                .from('users')
                .delete()
                .eq('id', effectiveUserId);
            usersDeleted = true;
            debugPrint('deleteAccount direct users delete succeeded');
          } catch (delErr) {
            debugPrint('deleteAccount direct users delete note: $delErr');
          }
        }

        // E. Fallback: If row could not be deleted, update & anonymize to free original email and username
        if (!rpcDeleted && !usersDeleted) {
          try {
            final ts = DateTime.now().millisecondsSinceEpoch;
            final anonEmail =
                'deleted_${effectiveUserId.isNotEmpty ? effectiveUserId : cleanEmail}_$ts@deleted.local';
            final anonUsername =
                'deleted_${effectiveUserId.isNotEmpty ? effectiveUserId : cleanEmail}_$ts';

            final updateData = {
              'status': 'DELETED',
              'email': anonEmail,
              'username': anonUsername,
              'is_suspended': true,
              'suspension_reason': 'ACCOUNT_DELETED',
              'updated_at': DateTime.now().toIso8601String(),
            };
            if (effectiveUserId.isNotEmpty) {
              await client
                  .from('users')
                  .update(updateData)
                  .eq('id', effectiveUserId);
            } else if (cleanEmail.isNotEmpty) {
              await client
                  .from('users')
                  .update(updateData)
                  .ilike('email', cleanEmail);
            }
          } catch (updateErr) {
            debugPrint('deleteAccount direct users update note: $updateErr');
          }
        }

        // F. Update Supabase Auth user metadata ONLY if user was not deleted from auth.users
        if (!rpcDeleted) {
          try {
            await client.auth.updateUser(
              UserAttributes(
                data: {
                  'status': 'DELETED',
                  'is_deleted': true,
                },
              ),
            );
          } catch (metaErr) {
            debugPrint('deleteAccount auth.updateUser note: $metaErr');
          }
        }

        // G. Sign out Supabase auth session
        try {
          await client.auth.signOut();
        } catch (e) {
          debugPrint('Supabase deleteAccount auth.signOut note: $e');
        }
      } catch (e) {
        debugPrint('Supabase deleteAccount general note: $e');
      }
    }

    // 2. Record in persistent deleted accounts and usernames store
    await _recordDeletedAccount(cleanEmail);
    if (username != null && username.trim().isNotEmpty) {
      await _recordDeletedUsername(username);
    }
    final inMemoryUsername =
        (_userStore[cleanEmail]?['username'] as String?)?.trim();
    if (inMemoryUsername != null && inMemoryUsername.isNotEmpty) {
      await _recordDeletedUsername(inMemoryUsername);
    }

    // 3. Remove user from local in-memory store
    _userStore.remove(cleanEmail);
    _userStore.removeWhere(
      (key, value) =>
          key.toLowerCase() == cleanEmail ||
          (userId.isNotEmpty && value['id'] == userId),
    );

    // 4. Clear any pending OTPs or reset tokens for this account
    _recoveryAccessToken = null;

    // 5. Clear local session from SharedPreferences
    await _clearAuthSession();
  }

  // --- Directory Services ---

  Future<List<ArtisanModel>> fetchArtisans() async {
    final client = _client;
    if (client == null) throw StateError('Supabase is not initialized.');

    try {
      debugPrint('Fetching artisans from Supabase...');
      final response = await client
          .from('artisan_profiles')
          .select(
            '*, users(full_name, avatar_url), artisan_documents(file_url, doc_type)',
          )
          .eq('status', 'APPROVED');

      debugPrint('Supabase response: $response');
      final prefs = await SharedPreferences.getInstance();
      final list = List<Map<String, dynamic>>.from(response);
      final mapped = list.map((map) {
        final profileId = map['id']?.toString() ?? '';
        final userId = map['user_id']?.toString() ?? '';
        final savedLive = prefs.getBool('artisan_live_open_$profileId') ??
            prefs.getBool('artisan_live_open_$userId');
        if (savedLive != null) {
          map['is_live_open'] = savedLive;
        }
        final savedWorkshops = prefs.getInt('artisan_workshop_count_$profileId') ??
            prefs.getInt('artisan_workshop_count_$userId');
        if (savedWorkshops != null) {
          map['workshop_count'] = savedWorkshops;
        }
        final savedSsm = prefs.getString('artisan_ssm_$profileId') ??
            prefs.getString('artisan_ssm_$userId');
        if (savedSsm != null && savedSsm.isNotEmpty && (map['ssm_number'] == null || map['ssm_number'].toString().isEmpty)) {
          map['ssm_number'] = savedSsm;
        }
        return ArtisanModel.fromMap(map);
      }).toList();
      debugPrint('Mapped artisans count: ${mapped.length}');
      return mapped;
    } catch (e) {
      debugPrint('Error fetching artisans from Supabase: $e');
      return [];
    }
  }

  Future<Map<String, String>?> uploadArtisanDocument(
    String artisanId,
    PlatformFile file,
    String docType,
  ) async {
    try {
      final client = _client;
      if (client == null) return null;

      Uint8List bytes;
      if (file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      } else {
        bytes = await file.readAsBytes();
      }

      final bucket = docType == 'STUDIO_PHOTO' || docType == 'PORTFOLIO_IMAGE'
          ? 'artisan_public_media'
          : 'artisan_private_docs';
      final folder = '$artisanId/$docType';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
      String finalFileName = fileName;
      String mimeType = 'application/octet-stream';

      final lcName = file.name.toLowerCase();
      if (lcName.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (lcName.endsWith('.png') ||
          lcName.endsWith('.jpg') ||
          lcName.endsWith('.jpeg')) {
        try {
          final compressed = await FlutterImageCompress.compressWithList(
            bytes,
            format: CompressFormat.webp,
            quality: 85,
          );

          if (compressed.isNotEmpty) {
            bytes = compressed;
            mimeType = 'image/webp';
            final lastDot = finalFileName.lastIndexOf('.');
            if (lastDot != -1) {
              finalFileName = finalFileName.substring(0, lastDot) + '.webp';
            } else {
              finalFileName += '.webp';
            }
          } else {
            if (lcName.endsWith('.png'))
              mimeType = 'image/png';
            else
              mimeType = 'image/jpeg';
          }
        } catch (e) {
          debugPrint('WebP conversion failed: $e');
          if (lcName.endsWith('.png'))
            mimeType = 'image/png';
          else
            mimeType = 'image/jpeg';
        }
      }

      final path = '$folder/$finalFileName';

      await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      final url = client.storage.from(bucket).getPublicUrl(path);

      // Update DB
      await client.from('artisan_documents').insert({
        'artisan_id': artisanId,
        'doc_type': docType,
        'file_name': finalFileName,
        'file_url': url,
      });

      return {'url': url, 'name': finalFileName};
    } catch (e) {
      debugPrint('Error uploading doc: $e');
      return null;
    }
  }

  Future<String?> uploadUserAvatar(
    String userIdOrEmail,
    PlatformFile file,
  ) async {
    try {
      final client = _client;
      Uint8List bytes;
      if (file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      } else {
        bytes = await file.readAsBytes();
      }

      final lcName = file.name.toLowerCase();
      String mimeType = 'image/jpeg';
      if (lcName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lcName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      try {
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          format: CompressFormat.webp,
          quality: 85,
        );
        if (compressed.isNotEmpty) {
          bytes = compressed;
          mimeType = 'image/webp';
        }
      } catch (e) {
        debugPrint('Avatar WebP conversion note: $e');
      }

      if (client == null) {
        final base64Str = base64Encode(bytes);
        final localDataUrl = 'data:$mimeType;base64,$base64Str';
        return localDataUrl;
      }

      const bucket = 'artisan_public_media';
      final cleanId = userIdOrEmail.replaceAll('@', '_').replaceAll('.', '_');
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.webp';
      final path = 'avatars/$cleanId/$fileName';

      await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final url = client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Error uploading user avatar: $e');
      try {
        Uint8List bytes;
        if (file.path != null) {
          bytes = await io.File(file.path!).readAsBytes();
        } else {
          bytes = await file.readAsBytes();
        }
        final base64Str = base64Encode(bytes);
        final mime = file.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
        return 'data:$mime;base64,$base64Str';
      } catch (_) {}
      return null;
    }
  }

  Future<bool> deleteArtisanDocumentByUrl(String fileUrl) async {
    try {
      final client = _client;
      if (client == null) return false;

      // Find the document record
      final response = await client
          .from('artisan_documents')
          .select('id, file_name')
          .eq('file_url', fileUrl)
          .maybeSingle();

      if (response != null) {
        // Delete from storage if it exists in Supabase storage
        if (fileUrl.contains('supabase.co/storage')) {
          // Try to extract the path from the URL
          final uri = Uri.parse(fileUrl);
          final pathSegments = uri.pathSegments;
          final publicIndex = pathSegments.indexOf('public');
          if (publicIndex != -1 && publicIndex + 2 < pathSegments.length) {
            final extractedBucket = pathSegments[publicIndex + 1];
            final filePath = pathSegments.sublist(publicIndex + 2).join('/');
            await client.storage.from(extractedBucket).remove([filePath]);
          }
        }

        // Delete the database row
        await client
            .from('artisan_documents')
            .delete()
            .eq('id', response['id']);
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting doc: $e');
      return false;
    }
  }

  // --- Tourist Functions ---

  static final List<ForumThread> _forumStore = [];
  static final Map<String, int> _sessionThreadVotes = {};
  static final Map<String, int> _sessionReplyVotes = {};
  static final List<Map<String, dynamic>> _localReportQueue = [];
  static final List<Map<String, dynamic>> _localModerationHistory = [];
  static final Set<String> _deletedPostIds = {};
  static final Set<String> _dismissedReportPostIds = {};
  static final Set<String> _dismissedReportReplyIds = {};

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
    // Load persisted admin-deleted post IDs (survive app restart)
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('wk_admin_deleted_posts');
      if (saved != null) _deletedPostIds.addAll(saved);
    } catch (_) {}
    final client = _client;
    if (client != null) {
      try {
        dynamic res;
        try {
          res = await client
              .from('forum_posts')
              .select(
                '*, users!forum_posts_user_id_fkey(id, email, full_name, username, avatar_url, role)',
              );
        } catch (_) {
          try {
            res = await client
                .from('forum_posts')
                .select(
                  '*, users(id, email, full_name, username, avatar_url, role)',
                );
          } catch (_) {
            res = await client.from('forum_posts').select();
          }
        }

        // =====================================================
        // Load current user's persistent POST & REPLY votes
        // =====================================================
        final Map<String, int> persistedPostVotes = {};
        final Map<String, int> persistedReplyVotes = {};

        final String? currentUserId = client.auth.currentUser?.id;

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

        // =====================================================
        // Query active pending reports from forum_reports table
        // =====================================================
        final Set<String> activePendingPostReports = {};
        final Set<String> activePendingReplyReports = {};
        final Map<String, Map<String, dynamic>> activeReportDetails = {};

        try {
          final pendingReportsRes = await client
              .from('forum_reports')
              .select('post_id, reply_id, reason, notes, status')
              .eq('status', 'pending');

          for (final r in pendingReportsRes) {
            final rMap = Map<String, dynamic>.from(r);
            final pId = rMap['post_id']?.toString();
            final repId = rMap['reply_id']?.toString();
            if (pId != null && pId.isNotEmpty) {
              activePendingPostReports.add(pId);
              activeReportDetails['post_$pId'] = rMap;
            }
            if (repId != null && repId.isNotEmpty) {
              activePendingReplyReports.add(repId);
              activeReportDetails['reply_$repId'] = rMap;
            }
          }
        } catch (e) {
          debugPrint('fetch pending reports note: $e');
        }

        final List<ForumThread> remote = [];
        if (res is List && res.isNotEmpty) {
          for (final row in res) {
            final threadMap = Map<String, dynamic>.from(row);
            final threadId = threadMap['id'].toString();

            final int persistedVote =
                persistedPostVotes[threadId] ??
                _sessionThreadVotes[_threadVoteKey(threadId)] ??
                (threadMap['user_vote'] as num?)?.toInt() ??
                0;

            // Keep session cache synchronized with database
            _sessionThreadVotes[_threadVoteKey(threadId)] = persistedVote;
            threadMap['userVote'] = persistedVote;

            // Content is reported ONLY if there is an active pending report in Supabase, and NOT dismissed
            bool isPostReported = false;
            String? postReportReason;
            String? postReportNotes;

            if (!_deletedPostIds.contains(threadId) &&
                !_dismissedReportPostIds.contains(threadId)) {
              if (activePendingPostReports.contains(threadId)) {
                isPostReported = true;
                postReportReason =
                    activeReportDetails['post_$threadId']?['reason']
                        ?.toString() ??
                    threadMap['report_reason']?.toString() ??
                    'Reported Content';
                postReportNotes =
                    activeReportDetails['post_$threadId']?['notes']
                        ?.toString() ??
                    threadMap['report_notes']?.toString();
              } else {
                // If not in active pending reports from Supabase, clear from local queue
                _localReportQueue.removeWhere(
                  (r) =>
                      (r['postId']?.toString() == threadId ||
                          r['id']?.toString() == threadId) &&
                      (r['type'] == null || r['type'] == 'post'),
                );
              }
            }

            threadMap['is_reported'] = isPostReported;
            threadMap['report_reason'] = isPostReported
                ? postReportReason
                : null;
            threadMap['report_notes'] = isPostReported ? postReportNotes : null;

            final localMatch = _forumStore
                .where((l) => l.id == threadMap['id'])
                .firstOrNull;

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
                  final int pReplyVote =
                      persistedReplyVotes[replyId] ??
                      _sessionReplyVotes[_replyVoteKey(replyId)] ??
                      (rMap['user_vote'] as num?)?.toInt() ??
                      0;
                  _sessionReplyVotes[_replyVoteKey(replyId)] = pReplyVote;
                  rMap['userVote'] = pReplyVote;

                  // Reply is reported ONLY if there is an active pending report, and NOT dismissed
                  bool isReplyReported = false;
                  String? replyReportReason;
                  String? replyReportNotes;

                  if (!_dismissedReportReplyIds.contains(replyId)) {
                    if (activePendingReplyReports.contains(replyId)) {
                      isReplyReported = true;
                      replyReportReason =
                          activeReportDetails['reply_$replyId']?['reason']
                              ?.toString() ??
                          rMap['report_reason']?.toString() ??
                          'Reported Reply';
                      replyReportNotes =
                          activeReportDetails['reply_$replyId']?['notes']
                              ?.toString() ??
                          rMap['report_notes']?.toString();
                    } else {
                      _localReportQueue.removeWhere(
                        (rep) =>
                            rep['replyId'] == replyId && rep['type'] == 'reply',
                      );
                    }
                  }

                  rMap['is_reported'] = isReplyReported;
                  rMap['report_reason'] = isReplyReported
                      ? replyReportReason
                      : null;
                  rMap['report_notes'] = isReplyReported
                      ? replyReportNotes
                      : null;

                  processedReplies.add(rMap);
                }
              }
              // Always trust Supabase result, even when there are 0 replies.
              threadMap['replies'] = processedReplies;
            } catch (_) {
              if (localMatch != null && localMatch.replies.isNotEmpty) {
                threadMap['replies'] = localMatch.replies
                    .map((r) => r.toMap())
                    .toList();
              }
            }
            // Skip posts that have been admin-deleted (_deletedPostIds)
            if (_deletedPostIds.contains(threadMap['id']?.toString())) {
              continue;
            }
            remote.add(ForumThread.fromMap(threadMap));
          }
        }

        _forumStore.clear();
        _forumStore.addAll(remote);
        _forumStore.removeWhere((t) => _deletedPostIds.contains(t.id));
        return remote;
      } catch (e) {
        debugPrint('Supabase fetchThreads error: $e');
      }
    }
    return List.from(_forumStore);
  }

  Future<List<Map<String, dynamic>>> fetchForumReportQueue() async {
    final Map<String, Map<String, dynamic>> groupedReports = {};

    // =====================================================
    // 1. Add reports already stored in local report queue
    // =====================================================
    for (final item in _localReportQueue) {
      final String? postId =
          (item['postId'] ?? (item['type'] == 'post' ? item['id'] : null))
              ?.toString();

      final String? replyId =
          (item['replyId'] ?? (item['type'] == 'reply' ? item['id'] : null))
              ?.toString();

      if (postId != null &&
          (_deletedPostIds.contains(postId) ||
              _dismissedReportPostIds.contains(postId))) {
        continue;
      }

      if (replyId != null && _dismissedReportReplyIds.contains(replyId)) {
        continue;
      }

      if (_forumStore.isNotEmpty) {
        if (postId != null && !_forumStore.any((t) => t.id == postId)) {
          continue;
        }

        if (replyId != null &&
            !_forumStore.any((t) => t.replies.any((r) => r.id == replyId))) {
          continue;
        }
      }

      final String key = postId != null ? 'post_$postId' : 'reply_$replyId';

      groupedReports[key] = Map<String, dynamic>.from(item);
    }

    // =====================================================
    // 2. Add reported posts/replies from forum store
    // =====================================================
    for (final thread in _forumStore) {
      // -------------------------
      // Reported post
      // -------------------------
      if (thread.isReported &&
          !_deletedPostIds.contains(thread.id) &&
          !_dismissedReportPostIds.contains(thread.id)) {
        final String key = 'post_${thread.id}';

        if (!groupedReports.containsKey(key)) {
          groupedReports[key] = {
            'type': 'post',
            'postId': thread.id,
            'reports': [
              {
                'reason': thread.reportReason ?? 'Inappropriate Content',
                'notes': thread.reportNotes ?? '',
                'created_at': thread.timestamp,
              },
            ],
            'reportsCount': 1,
          };
        }
      }

      // -------------------------
      // Reported replies
      // -------------------------
      for (final reply in thread.replies) {
        if (reply.isReported && !_dismissedReportReplyIds.contains(reply.id)) {
          final String key = 'reply_${reply.id}';

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
                },
              ],
              'reportsCount': 1,
            };
          }
        }
      }
    }

    // =====================================================
    // 3. Load REAL reports from Supabase
    // =====================================================
    final client = _client;

    if (client != null) {
      try {
        final response = await client
            .from('forum_reports')
            .select()
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        final List<Map<String, dynamic>> reports =
            List<Map<String, dynamic>>.from(response);

        for (final report in reports) {
          final String? postId = report['post_id']?.toString();

          final String? replyId = report['reply_id']?.toString();

          // Skip deleted/dismissed posts
          if (postId != null &&
              (_deletedPostIds.contains(postId) ||
                  _dismissedReportPostIds.contains(postId))) {
            continue;
          }

          // Skip dismissed replies
          if (replyId != null && _dismissedReportReplyIds.contains(replyId)) {
            continue;
          }

          // Make sure target still exists
          if (_forumStore.isNotEmpty) {
            if (postId != null && !_forumStore.any((t) => t.id == postId)) {
              continue;
            }

            if (replyId != null &&
                !_forumStore.any(
                  (t) => t.replies.any((r) => r.id == replyId),
                )) {
              continue;
            }
          }

          // Determine grouping key
          final String key;

          if (postId != null) {
            key = 'post_$postId';
          } else if (replyId != null) {
            key = 'reply_$replyId';
          } else {
            continue;
          }

          // Create group if it does not exist
          if (!groupedReports.containsKey(key)) {
            groupedReports[key] = {
              'type': postId != null ? 'post' : 'reply',
              'postId': postId,
              'replyId': replyId,
              'reports': <Map<String, dynamic>>[],
              'reportsCount': 0,
            };
          }

          final List<Map<String, dynamic>> reportList =
              List<Map<String, dynamic>>.from(
                groupedReports[key]!['reports'] ?? [],
              );

          final String? realReportId = report['id']?.toString();

          // =================================================
          // Remove temporary/local placeholder reports.
          //
          // Real Supabase reports contain database "id".
          // Local placeholders do not.
          // =================================================
          reportList.removeWhere((existingReport) {
            final String? existingId = existingReport['id']?.toString();

            return existingId == null ||
                existingId.isEmpty ||
                existingId == 'null';
          });

          // =================================================
          // Prevent duplicate REAL reports using DB report id
          // =================================================
          final bool alreadyExists = reportList.any((existingReport) {
            return existingReport['id']?.toString() == realReportId;
          });

          if (!alreadyExists) {
            // IMPORTANT:
            // "report" comes directly from Supabase .select(),
            // therefore reporter_id is preserved here.
            reportList.add(Map<String, dynamic>.from(report));
          }

          groupedReports[key]!['reports'] = reportList;

          groupedReports[key]!['reportsCount'] = reportList.length;
        }
      } catch (e) {
        debugPrint('fetchForumReportQueue Supabase note: $e');
      }
    }

    return groupedReports.values.toList();
  }

  static const String _keyDismissedNotices = 'wk_dismissed_moderation_notices';
  static final Set<String> _dismissedNoticeIds = {};

  Future<List<Map<String, dynamic>>> fetchForumModerationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_keyDismissedNotices);
      if (saved != null) {
        _dismissedNoticeIds.addAll(saved);
      }
    } catch (_) {}

    final List<Map<String, dynamic>> history =
        List.from(_localModerationHistory)..removeWhere(
          (h) =>
              _dismissedNoticeIds.contains(h['id']?.toString()) ||
              _dismissedNoticeIds.contains(h['resolved_at']?.toString()),
        );

    final client = _client;
    if (client != null) {
      try {
        dynamic response;
        try {
          response = await client
              .from('forum_reports')
              .select()
              .inFilter('status', ['dismissed', 'actioned'])
              .order('resolved_at', ascending: false);
        } catch (_) {
          // Fallback if resolved_at column does not exist yet
          response = await client.from('forum_reports').select().inFilter(
            'status',
            ['dismissed', 'actioned'],
          );
        }

        final remoteHistory = List<Map<String, dynamic>>.from(response ?? []);
        for (final item in remoteHistory) {
          final id = item['id']?.toString();
          final postId = item['post_id']?.toString();
          final replyId = item['reply_id']?.toString();

          if (id != null && !_dismissedNoticeIds.contains(id)) {
            // Check if this post or reply is already in history (e.g. from local history)
            final existingIdx = history.indexWhere(
              (h) =>
                  h['id']?.toString() == id ||
                  (postId != null &&
                      postId.isNotEmpty &&
                      h['post_id']?.toString() == postId) ||
                  (replyId != null &&
                      replyId.isNotEmpty &&
                      h['reply_id']?.toString() == replyId),
            );

            if (existingIdx != -1) {
              // Merge remote item with local item, preserving moderator_name if local has it
              history[existingIdx] = {
                ...item,
                if (history[existingIdx]['moderator_name'] != null)
                  'moderator_name': history[existingIdx]['moderator_name'],
                if (history[existingIdx]['author_name'] != null)
                  'author_name': history[existingIdx]['author_name'],
                if (history[existingIdx]['post_title'] != null)
                  'post_title': history[existingIdx]['post_title'],
              };
            } else {
              history.add(item);
            }
          }
        }
      } catch (e) {
        debugPrint('fetchForumModerationHistory Supabase note: $e');
      }
    }
    return history;
  }

  Future<void> dismissModerationNotice(String reportId) async {
    _dismissedNoticeIds.add(reportId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _keyDismissedNotices,
        _dismissedNoticeIds.toList(),
      );
    } catch (_) {}

    _localModerationHistory.removeWhere(
      (item) =>
          item['id']?.toString() == reportId ||
          item['resolved_at']?.toString() == reportId,
    );

    final client = _client;
    if (client != null) {
      try {
        await client.rpc(
          'dismiss_moderation_notice',
          params: {'p_report_id': reportId},
        );
      } catch (_) {}

      try {
        await client
            .from('forum_reports')
            .update({
              'status': 'dismissed_by_user',
              'resolved_at': DateTime.now().toIso8601String(),
            })
            .eq('id', reportId);
      } catch (_) {}
    }
  }

  Future<void> createThread(ForumThread thread) async {
    _deletedPostIds.remove(thread.id);
    _dismissedReportPostIds.remove(thread.id);
    _forumStore.insert(0, thread);
    _sessionThreadVotes[_threadVoteKey(thread.id)] = 0; // Initial neutral vote

    if (thread.isReported) {
      final existingIdx = _localReportQueue.indexWhere(
        (r) => r['postId'] == thread.id && r['type'] == 'post',
      );
      final newReportItem = {
        'reason': thread.reportReason ?? 'Automated content flag',
        'notes': thread.reportNotes ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };
      if (existingIdx != -1) {
        final existingReports = List<Map<String, dynamic>>.from(
          _localReportQueue[existingIdx]['reports'] ?? [],
        );
        existingReports.add(newReportItem);
        _localReportQueue[existingIdx]['reports'] = existingReports;
        _localReportQueue[existingIdx]['reportsCount'] = existingReports.length;
      } else {
        _localReportQueue.add({
          'type': 'post',
          'postId': thread.id,
          'reports': [newReportItem],
          'reportsCount': 1,
        });
      }
    }

    final client = _client;
    if (client != null) {
      final String? authUid = client.auth.currentUser?.id;
      final String? userStoreUid = _userStore[thread.authorEmail]?['id']
          ?.toString();
      final String effectiveUid =
          thread.userId ??
          authUid ??
          userStoreUid ??
          '00000000-0000-4000-8000-000000000001';
      final String postContent = thread.replies.isNotEmpty
          ? thread.replies.first.text
          : thread.title;
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
        if (e.toString().contains('23503') ||
            e.toString().contains('foreign key') ||
            e.toString().contains('user_id')) {
          try {
            final fallbackMap = Map<String, dynamic>.from(verifiedDbMap)
              ..remove('user_id');
            await client.from('forum_posts').insert(fallbackMap);
          } catch (dbErr) {
            debugPrint('Supabase createThread fallback insert error: $dbErr');
          }
        }
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
          if (re.toString().contains('23503') ||
              re.toString().contains('foreign key') ||
              re.toString().contains('user_id')) {
            try {
              await client.from('forum_replies').insert({
                'id': reply.id,
                'post_id': thread.id,
                'content': reply.text,
                'upvotes': reply.upvotes,
                'is_verified_answer': reply.isVerifiedAnswer,
                'is_edited': reply.isEdited,
              });
            } catch (_) {}
          }
        }
      }
    }
  }

  Future<void> postReply(String threadId, ThreadReply reply) async {
    _dismissedReportReplyIds.remove(reply.id);
    final postVoteKey = _replyVoteKey(reply.id);
    _sessionReplyVotes[postVoteKey] = 0;

    if (reply.isReported) {
      final existingIdx = _localReportQueue.indexWhere(
        (r) => r['replyId'] == reply.id && r['type'] == 'reply',
      );
      final newReportItem = {
        'reason': reply.reportReason ?? 'Automated reply flag',
        'notes': reply.reportNotes ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };
      if (existingIdx != -1) {
        final existingReports = List<Map<String, dynamic>>.from(
          _localReportQueue[existingIdx]['reports'] ?? [],
        );
        existingReports.add(newReportItem);
        _localReportQueue[existingIdx]['reports'] = existingReports;
        _localReportQueue[existingIdx]['reportsCount'] = existingReports.length;
      } else {
        _localReportQueue.add({
          'type': 'reply',
          'postId': threadId,
          'replyId': reply.id,
          'reports': [newReportItem],
          'reportsCount': 1,
        });
      }
    }

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
      final String? userStoreUid = _userStore[reply.authorEmail]?['id']
          ?.toString();
      final String effectiveUid =
          authUid ?? userStoreUid ?? '00000000-0000-4000-8000-000000000001';

      final Map<String, dynamic> verifiedReplyMap = {
        'id': reply.id,
        'post_id': threadId,
        'user_id': effectiveUid,
        'content': reply.text,
        'upvotes': reply.upvotes,
        'is_verified_answer': reply.isVerifiedAnswer,
        'is_edited': reply.isEdited,
        'is_reported': reply.isReported,
        if (reply.reportReason != null) 'report_reason': reply.reportReason,
        if (reply.reportNotes != null) 'report_notes': reply.reportNotes,
        if (reply.parentReplyId != null) 'parent_reply_id': reply.parentReplyId,
      };

      try {
        await client.from('forum_replies').insert(verifiedReplyMap);

        // If a verified Artisan replies,
        // mark the thread as having a verified Artisan answer.
        if (reply.isArtisan) {
          await client
              .from('forum_posts')
              .update({'is_solved': true})
              .eq('id', threadId);
        }
      } catch (e) {
        debugPrint('Supabase postReply insert/update note: $e');
        if (e.toString().contains('23503') ||
            e.toString().contains('foreign key') ||
            e.toString().contains('user_id')) {
          try {
            final fallbackMap = Map<String, dynamic>.from(verifiedReplyMap)
              ..remove('user_id');
            await client.from('forum_replies').insert(fallbackMap);
          } catch (dbErr) {
            debugPrint('Supabase postReply fallback insert error: $dbErr');
          }
        }
      }
    }
  }

  Future<void> voteThread(String threadId, int voteDirection) async {
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
    final bool isAuthor =
        (currentUserId != null &&
            currentThread.userId != null &&
            currentThread.userId == currentUserId) ||
        (currentUserEmail != null &&
            currentThread.authorEmail.isNotEmpty &&
            currentThread.authorEmail.toLowerCase() ==
                currentUserEmail.toLowerCase());
    if (isAuthor) {
      debugPrint(
        'Self-vote prevention: Author cannot vote on their own thread',
      );
      return;
    }

    final String voteKey = _threadVoteKey(threadId);
    final int currentVote =
        _sessionThreadVotes[voteKey] ?? currentThread.userVote;

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
        params: {'p_post_id': threadId, 'p_vote': voteDirection},
      );

      if (result is Map) {
        final Map<String, dynamic> resultMap = Map<String, dynamic>.from(
          result,
        );
        final int rpcUpvotes =
            (resultMap['upvotes'] as num?)?.toInt() ?? newUpvotes;
        final int rpcUserVote =
            (resultMap['user_vote'] as num?)?.toInt() ?? newVote;

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
      await client
          .from('forum_posts')
          .update({'upvotes': newUpvotes})
          .eq('id', threadId);
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
    final bool isAuthor =
        (currentUserEmail != null &&
            currentReply.authorEmail.isNotEmpty &&
            currentReply.authorEmail.toLowerCase() ==
                currentUserEmail.toLowerCase()) ||
        (currentReply.isMe && currentUserId != null);
    if (isAuthor) {
      debugPrint('Self-vote prevention: Author cannot vote on their own reply');
      return;
    }

    final String voteKey = _replyVoteKey(replyId);
    final int currentVote =
        _sessionReplyVotes[voteKey] ?? currentReply.userVote;

    // Toggle off if same direction, else switch
    final int newVote = (currentVote == voteDirection) ? 0 : voteDirection;
    final int delta = newVote - currentVote;
    final int newUpvotes = currentReply.upvotes + delta;

    // Optimistic local update
    _sessionReplyVotes[voteKey] = newVote;
    final List<ThreadReply> updatedReplies = List<ThreadReply>.from(
      thread.replies,
    );
    updatedReplies[rIdx] = currentReply.copyWith(
      upvotes: newUpvotes,
      userVote: newVote,
    );
    _forumStore[tIdx] = thread.copyWith(replies: updatedReplies);

    if (client == null) return;

    try {
      final result = await client.rpc(
        'vote_forum_reply',
        params: {'p_reply_id': replyId, 'p_vote': voteDirection},
      );

      if (result is Map) {
        final Map<String, dynamic> resultMap = Map<String, dynamic>.from(
          result,
        );
        final int rpcUpvotes =
            (resultMap['upvotes'] as num?)?.toInt() ?? newUpvotes;
        final int rpcUserVote =
            (resultMap['user_vote'] as num?)?.toInt() ?? newVote;

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
      await client
          .from('forum_replies')
          .update({'upvotes': newUpvotes})
          .eq('id', replyId);
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
        await client
            .from('forum_posts')
            .update({'title': newTitle, 'is_edited': true})
            .eq('id', threadId);
      } catch (e) {
        try {
          await client
              .from('forum_posts')
              .update({'title': newTitle})
              .eq('id', threadId);
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
        // 1. Delete post votes
        try {
          await client
              .from('forum_post_votes')
              .delete()
              .eq('post_id', threadId);
        } catch (_) {}

        // 2. Delete reply votes and reports
        try {
          final repliesRes = await client
              .from('forum_replies')
              .select('id')
              .eq('post_id', threadId);
          if (repliesRes.isNotEmpty) {
            final replyIds = repliesRes.map((r) => r['id'].toString()).toList();
            try {
              await client
                  .from('forum_reply_votes')
                  .delete()
                  .inFilter('reply_id', replyIds);
            } catch (_) {}
            try {
              await client
                  .from('forum_reports')
                  .delete()
                  .inFilter('reply_id', replyIds);
            } catch (_) {}
          }
        } catch (_) {}

        // 3. Nullify parent_reply_id to prevent nested constraint violations, then delete replies
        try {
          await client
              .from('forum_replies')
              .update({'parent_reply_id': null})
              .eq('post_id', threadId);
        } catch (_) {}
        try {
          await client.from('forum_replies').delete().eq('post_id', threadId);
        } catch (_) {}

        // 4. Delete reports referencing this post
        try {
          await client.from('forum_reports').delete().eq('post_id', threadId);
        } catch (_) {}

        // 5. Delete the post
        await client.from('forum_posts').delete().eq('id', threadId);
      } catch (e) {
        debugPrint('Supabase deleteThread note: $e');
      }
    }
  }

  // Returns empty string on full success, or an error/status message.
  Future<String> adminDeleteForumPost(
    String postId,
    String deletionReason, [
    String? adminUsername,
  ]) async {
    final foundThread = _forumStore.where((t) => t.id == postId).firstOrNull;

    final String authorEmail = foundThread?.authorEmail ?? '';
    String authorName = '';
    final String postTitle = foundThread?.title ?? 'Post';
    final String modName = adminUsername ?? 'Admin';

    final client = _client;

    // Always use username for moderation history
    if (client != null && authorEmail.trim().isNotEmpty) {
      try {
        final userRow = await client
            .from('users')
            .select('username')
            .ilike('email', authorEmail.trim())
            .maybeSingle();

        if (userRow != null) {
          final String username = (userRow['username'] ?? '').toString().trim();

          if (username.isNotEmpty) {
            authorName = username;
          }
        }
      } catch (e) {
        debugPrint('adminDeleteForumPost author lookup note: $e');
      }
    }

    if (authorName.trim().isEmpty) {
      authorName = 'Unknown User';
    }

    // 2. Immediately update local state (admin sees deletion instantly)
    _forumStore.removeWhere((thread) => thread.id == postId);
    _deletedPostIds.add(postId);
    _dismissedReportPostIds.remove(postId);
    // Persist so deletion survives app restart
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'wk_admin_deleted_posts',
        _deletedPostIds.toList(),
      );
    } catch (_) {}
    _localReportQueue.removeWhere(
      (r) =>
          (r['postId']?.toString() == postId ||
              r['id']?.toString() == postId) &&
          (r['type'] == null || r['type'] == 'post'),
    );

    // 3. Add a local moderation history entry (user gets notification even if network fails)
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'post_id': postId,
      'post_title': postTitle,
      'author_email': authorEmail,
      'author_name': authorName,
      'moderator_name': modName,
      'status': 'actioned',
      'action_type': 'deleted',
      'reason': deletionReason,
      'admin_reason': deletionReason,
      'notes':
          'Post "$postTitle" by $authorName ($authorEmail) deleted by Admin $modName: $deletionReason',
      'resolution_notes': deletionReason,
      'resolved_at': DateTime.now().toIso8601String(),
    });

    if (client == null) return 'Supabase client not initialized';

    String deleteError = '';

    // Mark existing reports for this post as actioned in Supabase DB immediately
    try {
      await client
          .from('forum_reports')
          .update({
            'status': 'actioned',
            'action_type': 'deleted',
            'resolution_notes': deletionReason,
            'deletion_reason': deletionReason,
            'notes':
                'Post "$postTitle" by $authorName ($authorEmail) deleted by Admin $modName: $deletionReason',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('post_id', postId);
    } catch (_) {}

    // 4. Try stored procedure
    try {
      await client.rpc(
        'admin_delete_forum_content',
        params: {
          'p_post_id': postId,
          'p_reply_id': null,
          'p_deletion_reason': deletionReason,
        },
      );
      debugPrint('adminDeleteForumPost: RPC succeeded for $postId');
      deleteError = '';
    } catch (e) {
      deleteError = e.toString();
      debugPrint('adminDeleteForumPost: RPC failed ($e)');
    }

    // 5. If RPC failed, try direct delete with .select() to confirm result
    if (deleteError.isNotEmpty) {
      try {
        // Unlink reports so ON DELETE CASCADE does not wipe out moderation history
        try {
          await client
              .from('forum_reports')
              .update({
                'status': 'actioned',
                'action_type': 'deleted',
                'resolution_notes': deletionReason,
                'deletion_reason': deletionReason,
                'resolved_at': DateTime.now().toIso8601String(),
                'post_id': null,
              })
              .eq('post_id', postId);
        } catch (_) {}

        final result = await client
            .from('forum_posts')
            .delete()
            .eq('id', postId)
            .select('id');
        debugPrint('adminDeleteForumPost: direct delete result: $result');
        if (result.isEmpty) {
          // Deleted successfully (no rows returned means the row is gone)
          deleteError = '';
        } else if (result.isNotEmpty) {
          // Row still exists somehow - report as error
          deleteError =
              'Post still exists after delete (rows returned: ${result.length})';
        } else {
          deleteError = '';
        }
      } catch (e) {
        deleteError = 'Direct delete FAILED: $e';
        debugPrint('adminDeleteForumPost: direct delete FAILED ($e)');
      }
    }

    // 6. Insert a standalone forum_reports record for the artisan/tourist notification
    try {
      try {
        await client.from('forum_reports').insert({
          'reason': deletionReason,
          'status': 'actioned',
          'action_type': 'deleted',
          'notes':
              'Post "$postTitle" by $authorName ($authorEmail) deleted: $deletionReason',
          'resolution_notes': deletionReason,
          'deletion_reason': deletionReason,
          'resolved_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Fallback for older database schemas missing action_type / resolution_notes columns
        await client.from('forum_reports').insert({
          'reason': deletionReason,
          'status': 'actioned',
          'notes':
              'Post "$postTitle" by $authorName ($authorEmail) deleted: $deletionReason',
        });
      }
      debugPrint('adminDeleteForumPost: standalone report inserted');
    } catch (e) {
      debugPrint('adminDeleteForumPost: report insert FAILED ($e)');
      if (deleteError.isEmpty) deleteError = 'Report insert failed: $e';
    }

    return deleteError;
  }

  Future<String> adminDeleteForumReply(
    String threadId,
    String replyId,
    String deletionReason, [
    String? adminUsername,
  ]) async {
    // 1. Capture reply metadata BEFORE removing from local store
    String authorEmail = '';
    String authorName = '';
    String replyText = '';
    final modName = adminUsername ?? 'Admin';
    for (final t in _forumStore) {
      final r = t.replies.where((rep) => rep.id == replyId).firstOrNull;

      if (r != null) {
        authorEmail = r.authorEmail;
        authorName = r.sender;
        replyText = r.text;
        break;
      }
    }

    // =====================================================
    // Resolve the REAL author name from public.users
    // instead of relying only on reply.sender
    // =====================================================
    final client = _client;

    if (client != null && authorEmail.trim().isNotEmpty) {
      try {
        final userRow = await client
            .from('users')
            .select('username')
            .ilike('email', authorEmail.trim())
            .maybeSingle();

        if (userRow != null) {
          final String username = (userRow['username'] ?? '').toString().trim();

          if (username.isNotEmpty) {
            authorName = username;
          }
        }
      } catch (e) {
        debugPrint('adminDeleteForumReply author lookup note: $e');
      }
    }

    if (authorName.trim().isEmpty ||
        authorName.trim().toLowerCase() == 'community member') {
      authorName = 'Unknown User';
    }

    // 2. Immediately update local state
    for (int i = 0; i < _forumStore.length; i++) {
      final t = _forumStore[i];
      final rIdx = t.replies.indexWhere((r) => r.id == replyId);
      if (rIdx != -1) {
        final updatedReplies = List<ThreadReply>.from(t.replies)
          ..removeAt(rIdx);
        _forumStore[i] = t.copyWith(
          replies: updatedReplies,
          replyCount: updatedReplies.length,
        );
      }
    }
    _dismissedReportReplyIds.add(replyId);
    _localReportQueue.removeWhere(
      (r) =>
          (r['replyId']?.toString() == replyId ||
              r['id']?.toString() == replyId) &&
          (r['type'] == null || r['type'] == 'reply'),
    );

    // 3. Add local moderation history entry
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'reply_id': replyId,
      'reply_text': replyText,
      'author_email': authorEmail,
      'author_name': authorName,
      'moderator_name': modName,
      'status': 'actioned',
      'action_type': 'deleted',
      'reason': deletionReason,
      'admin_reason': deletionReason,
      'notes':
          'Reply by $authorName ($authorEmail) deleted by Admin $modName: $deletionReason',
      'resolution_notes': deletionReason,
      'resolved_at': DateTime.now().toIso8601String(),
    });

    if (client == null) return 'Supabase client not initialized';

    String deleteError = '';

    // Mark existing reports for this reply as actioned in Supabase DB immediately
    try {
      await client
          .from('forum_reports')
          .update({
            'status': 'actioned',
            'action_type': 'deleted',
            'resolution_notes': deletionReason,
            'deletion_reason': deletionReason,
            'notes':
                'Reply by $authorName ($authorEmail) deleted by Admin $modName: $deletionReason',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('reply_id', replyId);
    } catch (_) {}

    // 4. Try stored procedure
    try {
      await client.rpc(
        'admin_delete_forum_content',
        params: {
          'p_post_id': null,
          'p_reply_id': replyId,
          'p_deletion_reason': deletionReason,
        },
      );
      debugPrint('adminDeleteForumReply: RPC succeeded for $replyId');
    } catch (e) {
      deleteError = e.toString();
      debugPrint('adminDeleteForumReply: RPC failed ($e)');
    }

    // 5. If RPC failed, direct delete
    if (deleteError.isNotEmpty) {
      try {
        try {
          await client
              .from('forum_reports')
              .update({
                'status': 'actioned',
                'action_type': 'deleted',
                'resolution_notes': deletionReason,
                'deletion_reason': deletionReason,
                'resolved_at': DateTime.now().toIso8601String(),
                'reply_id': null,
              })
              .eq('reply_id', replyId);
        } catch (_) {}

        await client
            .from('forum_replies')
            .delete()
            .eq('id', replyId)
            .select('id');
        debugPrint(
          'adminDeleteForumReply: direct delete succeeded for $replyId',
        );
        deleteError = '';
      } catch (e) {
        deleteError = 'Direct delete FAILED: $e';
        debugPrint('adminDeleteForumReply: direct delete FAILED ($e)');
      }
    }

    // 6. Insert standalone report record
    try {
      try {
        await client.from('forum_reports').insert({
          'reason': deletionReason,
          'status': 'actioned',
          'action_type': 'deleted',
          'notes':
              'Reply by $authorName ($authorEmail) deleted: $deletionReason',
          'resolution_notes': deletionReason,
          'deletion_reason': deletionReason,
          'resolved_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        await client.from('forum_reports').insert({
          'reason': deletionReason,
          'status': 'actioned',
          'notes':
              'Reply by $authorName ($authorEmail) deleted: $deletionReason',
        });
      }
      debugPrint('adminDeleteForumReply: report record inserted for $replyId');
    } catch (e) {
      debugPrint('adminDeleteForumReply: report insert FAILED ($e)');
      if (deleteError.isEmpty) deleteError = 'Report insert failed: $e';
    }

    return deleteError;
  }

  Future<void> editReply(
    String threadId,
    String replyId,
    String newText,
  ) async {
    final tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      final t = _forumStore[tIdx];
      final rIdx = t.replies.indexWhere((r) => r.id == replyId);
      if (rIdx != -1) {
        final updatedReply = t.replies[rIdx].copyWith(
          text: newText,
          isEdited: true,
        );
        final updatedReplies = List<ThreadReply>.from(t.replies)
          ..[rIdx] = updatedReply;
        _forumStore[tIdx] = t.copyWith(replies: updatedReplies);
      }
    }
    final client = _client;
    if (client != null) {
      try {
        await client
            .from('forum_replies')
            .update({'content': newText, 'is_edited': true})
            .eq('id', replyId);
      } catch (e) {
        debugPrint('Supabase editReply note: $e');
      }
    }
  }

  Future<void> deleteReply(String threadId, String replyId) async {
    final tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      final t = _forumStore[tIdx];
      final updatedReplies = List<ThreadReply>.from(t.replies)
        ..removeWhere((r) => r.id == replyId || r.parentReplyId == replyId);
      _forumStore[tIdx] = t.copyWith(
        replies: updatedReplies,
        replyCount: updatedReplies.length,
      );
    }
    _localReportQueue.removeWhere(
      (r) =>
          (r['replyId']?.toString() == replyId ||
              r['id']?.toString() == replyId) &&
          (r['type'] == null || r['type'] == 'reply'),
    );
    _dismissedReportReplyIds.add(replyId);

    final client = _client;
    if (client != null) {
      try {
        // 1. Try RPC admin_delete_forum_content first (handles all constraints with SECURITY DEFINER)
        bool rpcSuccess = false;
        try {
          await client.rpc(
            'admin_delete_forum_content',
            params: {
              'p_post_id': null,
              'p_reply_id': replyId,
              'p_deletion_reason': 'Deleted by author/user',
            },
          );
          rpcSuccess = true;
        } catch (_) {}

        if (!rpcSuccess) {
          // 2. Delete reply votes
          try {
            await client
                .from('forum_reply_votes')
                .delete()
                .eq('reply_id', replyId);
          } catch (_) {}

          // 3. Unlink/nullify child replies then delete them
          try {
            await client
                .from('forum_replies')
                .update({'parent_reply_id': null})
                .eq('parent_reply_id', replyId);
          } catch (_) {}
          try {
            await client
                .from('forum_replies')
                .delete()
                .eq('parent_reply_id', replyId);
          } catch (_) {}

          // 4. Nullify or delete reports referencing this reply
          try {
            await client
                .from('forum_reports')
                .update({
                  'status': 'actioned',
                  'action_type': 'deleted',
                  'reply_id': null,
                })
                .eq('reply_id', replyId);
          } catch (_) {}
          try {
            await client.from('forum_reports').delete().eq('reply_id', replyId);
          } catch (_) {}

          // 5. Delete the reply
          await client.from('forum_replies').delete().eq('id', replyId);
        }
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
    _dismissedReportReplyIds.remove(replyId);

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
    final existingIdx = _localReportQueue.indexWhere(
      (r) => r['replyId'] == replyId && r['type'] == 'reply',
    );
    final newReportItem = {
      'reason': reason,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (existingIdx != -1) {
      final existingReports = List<Map<String, dynamic>>.from(
        _localReportQueue[existingIdx]['reports'] ?? [],
      );
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
        params: {'p_reply_id': replyId, 'p_reason': reason, 'p_notes': notes},
      );

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'success': true, 'already_reported': false};
    } catch (e) {
      final error = e.toString();
      if (error.contains('23505') ||
          error.toLowerCase().contains('duplicate key')) {
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
        await client
            .from('forum_replies')
            .update({
              'is_reported': true,
              'report_reason': reason,
              'report_notes': notes,
            })
            .eq('id', replyId);
        return {'success': true, 'already_reported': false};
      } catch (dbErr) {
        debugPrint('reportReply direct fallback note: $dbErr');
        return {'success': true, 'already_reported': false};
      }
    }
  }

  Future<void> dismissReplyReport(
    String threadId,
    String replyId, [
    String? adminUsername,
  ]) async {
    final modName = adminUsername ?? 'Admin';
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

    _dismissedReportReplyIds.add(replyId);
    _localReportQueue.removeWhere(
      (r) =>
          (r['replyId']?.toString() == replyId ||
              r['id']?.toString() == replyId) &&
          (r['type'] == null || r['type'] == 'reply'),
    );
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'reply_id': replyId,
      'status': 'dismissed',
      'moderator_name': modName,
      'notes': 'Reply flag dismissed by Admin $modName',
      'resolved_at': DateTime.now().toIso8601String(),
    });

    final client = _client;
    if (client == null) return;

    try {
      await client.rpc(
        'dismiss_forum_reports',
        params: {'p_post_id': null, 'p_reply_id': replyId},
      );
    } catch (e) {
      debugPrint(
        'dismissReplyReport RPC note: $e, using direct table fallback',
      );
      try {
        await client
            .from('forum_reports')
            .update({
              'status': 'dismissed',
              'resolved_at': DateTime.now().toIso8601String(),
            })
            .eq('reply_id', replyId);
        await client
            .from('forum_replies')
            .update({
              'is_reported': false,
              'report_reason': null,
              'report_notes': null,
            })
            .eq('id', replyId);
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
    _dismissedReportPostIds.remove(threadId);
    _deletedPostIds.remove(threadId);

    final tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      _forumStore[tIdx] = _forumStore[tIdx].copyWith(
        isReported: true,
        reportReason: reason,
        reportNotes: notes,
      );
    }

    final existingIdx = _localReportQueue.indexWhere(
      (r) => r['postId'] == threadId && r['type'] == 'post',
    );
    final newReportItem = {
      'reason': reason,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (existingIdx != -1) {
      final existingReports = List<Map<String, dynamic>>.from(
        _localReportQueue[existingIdx]['reports'] ?? [],
      );
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
        params: {'p_post_id': threadId, 'p_reason': reason, 'p_notes': notes},
      );

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'success': true, 'already_reported': false};
    } catch (e) {
      final error = e.toString();
      if (error.contains('23505') ||
          error.toLowerCase().contains('duplicate key')) {
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
        await client
            .from('forum_posts')
            .update({
              'is_reported': true,
              'report_reason': reason,
              'report_notes': notes,
            })
            .eq('id', threadId);
        return {'success': true, 'already_reported': false};
      } catch (dbErr) {
        debugPrint('reportThread direct fallback note: $dbErr');
        return {'success': true, 'already_reported': false};
      }
    }
  }

  Future<void> dismissReport(String threadId, [String? adminUsername]) async {
    final modName = adminUsername ?? 'Admin';
    _deletedPostIds.remove(threadId);
    _dismissedReportPostIds.add(threadId);

    final idx = _forumStore.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      _forumStore[idx] = _forumStore[idx].copyWith(
        isReported: false,
        reportReason: null,
        reportNotes: null,
      );
    }

    _localReportQueue.removeWhere(
      (r) =>
          (r['postId']?.toString() == threadId ||
              r['id']?.toString() == threadId) &&
          (r['type'] == null || r['type'] == 'post'),
    );
    _localModerationHistory.insert(0, {
      'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
      'post_id': threadId,
      'status': 'dismissed',
      'moderator_name': modName,
      'notes': 'Flag dismissed by Admin $modName',
      'resolved_at': DateTime.now().toIso8601String(),
    });

    final client = _client;
    if (client == null) return;

    try {
      await client.rpc(
        'dismiss_forum_reports',
        params: {'p_post_id': threadId, 'p_reply_id': null},
      );
    } catch (e) {
      debugPrint('dismissReport RPC note: $e, using direct table fallback');
      try {
        await client
            .from('forum_reports')
            .update({
              'status': 'dismissed',
              'resolved_at': DateTime.now().toIso8601String(),
            })
            .eq('post_id', threadId);
        await client
            .from('forum_posts')
            .update({
              'is_reported': false,
              'report_reason': null,
              'report_notes': null,
            })
            .eq('id', threadId);
      } catch (dbErr) {
        debugPrint('dismissReport direct fallback note: $dbErr');
      }
    }
  }

  // --- Gamification Services ---

  Future<Map<String, dynamic>> fetchPassportData() async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view your Heritage Passport.',
    );

    final warnings = <String>[];
    Map<String, dynamic>? experienceRow;
    var taskAwardRows = <Map<String, dynamic>>[];
    var stampRows = <Map<String, dynamic>>[];
    var availableQuestRows = <Map<String, dynamic>>[];
    var completedQuestRows = <Map<String, dynamic>>[];
    var digitalPlaqueCount = 0;
    var xpAvailable = false;
    var taskAwardsAvailable = false;
    var stampsAvailable = false;
    var availableQuestsAvailable = false;
    var questStatisticsAvailable = false;
    var digitalPlaquesAvailable = false;

    try {
      experienceRow = await client
          .from('user_experience')
          .select('user_id, total_xp, updated_at')
          .eq('user_id', user.id)
          .maybeSingle();
      xpAvailable = true;
    } catch (error) {
      warnings.add('xp');
      debugPrint('fetchPassportData XP note: $error');
    }

    try {
      taskAwardRows = List<Map<String, dynamic>>.from(
        await client
            .from('user_task_xp_awards')
            .select(
              'task_id, xp_awarded, awarded_at, '
              'heritage_tasks!inner('
              'quest_id, status, is_archived, is_system_task, sort_order, '
              'quests!inner(artisan_id)'
              ')',
            )
            .eq('user_id', user.id)
            .eq('heritage_tasks.status', 'APPROVED')
            .eq('heritage_tasks.is_archived', false),
      );
      taskAwardsAvailable = true;
    } catch (error) {
      warnings.add('task_awards');
      debugPrint('fetchPassportData task awards note: $error');
    }

    try {
      stampRows = List<Map<String, dynamic>>.from(
        await client
            .from('passport_stamps')
            .select(
              'id, quest_id, stamp_code, unlocked_at, '
              'quests!inner('
              'id, title, category, stamp_title, stamp_image_url, status'
              ')',
            )
            .eq('user_id', user.id)
            .eq('quests.status', 'APPROVED')
            .order('unlocked_at', ascending: false),
      );
      stampsAvailable = true;
    } catch (error) {
      warnings.add('stamps');
      debugPrint('fetchPassportData stamps note: $error');
    }

    try {
      availableQuestRows = List<Map<String, dynamic>>.from(
        await client
            .from('quests')
            .select('id, title, category, stamp_title, stamp_image_url, status')
            .eq('status', 'APPROVED'),
      );
      availableQuestsAvailable = true;
    } catch (error) {
      warnings.add('available_quests');
      debugPrint('fetchPassportData available quests note: $error');
    }

    try {
      completedQuestRows = List<Map<String, dynamic>>.from(
        await client
            .from('quest_progress')
            .select('quest_id, quests!inner(id, artisan_id, status)')
            .eq('user_id', user.id)
            .eq('status', 'COMPLETED')
            .eq('quests.status', 'APPROVED'),
      );
      questStatisticsAvailable = true;
    } catch (error) {
      warnings.add('quest_statistics');
      debugPrint('fetchPassportData quest statistics note: $error');
    }

    try {
      final plaqueRows = List<Map<String, dynamic>>.from(
        await client
            .from('digital_plaques')
            .select('id')
            .eq('user_id', user.id),
      );
      digitalPlaqueCount = plaqueRows.length;
      digitalPlaquesAvailable = true;
    } catch (error) {
      warnings.add('digital_plaques');
      debugPrint('fetchPassportData digital plaques note: $error');
    }

    if (!xpAvailable &&
        !taskAwardsAvailable &&
        !stampsAvailable &&
        !availableQuestsAvailable &&
        !questStatisticsAvailable &&
        !digitalPlaquesAvailable) {
      throw StateError('Unable to load your Heritage Passport.');
    }

    return {
      'total_xp': experienceRow?['total_xp'] ?? 0,
      'xp_updated_at': experienceRow?['updated_at'],
      'task_awards': taskAwardRows,
      'stamps': stampRows,
      'available_quests': availableQuestRows,
      'completed_quests': completedQuestRows,
      'digital_plaque_count': digitalPlaqueCount,
      'xp_available': xpAvailable,
      'task_awards_available': taskAwardsAvailable,
      'stamps_available': stampsAvailable,
      'available_quests_available': availableQuestsAvailable,
      'quest_statistics_available': questStatisticsAvailable,
      'digital_plaques_available': digitalPlaquesAvailable,
      'warnings': warnings,
    };
  }

  Future<Map<String, dynamic>> fetchTouristMapJourneyData() async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view Heritage Quest journeys.',
    );

    final warnings = <String>[];
    var questRows = <Map<String, dynamic>>[];
    var taskRows = <Map<String, dynamic>>[];
    var questProgressRows = <Map<String, dynamic>>[];
    var taskProgressRows = <Map<String, dynamic>>[];
    var stampRows = <Map<String, dynamic>>[];
    Map<String, dynamic>? experienceRow;
    var questDataAvailable = false;
    var xpAvailable = false;
    var stampsAvailable = false;

    try {
      questRows = List<Map<String, dynamic>>.from(
        await client
            .from('quests')
            .select(
              'id, artisan_id, title, category, stamp_title, '
              'stamp_image_url, status, created_at',
            )
            .eq('status', 'APPROVED')
            .order('created_at', ascending: false),
      );
      questDataAvailable = true;
    } catch (error) {
      warnings.add('quests');
      debugPrint('fetchTouristMapJourneyData quests note: $error');
    }

    try {
      taskRows = List<Map<String, dynamic>>.from(
        await client
            .from('heritage_tasks')
            .select(
              'id, quest_id, is_required, xp_reward, created_at, status, is_archived',
            )
            .eq('status', 'APPROVED')
            .eq('is_archived', false),
      );
    } catch (error) {
      warnings.add('tasks');
      debugPrint('fetchTouristMapJourneyData tasks note: $error');
    }

    try {
      questProgressRows = List<Map<String, dynamic>>.from(
        await client
            .from('quest_progress')
            .select('quest_id, status, started_at')
            .eq('user_id', user.id),
      );
    } catch (error) {
      warnings.add('quest_progress');
      debugPrint('fetchTouristMapJourneyData quest progress note: $error');
    }

    try {
      taskProgressRows = List<Map<String, dynamic>>.from(
        await client
            .from('task_progress')
            .select('task_id, is_completed')
            .eq('user_id', user.id),
      );
    } catch (error) {
      warnings.add('task_progress');
      debugPrint('fetchTouristMapJourneyData task progress note: $error');
    }

    try {
      stampRows = List<Map<String, dynamic>>.from(
        await client
            .from('passport_stamps')
            .select('quest_id')
            .eq('user_id', user.id),
      );
      stampsAvailable = true;
    } catch (error) {
      warnings.add('stamps');
      debugPrint('fetchTouristMapJourneyData stamps note: $error');
    }

    try {
      experienceRow = await client
          .from('user_experience')
          .select('total_xp')
          .eq('user_id', user.id)
          .maybeSingle();
      xpAvailable = true;
    } catch (error) {
      warnings.add('xp');
      debugPrint('fetchTouristMapJourneyData XP note: $error');
    }

    if (!questDataAvailable && !xpAvailable && !stampsAvailable) {
      throw StateError('Unable to load Heritage Quest journeys.');
    }

    return {
      'quests': questRows,
      'tasks': taskRows,
      'quest_progress': questProgressRows,
      'task_progress': taskProgressRows,
      'stamps': stampRows,
      'total_xp': experienceRow?['total_xp'] ?? 0,
      'quest_data_available': questDataAvailable,
      'xp_available': xpAvailable,
      'stamps_available': stampsAvailable,
      'warnings': warnings,
    };
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

  Future<Map<String, dynamic>> fetchArtisanHeritageAnalytics({
    required DateTime startedAtUtc,
    required DateTime endedAtUtcExclusive,
  }) async {
    final client = _requireSupabaseClient();
    final authenticatedUser = _requireAuthenticatedUser(
      client,
      'You must be signed in to view heritage analytics.',
    );
    final artisanProfile = await fetchCurrentArtisanQuestProfile();
    if (artisanProfile == null) {
      throw StateError(
        'No artisan profile is linked to this signed-in account.',
      );
    }

    final questRows = List<Map<String, dynamic>>.from(
      await client
          .from('quests')
          .select('id')
          .eq('artisan_id', artisanProfile['id'])
          .eq('status', 'APPROVED'),
    );
    final questIds = questRows
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (questIds.isEmpty) {
      return const {
        'visits': <Object>[],
        'stamps': <Object>[],
        'completions': <Object>[],
        'stamps_available': true,
        'completions_available': true,
      };
    }

    final arrivalTaskRows = List<Map<String, dynamic>>.from(
      await client
          .from('heritage_tasks')
          .select('id')
          .inFilter('quest_id', questIds)
          .eq('is_system_task', true)
          .eq('sort_order', 1)
          .eq('status', 'APPROVED')
          .eq('is_archived', false),
    );
    final arrivalTaskIds = arrivalTaskRows
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    var visits = <Map<String, dynamic>>[];
    var visitorSource = 'arrival_task';
    if (arrivalTaskIds.isNotEmpty) {
      visits = List<Map<String, dynamic>>.from(
        await client
            .from('task_progress')
            .select('user_id, completed_at')
            .inFilter('task_id', arrivalTaskIds)
            .eq('is_completed', true)
            .neq('user_id', authenticatedUser.id)
            .not('completed_at', 'is', null)
            .gte('completed_at', startedAtUtc.toIso8601String())
            .lt('completed_at', endedAtUtcExclusive.toIso8601String()),
      );
    } else {
      // Some legacy quests do not expose a reliably identifiable arrival task.
      // A completed approved quest is the only verified fallback available in
      // the existing schema.
      visitorSource = 'completed_quest';
      visits = List<Map<String, dynamic>>.from(
        await client
            .from('quest_progress')
            .select('user_id, completed_at')
            .inFilter('quest_id', questIds)
            .eq('status', 'COMPLETED')
            .neq('user_id', authenticatedUser.id)
            .not('completed_at', 'is', null)
            .gte('completed_at', startedAtUtc.toIso8601String())
            .lt('completed_at', endedAtUtcExclusive.toIso8601String()),
      );
    }

    var stamps = <Map<String, dynamic>>[];
    var completions = <Map<String, dynamic>>[];
    var stampsAvailable = false;
    var completionsAvailable = false;
    try {
      stamps = List<Map<String, dynamic>>.from(
        await client
            .from('passport_stamps')
            .select('user_id, quest_id')
            .inFilter('quest_id', questIds)
            .neq('user_id', authenticatedUser.id),
      );
      stampsAvailable = true;
    } catch (error) {
      debugPrint('Artisan passport-stamp analytics unavailable: $error');
    }
    try {
      completions = List<Map<String, dynamic>>.from(
        await client
            .from('quest_progress')
            .select('user_id, quest_id')
            .inFilter('quest_id', questIds)
            .eq('status', 'COMPLETED')
            .neq('user_id', authenticatedUser.id),
      );
      completionsAvailable = true;
    } catch (error) {
      debugPrint('Artisan quest-completion analytics unavailable: $error');
    }

    return {
      'visits': visits,
      'visitor_source': visitorSource,
      'stamps': stamps,
      'completions': completions,
      'stamps_available': stampsAvailable,
      'completions_available': completionsAvailable,
    };
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
          'qr_code_secret, geofence_radius_meters, stamp_title, stamp_image_url, status, '
          'created_at',
        )
        .eq('artisan_id', artisanProfileId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
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
    final row = await fetchCurrentQuestProgressSnapshot(questId);
    final status = row?['status'];
    return status is String && status.trim().isNotEmpty ? status : null;
  }

  Future<Map<String, dynamic>?> fetchCurrentQuestProgressSnapshot(
    String questId,
  ) async {
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
        .select('status, started_at')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .maybeSingle();

    return row;
  }

  Future<List<Map<String, dynamic>>> fetchActiveQuestProgressRows() async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view your active journey.',
    );
    return _fetchActiveQuestProgressRowsForUser(client, user.id);
  }

  Future<List<Map<String, dynamic>>> _fetchActiveQuestProgressRowsForUser(
    SupabaseClient client,
    String userId,
  ) async {
    final progressRows = List<Map<String, dynamic>>.from(
      await client
          .from('quest_progress')
          .select('quest_id, status, started_at')
          .eq('user_id', userId)
          .eq('status', 'IN_PROGRESS'),
    );
    if (progressRows.isEmpty) return const [];

    final questIds = progressRows
        .map((row) => row['quest_id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (questIds.isEmpty) return const [];

    final questRows = List<Map<String, dynamic>>.from(
      await client
          .from('quests')
          .select('id, artisan_id, title')
          .inFilter('id', questIds),
    );
    final questsById = {
      for (final row in questRows) row['id']?.toString() ?? '': row,
    };
    final artisanIds = questRows
        .map((row) => row['artisan_id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final artisanRows = artisanIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await client
                .from('artisan_profiles')
                .select('id, studio_name')
                .inFilter('id', artisanIds),
          );
    final artisansById = {
      for (final row in artisanRows) row['id']?.toString() ?? '': row,
    };

    final enriched = <Map<String, dynamic>>[];
    for (final progress in progressRows) {
      final questId = progress['quest_id']?.toString() ?? '';
      final quest = questsById[questId];
      final artisanId = quest?['artisan_id']?.toString() ?? '';
      final artisan = artisansById[artisanId];
      enriched.add({
        ...progress,
        'quest_title': quest?['title'] ?? 'Cultural Quest',
        'artisan_id': artisanId,
        'studio_name': artisan?['studio_name'] ?? 'Artisan Studio',
      });
    }
    enriched.sort(_compareActiveQuestRows);
    return enriched;
  }

  int _compareActiveQuestRows(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstStarted = DateTime.tryParse(
      first['started_at']?.toString() ?? '',
    )?.toUtc();
    final secondStarted = DateTime.tryParse(
      second['started_at']?.toString() ?? '',
    )?.toUtc();
    if (firstStarted != null && secondStarted != null) {
      final newestFirst = secondStarted.compareTo(firstStarted);
      if (newestFirst != 0) return newestFirst;
    } else if (firstStarted != null) {
      return -1;
    } else if (secondStarted != null) {
      return 1;
    }
    return (first['quest_id']?.toString() ?? '').compareTo(
      second['quest_id']?.toString() ?? '',
    );
  }

  Future<bool> hasEarnedQuestStamp(String questId) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view passport rewards.',
    );
    final row = await client
        .from('passport_stamps')
        .select('id')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .maybeSingle();
    return row != null;
  }

  Future<Map<String, dynamic>> startQuest({
    required String questId,
    required List<String> taskIds,
  }) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to start a quest.',
    );

    var activeRows = await _fetchActiveQuestProgressRowsForUser(
      client,
      user.id,
    );
    if (activeRows.isNotEmpty) {
      final activeQuestId = activeRows.first['quest_id']?.toString() ?? '';
      if (activeQuestId != questId) {
        return {
          'outcome': 'blocked',
          'active_rows': activeRows,
          'progress': activeRows.first,
        };
      }
      await _ensureTaskProgressRows(client, user.id, taskIds);
      return {
        'outcome': 'resumed',
        'active_rows': activeRows,
        'progress': activeRows.first,
      };
    }

    try {
      await client
          .from('quest_progress')
          .upsert(
            {'user_id': user.id, 'quest_id': questId, 'status': 'IN_PROGRESS'},
            onConflict: 'user_id,quest_id',
            ignoreDuplicates: true,
          );
    } catch (_) {
      activeRows = await _fetchActiveQuestProgressRowsForUser(client, user.id);
      if (activeRows.isEmpty) rethrow;
      final activeQuestId = activeRows.first['quest_id']?.toString() ?? '';
      if (activeRows.length > 1) {
        return {
          'outcome': 'integrity_conflict',
          'active_rows': activeRows,
          'progress': activeRows.first,
        };
      }
      if (activeQuestId == questId) {
        await _ensureTaskProgressRows(client, user.id, taskIds);
      }
      return {
        'outcome': activeQuestId == questId ? 'resumed' : 'blocked',
        'active_rows': activeRows,
        'progress': activeRows.first,
      };
    }

    activeRows = await _fetchActiveQuestProgressRowsForUser(client, user.id);
    final activeQuestId = activeRows.isEmpty
        ? ''
        : activeRows.first['quest_id']?.toString() ?? '';
    if (activeRows.length != 1 || activeQuestId != questId) {
      return {
        'outcome': activeRows.length > 1 ? 'integrity_conflict' : 'blocked',
        'active_rows': activeRows,
        'progress': activeRows.isEmpty ? null : activeRows.first,
      };
    }

    await _ensureTaskProgressRows(client, user.id, taskIds);
    return {
      'outcome': 'started',
      'active_rows': activeRows,
      'progress': activeRows.first,
    };
  }

  Future<void> _ensureTaskProgressRows(
    SupabaseClient client,
    String userId,
    List<String> taskIds,
  ) async {
    if (taskIds.isNotEmpty) {
      await client
          .from('task_progress')
          .upsert(
            taskIds
                .map(
                  (taskId) => {
                    'user_id': userId,
                    'task_id': taskId,
                    'is_completed': false,
                  },
                )
                .toList(growable: false),
            onConflict: 'user_id,task_id',
            ignoreDuplicates: true,
          );
    }
  }

  Future<List<Map<String, dynamic>>> fetchTaskProgress(
    List<String> taskIds,
  ) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view task progress.',
    );
    if (taskIds.isEmpty) return const [];

    final rows = await client
        .from('task_progress')
        .select(_taskProgressColumns)
        .eq('user_id', user.id)
        .inFilter('task_id', taskIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> completeTask(String taskId) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to complete a task.',
    );
    final task = await client
        .from('heritage_tasks')
        .select('quest_id')
        .eq('id', taskId)
        .eq('status', 'APPROVED')
        .eq('is_archived', false)
        .maybeSingle();
    if (task == null) {
      throw StateError('This task is not available for completion.');
    }
    final questId = task['quest_id'].toString();
    await _assertNoDifferentActiveQuest(
      client: client,
      userId: user.id,
      questId: questId,
    );
    await _ensureTaskProgress(client, user.id, taskId);

    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('task_progress')
        .update({
          'is_completed': true,
          'completed_at': now,
          'progress_seconds': 0,
          'tracking_started_at': null,
          'updated_at': now,
        })
        .eq('user_id', user.id)
        .eq('task_id', taskId)
        .eq('is_completed', false);
    final completed = await _fetchTaskProgressRow(client, user.id, taskId);
    await _updateQuestRewardAndCompletion(
      client: client,
      userId: user.id,
      questId: questId,
    );
    return completed;
  }

  Future<Map<String, dynamic>> completeTaskWithArtisanQr({
    required String questId,
    required String artisanId,
    required String taskId,
    required String qrPayload,
  }) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to verify a workshop task.',
    );

    final parts = qrPayload.trim().split(':');
    if (parts.length != 3 ||
        parts[0] != 'WK_ARTISAN' ||
        parts[1] != artisanId ||
        parts[2].trim().isEmpty) {
      throw StateError('This QR code does not belong to this artisan.');
    }

    final matchingQuest = await client
        .from('quests')
        .select('id')
        .eq('id', questId)
        .eq('artisan_id', artisanId)
        .eq('qr_code_secret', parts[2])
        .eq('status', 'APPROVED')
        .maybeSingle();
    if (matchingQuest == null) {
      throw StateError('This QR code does not belong to this artisan.');
    }

    final task = await client
        .from('heritage_tasks')
        .select('id, is_system_task, sort_order, created_at')
        .eq('id', taskId)
        .eq('quest_id', questId)
        .eq('status', 'APPROVED')
        .eq('is_archived', false)
        .maybeSingle();
    if (task == null) {
      throw StateError('This task is not available for verification.');
    }
    if (task['is_system_task'] == true) {
      throw StateError(
        'System tasks complete automatically and do not require a QR scan.',
      );
    }

    final questProgress = await client
        .from('quest_progress')
        .select('status, started_at')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .maybeSingle();
    final progressStatus = questProgress?['status']?.toString().toUpperCase();
    final taskCreatedAt = DateTime.tryParse(
      task['created_at']?.toString() ?? '',
    )?.toUtc();
    final participantStartedAt = DateTime.tryParse(
      questProgress?['started_at']?.toString() ?? '',
    )?.toUtc();
    final isBonusForParticipant =
        taskCreatedAt != null &&
        participantStartedAt != null &&
        taskCreatedAt.isAfter(participantStartedAt);
    final hasStamp =
        progressStatus == 'COMPLETED' ||
        await client
                .from('passport_stamps')
                .select('id')
                .eq('user_id', user.id)
                .eq('quest_id', questId)
                .maybeSingle() !=
            null;
    final isPermanentlyCompleted = progressStatus == 'COMPLETED' || hasStamp;
    final canCompleteJourneyTask =
        progressStatus == 'IN_PROGRESS' && !isPermanentlyCompleted;
    final canCompleteBonusTask =
        isPermanentlyCompleted && isBonusForParticipant;
    if (!canCompleteJourneyTask && !canCompleteBonusTask) {
      throw StateError('Start this quest before scanning the workshop QR.');
    }

    await _ensureTaskProgress(client, user.id, taskId);
    final current = await _fetchTaskProgressRow(client, user.id, taskId);
    if (current['is_completed'] == true) return current;

    return completeTask(taskId);
  }

  Future<void> _updateQuestRewardAndCompletion({
    required SupabaseClient client,
    required String userId,
    required String questId,
  }) async {
    final progress = await client
        .from('quest_progress')
        .select('status, started_at')
        .eq('user_id', userId)
        .eq('quest_id', questId)
        .maybeSingle();
    if (progress == null) return;

    final existingStamp = await client
        .from('passport_stamps')
        .select('id')
        .eq('user_id', userId)
        .eq('quest_id', questId)
        .maybeSingle();
    if (progress['status']?.toString().toUpperCase() == 'COMPLETED' ||
        existingStamp != null) {
      return;
    }

    final participantStartedAt = DateTime.tryParse(
      progress['started_at']?.toString() ?? '',
    )?.toUtc();
    final taskRows = await client
        .from('heritage_tasks')
        .select('id, is_required, created_at')
        .eq('quest_id', questId)
        .eq('status', 'APPROVED')
        .eq('is_archived', false);
    final tasks = List<Map<String, dynamic>>.from(taskRows);
    final requiredTaskIds = tasks
        .where((row) {
          if (row['is_required'] != true) return false;
          final taskCreatedAt = DateTime.tryParse(
            row['created_at']?.toString() ?? '',
          )?.toUtc();
          return taskCreatedAt == null ||
              participantStartedAt == null ||
              !taskCreatedAt.isAfter(participantStartedAt);
        })
        .map((row) => row['id'].toString())
        .toList(growable: false);
    if (requiredTaskIds.isEmpty) return;

    final progressRows = await client
        .from('task_progress')
        .select('task_id')
        .eq('user_id', userId)
        .eq('is_completed', true)
        .inFilter('task_id', requiredTaskIds);
    final completedIds = List<Map<String, dynamic>>.from(
      progressRows,
    ).map((row) => row['task_id'].toString()).toSet();
    if (!requiredTaskIds.every(completedIds.contains)) return;

    await client
        .from('passport_stamps')
        .upsert(
          {
            'user_id': userId,
            'quest_id': questId,
            'stamp_code': 'QUEST_$questId',
          },
          onConflict: 'user_id,quest_id',
          ignoreDuplicates: true,
        );

    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('quest_progress')
        .update({'status': 'COMPLETED', 'completed_at': now})
        .eq('user_id', userId)
        .eq('quest_id', questId)
        .neq('status', 'COMPLETED');
  }

  Future<Map<String, dynamic>> startTimedTask(String taskId) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to track a task.',
    );
    final task = await client
        .from('heritage_tasks')
        .select('quest_id')
        .eq('id', taskId)
        .eq('status', 'APPROVED')
        .eq('is_archived', false)
        .maybeSingle();
    if (task == null) {
      throw StateError('This task is not available for tracking.');
    }
    await _assertNoDifferentActiveQuest(
      client: client,
      userId: user.id,
      questId: task['quest_id'].toString(),
    );
    await _ensureTaskProgress(client, user.id, taskId);

    final current = await _fetchTaskProgressRow(client, user.id, taskId);
    if (current['is_completed'] == true ||
        current['tracking_started_at'] != null) {
      return current;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('task_progress')
        .update({'tracking_started_at': now, 'updated_at': now})
        .eq('user_id', user.id)
        .eq('task_id', taskId)
        .eq('is_completed', false);
    return _fetchTaskProgressRow(client, user.id, taskId);
  }

  Future<Map<String, dynamic>> pauseTimedTask({
    required String taskId,
    required int progressSeconds,
  }) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to save task progress.',
    );
    await _ensureTaskProgress(client, user.id, taskId);

    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('task_progress')
        .update({
          'progress_seconds': progressSeconds.clamp(0, 900),
          'tracking_started_at': null,
          'updated_at': now,
        })
        .eq('user_id', user.id)
        .eq('task_id', taskId)
        .eq('is_completed', false);
    return _fetchTaskProgressRow(client, user.id, taskId);
  }

  Future<Map<String, dynamic>> completeTimedTask(String taskId) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to complete a task.',
    );
    final task = await client
        .from('heritage_tasks')
        .select('quest_id, is_system_task, sort_order')
        .eq('id', taskId)
        .eq('status', 'APPROVED')
        .eq('is_archived', false)
        .maybeSingle();
    if (task == null ||
        task['is_system_task'] != true ||
        task['sort_order'] != 2) {
      throw StateError('This is not the workshop timer system task.');
    }
    await _assertNoDifferentActiveQuest(
      client: client,
      userId: user.id,
      questId: task['quest_id'].toString(),
    );
    await _ensureTaskProgress(client, user.id, taskId);

    final current = await _fetchTaskProgressRow(client, user.id, taskId);
    if (current['is_completed'] == true) return current;

    var elapsedSeconds = (current['progress_seconds'] as num?)?.toInt() ?? 0;
    final trackingStartedAt = DateTime.tryParse(
      current['tracking_started_at']?.toString() ?? '',
    );
    if (trackingStartedAt != null) {
      final elapsed = DateTime.now().toUtc().difference(trackingStartedAt);
      if (!elapsed.isNegative) elapsedSeconds += elapsed.inSeconds;
    }
    if (elapsedSeconds < 900) {
      throw StateError(
        'Stay at the workshop for 15 minutes before completing this task.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('task_progress')
        .update({
          'is_completed': true,
          'completed_at': now,
          'progress_seconds': 900,
          'tracking_started_at': null,
          'updated_at': now,
        })
        .eq('user_id', user.id)
        .eq('task_id', taskId)
        .eq('is_completed', false);
    final completed = await _fetchTaskProgressRow(client, user.id, taskId);
    await _updateQuestRewardAndCompletion(
      client: client,
      userId: user.id,
      questId: task['quest_id'].toString(),
    );
    return completed;
  }

  static const String _taskProgressColumns =
      'user_id, task_id, is_completed, completed_at, progress_seconds, '
      'tracking_started_at';

  Future<void> _assertNoDifferentActiveQuest({
    required SupabaseClient client,
    required String userId,
    required String questId,
  }) async {
    final rows = await client
        .from('quest_progress')
        .select('quest_id')
        .eq('user_id', userId)
        .eq('status', 'IN_PROGRESS');
    final activeQuestIds = List<Map<String, dynamic>>.from(rows)
        .map((row) => row['quest_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    if (activeQuestIds.any((id) => id != questId)) {
      throw StateError(
        'Complete your active journey before attempting activities from '
        'another quest.',
      );
    }
  }

  SupabaseClient _requireSupabaseClient() {
    final client = _client;
    if (client == null) throw StateError('Supabase is not initialized.');
    return client;
  }

  User _requireAuthenticatedUser(SupabaseClient client, String message) {
    final user = client.auth.currentUser;
    if (user == null) throw StateError(message);
    return user;
  }

  Future<void> _ensureTaskProgress(
    SupabaseClient client,
    String userId,
    String taskId,
  ) async {
    await client
        .from('task_progress')
        .upsert(
          {'user_id': userId, 'task_id': taskId},
          onConflict: 'user_id,task_id',
          ignoreDuplicates: true,
        );
  }

  Future<Map<String, dynamic>> _fetchTaskProgressRow(
    SupabaseClient client,
    String userId,
    String taskId,
  ) async {
    return client
        .from('task_progress')
        .select(_taskProgressColumns)
        .eq('user_id', userId)
        .eq('task_id', taskId)
        .single();
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

    final updatedTask = await client
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
        .maybeSingle();
    if (updatedTask == null) {
      throw StateError(
        'This task submission is no longer pending or rejected. Refresh to see the latest admin decision.',
      );
    }
    return updatedTask;
  }

  Future<void> deleteUnapprovedHeritageTask(String taskId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to cancel a task submission.');
    }

    final deletedTask = await client
        .from('heritage_tasks')
        .delete()
        .eq('id', taskId)
        .eq('is_system_task', false)
        .eq('status', 'REJECTED')
        .select('id')
        .maybeSingle();
    if (deletedTask == null) {
      throw StateError('Only a rejected new task can be deleted immediately.');
    }
  }

  Future<void> deleteRejectedHeritageTaskEditRequest(String requestId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to dismiss a rejected update.');
    }

    final deletedRequest = await client
        .from('heritage_task_change_requests')
        .delete()
        .eq('id', requestId)
        .eq('request_type', 'EDIT')
        .eq('status', 'REJECTED')
        .select('id')
        .maybeSingle();
    if (deletedRequest == null) {
      throw StateError(
        'This rejected task update no longer exists or cannot be dismissed.',
      );
    }
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

  Future<Map<String, dynamic>> updatePendingHeritageTaskEditRequest({
    required String requestId,
    required String taskId,
    required String proposedTitle,
    required bool proposedIsRequired,
    required int proposedXpReward,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to edit a pending task update.');
    }

    final updatedRequest = await client
        .from('heritage_task_change_requests')
        .update({
          'proposed_title': proposedTitle.trim(),
          'proposed_is_required': proposedIsRequired,
          'proposed_xp_reward': proposedXpReward,
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('task_id', taskId)
        .eq('request_type', 'EDIT')
        .eq('status', 'PENDING_APPROVAL')
        .select(
          'id, task_id, request_type, proposed_title, proposed_is_required, '
          'proposed_xp_reward, status, rejection_reason, submitted_at, '
          'reviewed_at, reviewed_by',
        )
        .maybeSingle();

    if (updatedRequest == null) {
      throw StateError(
        'This task update is no longer pending. Refresh to see the latest admin decision.',
      );
    }
    return updatedRequest;
  }

  Future<void> deletePendingHeritageTaskEditRequest({
    required String requestId,
    required String taskId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError(
        'You must be signed in to cancel a pending task update.',
      );
    }

    final deletedRequest = await client
        .from('heritage_task_change_requests')
        .delete()
        .eq('id', requestId)
        .eq('task_id', taskId)
        .eq('request_type', 'EDIT')
        .eq('status', 'PENDING_APPROVAL')
        .select('id')
        .maybeSingle();
    if (deletedRequest == null) {
      throw StateError(
        'This task update is no longer pending. Refresh to see the latest admin decision.',
      );
    }
  }

  Future<Map<String, dynamic>> resubmitRejectedHeritageTaskEditRequest({
    required String requestId,
    required String taskId,
    required String proposedTitle,
    required bool proposedIsRequired,
    required int proposedXpReward,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('You must be signed in to resubmit a task update.');
    }

    final updatedRequest = await client
        .from('heritage_task_change_requests')
        .update({
          'proposed_title': proposedTitle.trim(),
          'proposed_is_required': proposedIsRequired,
          'proposed_xp_reward': proposedXpReward,
          'status': 'PENDING_APPROVAL',
          'rejection_reason': null,
          'reviewed_at': null,
          'reviewed_by': null,
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('task_id', taskId)
        .eq('request_type', 'EDIT')
        .eq('status', 'REJECTED')
        .select(
          'id, task_id, request_type, proposed_title, proposed_is_required, '
          'proposed_xp_reward, status, rejection_reason, submitted_at, '
          'reviewed_at, reviewed_by',
        )
        .maybeSingle();
    if (updatedRequest == null) {
      throw StateError(
        'This rejected task update no longer exists or cannot be resubmitted.',
      );
    }
    return updatedRequest;
  }

  Future<List<Map<String, dynamic>>>
  fetchPendingGamificationModerationRequests() async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    const taskColumns =
        'id, quest_id, title, is_required, xp_reward, sort_order, created_at, '
        'status, rejection_reason, reviewed_at, reviewed_by, is_system_task, '
        'is_archived';
    const questColumns =
        'id, artisan_id, title, description, category, qr_code_secret, '
        'geofence_radius_meters, stamp_title, stamp_image_url, status, '
        'created_at';
    const taskChangeColumns =
        'id, task_id, request_type, proposed_title, proposed_is_required, '
        'proposed_xp_reward, status, rejection_reason, submitted_at, '
        'reviewed_at, reviewed_by';

    final newTaskRows = List<Map<String, dynamic>>.from(
      await client
          .from('heritage_tasks')
          .select(taskColumns)
          .eq('status', 'PENDING_APPROVAL')
          .eq('is_system_task', false)
          .eq('is_archived', false),
    );
    final taskChangeRows = List<Map<String, dynamic>>.from(
      await client
          .from('heritage_task_change_requests')
          .select(taskChangeColumns)
          .eq('status', 'PENDING_APPROVAL'),
    );

    final tasksById = <String, Map<String, dynamic>>{
      for (final row in newTaskRows) row['id'].toString(): row,
    };
    final changedTaskIds = taskChangeRows
        .map((row) => row['task_id'].toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (changedTaskIds.isNotEmpty) {
      final currentTaskRows = List<Map<String, dynamic>>.from(
        await client
            .from('heritage_tasks')
            .select(taskColumns)
            .inFilter('id', changedTaskIds),
      );
      for (final row in currentTaskRows) {
        tasksById[row['id'].toString()] = row;
      }
    }

    final questIds = <String>{
      ...tasksById.values.map((row) => row['quest_id'].toString()),
    }.where((id) => id.isNotEmpty).toList(growable: false);
    final questsById = <String, Map<String, dynamic>>{};
    if (questIds.isNotEmpty) {
      final questRows = List<Map<String, dynamic>>.from(
        await client
            .from('quests')
            .select(questColumns)
            .inFilter('id', questIds),
      );
      for (final row in questRows) {
        questsById[row['id'].toString()] = row;
      }
    }

    final artisanIds = questsById.values
        .map((row) => row['artisan_id'].toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final artisanNames = <String, String>{};
    if (artisanIds.isNotEmpty) {
      final artisanRows = List<Map<String, dynamic>>.from(
        await client
            .from('artisan_profiles')
            .select('id, studio_name')
            .inFilter('id', artisanIds),
      );
      for (final row in artisanRows) {
        artisanNames[row['id'].toString()] =
            (row['studio_name'] ?? 'Artisan Studio').toString();
      }
    }

    final requests = <Map<String, dynamic>>[];
    for (final task in newTaskRows) {
      final quest = questsById[task['quest_id'].toString()];
      if (quest == null) continue;
      requests.add({
        'request_kind': 'NEW_TASK',
        'request_id': task['id'],
        'submitted_at': task['created_at'],
        'artisan_name': artisanNames[quest['artisan_id'].toString()],
        'quest': quest,
        'task': task,
      });
    }
    for (final change in taskChangeRows) {
      final task = tasksById[change['task_id'].toString()];
      final quest = task == null
          ? null
          : questsById[task['quest_id'].toString()];
      if (task == null || quest == null) continue;
      requests.add({
        'request_kind': 'TASK_CHANGE',
        'request_id': change['id'],
        'submitted_at': change['submitted_at'],
        'artisan_name': artisanNames[quest['artisan_id'].toString()],
        'quest': quest,
        'task': task,
        'task_change': change,
      });
    }
    requests.sort((a, b) {
      final aDate = DateTime.tryParse(a['submitted_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['submitted_at']?.toString() ?? '');
      return (bDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        aDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    return requests;
  }

  Future<void> reviewNewHeritageTask({
    required String taskId,
    required bool approve,
    String? rejectionReason,
  }) async {
    final client = _requireSupabaseClient();
    final pendingRows = List<Map<String, dynamic>>.from(
      await client
          .from('heritage_tasks')
          .select('id')
          .eq('id', taskId)
          .eq('status', 'PENDING_APPROVAL')
          .eq('is_system_task', false)
          .limit(1),
    );
    if (pendingRows.isEmpty) {
      throw StateError('This task is no longer pending or cannot be reviewed.');
    }

    await client
        .from('heritage_tasks')
        .update(
          _gamificationReviewFields(
            approve: approve,
            rejectionReason: rejectionReason,
          ),
        )
        .eq('id', taskId)
        .eq('status', 'PENDING_APPROVAL')
        .eq('is_system_task', false);
  }

  Future<void> reviewHeritageTaskChange({
    required String requestId,
    required bool approve,
    String? rejectionReason,
  }) async {
    final client = _requireSupabaseClient();
    final request = await client
        .from('heritage_task_change_requests')
        .select(
          'id, task_id, request_type, proposed_title, proposed_is_required, '
          'proposed_xp_reward, status',
        )
        .eq('id', requestId)
        .eq('status', 'PENDING_APPROVAL')
        .maybeSingle();
    if (request == null) {
      throw StateError('This task change request is no longer pending.');
    }

    if (approve) {
      final requestType = request['request_type'].toString().toUpperCase();
      if (requestType == 'DELETE') {
        await client
            .from('heritage_tasks')
            .update({'is_archived': true})
            .eq('id', request['task_id'])
            .eq('is_system_task', false);
      } else {
        final updates = <String, dynamic>{};
        if (request['proposed_title'] != null) {
          updates['title'] = request['proposed_title'];
        }
        if (request['proposed_is_required'] != null) {
          updates['is_required'] = request['proposed_is_required'];
        }
        if (request['proposed_xp_reward'] != null) {
          updates['xp_reward'] = request['proposed_xp_reward'];
        }
        if (updates.isNotEmpty) {
          await client
              .from('heritage_tasks')
              .update(updates)
              .eq('id', request['task_id'])
              .eq('is_system_task', false);
        }
      }
    }

    await client
        .from('heritage_task_change_requests')
        .update(
          _gamificationReviewFields(
            approve: approve,
            rejectionReason: rejectionReason,
          ),
        )
        .eq('id', requestId)
        .eq('status', 'PENDING_APPROVAL');
  }

  Map<String, dynamic> _gamificationReviewFields({
    required bool approve,
    String? rejectionReason,
  }) {
    final reviewerId = _client?.auth.currentUser?.id;
    return {
      'status': approve ? 'APPROVED' : 'REJECTED',
      'rejection_reason': approve ? null : rejectionReason?.trim(),
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      if (reviewerId != null) 'reviewed_by': reviewerId,
    };
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

  Stream<List<Map<String, dynamic>>> watchWorkshopLocations() {
    final client = _client;
    if (client == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }

    return client
        .from('artisan_profiles')
        .stream(primaryKey: const ['id'])
        .eq('status', 'APPROVED')
        .map(
          (rows) => rows
              .where(
                (row) => row['latitude'] != null && row['longitude'] != null,
              )
              .map(Map<String, dynamic>.from)
              .toList(growable: false),
        );
  }
}
