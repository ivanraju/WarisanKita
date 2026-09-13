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
import 'package:warisan_kita/domain/models/system_task_provisioning.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/ssm_validator.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';

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

  SupabaseClient get _authClient =>
      _client ??
      (throw StateError(
        'Authentication is unavailable. Please reconnect and try again.',
      ));

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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  // Profile cache only: never stores passwords or authenticates a user.
  static final Map<String, Map<String, dynamic>> _userStore = {};

  // Pending relocation requests store: cleanEmail -> {pending_relocation_address, ...}
  static final Map<String, Map<String, dynamic>> _pendingRelocationsStore = {};
  static const String _keyPendingRelocPrefix = 'pending_reloc_';
  static const String _keyPendingRelocEmails = 'wk_pending_reloc_emails';

  static Future<void> _savePendingRelocation(
    String email,
    Map<String, dynamic> data,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    _pendingRelocationsStore[cleanEmail] = Map<String, dynamic>.from(data);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPendingRelocPrefix$cleanEmail',
        jsonEncode(data),
      );
      final list = prefs.getStringList(_keyPendingRelocEmails) ?? [];
      if (!list.contains(cleanEmail)) {
        list.add(cleanEmail);
        await prefs.setStringList(_keyPendingRelocEmails, list);
      }
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
      final list = prefs.getStringList(_keyPendingRelocEmails) ?? [];
      if (list.contains(cleanEmail)) {
        list.remove(cleanEmail);
        await prefs.setStringList(_keyPendingRelocEmails, list);
      }
    } catch (e) {
      debugPrint('clearPendingRelocation note: $e');
    }
  }

  static Future<List<String>> getPendingRelocationEmails() async {
    final Set<String> emails = {..._pendingRelocationsStore.keys};
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingRelocEmails) ?? [];
      emails.addAll(list.map((e) => e.trim().toLowerCase()));
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_keyPendingRelocPrefix)) {
          final e = key.substring(_keyPendingRelocPrefix.length).trim().toLowerCase();
          if (e.isNotEmpty) emails.add(e);
        }
      }
    } catch (_) {}
    return emails.toList();
  }

  static Future<Map<String, dynamic>?> getPendingRelocationData(String email) async {
    return _getPendingRelocation(email);
  }

  static Future<void> savePendingRelocationData(
    String email,
    Map<String, dynamic> data,
  ) async {
    return _savePendingRelocation(email, data);
  }

  static Future<Map<String, dynamic>?> _getPendingRelocation(
    String email,
  ) async {
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
  static Future<UserModel> _enrichUserWithPendingRelocation(
    UserModel user,
  ) async {
    final email = user.email.trim().toLowerCase();
    if (email.isEmpty) return user;
    final reloc = await _getPendingRelocation(email);
    if (reloc != null) {
      final proposedAddress =
          (reloc['pending_relocation_address'] ?? reloc['address'])?.toString();
      // If the user's verified address in the database has already been updated to the proposed address,
      // the relocation has been officially approved! Clear the local pending relocation cache.
      if (proposedAddress != null &&
          proposedAddress.isNotEmpty &&
          user.address == proposedAddress) {
        await _clearPendingRelocation(email);
        return user.copyWith(clearPendingRelocation: true);
      }
      final pLat = reloc['pending_relocation_lat'] ?? reloc['latitude'];
      final pLng = reloc['pending_relocation_lng'] ?? reloc['longitude'];
      return user.copyWith(
        pendingRelocationAddress: proposedAddress,
        pendingRelocationState:
            (reloc['pending_relocation_state'] ?? reloc['state'])?.toString(),
        pendingRelocationLatitude: pLat is num
            ? pLat.toDouble()
            : (pLat != null ? double.tryParse(pLat.toString()) : null),
        pendingRelocationLongitude: pLng is num
            ? pLng.toDouble()
            : (pLng != null ? double.tryParse(pLng.toString()) : null),
        pendingRelocationReason:
            (reloc['pending_relocation_reason'] ?? reloc['reason'])?.toString(),
        pendingRelocationDate:
            (reloc['pending_relocation_date'] ?? reloc['date'])?.toString(),
      );
    } else if (user.hasPendingRelocation &&
        user.address != null &&
        user.pendingRelocationAddress != null &&
        user.pendingRelocationAddress!.trim().toLowerCase() ==
            user.address!.trim().toLowerCase()) {
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
    return !rows.any(
      (row) =>
          (row['status'] ?? '').toString().toUpperCase() != 'DELETED' &&
          (excludeEmail == null ||
              row['email'].toString().toLowerCase() !=
                  excludeEmail.trim().toLowerCase()),
    );
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

  Future<bool> isPhoneRegistered(
    String phone, {
    String? excludeEmail,
    String? excludeUserId,
  }) async {
    final clean = phone.trim();
    if (clean.isEmpty) return false;

    // 1. Check local in-memory store (fast cache & offline unit tests)
    for (final entry in _userStore.entries) {
      if (excludeEmail != null &&
          entry.key.toLowerCase().trim() == excludeEmail.toLowerCase().trim()) {
        continue;
      }
      final u = entry.value;
      if (excludeUserId != null && u['id']?.toString() == excludeUserId.trim()) {
        continue;
      }
      final existingPhone = (u['phone_number'] ?? u['phone']) as String?;
      if (existingPhone != null && existingPhone.trim().isNotEmpty) {
        if (ProfileValidator.arePhonesEqual(existingPhone, clean)) {
          return true;
        }
      }
    }

    // 2. Check Supabase database (deployed users table)
    final client = _client;
    if (client != null) {
      try {
        final userRows = await client
            .from('users')
            .select('id, email, phone_number, status')
            .not('phone_number', 'is', null)
            .timeout(const Duration(seconds: 10));

        for (final row in userRows) {
          final status = (row['status'] ?? '').toString().toUpperCase();
          if (status == 'DELETED') continue;

          if (excludeEmail != null &&
              row['email']?.toString().toLowerCase().trim() ==
                  excludeEmail.toLowerCase().trim()) {
            continue;
          }
          if (excludeUserId != null &&
              row['id']?.toString() == excludeUserId.trim()) {
            continue;
          }
          final rowPhone = row['phone_number']?.toString();
          if (rowPhone != null && rowPhone.trim().isNotEmpty) {
            if (ProfileValidator.arePhonesEqual(rowPhone, clean)) {
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('Supabase phone uniqueness check note: $e');
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
      isDualRole: false,
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
    final row = await client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();
    if (row == null) {
      throw const AuthException(
        'Account profile is unavailable. Please contact support.',
      );
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
        row['artisan_profiles'] = artisan;
        if (artisan['bio'] != null &&
            (artisan['bio'] as String).trim().isNotEmpty) {
          row['bio'] = artisan['bio'];
        }
        if (artisan['studio_name'] != null &&
            (artisan['studio_name'] as String).trim().isNotEmpty) {
          row['studio_name'] = artisan['studio_name'];
        }
        if (artisan['craft_category'] != null &&
            (artisan['craft_category'] as String).trim().isNotEmpty) {
          row['craft_category'] = artisan['craft_category'];
        }
        if (artisan['address'] != null &&
            (artisan['address'] as String).trim().isNotEmpty) {
          row['address'] = artisan['address'];
        }
        if (artisan['state'] != null &&
            (artisan['state'] as String).trim().isNotEmpty) {
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
          final aTags = List<String>.from(
            artisan['tags'] is List ? artisan['tags'] : [],
          );
          if (aTags.contains('__LIVE_DEMO_CLOSED__')) {
            row['is_live_open'] = false;
            row['isLiveOpen'] = false;
          } else {
            row['is_live_open'] = true;
            row['isLiveOpen'] = true;
          }
        }
        if (artisan['artisan_documents'] != null) {
          row['artisan_documents'] = artisan['artisan_documents'];
        }
        if (artisan['experience'] != null &&
            artisan['experience'].toString().trim().isNotEmpty) {
          row['experience'] = artisan['experience'].toString().trim();
        } else if (artisan['years_experience'] != null &&
            (artisan['years_experience'] as num) > 1) {
          row['experience'] = '${artisan['years_experience']} Years';
        }
        final userArtisanStat = (row['artisan_status'] ?? '')
            .toString()
            .toUpperCase();
        final isUserClosedOrPending =
            userArtisanStat == 'CLOSED' ||
            userArtisanStat == 'PENDING_APPROVAL' ||
            userArtisanStat == 'PENDING';

        if (artisan['status'] != null) {
          final artisanStatus = artisan['status'].toString().toUpperCase();
          if (!isUserClosedOrPending) {
            row['artisan_status'] = artisanStatus;
          }
          if (artisanStatus == 'CLOSED' || userArtisanStat == 'CLOSED') {
            row['role'] = 'Tourist';
            row['roles'] = ['Tourist'];
            row['artisan_status'] = 'CLOSED';
            row['studio_name'] = null;
            row['craft_category'] = null;
            row['ssm_number'] = null;
            row['artisan_profiles'] = null;
          } else if (artisanStatus == 'PENDING_APPROVAL' ||
              artisanStatus == 'PENDING' ||
              userArtisanStat == 'PENDING_APPROVAL' ||
              userArtisanStat == 'PENDING') {
            row['role'] = 'Tourist';
            row['roles'] = ['Tourist'];
            row['artisan_status'] = 'PENDING_APPROVAL';
            row['rejection_reason'] = null;
          } else if (artisanStatus == 'APPROVED' && !isUserClosedOrPending) {
            final userRole = (row['role'] ?? '').toString();
            final hasStudio =
                (row['studio_name'] != null &&
                    row['studio_name'].toString().trim().isNotEmpty) ||
                (artisan['studio_name'] != null &&
                    artisan['studio_name'].toString().trim().isNotEmpty);
            if (userRole.toLowerCase().contains('artisan') || hasStudio) {
              row['role'] = 'Artisan';
              row['roles'] = ['Artisan'];
              row['artisan_status'] = 'APPROVED';
            }
          } else if (artisanStatus == 'REJECTED') {
            row['artisan_status'] = 'REJECTED';
            if (artisan['rejection_reason'] != null) {
              row['rejection_reason'] = artisan['rejection_reason'];
            }
          }
        }
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
          if (artisan['bio'] != null &&
              (artisan['bio'] as String).trim().isNotEmpty) {
            row['bio'] = artisan['bio'];
          }
          if (artisan['studio_name'] != null &&
              (artisan['studio_name'] as String).trim().isNotEmpty) {
            row['studio_name'] = artisan['studio_name'];
          }
          if (artisan['craft_category'] != null &&
              (artisan['craft_category'] as String).trim().isNotEmpty) {
            row['craft_category'] = artisan['craft_category'];
          }
          if (artisan['address'] != null &&
              (artisan['address'] as String).trim().isNotEmpty) {
            row['address'] = artisan['address'];
          }
          if (artisan['state'] != null &&
              (artisan['state'] as String).trim().isNotEmpty) {
            row['state'] = artisan['state'];
          }
          if (artisan['latitude'] != null)
            row['latitude'] = artisan['latitude'];
          if (artisan['longitude'] != null)
            row['longitude'] = artisan['longitude'];
          if (artisan['tags'] != null) {
            row['tags'] = artisan['tags'];
            final aTags = List<String>.from(
              artisan['tags'] is List ? artisan['tags'] : [],
            );
            if (aTags.contains('__LIVE_DEMO_CLOSED__')) {
              row['is_live_open'] = false;
              row['isLiveOpen'] = false;
            } else {
              row['is_live_open'] = true;
              row['isLiveOpen'] = true;
            }
          }
          if (artisan['artisan_documents'] != null)
            row['artisan_documents'] = artisan['artisan_documents'];
          if (artisan['experience'] != null &&
              artisan['experience'].toString().trim().isNotEmpty) {
            row['experience'] = artisan['experience'].toString().trim();
          } else if (artisan['years_experience'] != null &&
              (artisan['years_experience'] as num) > 1) {
            final y = (artisan['years_experience'] as num).toInt();
            row['experience'] = '$y Years';
          }
          final userArtisanStat = (row['artisan_status'] ?? '')
              .toString()
              .toUpperCase();
          final isUserClosedOrPending =
              userArtisanStat == 'CLOSED' ||
              userArtisanStat == 'PENDING_APPROVAL' ||
              userArtisanStat == 'PENDING';

          if (artisan['status'] != null) {
            final artisanStatus = artisan['status'].toString().toUpperCase();
            if (!isUserClosedOrPending) {
              row['artisan_status'] = artisanStatus;
            }
            if (artisanStatus == 'CLOSED' || userArtisanStat == 'CLOSED') {
              row['role'] = 'Tourist';
              row['roles'] = ['Tourist'];
              row['artisan_status'] = 'CLOSED';
              row['studio_name'] = null;
              row['craft_category'] = null;
              row['ssm_number'] = null;
              row['artisan_profiles'] = null;
            } else if (artisanStatus == 'PENDING_APPROVAL' ||
                artisanStatus == 'PENDING' ||
                userArtisanStat == 'PENDING_APPROVAL' ||
                userArtisanStat == 'PENDING') {
              row['role'] = 'Tourist';
              row['roles'] = ['Tourist'];
              row['artisan_status'] = 'PENDING_APPROVAL';
              row['rejection_reason'] = null;
            } else if (artisanStatus == 'APPROVED' && !isUserClosedOrPending) {
              final userRole = (row['role'] ?? '').toString();
              final hasStudio =
                  (row['studio_name'] != null &&
                      row['studio_name'].toString().trim().isNotEmpty) ||
                  (artisan['studio_name'] != null &&
                      artisan['studio_name'].toString().trim().isNotEmpty);
              if (userRole.toLowerCase().contains('artisan') || hasStudio) {
                row['role'] = 'Artisan';
                row['roles'] = ['Artisan'];
                row['artisan_status'] = 'APPROVED';
              }
            } else if (artisanStatus == 'REJECTED') {
              row['artisan_status'] = 'REJECTED';
              if (artisan['rejection_reason'] != null) {
                row['rejection_reason'] = artisan['rejection_reason'];
              }
            }
          }
        }
      } catch (profileErr) {
        debugPrint('Error loading artisan_profiles fallback: $profileErr');
      }
    }

    final cachedStatus =
        (_userStore[authUser.email?.toLowerCase()]?['artisan_status'] ?? '')
            .toString()
            .toUpperCase();
    final userArtisanStatus = (row['artisan_status'] ?? '')
        .toString()
        .toUpperCase();
    if (userArtisanStatus == 'CLOSED' || cachedStatus == 'CLOSED') {
      row['role'] = 'Tourist';
      row['roles'] = ['Tourist'];
      row['artisan_status'] = 'CLOSED';
      row['studio_name'] = null;
      row['craft_category'] = null;
      row['ssm_number'] = null;
      row['artisan_profiles'] = null;
    } else if (userArtisanStatus == 'PENDING_APPROVAL' ||
        userArtisanStatus == 'PENDING') {
      row['role'] = 'Tourist';
      row['roles'] = ['Tourist'];
      row['artisan_status'] = 'PENDING_APPROVAL';
      row['rejection_reason'] = null;
    } else if (userArtisanStatus == 'APPROVED') {
      row['role'] = 'Artisan';
      row['roles'] = ['Artisan'];
      row['artisan_status'] = 'APPROVED';
    } else if (userArtisanStatus == 'REJECTED') {
      row['artisan_status'] = 'REJECTED';
    }

    if (row['is_live_open'] == null &&
        authUser.userMetadata?['is_live_open'] != null) {
      row['is_live_open'] = authUser.userMetadata!['is_live_open'];
      row['isLiveOpen'] = authUser.userMetadata!['is_live_open'];
    }

    if (row['experience'] == null &&
        _userStore.containsKey(authUser.email?.toLowerCase())) {
      final cached = _userStore[authUser.email!.toLowerCase()];
      if (cached?['experience'] != null &&
          cached!['experience'].toString().trim().isNotEmpty) {
        row['experience'] = cached['experience'].toString().trim();
      }
    }
    if (row['is_live_open'] == null &&
        _userStore.containsKey(authUser.email?.toLowerCase())) {
      final cached = _userStore[authUser.email!.toLowerCase()];
      if (cached?['is_live_open'] != null) {
        row['is_live_open'] = cached!['is_live_open'];
        row['isLiveOpen'] = cached['is_live_open'];
      }
    }
    if (row['phone_number'] == null ||
        row['phone_number'].toString().trim().isEmpty) {
      final userMeta = authUser.userMetadata;
      if (userMeta?['phone_number'] != null &&
          userMeta!['phone_number'].toString().trim().isNotEmpty) {
        row['phone_number'] = userMeta['phone_number'].toString().trim();
      } else if (userMeta?['phone'] != null &&
          userMeta!['phone'].toString().trim().isNotEmpty) {
        row['phone_number'] = userMeta['phone'].toString().trim();
      } else if (authUser.phone != null && authUser.phone!.trim().isNotEmpty) {
        row['phone_number'] = authUser.phone!.trim();
      } else if (_userStore.containsKey(authUser.email?.toLowerCase())) {
        final cached = _userStore[authUser.email!.toLowerCase()];
        if (cached?['phone_number'] != null &&
            cached!['phone_number'].toString().trim().isNotEmpty) {
          row['phone_number'] = cached['phone_number'].toString().trim();
        } else if (cached?['phone'] != null &&
            cached!['phone'].toString().trim().isNotEmpty) {
          row['phone_number'] = cached['phone'].toString().trim();
        }
      }
    }
    if (row['experience'] == null ||
        row['is_live_open'] == null ||
        row['phone_number'] == null ||
        row['phone_number'].toString().trim().isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawUser = prefs.getString(_keyAuthUser);
        if (rawUser != null && rawUser.isNotEmpty) {
          final cachedUser = jsonDecode(rawUser) as Map<String, dynamic>;
          if (row['experience'] == null &&
              cachedUser['experience'] != null &&
              cachedUser['experience'].toString().trim().isNotEmpty) {
            row['experience'] = cachedUser['experience'].toString().trim();
          }
          if (row['is_live_open'] == null &&
              cachedUser['is_live_open'] != null) {
            row['is_live_open'] = cachedUser['is_live_open'];
            row['isLiveOpen'] = cachedUser['is_live_open'];
          }
          if ((row['phone_number'] == null ||
                  row['phone_number'].toString().trim().isEmpty) &&
              cachedUser['phone_number'] != null &&
              cachedUser['phone_number'].toString().trim().isNotEmpty) {
            row['phone_number'] = cachedUser['phone_number'].toString().trim();
          } else if ((row['phone_number'] == null ||
                  row['phone_number'].toString().trim().isEmpty) &&
              cachedUser['phone'] != null &&
              cachedUser['phone'].toString().trim().isNotEmpty) {
            row['phone_number'] = cachedUser['phone'].toString().trim();
          }
        }
      } catch (_) {}
    }

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
      final pattern = username
          .replaceAll(r'\', r'\\')
          .replaceAll('_', r'\_')
          .replaceAll('%', r'\%');
      final row = await client
          .from('users')
          .select('email')
          .ilike('username', pattern)
          .maybeSingle();
      if (row == null)
        throw const AuthException('INVALID CREDENTIALS: Account not found.');
      email = row['email'] as String;
    }
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw const AuthException('Sign in did not create a valid session.');
      }
      final profile = await _loadAuthenticatedProfile();
      if (profile.status.toUpperCase() == 'SUSPENDED' || profile.isSuspended) {
        await signOut();
        throw const AuthException(
          'ACCOUNT SUSPENDED BY ADMINISTRATOR: Contact support.',
        );
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
      } catch (error) {
        // Retryable transport failures do not prove that the session is
        // invalid. Preserve it so a later refresh can recover normally.
        if (error is! AuthRetryableFetchException) {
          await signOut();
        }
        rethrow;
      }
    }

    // Fallback when client == null (offline or unit test without injected Supabase client)
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString(_keyAuthUser);
      if (rawUser != null && rawUser.isNotEmpty) {
        final map = jsonDecode(rawUser) as Map<String, dynamic>;
        UserModel user = await _enrichUserWithPendingRelocation(
          UserModel.fromMap(map),
        );
        final email = user.email.toLowerCase();
        if (user.status.toUpperCase() == 'DELETED' ||
            _deletedAccounts.contains(email)) {
          await _clearAuthSession();
          _userStore.remove(email);
          return null;
        }
        if (_userStore.containsKey(email)) {
          final storeData = _userStore[email]!;
          final storeStatus = (storeData['status'] ?? '')
              .toString()
              .toUpperCase();
          final isSuspended = storeData['isSuspended'] == true;
          final reason = (storeData['suspensionReason'] ?? '').toString();
          if (storeStatus == 'DELETED' ||
              (isSuspended && reason == 'ACCOUNT_DELETED')) {
            await _clearAuthSession();
            _userStore.remove(email);
            return null;
          }
          final fromStore = await _enrichUserWithPendingRelocation(
            UserModel.fromMap(storeData),
          );
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
      throw const AuthException(
        'This role cannot be created through registration.',
      );
    }
    final finalRole = isArtisan ? 'Artisan' : 'Tourist';
    final status = isArtisan ? 'PENDING_APPROVAL' : 'ACTIVE';
    final handle = (username?.trim().isNotEmpty == true
        ? username!.trim().replaceAll('@', '')
        : cleanEmail.split('@').first);
    if (!await isUsernameAvailable(handle)) {
      throw const AuthException(
        'USERNAME ALREADY TAKEN: Please choose a unique username.',
      );
    }
    if (isArtisan) {
      final error = SsmValidator.validate(ssmNumber);
      if (error != null) throw AuthException('INVALID SSM: $error');
      if (await isSsmRegistered(ssmNumber!)) {
        throw const AuthException(
          'DUPLICATE SSM: This studio is already registered.',
        );
      }
    }
    await signOut();
    final response = await client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'username': handle,
        'full_name': displayName ?? handle,
        'display_name': displayName ?? handle,
        'role': finalRole,
        'roles': [finalRole],
        'status': status,
        'studio_name': studioName,
        'craft_category': craftCategory,
        'ssm_number': ssmNumber,
      },
    );
    final user = response.user;
    if (user == null || user.identities?.isEmpty == true) {
      throw const AuthException(
        'Account could not be created. If already registered, please sign in.',
      );
    }
    await _unrecordDeletedAccount(cleanEmail);
    await _unrecordDeletedUsername(handle);
    // The auth.users trigger creates the profile atomically. Do not insert
    // a substitute identity when signup fails or before email confirmation.
    return UserModel(
      id: user.id,
      email: cleanEmail,
      username: handle,
      displayName: displayName ?? handle,
      role: finalRole,
      roles: [finalRole],
      status: status,
      studioName: studioName,
      craftCategory: craftCategory,
      ssmNumber: ssmNumber,
    );
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
    final account = await client
        .from('users')
        .select('role, username')
        .eq('email', cleanEmail)
        .maybeSingle();
    if (account == null) {
      throw const AuthException(
        'EMAIL NOT FOUND: No account is registered with this email address.',
      );
    }
    final role = (account['role'] ?? '').toString().toLowerCase();
    final username = (account['username'] ?? '').toString().toLowerCase();
    if (role.contains('admin') ||
        username == 'admin' ||
        username == 'clqadmin') {
      throw const AuthException(
        'ADMINISTRATOR ACCOUNT PROTECTED: Administrator credentials cannot be reset via self-service. Contact support.',
      );
    }
    await client.auth.resetPasswordForEmail(
      cleanEmail,
      redirectTo: kIsWeb
          ? Uri.base.resolve('/forgot-password').toString()
          : 'io.supabase.warisankita://reset-callback',
    );
  }

  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    if (_resetInProgress)
      throw const AuthException('Password reset is already in progress.');
    final client = _authClient;
    _resetInProgress = true;
    try {
      final session = client.auth.currentSession;
      // The UI enters this flow through a recovery link validated by Supabase.
      // An arbitrary token or an ordinary signed-in session is not recovery proof.
      if (token.isNotEmpty ||
          session == null ||
          session.isExpired ||
          _recoveryAccessToken != session.accessToken ||
          session.user.email?.toLowerCase() != email.trim().toLowerCase()) {
        throw const AuthException(
          'Invalid or expired recovery session. Please open a new password reset link.',
        );
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
        final message = e.message.toLowerCase();
        if (message.contains('should be different') ||
            message.contains('same as old') ||
            message.contains('same password') ||
            e.code == 'same_password') {
          throw const AuthException(
            'NEW PASSWORD CANNOT BE THE SAME AS YOUR CURRENT PASSWORD; it should be different.',
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

  Future<UserModel> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final client = _authClient;
    final response = await client.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: token.trim(),
      type: OtpType.signup,
    );
    if (response.session == null)
      throw const AuthException('Email verification failed.');
    try {
      return await _loadAuthenticatedProfile();
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  Future<void> resendVerificationOtp({required String email}) async {
    await _authClient.auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
    );
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
    String? premiseType,
  }) async {
    String cleanEmail = email.trim().toLowerCase();
    final client = _client;

    if (cleanEmail.isEmpty &&
        client != null &&
        client.auth.currentUser != null) {
      cleanEmail = client.auth.currentUser!.email?.toLowerCase() ?? '';
    }
    if (cleanEmail.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString(_keyAuthUser);
      if (rawUser != null && rawUser.isNotEmpty) {
        try {
          final cached = jsonDecode(rawUser) as Map<String, dynamic>;
          cleanEmail = (cached['email'] ?? '').toString().trim().toLowerCase();
        } catch (_) {}
      }
    }
    if (cleanEmail.isEmpty) {
      throw Exception('User email is required to submit artisan application.');
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

    final bool isVillage = premiseType != null &&
        (premiseType.contains('Village') ||
            premiseType.contains('Desa') ||
            premiseType.contains('Home') ||
            premiseType.contains('Kediaman'));

    final cleanSsm = ssmNumber.trim();
    if (cleanSsm.isNotEmpty) {
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
    } else if (!isVillage) {
      throw Exception('INVALID_SSM: SSM registration number is required for Commercial Studios.');
    }

    final cleanPhone = phone?.trim() ?? '';
    if (cleanPhone.isNotEmpty) {
      final phoneErr = ProfileValidator.validatePhone(cleanPhone);
      if (phoneErr != null) {
        throw Exception('INVALID_PHONE: $phoneErr');
      }
      final isPhoneTaken = await isPhoneRegistered(
        cleanPhone,
        excludeEmail: cleanEmail,
        excludeUserId: userRecord['id'],
      );
      if (isPhoneTaken) {
        throw Exception(
          'DUPLICATE_PHONE: An artisan studio or user account is already registered with contact phone "$cleanPhone".',
        );
      }
    }

    // Update user record with pending artisan credentials
    userRecord['studioName'] = studioName;
    userRecord['craftCategory'] = craftCategory;
    userRecord['ssmNumber'] = cleanSsm.isNotEmpty ? cleanSsm : (isVillage ? 'VILLAGE_EXEMPT' : '');
    if (premiseType != null) {
      userRecord['premiseType'] = premiseType;
      userRecord['premise_type'] = premiseType;
    }
    if (experience != null) userRecord['experience'] = experience;
    if (phone != null && phone.trim().isNotEmpty) {
      userRecord['phone'] = phone.trim();
      userRecord['phone_number'] = phone.trim();
    }
    if (bio != null && bio.trim().isNotEmpty) {
      userRecord['bio'] = bio.trim();
    }
    if (ssmFile != null) userRecord['ssm_file_name'] = ssmFile.name;
    if (certFile != null) userRecord['cert_file_name'] = certFile.name;
    if (address != null) userRecord['address'] = address;
    if (state != null) userRecord['state'] = state;
    userRecord['status'] = 'PENDING_APPROVAL';
    userRecord['artisanStatus'] = 'PENDING_APPROVAL';
    userRecord['artisan_status'] = 'PENDING_APPROVAL';
    userRecord['role'] = 'Tourist';
    userRecord['roles'] = ['Tourist'];
    userRecord['rejectionReason'] = null;
    userRecord['rejection_reason'] = null;

    final preservedDocuments = (userRecord['artisan_documents'] is List
            ? List<Map<String, dynamic>>.from(
                (userRecord['artisan_documents'] as List).map(
                  (item) => Map<String, dynamic>.from(item as Map),
                ),
              )
            : (userRecord['artisanDocuments'] is List
                ? List<Map<String, dynamic>>.from(
                    (userRecord['artisanDocuments'] as List).map(
                      (item) => Map<String, dynamic>.from(item as Map),
                    ),
                  )
                : (userRecord['artisan_profiles'] is Map &&
                        userRecord['artisan_profiles']['artisan_documents'] is List
                    ? List<Map<String, dynamic>>.from(
                        (userRecord['artisan_profiles']['artisan_documents'] as List).map(
                          (item) => Map<String, dynamic>.from(item as Map),
                        ),
                      )
                    : <Map<String, dynamic>>[])));

    void replaceLocalDocument(String type, PlatformFile? file) {
      if (file == null) return;
      preservedDocuments.removeWhere((doc) => doc['doc_type'] == type);
      preservedDocuments.add({
        'doc_type': type,
        'file_name': file.name,
        'file_url': '',
      });
    }

    final certDocType = isVillage ? 'CRAFTING_PHOTO' : 'SSM_BUSINESS_CERT';
    replaceLocalDocument(certDocType, ssmFile);
    replaceLocalDocument('KRAFTANGAN_MASTER_CERT', certFile);
    if (photos != null && photos.isNotEmpty) {
      preservedDocuments.removeWhere((doc) => doc['doc_type'] == 'STUDIO_PHOTO');
      for (final photo in photos) {
        preservedDocuments.add({
          'doc_type': 'STUDIO_PHOTO',
          'file_name': photo.name,
          'file_url': '',
        });
      }
    }
    userRecord['artisan_documents'] = preservedDocuments;
    userRecord['artisanDocuments'] = preservedDocuments;

    if (client != null) {
      try {
        try {
          await client.auth.updateUser(
            UserAttributes(
              data: {
                'status': 'ACTIVE',
                'role': 'Tourist',
                'artisan_status': 'PENDING_APPROVAL',
                'rejection_reason': null,
                'studio_name': studioName,
                'craft_category': craftCategory,
                'ssm_number': cleanSsm.isNotEmpty ? cleanSsm : (isVillage ? 'VILLAGE_EXEMPT' : ''),
                if (premiseType != null) 'premise_type': premiseType,
                if (phone != null && phone.trim().isNotEmpty)
                  'phone_number': phone.trim(),
                if (phone != null && phone.trim().isNotEmpty)
                  'phone': phone.trim(),
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

        final userPayload = <String, dynamic>{
          'status': 'ACTIVE',
          'role': 'Tourist',
          'artisan_status': 'PENDING_APPROVAL',
          'rejection_reason': null,
          if (phone != null && phone.trim().isNotEmpty)
            'phone_number': phone.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (existing != null) {
          try {
            await client.from('users').update(userPayload).eq('id', userId);
          } catch (uErr) {
            debugPrint('users table id update note: $uErr');
            try {
              await client
                  .from('users')
                  .update(userPayload)
                  .ilike('email', cleanEmail);
            } catch (uErr2) {
              debugPrint('users table email update note: $uErr2');
            }
          }
        } else {
          await client.from('users').insert({
            'id': userId,
            'email': cleanEmail,
            'username': userRecord['username'] ?? cleanEmail.split('@').first,
            'full_name': userRecord['displayName'] ?? studioName,
            ...userPayload,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        try {
          dynamic profileRes = await client
              .from('artisan_profiles')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

          final resolvedBio = (bio != null && bio.trim().isNotEmpty)
              ? bio.trim()
              : 'Master artisan dedicated to traditional Malaysian craft.';
          final resolvedState = (state != null && state.trim().isNotEmpty)
              ? state.trim()
              : 'Melaka';
          final resolvedAddress = (address != null && address.trim().isNotEmpty)
              ? address.trim()
              : resolvedState;

          final profileTags = List<String>.from(toolsAndMaterials);
          if (premiseType != null && premiseType.isNotEmpty) {
            profileTags.removeWhere((t) => t.startsWith('premise:'));
            profileTags.add('premise:$premiseType');
          }

          final profileData = <String, dynamic>{
            'studio_name': studioName,
            'craft_category': craftCategory,
            'ssm_number': cleanSsm.isNotEmpty ? cleanSsm : (isVillage ? 'VILLAGE_EXEMPT' : ''),
            if (experience != null &&
                experience.trim().isNotEmpty &&
                RegExp(r'\d+').firstMatch(experience) != null)
              'years_experience': int.tryParse(
                RegExp(r'\d+').firstMatch(experience)!.group(0)!,
              ),
            'bio': resolvedBio,
            'address': resolvedAddress,
            'state': resolvedState,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            'status': 'PENDING_APPROVAL',
            'rejection_reason': null,
            'tags': profileTags,
            'updated_at': DateTime.now().toIso8601String(),
          };

          if (profileRes != null) {
            try {
              await client
                  .from('artisan_profiles')
                  .update(profileData)
                  .eq('user_id', userId);
            } catch (err) {
              debugPrint('artisan_profiles update note: $err');
              final fallbackData = Map<String, dynamic>.from(profileData)
                ..remove('rejection_reason')
                ..remove('premise_type');
              try {
                await client
                    .from('artisan_profiles')
                    .update(fallbackData)
                    .eq('user_id', userId);
              } catch (err2) {
                debugPrint('artisan_profiles update fallback note: $err2');
                try {
                  await client.from('artisan_profiles').update({
                    'studio_name': studioName,
                    'craft_category': craftCategory,
                    'status': 'PENDING_APPROVAL',
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('user_id', userId);
                } catch (_) {}
              }
            }
          } else {
            profileData['user_id'] = userId;
            profileData['created_at'] = DateTime.now().toIso8601String();
            try {
              profileRes = await client
                  .from('artisan_profiles')
                  .insert(profileData)
                  .select('id')
                  .maybeSingle();
            } catch (err) {
              debugPrint('artisan_profiles insert note: $err');
              final fallbackData = Map<String, dynamic>.from(profileData)
                ..remove('rejection_reason')
                ..remove('premise_type');
              try {
                profileRes = await client
                    .from('artisan_profiles')
                    .insert(fallbackData)
                    .select('id')
                    .maybeSingle();
              } catch (_) {}
            }
          }

          if (profileRes != null) {
            final artisanId = profileRes['id'];

            Future<Map<String, String>?> uploadDoc(
              PlatformFile? file,
              String bucket,
              String folder,
            ) async {
              if (file == null) return null;
              try {
                Uint8List bytes;
                if (file.path != null) {
                  bytes = await io.File(file.path!).readAsBytes();
                } else {
                  bytes = await file.readAsBytes();
                }
                if (bytes.isEmpty) return null;

                final fileName =
                    '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
                String finalFileName = fileName;
                String mimeType = 'image/jpeg';

                final lcName = file.name.toLowerCase();
                if (lcName.endsWith('.pdf')) {
                  mimeType = 'application/pdf';
                } else if (lcName.endsWith('.png')) {
                  mimeType = 'image/png';
                } else if (lcName.endsWith('.webp')) {
                  mimeType = 'image/webp';
                } else if (lcName.endsWith('.jpg') || lcName.endsWith('.jpeg')) {
                  mimeType = 'image/jpeg';
                } else if (bytes.length > 4) {
                  if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
                    mimeType = 'application/pdf';
                  } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
                    mimeType = 'image/png';
                  } else if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
                    mimeType = 'image/jpeg';
                  }
                }

                if (mimeType.startsWith('image/') && !lcName.endsWith('.pdf')) {
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
                    }
                  } catch (e) {
                    debugPrint('WebP conversion note: $e');
                  }
                }

                final path = '$folder/$finalFileName';
                String? uploadedUrl;

                // 1. Try specified bucket
                try {
                  await client.storage
                      .from(bucket)
                      .uploadBinary(
                        path,
                        bytes,
                        fileOptions: FileOptions(contentType: mimeType, upsert: true),
                      );
                  uploadedUrl = client.storage.from(bucket).getPublicUrl(path);
                } catch (firstErr) {
                  debugPrint('Upload to $bucket failed ($firstErr), trying artisan_public_media fallback...');
                  if (bucket != 'artisan_public_media') {
                    try {
                      await client.storage
                          .from('artisan_public_media')
                          .uploadBinary(
                            path,
                            bytes,
                            fileOptions: FileOptions(contentType: mimeType, upsert: true),
                          );
                      uploadedUrl = client.storage.from('artisan_public_media').getPublicUrl(path);
                    } catch (secondErr) {
                      debugPrint('Fallback upload to artisan_public_media also failed: $secondErr');
                    }
                  }
                }

                if (uploadedUrl != null) {
                  return {'url': uploadedUrl, 'name': finalFileName};
                }

                // 2. Resilient fallback: base64 data URL so the uploaded proof is never lost
                if (mimeType.startsWith('image/')) {
                  final b64 = base64Encode(bytes);
                  return {'url': 'data:$mimeType;base64,$b64', 'name': finalFileName};
                }
                return null;
              } catch (e) {
                debugPrint('Upload error: $e');
                return null;
              }
            }

            try {
              final ssmBucket = isVillage ? 'artisan_public_media' : 'artisan_private_docs';
              final ssmUpload = await uploadDoc(
                ssmFile,
                ssmBucket,
                '$artisanId/${isVillage ? "craft" : "ssm"}',
              );
              final certUpload = await uploadDoc(
                certFile,
                'artisan_public_media',
                '$artisanId/cert',
              );

              final List<Map<String, dynamic>> docsToInsert = [];

              if (ssmUpload != null) {
                profileTags.removeWhere((t) =>
                    t.startsWith('doc_crafting_photo_') ||
                    t.startsWith('doc_ssm_cert_'));
                if (isVillage) {
                  profileTags.add('doc_crafting_photo_url:${ssmUpload['url']}');
                  profileTags.add('doc_crafting_photo_name:${ssmUpload['name']}');
                } else {
                  profileTags.add('doc_ssm_cert_url:${ssmUpload['url']}');
                  profileTags.add('doc_ssm_cert_name:${ssmUpload['name']}');
                }
                userRecord['ssm_file_url'] = ssmUpload['url'];
                userRecord['ssm_file_name'] = ssmUpload['name'];
                docsToInsert.add({
                  'artisan_id': artisanId,
                  'doc_type': isVillage ? 'CRAFTING_PHOTO' : 'SSM_BUSINESS_CERT',
                  'file_url': ssmUpload['url'],
                  'file_name': ssmUpload['name'],
                });
              }

              if (certUpload != null) {
                profileTags.removeWhere((t) => t.startsWith('doc_kraftangan_cert_'));
                profileTags.add('doc_kraftangan_cert_url:${certUpload['url']}');
                profileTags.add('doc_kraftangan_cert_name:${certUpload['name']}');
                userRecord['cert_file_url'] = certUpload['url'];
                userRecord['cert_file_name'] = certUpload['name'];
                docsToInsert.add({
                  'artisan_id': artisanId,
                  'doc_type': 'KRAFTANGAN_MASTER_CERT',
                  'file_url': certUpload['url'],
                  'file_name': certUpload['name'],
                });
              }

              if (photos != null && photos.isNotEmpty) {
                profileTags.removeWhere((t) => t.startsWith('doc_studio_photo:'));
                for (var p in photos) {
                  final pUpload = await uploadDoc(
                    p,
                    'artisan_public_media',
                    '$artisanId/studio',
                  );
                  if (pUpload != null) {
                    profileTags.add('doc_studio_photo:${pUpload['url']}');
                    docsToInsert.add({
                      'artisan_id': artisanId,
                      'doc_type': 'STUDIO_PHOTO',
                      'file_url': pUpload['url'],
                      'file_name': pUpload['name'],
                    });
                  }
                }
              }

              // Persist document metadata directly into artisan_profiles.tags so documents
              // are NEVER lost even if artisan_documents table has RLS policy restrictions
              try {
                await client
                    .from('artisan_profiles')
                    .update({'tags': profileTags})
                    .eq('id', artisanId);
                userRecord['tags'] = profileTags;
              } catch (tagErr) {
                debugPrint('artisan_profiles tags update note: $tagErr');
              }

              try {
                await client
                    .from('artisan_documents')
                    .delete()
                    .eq('artisan_id', artisanId);
                if (docsToInsert.isNotEmpty) {
                  final replacedTypes = docsToInsert.map((d) => d['doc_type']).toSet();
                  preservedDocuments.removeWhere((doc) => replacedTypes.contains(doc['doc_type']));
                  preservedDocuments.addAll(docsToInsert);
                  try {
                    await client
                        .from('artisan_documents')
                        .delete()
                        .eq('artisan_id', artisanId);
                    await client.from('artisan_documents').insert(preservedDocuments);
                  } catch (_) {}
                  userRecord['artisan_documents'] = preservedDocuments;
                  userRecord['artisanDocuments'] = preservedDocuments;
                }
              } catch (docErr) {
                debugPrint(
                  'Supabase linkArtisanRoleToTourist artisan_documents table note: $docErr',
                );
              }
            } catch (docErr) {
              debugPrint(
                'Supabase linkArtisanRoleToTourist document handling note: $docErr',
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

    userRecord['studioName'] = studioName;
    userRecord['studio_name'] = studioName;
    userRecord['craftCategory'] = craftCategory;
    userRecord['craft_category'] = craftCategory;
    userRecord['ssmNumber'] = cleanSsm.isNotEmpty ? cleanSsm : (isVillage ? 'VILLAGE_EXEMPT' : '');
    userRecord['ssm_number'] = cleanSsm.isNotEmpty ? cleanSsm : (isVillage ? 'VILLAGE_EXEMPT' : '');
    if (premiseType != null) {
      userRecord['premiseType'] = premiseType;
      userRecord['premise_type'] = premiseType;
    }
    userRecord['role'] = 'Tourist';
    userRecord['roles'] = const ['Tourist'];
    userRecord['status'] = 'PENDING_APPROVAL';
    userRecord['artisanStatus'] = 'PENDING_APPROVAL';
    userRecord['artisan_status'] = 'PENDING_APPROVAL';
    userRecord['rejectionReason'] = null;
    userRecord['rejection_reason'] = null;

    final currentDocs = userRecord['artisan_documents'] ?? preservedDocuments;
    userRecord['artisan_profiles'] = {
      if (userRecord['artisan_profiles'] is Map)
        ...(userRecord['artisan_profiles'] as Map),
      'studio_name': studioName,
      'craft_category': craftCategory,
      'ssm_number': cleanSsm.isNotEmpty ? cleanSsm : (isVillage ? 'VILLAGE_EXEMPT' : ''),
      'bio': bio ?? userRecord['bio'],
      'state': state ?? userRecord['state'],
      'address': address ?? userRecord['address'],
      'status': 'PENDING_APPROVAL',
      'rejection_reason': null,
      if (premiseType != null) 'premise_type': premiseType,
      'artisan_documents': currentDocs,
    };

    _userStore[cleanEmail] = userRecord;
    final returnUser = UserModel.fromMap(userRecord);
    await _saveAuthSession(returnUser);
    return returnUser;
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
            final existing = (entry.value['username'] as String?)
                ?.trim()
                .toLowerCase();
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
    if (phone != null && phone.trim().isNotEmpty) {
      final cleanPhone = phone.trim();
      final phoneErr = ProfileValidator.validatePhone(cleanPhone, isRequired: true);
      if (phoneErr != null) {
        throw Exception('INVALID_PHONE: $phoneErr');
      }
      final currentPhone = (userRecord['phone_number'] ?? userRecord['phone']) as String?;
      if (currentPhone == null || !ProfileValidator.arePhonesEqual(currentPhone, cleanPhone)) {
        final isTaken = await isPhoneRegistered(
          cleanPhone,
          excludeEmail: cleanEmail,
          excludeUserId: userRecord['id']?.toString(),
        );
        if (isTaken) {
          throw Exception(
            'DUPLICATE_PHONE: An artisan studio or user account is already registered with contact phone "$cleanPhone".',
          );
        }
      }
      userRecord['phone'] = cleanPhone;
      userRecord['phone_number'] = cleanPhone;
    }
    if (experience != null) userRecord['experience'] = experience;
    final List<String> currentTags = (userRecord['tags'] is List
        ? List<String>.from(userRecord['tags'])
        : (userRecord['artisan_profiles'] is Map && userRecord['artisan_profiles']['tags'] is List
            ? List<String>.from(userRecord['artisan_profiles']['tags'])
            : <String>[]));

    final existingSystemTags = currentTags
        .where((t) => t.startsWith('doc_') || t.startsWith('premise:'))
        .toList();

    List<String> existingUserTags;
    if (toolsAndMaterials != null) {
      final userTools = toolsAndMaterials
          .where((t) => !t.startsWith('doc_') && !t.startsWith('premise:') && !t.startsWith('__'))
          .toList();
      existingUserTags = [...userTools, ...existingSystemTags];
    } else {
      existingUserTags = List<String>.from(currentTags);
    }

    final bool currentIsLive =
        isLiveOpen ??
        (userRecord['is_live_open'] as bool?) ??
        (userRecord['isLiveOpen'] as bool?) ??
        (userRecord['artisan_profiles'] is Map
            ? (userRecord['artisan_profiles']['is_live_open'] as bool?)
            : null) ??
        true;

    if (isLiveOpen != null) {
      userRecord['is_live_open'] = isLiveOpen;
      userRecord['isLiveOpen'] = isLiveOpen;
    }

    if (!currentIsLive) {
      if (!existingUserTags.contains('__LIVE_DEMO_CLOSED__')) {
        existingUserTags.add('__LIVE_DEMO_CLOSED__');
      }
    } else {
      existingUserTags.removeWhere((t) => t == '__LIVE_DEMO_CLOSED__');
    }
    userRecord['tags'] = existingUserTags;

    if (workshopCount != null) {
      userRecord['workshop_count'] = workshopCount;
      userRecord['workshopCount'] = workshopCount;
    }

    Map<String, dynamic> apMap;
    if (userRecord['artisan_profiles'] is Map) {
      apMap = Map<String, dynamic>.from(userRecord['artisan_profiles'] as Map);
    } else {
      apMap = <String, dynamic>{};
    }
    if (apMap['id'] == null) {
      if (userRecord['artisanProfileId'] != null) {
        apMap['id'] = userRecord['artisanProfileId'];
      } else if (userRecord['artisan_profile_id'] != null) {
        apMap['id'] = userRecord['artisan_profile_id'];
      }
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
    apMap['is_live_open'] = currentIsLive;
    apMap['isLiveOpen'] = currentIsLive;

    final existingApTags = List<String>.from(existingUserTags);
    if (apMap['tags'] is List) {
      for (final t in (apMap['tags'] as List)) {
        final st = t.toString();
        if ((st.startsWith('doc_') || st.startsWith('premise:')) &&
            !existingApTags.contains(st)) {
          existingApTags.add(st);
        }
      }
    }
    apMap['tags'] = existingApTags;
    userRecord['tags'] = existingApTags;

    if (workshopCount != null) apMap['workshop_count'] = workshopCount;
    userRecord['artisan_profiles'] = apMap;

    if (isArtisanAccount || studioName != null || craftCategory != null) {
      if (userRecord['role'] != 'Artisan' &&
          userRecord['role'] != 'Master Artisan') {
        userRecord['role'] = 'Artisan';
      }
      if (userRecord['roles'] is List &&
          !(userRecord['roles'] as List).contains('Artisan')) {
        (userRecord['roles'] as List).add('Artisan');
      }
    }

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
        if (isLiveOpen != null) updateMap['is_live_open'] = isLiveOpen;
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

          // Optional attempt to update is_live_open on users table in case migration was executed
          if (isLiveOpen != null) {
            try {
              await client
                  .from('users')
                  .update({'is_live_open': isLiveOpen})
                  .ilike('email', cleanEmail);
            } catch (_) {}
          }

          // 2. Update or Insert Supabase Postgres 'artisan_profiles' table (Professional columns only, by user_id)
          if (isArtisanAccount ||
              studioName != null ||
              bio != null ||
              craftCategory != null ||
              toolsAndMaterials != null ||
              isLiveOpen != null ||
              experience != null) {
            try {
              final userRow = await client
                  .from('users')
                  .select('id, full_name, username')
                  .ilike('email', cleanEmail)
                  .maybeSingle();
              final String? effectiveUid =
                  userRow?['id']?.toString() ?? client.auth.currentUser?.id;
              if (effectiveUid != null) {
                final effectiveTags = List<String>.from(existingApTags);
                final artisanUpdates = <String, dynamic>{
                  if (studioName != null && studioName.trim().isNotEmpty)
                    'studio_name': studioName.trim(),
                  if (bio != null) 'bio': bio,
                  if (experience != null && experience.trim().isNotEmpty) ...{
                    'experience': experience.trim(),
                    if (RegExp(r'\d+').firstMatch(experience) != null)
                      'years_experience': int.tryParse(
                        RegExp(r'\d+').firstMatch(experience)!.group(0)!,
                      ),
                  },
                  if (state != null) 'state': state,
                  if (address != null) 'address': address,
                  if (latitude != null) 'latitude': latitude,
                  if (longitude != null) 'longitude': longitude,
                  if (craftCategory != null) 'craft_category': craftCategory,
                  if (toolsAndMaterials != null || isLiveOpen != null)
                    'tags': effectiveTags,
                  if (workshopCount != null) 'workshop_count': workshopCount,
                  'updated_at': DateTime.now().toIso8601String(),
                };
                if (artisanUpdates.isNotEmpty) {
                  final existingProfile = await client
                      .from('artisan_profiles')
                      .select('id, status, tags')
                      .eq('user_id', effectiveUid)
                      .maybeSingle();

                  if (existingProfile != null) {
                    if (existingProfile['id'] != null) {
                      apMap['id'] = existingProfile['id'];
                      userRecord['artisanProfileId'] = existingProfile['id'];
                      userRecord['artisan_profile_id'] = existingProfile['id'];
                    }
                    if (existingProfile['tags'] is List) {
                      for (final t in (existingProfile['tags'] as List)) {
                        final st = t.toString();
                        if ((st.startsWith('doc_') || st.startsWith('premise:')) &&
                            !effectiveTags.contains(st)) {
                          effectiveTags.add(st);
                        }
                      }
                      if (artisanUpdates.containsKey('tags')) {
                        artisanUpdates['tags'] = effectiveTags;
                      }
                    }
                    try {
                      await client
                          .from('artisan_profiles')
                          .update(artisanUpdates)
                          .eq('user_id', effectiveUid);
                    } catch (artisanErr) {
                      debugPrint(
                        'Direct artisan_profiles update note: $artisanErr',
                      );
                      if (artisanUpdates.containsKey('experience')) {
                        try {
                          final fallbackUpdates = Map<String, dynamic>.from(
                            artisanUpdates,
                          )..remove('experience');
                          await client
                              .from('artisan_profiles')
                              .update(fallbackUpdates)
                              .eq('user_id', effectiveUid);
                        } catch (fallbackErr) {
                          debugPrint(
                            'Fallback artisan_profiles update note: $fallbackErr',
                          );
                        }
                      }
                    }

                    // Optional attempt to update is_live_open column on artisan_profiles
                    if (isLiveOpen != null) {
                      try {
                        await client
                            .from('artisan_profiles')
                            .update({'is_live_open': isLiveOpen})
                            .eq('user_id', effectiveUid);
                      } catch (_) {}
                    }
                  } else {
                    // CRITICAL FIX: The artisan_profiles row was missing!
                    // Insert new record so artisan data is NEVER silently dropped.
                    final newProfile = Map<String, dynamic>.from(
                      artisanUpdates,
                    );
                    newProfile['user_id'] = effectiveUid;
                    newProfile['created_at'] = DateTime.now().toIso8601String();
                    newProfile['studio_name'] ??=
                        studioName ??
                        displayName ??
                        username ??
                        userRow?['full_name'] ??
                        'Artisan Studio';
                    newProfile['craft_category'] ??=
                        craftCategory ?? 'Traditional Crafts';
                    newProfile['bio'] ??=
                        bio ??
                        'Master artisan dedicated to traditional Malaysian craft.';
                    newProfile['experience'] ??= experience ?? '10+ Years';
                    newProfile['address'] ??= address ?? state ?? 'Malaysia';
                    newProfile['state'] ??= state ?? 'Malaysia';
                    newProfile['status'] = 'APPROVED';
                    if (latitude != null) newProfile['latitude'] = latitude;
                    if (longitude != null) newProfile['longitude'] = longitude;
                    newProfile['tags'] = effectiveTags;

                    try {
                      final inserted = await client
                          .from('artisan_profiles')
                          .insert(newProfile)
                          .select('id')
                          .maybeSingle();
                      if (inserted != null && inserted['id'] != null) {
                        apMap['id'] = inserted['id'];
                        userRecord['artisanProfileId'] = inserted['id'];
                        userRecord['artisan_profile_id'] = inserted['id'];
                      }
                    } catch (insertErr) {
                      debugPrint(
                        'Direct artisan_profiles insert note: $insertErr',
                      );
                      if (newProfile.containsKey('experience')) {
                        try {
                          final fallbackProfile = Map<String, dynamic>.from(
                            newProfile,
                          )..remove('experience');
                          final fallbackInserted = await client
                              .from('artisan_profiles')
                              .insert(fallbackProfile)
                              .select('id')
                              .maybeSingle();
                          if (fallbackInserted != null &&
                              fallbackInserted['id'] != null) {
                            apMap['id'] = fallbackInserted['id'];
                            userRecord['artisanProfileId'] =
                                fallbackInserted['id'];
                            userRecord['artisan_profile_id'] =
                                fallbackInserted['id'];
                          }
                        } catch (fallbackInsertErr) {
                          debugPrint(
                            'Fallback artisan_profiles insert note: $fallbackInsertErr',
                          );
                        }
                      }
                    }
                  }
                  userRecord['artisan_profiles'] = apMap;
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
    String? certUrl,
    String? certName,
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
    if (certUrl != null) {
      relocData['pending_relocation_cert_url'] = certUrl;
      relocData['pendingRelocationCertUrl'] = certUrl;
    }
    if (certName != null) {
      relocData['pending_relocation_cert_name'] = certName;
      relocData['pendingRelocationCertName'] = certName;
    }

    await _savePendingRelocation(cleanEmail, relocData);

    final userRecord =
        _userStore[cleanEmail] ?? <String, dynamic>{'email': cleanEmail};
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
            await client
                .from('artisan_profiles')
                .update({
                  'pending_relocation_address': address.trim(),
                  'pending_relocation_state': state.trim(),
                  'pending_relocation_lat': latitude,
                  'pending_relocation_lng': longitude,
                  'pending_relocation_reason': reason.trim(),
                  'pending_relocation_date':
                      relocData['pending_relocation_date'],
                  if (certUrl != null) 'pending_relocation_cert_url': certUrl,
                  if (certName != null)
                    'pending_relocation_cert_name': certName,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('user_id', userId);
          } catch (e) {
            debugPrint('Supabase submitRelocationRequest table note: $e');
          }
          try {
            await client
                .from('users')
                .update({
                  'pending_relocation_address': address.trim(),
                  'pending_relocation_state': state.trim(),
                  'pending_relocation_lat': latitude,
                  'pending_relocation_lng': longitude,
                  'pending_relocation_reason': reason.trim(),
                  'pending_relocation_date':
                      relocData['pending_relocation_date'],
                  if (certUrl != null) 'pending_relocation_cert_url': certUrl,
                  if (certName != null)
                    'pending_relocation_cert_name': certName,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', userId);
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
      pendingRelocationCertUrl: certUrl,
      pendingRelocationCertName: certName,
    );
    await _saveAuthSession(updatedModel);
    return updatedModel;
  }

  Future<UserModel> cancelRelocationRequest({required String email}) async {
    final cleanEmail = email.trim().toLowerCase();
    await Future.delayed(const Duration(milliseconds: 100));

    await _clearPendingRelocation(cleanEmail);

    final userRecord =
        _userStore[cleanEmail] ?? <String, dynamic>{'email': cleanEmail};
    userRecord.remove('pending_relocation_address');
    userRecord.remove('pending_relocation_state');
    userRecord.remove('pending_relocation_lat');
    userRecord.remove('pending_relocation_lng');
    userRecord.remove('pending_relocation_reason');
    userRecord.remove('pending_relocation_date');
    userRecord.remove('pending_relocation_cert_url');
    userRecord.remove('pending_relocation_cert_name');
    userRecord.remove('pendingRelocationAddress');
    userRecord.remove('pendingRelocationState');
    userRecord.remove('pendingRelocationLatitude');
    userRecord.remove('pendingRelocationLongitude');
    userRecord.remove('pendingRelocationReason');
    userRecord.remove('pendingRelocationDate');
    userRecord.remove('pendingRelocationCertUrl');
    userRecord.remove('pendingRelocationCertName');

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
            await client
                .from('artisan_profiles')
                .update({
                  'pending_relocation_address': null,
                  'pending_relocation_state': null,
                  'pending_relocation_lat': null,
                  'pending_relocation_lng': null,
                  'pending_relocation_reason': null,
                  'pending_relocation_date': null,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('user_id', userId);
          } catch (e) {
            debugPrint('Supabase cancelRelocationRequest table note: $e');
          }
          try {
            await client
                .from('users')
                .update({
                  'pending_relocation_address': null,
                  'pending_relocation_state': null,
                  'pending_relocation_lat': null,
                  'pending_relocation_lng': null,
                  'pending_relocation_reason': null,
                  'pending_relocation_date': null,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', userId);
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Supabase cancelRelocationRequest note: $e');
      }
    }

    final updatedModel = UserModel.fromMap(
      userRecord,
    ).copyWith(clearPendingRelocation: true);
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
    final userRecord =
        _userStore[cleanEmail] ?? <String, dynamic>{'email': cleanEmail};
    String? newAddress =
        proposedAddress ??
        relocData?['pending_relocation_address'] ??
        userRecord['pending_relocation_address'] ??
        userRecord['pendingRelocationAddress'];
    String? newState =
        proposedState ??
        relocData?['pending_relocation_state'] ??
        userRecord['pending_relocation_state'] ??
        userRecord['pendingRelocationState'];
    dynamic newLat =
        proposedLat ??
        relocData?['pending_relocation_lat'] ??
        userRecord['pending_relocation_lat'] ??
        userRecord['pendingRelocationLatitude'];
    dynamic newLng =
        proposedLng ??
        relocData?['pending_relocation_lng'] ??
        userRecord['pending_relocation_lng'] ??
        userRecord['pendingRelocationLongitude'];

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
          } else if (profileRes['artisan_profiles'] is List &&
              (profileRes['artisan_profiles'] as List).isNotEmpty) {
            ap = Map<String, dynamic>.from(
              (profileRes['artisan_profiles'] as List).first,
            );
          }
          newAddress ??=
              ap?['pending_relocation_address']?.toString() ??
              profileRes['pending_relocation_address']?.toString();
          newState ??=
              ap?['pending_relocation_state']?.toString() ??
              profileRes['pending_relocation_state']?.toString();
          newLat ??=
              ap?['pending_relocation_lat'] ??
              profileRes['pending_relocation_lat'];
          newLng ??=
              ap?['pending_relocation_lng'] ??
              profileRes['pending_relocation_lng'];
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
            if (newLat != null)
              'latitude': newLat is num
                  ? newLat
                  : double.tryParse(newLat.toString()),
            if (newLng != null)
              'longitude': newLng is num
                  ? newLng
                  : double.tryParse(newLng.toString()),
            'pending_relocation_address': null,
            'pending_relocation_state': null,
            'pending_relocation_lat': null,
            'pending_relocation_lng': null,
            'pending_relocation_reason': null,
            'pending_relocation_date': null,
            'updated_at': DateTime.now().toIso8601String(),
          };
          try {
            await client
                .from('artisan_profiles')
                .update(artisanUpdates)
                .eq('user_id', resolvedUserId);
          } catch (e) {
            debugPrint('artisan_profiles update note: $e');
            try {
              await client
                  .from('artisan_profiles')
                  .update({
                    if (newAddress != null) 'address': newAddress,
                    if (newState != null) 'state': newState,
                    if (newLat != null)
                      'latitude': newLat is num
                          ? newLat
                          : double.tryParse(newLat.toString()),
                    if (newLng != null)
                      'longitude': newLng is num
                          ? newLng
                          : double.tryParse(newLng.toString()),
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('user_id', resolvedUserId);
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
            await client
                .from('users')
                .update(userUpdates)
                .eq('id', resolvedUserId);
          } catch (e) {
            try {
              await client
                  .from('users')
                  .update({
                    if (newAddress != null) 'address': newAddress,
                    if (newState != null) 'state': newState,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', resolvedUserId);
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
      latitude: newLat is num
          ? newLat.toDouble()
          : (newLat != null ? double.tryParse(newLat.toString()) : null),
      longitude: newLng is num
          ? newLng.toDouble()
          : (newLng != null ? double.tryParse(newLng.toString()) : null),
      clearPendingRelocation: true,
    );
    await _saveAuthSession(updatedModel);
    return updatedModel;
  }

  Future<UserModel> rejectRelocationRequest({
    required String email,
    String? feedback,
  }) async {
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
              .or('status.ilike.%PENDING%,artisan_status.ilike.%PENDING%');
        } catch (_) {
          try {
            res = await client
                .from('users')
                .select('*, artisan_profiles(*, artisan_documents(*))')
                .or('status.ilike.%PENDING%,artisan_status.ilike.%PENDING%');
          } catch (_) {
            try {
              res = await client
                  .from('users')
                  .select()
                  .or('status.ilike.%PENDING%,artisan_status.ilike.%PENDING%');
            } catch (_) {
              res = await client
                  .from('users')
                  .select()
                  .ilike('status', '%PENDING%');
            }
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
              rowMap['phone'] ??=
                  rowMap['phone_number'] ?? ap['phone'] ?? ap['phone_number'];
              rowMap['phone_number'] ??= rowMap['phone'];
              rowMap['experience'] ??=
                  (ap['experience'] != null &&
                      ap['experience'].toString().trim().isNotEmpty)
                  ? (RegExp(
                          r'^\d+$',
                        ).hasMatch(ap['experience'].toString().trim())
                        ? '${ap['experience'].toString().trim()} Years'
                        : ap['experience'].toString().trim())
                  : (ap['years_experience'] != null &&
                            (ap['years_experience'] as num) > 1
                        ? '${(ap['years_experience'] as num).toInt()} Years'
                        : null);

              // Extract documents if they exist
              final apTags = ap['tags'] is List ? List<String>.from(ap['tags']) : <String>[];
              List<String> photos = [];
              String? ssmFileName;
              String? ssmFileUrl;
              String? certFileName;
              String? certFileUrl;
              String? avatarUrl;

              if (ap['artisan_documents'] is List) {
                final docs = ap['artisan_documents'] as List;
                for (var d in docs) {
                  final doc = d as Map;
                  final type = doc['doc_type']?.toString();
                  final url = doc['file_url']?.toString();
                  final name = doc['file_name']?.toString();

                  if (type == 'PORTFOLIO_IMAGE' || type == 'STUDIO_PHOTO') {
                    if (url != null) photos.add(url);
                  } else if (type == 'SSM_BUSINESS_CERT' ||
                             type == 'CRAFTING_PHOTO' ||
                             type == 'VILLAGE_HEAD_ENDORSEMENT') {
                    if (name != null) ssmFileName = name;
                    if (url != null) ssmFileUrl = url;
                  } else if (type == 'KRAFTANGAN_MASTER_CERT') {
                    if (name != null) certFileName = name;
                    if (url != null) certFileUrl = url;
                  } else if (type == 'MYKAD_SCAN') {
                    if (url != null) avatarUrl = url;
                  }
                }
              }

              // Fallback to tags if documents table query was restricted or empty
              if (ssmFileUrl == null) {
                for (final t in apTags) {
                  if (t.startsWith('doc_crafting_photo_url:')) {
                    ssmFileUrl = t.substring('doc_crafting_photo_url:'.length);
                    break;
                  } else if (t.startsWith('doc_ssm_cert_url:')) {
                    ssmFileUrl = t.substring('doc_ssm_cert_url:'.length);
                    break;
                  }
                }
              }
              if (ssmFileName == null) {
                for (final t in apTags) {
                  if (t.startsWith('doc_crafting_photo_name:')) {
                    ssmFileName = t.substring('doc_crafting_photo_name:'.length);
                    break;
                  } else if (t.startsWith('doc_ssm_cert_name:')) {
                    ssmFileName = t.substring('doc_ssm_cert_name:'.length);
                    break;
                  }
                }
              }
              if (ssmFileName == null && ssmFileUrl != null) {
                ssmFileName = ssmFileUrl.split('/').last;
              }
              if (certFileUrl == null) {
                for (final t in apTags) {
                  if (t.startsWith('doc_kraftangan_cert_url:')) {
                    certFileUrl = t.substring('doc_kraftangan_cert_url:'.length);
                    break;
                  }
                }
              }
              if (certFileName == null) {
                for (final t in apTags) {
                  if (t.startsWith('doc_kraftangan_cert_name:')) {
                    certFileName = t.substring('doc_kraftangan_cert_name:'.length);
                    break;
                  }
                }
              }
              if (certFileName == null && certFileUrl != null) {
                certFileName = certFileUrl.split('/').last;
              }
              for (final t in apTags) {
                if (t.startsWith('doc_studio_photo:')) {
                  final pUrl = t.substring('doc_studio_photo:'.length);
                  if (pUrl.isNotEmpty && !photos.contains(pUrl)) {
                    photos.add(pUrl);
                  }
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

              // Resolve premise_type
              String? pType = ap['premise_type']?.toString() ?? rowMap['premise_type']?.toString();
              if (pType == null) {
                for (final t in apTags) {
                  if (t.startsWith('premise:')) {
                    pType = t.substring('premise:'.length);
                    break;
                  }
                }
              }
              if (pType == null) {
                final docsList = (ap['artisan_documents'] is List) ? ap['artisan_documents'] as List : const [];
                final hasVillageDoc = docsList.any((d) =>
                    d is Map &&
                    (d['doc_type'] == 'CRAFTING_PHOTO' ||
                        d['doc_type'] == 'VILLAGE_HEAD_ENDORSEMENT')) ||
                    apTags.any((t) => t.startsWith('doc_crafting_photo_'));
                if (hasVillageDoc || ap['ssm_number'] == 'VILLAGE_EXEMPT') {
                  pType = 'Home / Village Workshop (Bengkel Kediaman / Desa)';
                }
              }
              if (pType != null) {
                rowMap['premise_type'] = pType;
                rowMap['premiseType'] = pType;
              }

              if (rowMap['ssm_file_url'] == null &&
                  photos.isNotEmpty &&
                  (pType?.contains('Home') == true ||
                   pType?.contains('Village') == true ||
                   ap['ssm_number'] == 'VILLAGE_EXEMPT')) {
                rowMap['ssm_file_url'] = photos.first;
                rowMap['ssm_file_name'] ??= photos.first.split('/').last;
              }
            }
            results.add(rowMap);
          }
        }

        // Also query artisan_profiles table directly to catch any pending applications
        try {
          final pendingProfiles = await client
              .from('artisan_profiles')
              .select('*, users(*), artisan_documents(*)')
              .ilike('status', '%PENDING%');
          for (final p in pendingProfiles) {
            final pMap = Map<String, dynamic>.from(p);
            final u = pMap['users'] is Map
                ? Map<String, dynamic>.from(pMap['users'])
                : <String, dynamic>{};
            final email = (u['email'] ?? pMap['email'] ?? '')
                .toString()
                .toLowerCase();
            if (email.isNotEmpty &&
                !results.any(
                  (r) => (r['email'] ?? '').toString().toLowerCase() == email,
                )) {
              final apExp =
                  (pMap['experience'] != null &&
                      pMap['experience'].toString().trim().isNotEmpty)
                  ? (RegExp(
                          r'^\d+$',
                        ).hasMatch(pMap['experience'].toString().trim())
                        ? '${pMap['experience'].toString().trim()} Years'
                        : pMap['experience'].toString().trim())
                  : (pMap['years_experience'] != null &&
                            (pMap['years_experience'] as num) > 1
                        ? '${(pMap['years_experience'] as num).toInt()} Years'
                        : (u['experience'] != null &&
                                  u['experience'].toString().trim().isNotEmpty
                              ? (RegExp(r'^\d+$').hasMatch(
                                      u['experience'].toString().trim(),
                                    )
                                    ? '${u['experience'].toString().trim()} Years'
                                    : u['experience'].toString().trim())
                              : 'Verified Studio'));
              final combined = <String, dynamic>{
                'id': u['id'] ?? pMap['user_id'] ?? pMap['id'],
                'full_name':
                    u['full_name'] ??
                    u['display_name'] ??
                    pMap['studio_name'] ??
                    'Artisan Applicant',
                'email': email,
                'studio_name': pMap['studio_name'] ?? u['studio_name'],
                'craft_category': pMap['craft_category'] ?? u['craft_category'],
                'ssm_number': pMap['ssm_number'] ?? u['ssm_number'],
                'bio': pMap['bio'] ?? u['bio'],
                'state': pMap['state'] ?? u['state'],
                'address': pMap['address'] ?? u['address'],
                'experience': apExp,
                'phone':
                    u['phone_number'] ??
                    u['phone'] ??
                    pMap['phone'] ??
                    pMap['phone_number'],
                'phone_number':
                    u['phone_number'] ??
                    u['phone'] ??
                    pMap['phone'] ??
                    pMap['phone_number'],
                'artisan_status': 'PENDING_APPROVAL',
                'artisan_profiles': pMap,
              };

              final pTags = pMap['tags'] is List ? List<String>.from(pMap['tags']) : <String>[];
              String? pPremise = pMap['premise_type']?.toString() ?? u['premise_type']?.toString();
              if (pPremise == null) {
                for (final t in pTags) {
                  if (t.startsWith('premise:')) {
                    pPremise = t.substring('premise:'.length);
                    break;
                  }
                }
              }

              if (pMap['artisan_documents'] is List) {
                final docs = pMap['artisan_documents'] as List;
                List<String> photos = [];
                for (var d in docs) {
                  final doc = d as Map;
                  final type = doc['doc_type']?.toString();
                  final url = doc['file_url']?.toString();
                  final name = doc['file_name']?.toString();
                  if ((type == 'PORTFOLIO_IMAGE' || type == 'STUDIO_PHOTO') &&
                      url != null) {
                    photos.add(url);
                  } else if (type == 'SSM_BUSINESS_CERT' ||
                             type == 'CRAFTING_PHOTO' ||
                             type == 'VILLAGE_HEAD_ENDORSEMENT') {
                    if (name != null) combined['ssm_file_name'] = name;
                    if (url != null) combined['ssm_file_url'] = url;
                  } else if (type == 'KRAFTANGAN_MASTER_CERT') {
                    if (name != null) combined['cert_file_name'] = name;
                    if (url != null) combined['cert_file_url'] = url;
                  }
                }
                if (photos.isNotEmpty) combined['photos'] = photos;
                if (pPremise == null) {
                  final hasVillageDoc = docs.any((d) =>
                      d is Map &&
                      (d['doc_type'] == 'CRAFTING_PHOTO' ||
                          d['doc_type'] == 'VILLAGE_HEAD_ENDORSEMENT'));
                  if (hasVillageDoc || pMap['ssm_number'] == 'VILLAGE_EXEMPT') {
                    pPremise = 'Home / Village Workshop (Bengkel Kediaman / Desa)';
                  }
                }
              }

              // Fallback to pTags if documents table was empty or restricted
              if (combined['ssm_file_url'] == null) {
                for (final t in pTags) {
                  if (t.startsWith('doc_crafting_photo_url:')) {
                    combined['ssm_file_url'] = t.substring('doc_crafting_photo_url:'.length);
                    break;
                  } else if (t.startsWith('doc_ssm_cert_url:')) {
                    combined['ssm_file_url'] = t.substring('doc_ssm_cert_url:'.length);
                    break;
                  }
                }
              }
              if (combined['ssm_file_name'] == null) {
                for (final t in pTags) {
                  if (t.startsWith('doc_crafting_photo_name:')) {
                    combined['ssm_file_name'] = t.substring('doc_crafting_photo_name:'.length);
                    break;
                  } else if (t.startsWith('doc_ssm_cert_name:')) {
                    combined['ssm_file_name'] = t.substring('doc_ssm_cert_name:'.length);
                    break;
                  }
                }
              }
              if (combined['ssm_file_name'] == null && combined['ssm_file_url'] != null) {
                combined['ssm_file_name'] = combined['ssm_file_url'].toString().split('/').last;
              }
              if (combined['cert_file_url'] == null) {
                for (final t in pTags) {
                  if (t.startsWith('doc_kraftangan_cert_url:')) {
                    combined['cert_file_url'] = t.substring('doc_kraftangan_cert_url:'.length);
                    break;
                  }
                }
              }
              if (combined['cert_file_name'] == null) {
                for (final t in pTags) {
                  if (t.startsWith('doc_kraftangan_cert_name:')) {
                    combined['cert_file_name'] = t.substring('doc_kraftangan_cert_name:'.length);
                    break;
                  }
                }
              }
              if (combined['cert_file_name'] == null && combined['cert_file_url'] != null) {
                combined['cert_file_name'] = combined['cert_file_url'].toString().split('/').last;
              }
              for (final t in pTags) {
                if (t.startsWith('doc_studio_photo:')) {
                  final pUrl = t.substring('doc_studio_photo:'.length);
                  final curPhotos = (combined['photos'] is List) ? List<String>.from(combined['photos'] as List) : <String>[];
                  if (pUrl.isNotEmpty && !curPhotos.contains(pUrl)) {
                    curPhotos.add(pUrl);
                    combined['photos'] = curPhotos;
                  }
                }
              }

              if (pPremise == null && pTags.any((t) => t.startsWith('doc_crafting_photo_'))) {
                pPremise = 'Home / Village Workshop (Bengkel Kediaman / Desa)';
              }

              final isVillagePending = (pPremise?.contains('Home') == true ||
                  pPremise?.contains('Village') == true ||
                  pMap['ssm_number'] == 'VILLAGE_EXEMPT');
              if (combined['ssm_file_url'] == null && isVillagePending && (combined['photos'] is List) && (combined['photos'] as List).isNotEmpty) {
                combined['ssm_file_url'] = (combined['photos'] as List).first;
                combined['ssm_file_name'] ??= combined['ssm_file_url'].toString().split('/').last;
              }

              if (pPremise != null) {
                combined['premise_type'] = pPremise;
                combined['premiseType'] = pPremise;
              }
              results.add(combined);
            }
          }
        } catch (apErr) {
          debugPrint(
            'Supabase getPendingArtisans artisan_profiles direct query note: $apErr',
          );
        }
      } catch (e) {
        debugPrint('Supabase getPendingArtisans note: $e');
      }
    }

    // Merge with in-memory _userStore
    for (final entry in _userStore.entries) {
      final user = entry.value;
      final status = (user['status'] ?? '').toString().toUpperCase();
      final artisanStatus =
          (user['artisan_status'] ?? user['artisanStatus'] ?? '')
              .toString()
              .toUpperCase();
      final userEmail = (user['email'] ?? entry.key).toString().toLowerCase();
      final hasReloc = user['pending_relocation_address'] != null ||
          user['pendingRelocationAddress'] != null ||
          _pendingRelocationsStore.containsKey(userEmail);
      if (status.contains('PENDING') ||
          artisanStatus.contains('PENDING') ||
          hasReloc) {
        if (!results.any(
          (r) => (r['email'] ?? '').toString().toLowerCase() == userEmail,
        )) {
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
            if (rowStatus == 'DELETED' || rowStatus == 'REJECTED') continue;

            final role = (rowMap['role'] ?? '').toString();
            if (!role.toLowerCase().contains('artisan')) continue;

            final artisanStatus = (rowMap['artisan_status'] ?? '')
                .toString()
                .toUpperCase();
            if (artisanStatus == 'CLOSED' || artisanStatus == 'REJECTED')
              continue;

            if (rowMap['artisan_profiles'] == null ||
                (rowMap['artisan_profiles'] is List &&
                    (rowMap['artisan_profiles'] as List).isEmpty)) {
              try {
                final ap = await client
                    .from('artisan_profiles')
                    .select()
                    .eq('user_id', rowMap['id'])
                    .maybeSingle();
                if (ap != null) rowMap['artisan_profiles'] = ap;
              } catch (_) {}
            }

            Map<String, dynamic>? apMap;
            if (rowMap['artisan_profiles'] is Map) {
              apMap = Map<String, dynamic>.from(rowMap['artisan_profiles']);
            } else if (rowMap['artisan_profiles'] is List &&
                (rowMap['artisan_profiles'] as List).isNotEmpty) {
              apMap = Map<String, dynamic>.from(
                (rowMap['artisan_profiles'] as List).first,
              );
            }
            if (apMap != null) {
              final apStatus = (apMap['status'] ?? '').toString().toUpperCase();
              if (apStatus == 'CLOSED' || apStatus == 'REJECTED') continue;
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
      final artisanStatus =
          (user['artisan_status'] ?? user['artisanStatus'] ?? '')
              .toString()
              .toUpperCase();
      final isSuspended = user['isSuspended'] == true || artisanStatus == 'SUSPENDED';
      final reason = (user['suspensionReason'] ?? '').toString();
      if (status == 'DELETED' ||
          status == 'REJECTED' ||
          artisanStatus == 'CLOSED' ||
          artisanStatus == 'REJECTED' ||
          (isSuspended && reason == 'ACCOUNT_DELETED')) {
        continue;
      }
      final email = (user['email'] ?? entry.key).toString().toLowerCase();
      if (_deletedAccounts.contains(email) || email.startsWith('deleted_')) {
        continue;
      }
      final existingIdx = results.indexWhere(
        (a) => a.email.toLowerCase() == email,
      );
      if ((role.contains('Artisan') || artisanStatus == 'SUSPENDED' || artisanStatus == 'APPROVED') && !status.contains('PENDING')) {
        if (existingIdx == -1) {
          results.add(
            ActiveArtisanMaster.fromMap(Map<String, dynamic>.from(user)),
          );
        } else {
          final existing = results[existingIdx];
          if ((existing.experience == 'Verified Studio' ||
                  existing.experience.isEmpty) &&
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
              .select(
                '*, artisan_profiles!artisan_profiles_user_id_fkey(*, artisan_documents(*))',
              )
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
                (rowMap['artisan_profiles'] is List &&
                    (rowMap['artisan_profiles'] as List).isEmpty)) {
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
      final existingIdx = results.indexWhere(
        (u) => u.email.toLowerCase() == email,
      );
      if (existingIdx == -1) {
        results.add(UserModel.fromMap(Map<String, dynamic>.from(user)));
      } else {
        final existing = results[existingIdx];
        final pendingAddr = (user['pending_relocation_address'] ?? user['pendingRelocationAddress'])?.toString();
        final pendingState = (user['pending_relocation_state'] ?? user['pendingRelocationState'])?.toString();
        final dynamic pLat = user['pending_relocation_lat'] ?? user['pendingRelocationLatitude'];
        final dynamic pLng = user['pending_relocation_lng'] ?? user['pendingRelocationLongitude'];
        final pendingReason = (user['pending_relocation_reason'] ?? user['pendingRelocationReason'])?.toString();
        final pendingDate = (user['pending_relocation_date'] ?? user['pendingRelocationDate'])?.toString();
        final pendingCertUrl = (user['pending_relocation_cert_url'] ?? user['pendingRelocationCertUrl'])?.toString();
        final pendingCertName = (user['pending_relocation_cert_name'] ?? user['pendingRelocationCertName'])?.toString();

        results[existingIdx] = existing.copyWith(
          experience: (existing.experience == null && user['experience'] != null)
              ? user['experience'].toString().trim()
              : existing.experience,
          pendingRelocationAddress: pendingAddr ?? existing.pendingRelocationAddress,
          pendingRelocationState: pendingState ?? existing.pendingRelocationState,
          pendingRelocationLatitude: pLat is num
              ? pLat.toDouble()
              : (pLat != null ? double.tryParse(pLat.toString()) : existing.pendingRelocationLatitude),
          pendingRelocationLongitude: pLng is num
              ? pLng.toDouble()
              : (pLng != null ? double.tryParse(pLng.toString()) : existing.pendingRelocationLongitude),
          pendingRelocationReason: pendingReason ?? existing.pendingRelocationReason,
          pendingRelocationDate: pendingDate ?? existing.pendingRelocationDate,
          pendingRelocationCertUrl: pendingCertUrl ?? existing.pendingRelocationCertUrl,
          pendingRelocationCertName: pendingCertName ?? existing.pendingRelocationCertName,
        );
      }
    }

    // Merge pending relocations into results
    for (int i = 0; i < results.length; i++) {
      results[i] = await _enrichUserWithPendingRelocation(results[i]);
    }

    // Ensure any user with a pending relocation in storage is present in results
    try {
      final pendingRelocEmails = await getPendingRelocationEmails();
      for (final relocEmail in pendingRelocEmails) {
        final clean = relocEmail.trim().toLowerCase();
        if (clean.isEmpty) continue;
        final existingIdx = results.indexWhere((u) => u.email.toLowerCase() == clean);
        if (existingIdx == -1) {
          final relocData = await _getPendingRelocation(clean);
          if (relocData != null) {
            final dynLat = relocData['pending_relocation_lat'] ?? relocData['latitude'];
            final dynLng = relocData['pending_relocation_lng'] ?? relocData['longitude'];
            results.add(
              UserModel(
                id: 'user_reloc_$clean',
                email: clean,
                displayName: relocData['name']?.toString() ?? 'Artisan Studio',
                studioName: relocData['studio_name']?.toString() ?? relocData['name']?.toString() ?? 'Artisan Studio',
                role: 'Artisan',
                status: 'ACTIVE',
                artisanStatus: 'APPROVED',
                state: relocData['state']?.toString() ?? 'Melaka',
                address: relocData['current_address']?.toString() ?? relocData['address']?.toString(),
                pendingRelocationAddress: (relocData['pending_relocation_address'] ?? relocData['address'])?.toString(),
                pendingRelocationState: (relocData['pending_relocation_state'] ?? relocData['state'])?.toString(),
                pendingRelocationLatitude: dynLat is num ? dynLat.toDouble() : (dynLat != null ? double.tryParse(dynLat.toString()) : null),
                pendingRelocationLongitude: dynLng is num ? dynLng.toDouble() : (dynLng != null ? double.tryParse(dynLng.toString()) : null),
                pendingRelocationReason: (relocData['pending_relocation_reason'] ?? relocData['reason'])?.toString(),
                pendingRelocationDate: (relocData['pending_relocation_date'] ?? relocData['date'])?.toString(),
                pendingRelocationCertUrl: (relocData['pending_relocation_cert_url'] ?? relocData['certUrl'])?.toString(),
                pendingRelocationCertName: (relocData['pending_relocation_cert_name'] ?? relocData['certName'])?.toString(),
              ),
            );
          }
        }
      }
    } catch (_) {}

    return results;
  }

  Future<void> _ensureDefaultSystemTasksForApproval({
    required SupabaseClient client,
    required String email,
  }) async {
    final userRow = await client
        .from('users')
        .select('id')
        .ilike('email', email)
        .maybeSingle();
    final userId = userRow?['id']?.toString().trim() ?? '';
    if (userId.isEmpty) {
      throw StateError('The artisan user account could not be found.');
    }

    final artisanProfile = await client
        .from('artisan_profiles')
        .select('id, studio_name, craft_category')
        .eq('user_id', userId)
        .maybeSingle();
    final artisanId = artisanProfile?['id']?.toString().trim() ?? '';
    if (artisanId.isEmpty) {
      throw StateError('The artisan profile could not be found.');
    }

    List<Map<String, dynamic>> questRows = List<Map<String, dynamic>>.from(
      await client
          .from('quests')
          .select('id, status')
          .eq('artisan_id', artisanId)
          .inFilter('status', const ['PENDING_APPROVAL', 'APPROVED']),
    );
    if (questRows.isEmpty) {
      final studioName =
          artisanProfile?['studio_name']?.toString().trim().isNotEmpty == true
          ? artisanProfile!['studio_name'].toString().trim()
          : 'Heritage Workshop';
      final craftCategory =
          artisanProfile?['craft_category']?.toString().trim().isNotEmpty ==
              true
          ? artisanProfile!['craft_category'].toString().trim()
          : 'Malaysian craft';
      try {
        final slug = craftCategory
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');
        final secret = '${artisanId}_${DateTime.now().millisecondsSinceEpoch}';
        final createdQuest = await client
            .from('quests')
            .insert({
              'artisan_id': artisanId,
              'title': '$studioName Cultural Quest',
              'category': 'Demonstration & Lore',
              'description':
                  'Visit $studioName and experience the heritage of $craftCategory.',
              'qr_code_secret': secret,
              'geofence_radius_meters': 50,
              'stamp_title': '$studioName Heritage Stamp',
              'stamp_image_url':
                  'https://zmvykemnpuremkebjvyo.supabase.co/storage/v1/object/public/quest-stamps/${slug.isEmpty ? "general" : slug}.webp',
              'status': 'APPROVED',
            })
            .select('id, status')
            .maybeSingle();
        if (createdQuest != null) {
          questRows = [createdQuest];
        }
      } catch (questInsertErr) {
        debugPrint(
          'Auto-provisioning quest for approved artisan note: $questInsertErr',
        );
      }
    }
    if (questRows.isEmpty) {
      throw StateError(
        'Approval cannot continue because this artisan has no current cultural quest.',
      );
    }
    if (questRows.length > 1) {
      throw StateError(
        'Approval cannot continue because this artisan has multiple current cultural quests.',
      );
    }

    final questId = questRows.single['id']?.toString().trim() ?? '';
    if (questId.isEmpty) {
      throw StateError('The artisan cultural quest is invalid.');
    }

    final taskRows = List<Map<String, dynamic>>.from(
      await client
          .from('heritage_tasks')
          .select(
            'id, title, is_required, xp_reward, sort_order, status, '
            'is_system_task, is_archived',
          )
          .eq('quest_id', questId),
    );

    // Recognize trigger-generated baseline tasks that missed the is_system_task flag
    for (final task in taskRows) {
      final sortOrder = task['sort_order'] is num
          ? (task['sort_order'] as num).toInt()
          : null;
      final title = (task['title'] ?? '').toString().toLowerCase();
      if (task['is_system_task'] != true) {
        if ((sortOrder == 1 && title.contains('workshop')) ||
            (sortOrder == 2 && title.contains('15 min'))) {
          task['is_system_task'] = true;
        }
      }
    }

    // Auto-shift custom tasks that occupy canonical system slots (1 or 2)
    final conflictingCustomTasks = taskRows.where((task) {
      final isSystem = task['is_system_task'] == true;
      final isArchived = task['is_archived'] == true;
      final sortOrder = task['sort_order'] is num
          ? (task['sort_order'] as num).toInt()
          : null;
      return !isSystem && !isArchived && (sortOrder == 1 || sortOrder == 2);
    }).toList();

    if (conflictingCustomTasks.isNotEmpty) {
      int nextAvailableOrder = 2;
      for (final task in taskRows) {
        final order = task['sort_order'] is num
            ? (task['sort_order'] as num).toInt()
            : 0;
        if (order > nextAvailableOrder) {
          nextAvailableOrder = order;
        }
      }

      for (final conflict in conflictingCustomTasks) {
        nextAvailableOrder++;
        final taskId = conflict['id']?.toString() ?? '';
        if (taskId.isNotEmpty) {
          try {
            await client
                .from('heritage_tasks')
                .update({'sort_order': nextAvailableOrder})
                .eq('id', taskId);
            conflict['sort_order'] = nextAvailableOrder;
          } catch (shiftErr) {
            debugPrint('Auto-shift conflicting custom task note: $shiftErr');
            conflict['sort_order'] = nextAvailableOrder;
          }
        }
      }
    }

    final plan = DefaultSystemTaskPolicy.plan(
      taskRows.map(
        (task) => ExistingQuestTaskSlot(
          id: task['id']?.toString() ?? '',
          sortOrder: task['sort_order'] is num
              ? (task['sort_order'] as num).toInt()
              : null,
          isSystemTask: task['is_system_task'] == true,
          isArchived: task['is_archived'] == true,
        ),
      ),
    );
    final reviewPayload = <String, dynamic>{
      'status': 'APPROVED',
      'rejection_reason': null,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      if (client.auth.currentUser != null)
        'reviewed_by': client.auth.currentUser!.id,
    };

    for (final specification in DefaultSystemTaskPolicy.specifications) {
      final existingTaskId = plan.taskIdsToNormalize[specification.sortOrder];
      try {
        if (existingTaskId == null) {
          await client.from('heritage_tasks').insert({
            'quest_id': questId,
            'title': specification.title,
            'is_required': true,
            'xp_reward': specification.xpReward,
            'sort_order': specification.sortOrder,
            'is_system_task': true,
            'is_archived': false,
            ...reviewPayload,
          });
        } else {
          await client
              .from('heritage_tasks')
              .update({
                'title': specification.title,
                'is_required': true,
                'xp_reward': specification.xpReward,
                'sort_order': specification.sortOrder,
                'is_system_task': true,
                'is_archived': false,
                ...reviewPayload,
              })
              .eq('id', existingTaskId);
        }
      } catch (taskErr) {
        debugPrint('Direct heritage_tasks provisioning note: $taskErr');
      }
    }

    final verifiedTasks = List<Map<String, dynamic>>.from(
      await client
          .from('heritage_tasks')
          .select(
            'title, is_required, xp_reward, sort_order, status, '
            'is_system_task, is_archived',
          )
          .eq('quest_id', questId)
          .eq('is_archived', false),
    );
    final isValid = DefaultSystemTaskPolicy.specifications.every((
      specification,
    ) {
      final matches = verifiedTasks.where(
        (task) =>
            task['sort_order'] == specification.sortOrder ||
            (task['title']?.toString().toLowerCase().contains(
                  specification.sortOrder == 1 ? 'workshop' : '15 min',
                ) ??
                false),
      );
      return matches.isNotEmpty;
    });
    if (!isValid) {
      throw StateError(
        'The two required system tasks could not be verified. Artisan approval was not completed.',
      );
    }
  }

  Future<void> updateArtisanStatusInDb({
    required String email,
    required String newStatus,
    required String newRole,
    bool updateArtisanProfileOnly = false,
    bool ensureSystemTasks = false,
    String? suspensionReason,
    String? rejectionReason,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final client = _client;
    final resolvedArtisanStatus =
        (newStatus.toUpperCase() == 'ACTIVE' ||
            newStatus.toUpperCase() == 'APPROVED')
        ? 'APPROVED'
        : (newStatus.toUpperCase() == 'REJECTED' ? 'REJECTED' : newStatus);
    final isApproval =
        ensureSystemTasks &&
        (newStatus.toUpperCase() == 'ACTIVE' ||
            newStatus.toUpperCase() == 'APPROVED') &&
        newRole.toLowerCase().contains('artisan');
    if (client != null && isApproval) {
      await _ensureDefaultSystemTasksForApproval(
        client: client,
        email: cleanEmail,
      );
    }

    if (_userStore.containsKey(cleanEmail)) {
      if (resolvedArtisanStatus == 'REJECTED') {
        _userStore[cleanEmail]!['rejectionReason'] = rejectionReason;
        _userStore[cleanEmail]!['rejection_reason'] = rejectionReason;
      } else if (resolvedArtisanStatus == 'APPROVED') {
        _userStore[cleanEmail]!['rejectionReason'] = null;
        _userStore[cleanEmail]!['rejection_reason'] = null;
      }
      if (updateArtisanProfileOnly) {
        _userStore[cleanEmail]!['artisanStatus'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['artisan_status'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['status'] = 'ACTIVE';
        _userStore[cleanEmail]!['isSuspended'] = (resolvedArtisanStatus == 'SUSPENDED');
        _userStore[cleanEmail]!['suspensionReason'] = null;
        _userStore[cleanEmail]!['suspension_reason'] = null;
        if (_userStore[cleanEmail]!['artisan_profiles'] is Map) {
          _userStore[cleanEmail]!['artisan_profiles']['status'] = resolvedArtisanStatus;
        }
        if (newRole.isNotEmpty) {
          _userStore[cleanEmail]!['role'] = newRole;
          _userStore[cleanEmail]!['roles'] = [newRole];
        }
      } else {
        _userStore[cleanEmail]!['status'] = newStatus;
        _userStore[cleanEmail]!['role'] = newRole;
        _userStore[cleanEmail]!['roles'] = [newRole];
        _userStore[cleanEmail]!['artisanStatus'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['artisan_status'] = resolvedArtisanStatus;
        _userStore[cleanEmail]!['isSuspended'] = (newStatus == 'SUSPENDED');
        if (newStatus == 'SUSPENDED') {
          _userStore[cleanEmail]!['suspensionReason'] = suspensionReason;
          _userStore[cleanEmail]!['suspension_reason'] = suspensionReason;
        } else {
          _userStore[cleanEmail]!['suspensionReason'] = null;
          _userStore[cleanEmail]!['suspension_reason'] = null;
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
                map['roles'] = [newRole];
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
                map['roles'] = [newRole];
              }
            }
            if (resolvedArtisanStatus == 'REJECTED') {
              map['rejectionReason'] = rejectionReason;
              map['rejection_reason'] = rejectionReason;
            } else if (resolvedArtisanStatus == 'APPROVED') {
              map['rejectionReason'] = null;
              map['rejection_reason'] = null;
            }
            await prefs.setString(_keyAuthUser, jsonEncode(map));
          }
        }
      } catch (e) {
        debugPrint('updateArtisanStatusInDb local sync note: $e');
      }
    }

    if (client != null) {
      // 1. Try invoking PostgreSQL SECURITY DEFINER RPC
      try {
        final rpcParams = <String, dynamic>{
          'p_email': cleanEmail,
          'p_status': newStatus,
          'p_role':
              (newStatus.toUpperCase() == 'REJECTED' && newRole == 'Tourist')
              ? null
              : newRole,
        };
        if (rejectionReason != null) {
          rpcParams['p_rejection_reason'] = rejectionReason;
        }
        await client.rpc('admin_update_user_status', params: rpcParams);
        debugPrint(
          'Supabase RPC admin_update_user_status succeeded for $cleanEmail',
        );
      } catch (rpcError) {
        debugPrint('Supabase RPC admin_update_user_status note: $rpcError');
      }

      // 2. Direct Table Updates Fallback
      try {
        final updatePayload = <String, dynamic>{
          'status': updateArtisanProfileOnly ? 'ACTIVE' : newStatus,
          'role': newRole,
          'artisan_status': resolvedArtisanStatus,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (newStatus == 'SUSPENDED') {
          updatePayload['is_suspended'] = true;
          if (suspensionReason != null) {
            updatePayload['suspension_reason'] = suspensionReason;
          }
        } else if (newStatus == 'ACTIVE') {
          updatePayload['is_suspended'] = false;
          updatePayload['suspension_reason'] = null;
        }
        if (resolvedArtisanStatus == 'REJECTED') {
          updatePayload['rejection_reason'] = rejectionReason;
        } else if (resolvedArtisanStatus == 'APPROVED') {
          updatePayload['rejection_reason'] = null;
        }
        try {
          await client
              .from('users')
              .update(updatePayload)
              .ilike('email', cleanEmail);
        } catch (updateErr) {
          // Fallback if remote table does not yet have suspension_reason/is_suspended column
          debugPrint('Direct user table update note: $updateErr');
          try {
            await client
                .from('users')
                .update({
                  'status': updateArtisanProfileOnly ? 'ACTIVE' : newStatus,
                  'role': newRole,
                  'artisan_status': resolvedArtisanStatus,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .ilike('email', cleanEmail);
          } catch (retryErr) {
            debugPrint('Direct user table fallback update note: $retryErr');
          }
        }

        // Update artisan_profiles status matching user_id if present
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
          if (artisanProfileBeforeUpdate != null) {
            final profileUpdatePayload = <String, dynamic>{
              'status': resolvedArtisanStatus,
              'updated_at': DateTime.now().toIso8601String(),
            };
            if (resolvedArtisanStatus == 'REJECTED' &&
                rejectionReason != null) {
              profileUpdatePayload['rejection_reason'] = rejectionReason;
            } else if (resolvedArtisanStatus == 'APPROVED') {
              profileUpdatePayload['rejection_reason'] = null;
            }
            await client
                .from('artisan_profiles')
                .update(profileUpdatePayload)
                .eq('user_id', userRow['id']);
          }

          // System tasks were verified before changing approval state. Keep
          // the one current quest aligned with the approved profile here.
          if (resolvedArtisanStatus == 'APPROVED' &&
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
          }
        }
      } catch (e) {
        debugPrint('Supabase direct updateArtisanStatusInDb note: $e');
        if (isApproval) {
          rethrow;
        }
      }
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
    final email = currentUser.email;
    if (email == null || email.isEmpty) {
      throw const AuthException('User email not found. Please sign in again.');
    }
    if (currentPassword.trim().toLowerCase() ==
        newPassword.trim().toLowerCase()) {
      throw const AuthException(
        'NEW PASSWORD IS TOO SIMILAR TO YOUR CURRENT PASSWORD',
      );
    }
    try {
      await client.auth.signInWithPassword(
        email: email,
        password: currentPassword.trim(),
      );
    } on AuthException catch (_) {
      throw const AuthException('INCORRECT CURRENT PASSWORD');
    }
    await client.auth.updateUser(UserAttributes(password: newPassword.trim()));
  }

  Future<UserModel> deactivateArtisanStudio() async {
    final prefs = await SharedPreferences.getInstance();
    final cloudUser = _client?.auth.currentUser;
    final email = (cloudUser?.email ?? prefs.getString(_keyAuthEmail) ?? '')
        .trim()
        .toLowerCase();
    if (email.isEmpty) {
      throw const AuthException('No active user session found.');
    }

    final existing = _userStore[email] ?? <String, dynamic>{'email': email};
    existing
      ..['role'] = 'Tourist'
      ..['roles'] = <String>['Tourist']
      ..['status'] = 'ACTIVE'
      ..['artisan_status'] = 'CLOSED'
      ..['artisanStatus'] = 'CLOSED'
      ..['studio_name'] = null
      ..['studioName'] = null
      ..['craft_category'] = null
      ..['craftCategory'] = null
      ..['ssm_number'] = null
      ..['ssmNumber'] = null
      ..['is_live_open'] = false
      ..remove('artisan_profiles');
    _userStore[email] = existing;

    final client = _client;
    if (client != null && cloudUser != null) {
      final userId = cloudUser.id;
      String effectiveUid = userId;
      try {
        final userLookup = await client
            .from('users')
            .select('id')
            .ilike('email', email)
            .maybeSingle();
        if (userLookup != null && userLookup['id'] != null) {
          effectiveUid = userLookup['id'].toString();
        }
      } catch (_) {}

      try {
        await client.rpc(
          'deactivate_artisan_studio',
          params: {'p_user_id': effectiveUid},
        );
      } catch (e) {
        debugPrint('deactivate_artisan_studio RPC note: $e');
      }
      try {
        await client.rpc(
          'admin_update_user_status',
          params: {
            'p_email': email,
            'p_status': 'CLOSED',
            'p_role': 'Tourist',
            'p_studio_name': null,
            'p_craft_category': null,
            'p_ssm_number': null,
          },
        );
      } catch (e) {
        debugPrint(
          'deactivateArtisanStudio admin_update_user_status fallback note: $e',
        );
      }

      // Retire active quests and remove artisan documents for this studio
      try {
        final apRows = await client
            .from('artisan_profiles')
            .select('id')
            .or('user_id.eq.$effectiveUid,user_id.eq.$userId');
        for (final ap in apRows) {
          if (ap['id'] != null) {
            try {
              await client
                  .from('artisan_documents')
                  .delete()
                  .eq('artisan_id', ap['id']);
            } catch (_) {}
            try {
              await client
                  .from('quests')
                  .update({'status': 'RETIRED'})
                  .eq('artisan_id', ap['id']);
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('deactivateArtisanStudio retire quests/docs note: $e');
      }

      // Remove artisan_profiles row upon studio deactivation
      bool profileRemoved = false;
      try {
        await client
            .from('artisan_profiles')
            .delete()
            .or('user_id.eq.$effectiveUid,user_id.eq.$userId');
        profileRemoved = true;
      } catch (e) {
        debugPrint('deactivateArtisanStudio delete artisan_profiles note: $e');
      }

      // Fallback: If delete was blocked by a foreign key constraint, mark as CLOSED (never SUSPENDED)
      if (!profileRemoved) {
        try {
          await client
              .from('artisan_profiles')
              .update({
                'status': 'CLOSED',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .or('user_id.eq.$effectiveUid,user_id.eq.$userId');
        } catch (e) {
          debugPrint('deactivateArtisanStudio profile status note: $e');
        }
      }

      // Resilient 3-tier user table update
      final fullPayload = <String, dynamic>{
        'role': 'Tourist',
        'roles': ['Tourist'],
        'artisan_status': 'CLOSED',
        'status': 'ACTIVE',
        'studio_name': null,
        'craft_category': null,
        'ssm_number': null,
        'is_live_open': false,
        'updated_at': DateTime.now().toIso8601String(),
      };
      bool userUpdated = false;
      try {
        await client.from('users').update(fullPayload).eq('id', effectiveUid);
        userUpdated = true;
      } catch (e) {
        debugPrint('deactivateArtisanStudio full update by id note: $e');
      }
      if (!userUpdated) {
        try {
          await client.from('users').update(fullPayload).ilike('email', email);
          userUpdated = true;
        } catch (e) {
          debugPrint('deactivateArtisanStudio full update by email note: $e');
        }
      }
      if (!userUpdated) {
        final fallbackPayload = <String, dynamic>{
          'role': 'Tourist',
          'artisan_status': 'CLOSED',
          'status': 'ACTIVE',
          'studio_name': null,
          'craft_category': null,
          'ssm_number': null,
          'updated_at': DateTime.now().toIso8601String(),
        };
        try {
          await client
              .from('users')
              .update(fallbackPayload)
              .eq('id', effectiveUid);
          userUpdated = true;
        } catch (e) {
          debugPrint('deactivateArtisanStudio fallback update by id note: $e');
        }
        if (!userUpdated) {
          try {
            await client
                .from('users')
                .update(fallbackPayload)
                .ilike('email', email);
            userUpdated = true;
          } catch (e) {
            debugPrint(
              'deactivateArtisanStudio fallback update by email note: $e',
            );
          }
        }
      }
      if (!userUpdated) {
        final minimalPayload = <String, dynamic>{
          'role': 'Tourist',
          'status': 'ACTIVE',
          'updated_at': DateTime.now().toIso8601String(),
        };
        try {
          await client
              .from('users')
              .update(minimalPayload)
              .eq('id', effectiveUid);
          userUpdated = true;
        } catch (e) {
          debugPrint('deactivateArtisanStudio minimal update by id note: $e');
        }
        if (!userUpdated) {
          try {
            await client
                .from('users')
                .update(minimalPayload)
                .ilike('email', email);
          } catch (e) {
            debugPrint(
              'deactivateArtisanStudio minimal update by email note: $e',
            );
          }
        }
      }

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
        debugPrint('deactivateArtisanStudio auth metadata note: $e');
      }
    }

    var updated = UserModel.fromMap(existing);
    if (client != null && cloudUser != null) {
      try {
        final reloaded = await _loadAuthenticatedProfile();
        updated = reloaded.copyWith(
          role: 'Tourist',
          roles: const ['Tourist'],
          artisanStatus: 'CLOSED',
          clearStudioDetails: true,
        );
      } catch (_) {}
    }
    updated = updated.copyWith(
      role: 'Tourist',
      roles: const ['Tourist'],
      artisanStatus: 'CLOSED',
      clearStudioDetails: true,
    );
    await _saveAuthSession(updated);
    return updated;
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

  Future<void> deleteAccount({
    required String userId,
    required String email,
    String? username,
    String? password,
  }) async {
    final clientForAuth = _client;
    if (password != null &&
        password.isNotEmpty &&
        clientForAuth?.auth.currentUser != null) {
      try {
        await clientForAuth!.auth.signInWithPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
      } on AuthException catch (_) {
        throw const AuthException('INCORRECT PASSWORD');
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanEmail = email.trim().toLowerCase();

    // 1. Record in persistent deleted accounts and usernames store
    await _recordDeletedAccount(cleanEmail);
    if (username != null && username.trim().isNotEmpty) {
      await _recordDeletedUsername(username);
    }
    final inMemoryUsername = (_userStore[cleanEmail]?['username'] as String?)
        ?.trim();
    if (inMemoryUsername != null && inMemoryUsername.isNotEmpty) {
      await _recordDeletedUsername(inMemoryUsername);
    }

    // 2. Remove user from local in-memory store
    _userStore.remove(cleanEmail);
    _userStore.removeWhere(
      (key, value) =>
          key.toLowerCase() == cleanEmail ||
          (userId.isNotEmpty && value['id'] == userId),
    );

    // 3. Clear any pending OTPs or reset tokens for this account
    _recoveryAccessToken = null;

    // 4. Clear local session from SharedPreferences
    await _clearAuthSession();

    // 5. Delete or deactivate in Supabase if connected
    final client = _client;
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
          await client.rpc(
            'admin_update_user_status',
            params: {'p_email': cleanEmail, 'p_status': 'DELETED'},
          );
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

        // D. Try direct DELETE on public.users table
        bool usersDeleted = false;
        if (!rpcDeleted && effectiveUserId.isNotEmpty) {
          try {
            await client.from('users').delete().eq('id', effectiveUserId);
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

        // F. Update Supabase Auth user metadata so it flags as DELETED
        try {
          await client.auth.updateUser(
            UserAttributes(data: {'status': 'DELETED', 'is_deleted': true}),
          );
        } catch (metaErr) {
          debugPrint('deleteAccount auth.updateUser note: $metaErr');
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
            '*, users(full_name, avatar_url, phone_number), artisan_documents(file_url, doc_type)',
          )
          .eq('status', 'APPROVED');

      debugPrint('Supabase response: $response');
      final list = List<Map<String, dynamic>>.from(response);
      final mapped = list.map((map) => ArtisanModel.fromMap(map)).toList();

      // Sync in-memory toggle state for current session consistency
      for (int i = 0; i < mapped.length; i++) {
        final a = mapped[i];
        for (final u in _userStore.values) {
          final uStudio = (u['studioName'] ?? u['studio_name'])
              ?.toString()
              .trim();
          final uName =
              (u['displayName'] ??
                      u['display_name'] ??
                      u['full_name'] ??
                      u['username'])
                  ?.toString()
                  .trim();
          if ((uStudio != null &&
                  uStudio.isNotEmpty &&
                  uStudio.toLowerCase() == a.name.toLowerCase()) ||
              (uName != null &&
                  uName.isNotEmpty &&
                  uName.toLowerCase() == a.name.toLowerCase())) {
            final uIsLive =
                u['is_live_open'] as bool? ?? u['isLiveOpen'] as bool?;
            final uPhone = (u['phone_number'] ?? u['phone'])?.toString().trim();
            ArtisanModel current = a;
            if (uIsLive != null && uIsLive != a.isLiveOpen) {
              current = current.copyWith(isLiveOpen: uIsLive);
            }
            if (uPhone != null &&
                uPhone.isNotEmpty &&
                (current.phone == null || current.phone!.isEmpty)) {
              current = current.copyWith(phone: uPhone);
            }
            mapped[i] = current;
            break;
          }
        }
      }
      debugPrint('Mapped artisans count: ${mapped.length}');
      return mapped;
    } catch (e) {
      debugPrint('Error fetching artisans from Supabase: $e');
      return [];
    }
  }

  Future<String?> ensureArtisanProfileId(
    String userId, {
    String? email,
    String? initialStatus,
  }) async {
    try {
      final cleanEmail = email?.trim().toLowerCase();
      // 1. Check in-memory store
      if (cleanEmail != null && _userStore.containsKey(cleanEmail)) {
        final storeData = _userStore[cleanEmail]!;
        if (storeData['artisanProfileId'] != null &&
            storeData['artisanProfileId'].toString().trim().isNotEmpty) {
          return storeData['artisanProfileId'].toString().trim();
        }
        if (storeData['artisan_profile_id'] != null &&
            storeData['artisan_profile_id'].toString().trim().isNotEmpty) {
          return storeData['artisan_profile_id'].toString().trim();
        }
        if (storeData['artisan_profiles'] is Map &&
            storeData['artisan_profiles']['id'] != null &&
            storeData['artisan_profiles']['id'].toString().trim().isNotEmpty) {
          return storeData['artisan_profiles']['id'].toString().trim();
        }
      }

      final client = _client;
      if (client != null && userId.isNotEmpty) {
        // 2. Query artisan_profiles for existing record
        try {
          final existing = await client
              .from('artisan_profiles')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();
          if (existing != null && existing['id'] != null) {
            final pid = existing['id'].toString();
            if (cleanEmail != null && _userStore.containsKey(cleanEmail)) {
              _userStore[cleanEmail]!['artisanProfileId'] = pid;
              _userStore[cleanEmail]!['artisan_profile_id'] = pid;
              if (_userStore[cleanEmail]!['artisan_profiles'] is Map) {
                _userStore[cleanEmail]!['artisan_profiles']['id'] = pid;
              }
            }
            return pid;
          }
        } catch (e) {
          debugPrint('ensureArtisanProfileId query note: $e');
        }

        // 3. If no row exists yet, create one so artisan documents and portfolio can attach
        try {
          final userRow = await client
              .from('users')
              .select('full_name, username, role, status, artisan_status')
              .eq('id', userId)
              .maybeSingle();
          final name =
              userRow?['full_name'] ?? userRow?['username'] ?? 'Artisan Studio';

          String? storeRole;
          String? storeStatus;
          String? storeArtisanStatus;
          if (cleanEmail != null && _userStore.containsKey(cleanEmail)) {
            final storeData = _userStore[cleanEmail]!;
            storeRole = storeData['role']?.toString();
            storeStatus = storeData['status']?.toString();
            storeArtisanStatus = storeData['artisan_status']?.toString();
          }

          final userRole =
              (userRow?['role'] ?? storeRole)?.toString().toLowerCase() ?? '';
          final userStatus =
              (userRow?['status'] ?? storeStatus)?.toString().toUpperCase() ??
              '';
          final artisanStatus =
              (userRow?['artisan_status'] ?? storeArtisanStatus)
                  ?.toString()
                  .toUpperCase() ??
              '';

          final isAlreadyApproved =
              (artisanStatus == 'APPROVED') ||
              (userRole == 'artisan' && userStatus == 'ACTIVE');
          final resolvedStatus =
              initialStatus?.trim().toUpperCase() ??
              (isAlreadyApproved ? 'APPROVED' : 'PENDING_APPROVAL');

          final newProfile = {
            'user_id': userId,
            'studio_name': name,
            'craft_category': 'Traditional Crafts',
            'bio': 'Master artisan dedicated to traditional Malaysian craft.',
            'status': resolvedStatus,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          final inserted = await client
              .from('artisan_profiles')
              .insert(newProfile)
              .select('id')
              .maybeSingle();
          if (inserted != null && inserted['id'] != null) {
            final pid = inserted['id'].toString();
            if (cleanEmail != null && _userStore.containsKey(cleanEmail)) {
              _userStore[cleanEmail]!['artisanProfileId'] = pid;
              _userStore[cleanEmail]!['artisan_profile_id'] = pid;
            }
            return pid;
          }
        } catch (e) {
          debugPrint('ensureArtisanProfileId insert note: $e');
        }
      }

      // 4. In-memory / offline mock fallback
      final fallbackId = 'artisan-$userId';
      if (cleanEmail != null && _userStore.containsKey(cleanEmail)) {
        _userStore[cleanEmail]!['artisanProfileId'] = fallbackId;
        _userStore[cleanEmail]!['artisan_profile_id'] = fallbackId;
        if (_userStore[cleanEmail]!['artisan_profiles'] is Map) {
          _userStore[cleanEmail]!['artisan_profiles']['id'] = fallbackId;
        }
      }
      return fallbackId;
    } catch (e) {
      debugPrint('ensureArtisanProfileId note: $e');
      return 'artisan-$userId';
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

      String effectiveArtisanId = artisanId.trim();
      if (effectiveArtisanId.isEmpty) {
        final currentUid = client.auth.currentUser?.id;
        if (currentUid != null) {
          final resolved = await ensureArtisanProfileId(currentUid);
          if (resolved != null) effectiveArtisanId = resolved;
        }
      }
      if (effectiveArtisanId.isEmpty) {
        debugPrint(
          'uploadArtisanDocument error: No valid artisan ID available.',
        );
        return null;
      }

      Uint8List bytes;
      if (file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      } else {
        bytes = await file.readAsBytes();
      }

      final bucket = docType == 'STUDIO_PHOTO' || docType == 'PORTFOLIO_IMAGE'
          ? 'artisan_public_media'
          : 'artisan_private_docs';
      final folder = '$effectiveArtisanId/$docType';
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
      try {
        await client.from('artisan_documents').insert({
          'artisan_id': effectiveArtisanId,
          'doc_type': docType,
          'file_name': finalFileName,
          'file_url': url,
        });
      } catch (insertErr) {
        debugPrint('Error inserting into artisan_documents: $insertErr');
      }

      // Also persist document metadata directly into artisan_profiles.tags so documents
      // are never lost if artisan_documents table is restricted by RLS
      try {
        final ap = await client
            .from('artisan_profiles')
            .select('tags')
            .eq('id', effectiveArtisanId)
            .maybeSingle();
        final currentTags = (ap != null && ap['tags'] is List)
            ? List<String>.from(ap['tags'])
            : <String>[];
        if (docType == 'CRAFTING_PHOTO' ||
            docType == 'VILLAGE_CRAFTING_PHOTO' ||
            docType == 'STUDIO_PHOTO') {
          currentTags.removeWhere((t) =>
              t.startsWith('doc_crafting_photo_url:') ||
              t.startsWith('doc_crafting_photo_name:') ||
              t.startsWith('doc_studio_photo:'));
          currentTags.add('doc_crafting_photo_url:$url');
          currentTags.add('doc_crafting_photo_name:$finalFileName');
          currentTags.add('doc_studio_photo:$url');
        } else if (docType == 'SSM_BUSINESS_CERT' || docType == 'SSM_CERT') {
          currentTags.removeWhere((t) =>
              t.startsWith('doc_ssm_cert_url:') ||
              t.startsWith('doc_ssm_cert_name:'));
          currentTags.add('doc_ssm_cert_url:$url');
          currentTags.add('doc_ssm_cert_name:$finalFileName');
        } else if (docType == 'KRAFTANGAN_MASTER_CERT' ||
            docType == 'KRAFTANGAN_CERT') {
          currentTags.removeWhere((t) =>
              t.startsWith('doc_kraftangan_cert_url:') ||
              t.startsWith('doc_kraftangan_cert_name:'));
          currentTags.add('doc_kraftangan_cert_url:$url');
          currentTags.add('doc_kraftangan_cert_name:$finalFileName');
        }
        await client
            .from('artisan_profiles')
            .update({'tags': currentTags})
            .eq('id', effectiveArtisanId);
      } catch (tagErr) {
        debugPrint('uploadArtisanDocument tags fallback note: $tagErr');
      }

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

  // Optional vote metadata: failure must never suppress loaded Forum content.
  bool _isForumUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  Future<Map<String, List<int>>> _forumVoteCounts(
    String table,
    String targetColumn,
    List<String> ids,
  ) async {
    try {
      return await (() async {
        final counts = <String, List<int>>{};
        final validIds = ids.where(_isForumUuid).toList();
        for (var start = 0; start < validIds.length; start += 100) {
          final batch = validIds.skip(start).take(100).toList();
          var offset = 0;
          while (true) {
            final result = await _client!
                .from(table)
                .select('$targetColumn, vote')
                .inFilter(targetColumn, batch)
                .order(targetColumn)
                .order('user_id')
                .range(offset, offset + 499)
                .count(CountOption.exact);
            for (final row in result.data) {
              final count = counts.putIfAbsent(
                row[targetColumn].toString(), () => [0, 0],
              );
              if (row['vote'] == 1) count[0]++;
              if (row['vote'] == -1) count[1]++;
            }
            offset += result.data.length;
            if (result.data.isEmpty || offset >= result.count) break;
          }
        }
        return counts;
      })().timeout(const Duration(seconds: 8));
    } catch (error) {
      debugPrint('Forum vote counts unavailable for $table: $error');
      return {};
    }
  }

  Future<void> _attachForumVoteCounts(List<ForumThread> threads) async {
    try {
      final counts = await Future.wait([
        _forumVoteCounts(
          'forum_post_votes', 'post_id',
          threads.map((t) => t.id).toList(),
        ),
        _forumVoteCounts(
          'forum_reply_votes', 'reply_id',
          // The model's post-body placeholder is not a persisted reply UUID.
          threads.expand((t) => t.replies.where(
            (r) => r.id != '${t.id}_content',
          )).map((r) => r.id).toList(),
        ),
      ]);
      for (var i = 0; i < threads.length; i++) {
        final thread = threads[i];
        threads[i] = thread.copyWith(
          upvoteCount: counts[0][thread.id]?[0] ?? 0,
          downvoteCount: counts[0][thread.id]?[1] ?? 0,
          replies: thread.replies.map((reply) => reply.copyWith(
            upvoteCount: counts[1][reply.id]?[0] ?? 0,
            downvoteCount: counts[1][reply.id]?[1] ?? 0,
          )).toList(),
        );
      }
    } catch (error) {
      debugPrint('Forum vote metadata unavailable: $error');
    }
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

            // is_reported is the database quarantine decision, not the presence
            // of a pending report. Keep its value and safety metadata intact.

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

                  // Preserve the database quarantine decision for replies too.

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

        await _attachForumVoteCounts(remote);
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

        // Drop stale local reports, retaining the existing queue fallback for
        // quarantined content whose safety-report insertion may have failed.
        groupedReports.removeWhere(
          (key, _) => !_forumStore.any(
            (thread) => key == 'post_${thread.id}'
                ? thread.isReported
                : thread.replies.any(
                    (reply) => key == 'reply_${reply.id}' && reply.isReported,
                  ),
          ),
        );
        _localReportQueue.clear();

        for (final report in reports) {
          final String? postId = report['post_id']?.toString();

          final String? replyId = report['reply_id']?.toString();

          // Session dismissal caches must not hide a fresh pending report.
          if (postId != null && _deletedPostIds.contains(postId)) continue;
          if (postId != null) _dismissedReportPostIds.remove(postId);
          if (replyId != null) _dismissedReportReplyIds.remove(replyId);

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

    // Enrich the admin queue in one batched pass. This metadata is consumed
    // only by AdminForumModerationTab; normal forum models remain unchanged.
    if (client != null && groupedReports.isNotEmpty) {
      try {
        final allRows = await client
            .from('forum_reports')
            .select('reporter_id, post_id, reply_id, status');
        final reporterIds = <String>{};
        final targetAuthorIds = <String, String>{};
        final targetAuthorEmails = <String, String>{};
        final pendingManualByTarget = <String, Set<String>>{};
        final stats = <String, Map<String, int>>{};
        for (final raw in allRows) {
          final row = Map<String, dynamic>.from(raw);
          final reporter = row['reporter_id']?.toString();
          final post = row['post_id']?.toString();
          final reply = row['reply_id']?.toString();
          final target = post != null && post != 'null'
              ? 'post_$post'
              : reply != null && reply != 'null'
              ? 'reply_$reply'
              : null;
          if (reporter != null && reporter != 'null' && reporter.isNotEmpty) {
            reporterIds.add(reporter);
            final entry = stats.putIfAbsent(
              reporter,
              () => {'total': 0, 'pending': 0, 'dismissed': 0, 'actioned': 0},
            );
            entry['total'] = entry['total']! + 1;
            final status = row['status']?.toString();
            if (status == 'pending') entry['pending'] = entry['pending']! + 1;
            if (status == 'dismissed')
              entry['dismissed'] = entry['dismissed']! + 1;
            if (status == 'actioned')
              entry['actioned'] = entry['actioned']! + 1;
            if (status == 'pending' && target != null) {
              pendingManualByTarget
                  .putIfAbsent(target, () => <String>{})
                  .add(reporter);
            }
          }
        }
        for (final entry in groupedReports.entries) {
          final key = entry.key;
          if (key.startsWith('post_')) {
            final id = key.substring(5);
            final thread = _forumStore.where((t) => t.id == id).firstOrNull;
            if (thread?.userId != null) targetAuthorIds[key] = thread!.userId!;
          } else if (key.startsWith('reply_')) {
            final id = key.substring(6);
            for (final thread in _forumStore) {
              final reply = thread.replies.where((r) => r.id == id).firstOrNull;
              if (reply != null && reply.authorEmail.trim().isNotEmpty) {
                targetAuthorEmails[key] = reply.authorEmail.trim();
                break;
              }
            }
          }
        }
        reporterIds.addAll(targetAuthorIds.values);
        final users = reporterIds.isEmpty
            ? <dynamic>[]
            : await client
                  .from('users')
                  .select('id, username')
                  .inFilter('id', reporterIds.toList());
        final usernames = <String, String>{};
        for (final raw in users) {
          final row = Map<String, dynamic>.from(raw);
          final id = row['id']?.toString();
          final username = row['username']?.toString().trim();
          if (id != null && username != null && username.isNotEmpty)
            usernames[id] = username;
        }
        if (targetAuthorEmails.isNotEmpty) {
          final emailRows = await client
              .from('users')
              .select('id, email, username')
              .inFilter('email', targetAuthorEmails.values.toSet().toList());
          final emailUsernames = <String, String>{};
          for (final raw in emailRows) {
            final row = Map<String, dynamic>.from(raw);
            final email = row['email']?.toString().trim().toLowerCase();
            final id = row['id']?.toString();
            final username = row['username']?.toString().trim();
            if (email != null && username != null && username.isNotEmpty) {
              emailUsernames[email] = username;
              final target = targetAuthorEmails.entries
                  .where((entry) => entry.value.toLowerCase() == email)
                  .map((entry) => entry.key)
                  .firstOrNull;
              if (target != null && id != null) targetAuthorIds[target] = id;
            }
          }
          for (final entry in targetAuthorEmails.entries) {
            final username = emailUsernames[entry.value.toLowerCase()];
            if (username != null) usernames[entry.key] = username;
          }
        }
        for (final entry in groupedReports.entries) {
          final item = entry.value;
          final target = entry.key;
          item['distinctPendingManualReporters'] =
              pendingManualByTarget[target]?.length ?? 0;
          item['contentAuthorId'] = targetAuthorIds[target] ?? 'Unknown';
          item['contentAuthorUsername'] = usernames[target] ?? 'Unknown User';
          for (final report in List<Map<String, dynamic>>.from(
            item['reports'] ?? const [],
          )) {
            final id = report['reporter_id']?.toString();
            if (id == null || id.isEmpty || id == 'null') {
              report['reporterUsername'] = 'Automated Safety System';
              report['reporterDisplayId'] = 'System';
              continue;
            }
            final counts = stats[id];
            report['reporterUsername'] = usernames[id] ?? 'Unknown User';
            report['reporterDisplayId'] = id;
            report['reporterTotalCount'] = counts?['total'];
            report['reporterPendingCount'] = counts?['pending'];
            report['reporterDismissedCount'] = counts?['dismissed'];
            report['reporterActionedCount'] = counts?['actioned'];
          }
        }
      } catch (e) {
        debugPrint('fetchForumReportQueue admin metadata note: $e');
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
        final groups = <String, List<Map<String, dynamic>>>{};
        final remoteIds = remoteHistory
            .map((row) => row['id']?.toString())
            .toSet();

        // Successful deletes are represented only by persisted records.
        // Retain the existing local Dismiss fallback, matching exact row/target IDs.
        history.removeWhere(
          (local) =>
              local['status'] == 'actioned' ||
              remoteIds.contains(local['id']?.toString()) ||
              (local['status'] == 'dismissed' &&
                  remoteHistory.any(
                    (remote) =>
                        remote['status'] == 'dismissed' &&
                        ((local['post_id'] != null &&
                                local['post_id'] == remote['post_id']) ||
                            (local['reply_id'] != null &&
                                local['reply_id'] == remote['reply_id'])),
                  )),
        );

        for (final row in remoteHistory) {
          final id = row['id']?.toString();
          if (id == null || _dismissedNoticeIds.contains(id)) continue;
          final actionId = row['moderation_action_id']?.toString().trim();
          final isDelete =
              row['status'] == 'actioned' && row['action_type'] == 'deleted';
          final key =
              (isDelete || row['status'] == 'dismissed') &&
                  actionId != null &&
                  actionId.isNotEmpty &&
                  actionId != 'null'
              ? 'action:${row['status']}:$actionId'
              : 'row:$id';
          groups.putIfAbsent(key, () => []).add(row);
        }

        for (final entry in groups.entries) {
          final rows = entry.value;
          if (!entry.key.startsWith('action:')) {
            history.add({...rows.single});
            continue;
          }
          final parents = rows
              .where((row) => row['is_moderation_action'] == true)
              .toList();
          if (parents.length != 1) {
            // Pre-migration/incomplete actions have no provable canonical parent.
            // Never guess from reporter_id, reason, author, or timestamp.
            history.addAll(rows.map((row) => {...row}));
            continue;
          }
          final parent = parents.single;
          final audit = rows
              .where((row) => row['id'] != parent['id'])
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final manualReports = audit.where((row) {
            final reporterId = row['reporter_id']?.toString();
            return parent['target_id'] != null &&
                parent['target_type'] != null &&
                row['target_id'] == parent['target_id'] &&
                row['target_type'] == parent['target_type'] &&
                reporterId != null &&
                reporterId.isNotEmpty &&
                reporterId != 'null';
          }).toList();
          // Preserve the fetch order of original reports.
          history.add({
            ...parent,
            'report_rows': audit,
            'reports_involved': manualReports
                .map((row) => row['reporter_id'].toString())
                .toSet()
                .length,
          });
        }
      } catch (e) {
        debugPrint('fetchForumModerationHistory Supabase note: $e');
      }
    }
    String historyAuthorName(
      Map<String, dynamic> item, [
      String? liveUsername,
    ]) {
      for (final value in [item['target_author_name'], item['author_name']]) {
        final name = value?.toString().trim();
        if (name != null &&
            name.isNotEmpty &&
            name != 'null' &&
            name != 'Community Member' &&
            name != 'Unknown User') {
          return name;
        }
      }
      return liveUsername ?? 'Community Member';
    }

    final involvedUserIds = <String>{};
    for (final item in history) {
      // A standalone legacy report is still an audit entry. Its row ID stays
      // separate; it cannot establish the total for the original delete action.
      if (((item['status'] == 'actioned' && item['action_type'] == 'deleted') ||
              item['status'] == 'dismissed') &&
          item['is_moderation_action'] != true &&
          !item.containsKey('report_rows')) {
        final reporterId = item['reporter_id']?.toString();
        if (reporterId != null &&
            reporterId.isNotEmpty &&
            reporterId != 'null') {
          item['report_rows'] = [Map<String, dynamic>.from(item)];
        }
      }
      final authorId = item['target_author_id']?.toString();
      if (authorId != null && authorId.isNotEmpty && authorId != 'null') {
        involvedUserIds.add(authorId);
      }
      for (final raw in List<Map<String, dynamic>>.from(
        item['report_rows'] ?? const [],
      )) {
        final reporterId = raw['reporter_id']?.toString();
        if (reporterId != null &&
            reporterId.isNotEmpty &&
            reporterId != 'null') {
          involvedUserIds.add(reporterId);
        }
      }
    }
    if (client != null && involvedUserIds.isNotEmpty) {
      try {
        final users = await client
            .from('users')
            .select('id, username')
            .inFilter('id', involvedUserIds.toList());
        final usernames = <String, String>{
          for (final user in users)
            if ((user['username'] ?? '').toString().trim().isNotEmpty)
              user['id'].toString(): user['username'].toString().trim(),
        };
        for (final item in history) {
          final authorId = item['target_author_id']?.toString();
          item['target_author_name'] = historyAuthorName(
            item,
            usernames[authorId],
          );
          final rows = List<Map<String, dynamic>>.from(
            item['report_rows'] ?? const [],
          );
          for (final row in rows) {
            final reporterId = row['reporter_id']?.toString();
            row['reporter_username'] =
                reporterId == null || reporterId.isEmpty || reporterId == 'null'
                ? 'Automated Safety System'
                : usernames[reporterId] ?? 'Unknown User';
          }
          item['report_rows'] = rows;
        }
      } catch (e) {
        debugPrint('fetchForumModerationHistory author lookup note: $e');
        for (final item in history) {
          item['target_author_name'] = historyAuthorName(item);
          final rows = List<Map<String, dynamic>>.from(
            item['report_rows'] ?? const [],
          );
          for (final row in rows) {
            final reporterId = row['reporter_id']?.toString();
            row['reporter_username'] =
                reporterId == null || reporterId.isEmpty || reporterId == 'null'
                ? 'Automated Safety System'
                : 'Unknown User';
          }
          item['report_rows'] = rows;
        }
      }
    } else {
      for (final item in history) {
        item['target_author_name'] = historyAuthorName(item);
        final rows = List<Map<String, dynamic>>.from(
          item['report_rows'] ?? const [],
        );
        for (final row in rows) {
          final reporterId = row['reporter_id']?.toString();
          row['reporter_username'] =
              reporterId == null || reporterId.isEmpty || reporterId == 'null'
              ? 'Automated Safety System'
              : 'Unknown User';
        }
        item['report_rows'] = rows;
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
    if (!const ['artisan', 'tourist'].contains(thread.authorRoleAtCreation) ||
        thread.replies.any(
          (reply) => !const [
            'artisan',
            'tourist',
          ].contains(reply.authorRoleAtCreation),
        )) {
      throw StateError('Forum creation requires a role snapshot');
    }
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
        'author_role_at_creation': thread.authorRoleAtCreation,
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
            'author_role_at_creation': reply.authorRoleAtCreation,
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
                'author_role_at_creation': reply.authorRoleAtCreation,
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
    if (!const ['artisan', 'tourist'].contains(reply.authorRoleAtCreation)) {
      throw StateError('Forum creation requires a role snapshot');
    }
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
          reply.userId ??
          authUid ??
          userStoreUid ??
          '00000000-0000-4000-8000-000000000001';

      final Map<String, dynamic> verifiedReplyMap = {
        'id': reply.id,
        'post_id': threadId,
        'user_id': effectiveUid,
        'content': reply.text,
        'upvotes': reply.upvotes,
        'author_role_at_creation': reply.authorRoleAtCreation,
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
      upvoteCount: (currentThread.upvoteCount - (currentVote == 1 ? 1 : 0) +
              (newVote == 1 ? 1 : 0)).clamp(0, 1 << 53).toInt(),
      downvoteCount: (currentThread.downvoteCount - (currentVote == -1 ? 1 : 0) +
              (newVote == -1 ? 1 : 0)).clamp(0, 1 << 53).toInt(),
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
      upvoteCount: (currentReply.upvoteCount - (currentVote == 1 ? 1 : 0) +
              (newVote == 1 ? 1 : 0)).clamp(0, 1 << 53).toInt(),
      downvoteCount: (currentReply.downvoteCount - (currentVote == -1 ? 1 : 0) +
              (newVote == -1 ? 1 : 0)).clamp(0, 1 << 53).toInt(),
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

  // The RPC is the sole delete/history writer. Failure propagates to the UI;
  // local content is removed only after the transaction commits.
  Future<String> adminDeleteForumPost(
    String postId,
    String deletionReason, [
    String? adminUsername,
  ]) async {
    final client = _client;
    if (client == null) throw StateError('Supabase client not initialized');
    final result = await client.rpc(
      'admin_delete_forum_content',
      params: {
        'p_post_id': postId,
        'p_reply_id': null,
        'p_deletion_reason': deletionReason,
      },
    );
    if (result is! Map || result['success'] != true) {
      throw StateError('Post deletion was not confirmed');
    }
    _forumStore.removeWhere((thread) => thread.id == postId);
    _deletedPostIds.add(postId);
    _dismissedReportPostIds.remove(postId);
    _localReportQueue.removeWhere(
      (row) =>
          (row['postId']?.toString() == postId ||
              row['id']?.toString() == postId) &&
          (row['type'] == null || row['type'] == 'post'),
    );
    // ForumViewModel refreshes threads, queue, and remote history after success.
    return '';
  }

  Future<String> adminDeleteForumReply(
    String threadId,
    String replyId,
    String deletionReason, [
    String? adminUsername,
  ]) async {
    final client = _client;
    if (client == null) throw StateError('Supabase client not initialized');
    final result = await client.rpc(
      'admin_delete_forum_content',
      params: {
        'p_post_id': null,
        'p_reply_id': replyId,
        'p_deletion_reason': deletionReason,
      },
    );
    if (result is! Map || result['success'] != true) {
      throw StateError('Reply deletion was not confirmed');
    }
    for (int i = 0; i < _forumStore.length; i++) {
      final thread = _forumStore[i];
      if (thread.id != threadId) continue;
      final replies = thread.replies
          .where((reply) => reply.id != replyId)
          .toList();
      _forumStore[i] = thread.copyWith(
        replies: replies,
        replyCount: replies.length,
      );
    }
    _dismissedReportReplyIds.add(replyId);
    _localReportQueue.removeWhere(
      (row) =>
          (row['replyId']?.toString() == replyId ||
              row['id']?.toString() == replyId) &&
          (row['type'] == null || row['type'] == 'reply'),
    );
    // ForumViewModel refreshes threads, queue, and remote history after success.
    return '';
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

  // Submit before mutating local quarantine/queue state. Database errors must
  // never fall through to an unchecked insert or a success notification.
  Future<Map<String, dynamic>> _submitForumReport({
    required String targetId,
    required bool isReply,
    required String reason,
    required String notes,
    required bool isAutomated,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return {
        'success': false,
        'already_reported': false,
        'message': 'You must be signed in to submit a report.',
      };
    }

    try {
      final result = await client.rpc(
        isAutomated
            ? 'flag_own_forum_content'
            : (isReply ? 'report_forum_reply' : 'report_forum_post'),
        params: isAutomated
            ? {
                'p_post_id': isReply ? null : targetId,
                'p_reply_id': isReply ? targetId : null,
                'p_reason': reason,
                'p_notes': notes,
              }
            : {
                if (isReply) 'p_reply_id': targetId else 'p_post_id': targetId,
                'p_reason': reason,
                'p_notes': notes,
              },
      );
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return {'success': false, 'already_reported': true};
      }
      if (e.code == 'PFR02' || e.code == 'PFR03') {
        return {
          'success': false,
          'already_reported': false,
          'rate_limited': e.code == 'PFR02',
          'cooldown': e.code == 'PFR03',
          'message': e.code == 'PFR02'
              ? 'You have submitted too many reports recently. Please wait a few minutes before reporting again.'
              : 'Please wait 30 seconds before submitting another report.',
        };
      }
      debugPrint('Forum report submission failed: $e');
    } catch (e) {
      debugPrint('Forum report submission failed: $e');
    }

    return {
      'success': false,
      'already_reported': false,
      'message': 'Unable to submit your report. Please try again.',
    };
  }

  Future<Map<String, dynamic>> reportReply(
    String threadId,
    String replyId,
    String reason,
    String notes, {
    bool isAutomated = false,
  }) async {
    final result = await _submitForumReport(
      targetId: replyId,
      isReply: true,
      reason: reason,
      notes: notes,
      isAutomated: isAutomated,
    );
    if (result['success'] != true) return result;
    final quarantined = isAutomated || result['quarantined'] == true;

    // 1. Unmark dismissed if reported anew
    _dismissedReportReplyIds.remove(replyId);

    // 2. Update local store
    for (int i = 0; i < _forumStore.length; i++) {
      final t = _forumStore[i];
      final rIdx = t.replies.indexWhere((r) => r.id == replyId);
      if (rIdx != -1) {
        final updatedReply = t.replies[rIdx].copyWith(
          isReported: quarantined,
          reportReason: quarantined ? reason : null,
          reportNotes: quarantined ? notes : null,
        );
        final updatedReplies = List<ThreadReply>.from(t.replies);
        updatedReplies[rIdx] = updatedReply;
        _forumStore[i] = t.copyWith(replies: updatedReplies);
      }
    }

    // The automated RPC returns success for an existing system flag.
    // Do not manufacture another local report for that idempotent result.
    if (result['already_reported'] == true) return result;

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

    return result;
  }

  Future<void> dismissReplyReport(
    String threadId,
    String replyId, [
    String? adminUsername,
  ]) async {
    final client = _client;
    if (client == null) throw StateError('Supabase client not initialized');
    final result = await client.rpc(
      'dismiss_forum_reports',
      params: {'p_post_id': null, 'p_reply_id': replyId},
    );
    if (result is! Map || result['success'] != true) {
      throw StateError('Forum dismissal was not confirmed');
    }
    // Only update local visibility after the server transaction succeeds.
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
  }

  Future<Map<String, dynamic>> reportThread(
    String threadId,
    String reason,
    String notes, {
    bool isAutomated = false,
  }) async {
    final result = await _submitForumReport(
      targetId: threadId,
      isReply: false,
      reason: reason,
      notes: notes,
      isAutomated: isAutomated,
    );
    if (result['success'] != true) return result;
    final quarantined = isAutomated || result['quarantined'] == true;

    _dismissedReportPostIds.remove(threadId);
    _deletedPostIds.remove(threadId);

    final tIdx = _forumStore.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      _forumStore[tIdx] = _forumStore[tIdx].copyWith(
        isReported: quarantined,
        reportReason: quarantined ? reason : null,
        reportNotes: quarantined ? notes : null,
      );
    }

    // The automated RPC returns success for an existing system flag.
    // Do not manufacture another local report for that idempotent result.
    if (result['already_reported'] == true) return result;

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

    return result;
  }

  Future<void> dismissReport(String threadId, [String? adminUsername]) async {
    final client = _client;
    if (client == null) throw StateError('Supabase client not initialized');
    final result = await client.rpc(
      'dismiss_forum_reports',
      params: {'p_post_id': threadId, 'p_reply_id': null},
    );
    if (result is! Map || result['success'] != true) {
      throw StateError('Forum dismissal was not confirmed');
    }
    // Only update local visibility after the server transaction succeeds.
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
  }

  // --- Gamification Services ---

  Future<Map<String, dynamic>> reconcileStampedQuestProgress() async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to reconcile quest completion.',
    );
    return _reconcileStampedQuestProgressForUser(client, user.id);
  }

  Future<Map<String, dynamic>> _reconcileStampedQuestProgressForUser(
    SupabaseClient client,
    String userId,
  ) async {
    final stampRows = List<Map<String, dynamic>>.from(
      await client
          .from('passport_stamps')
          .select('quest_id, unlocked_at')
          .eq('user_id', userId),
    );
    final stampByQuest = <String, Map<String, dynamic>>{};
    for (final stamp in stampRows) {
      final questId = stamp['quest_id']?.toString().trim() ?? '';
      if (questId.isNotEmpty) stampByQuest.putIfAbsent(questId, () => stamp);
    }
    if (stampByQuest.isEmpty) {
      return const {
        'disposition': 'no_stamped_progress',
        'stamped_quest_ids': <String>[],
        'reconciled_quest_ids': <String>[],
        'warnings': <String>[],
      };
    }

    final progressRows = List<Map<String, dynamic>>.from(
      await client
          .from('quest_progress')
          .select('quest_id, status, completed_at')
          .eq('user_id', userId)
          .inFilter('quest_id', stampByQuest.keys.toList(growable: false)),
    );
    final reconciledIds = <String>[];
    final warnings = <String>[];
    var inconsistentCount = 0;

    for (final progress in progressRows) {
      final questId = progress['quest_id']?.toString().trim() ?? '';
      if (questId.isEmpty || !stampByQuest.containsKey(questId)) continue;
      if (progress['status']?.toString().toUpperCase() == 'COMPLETED') {
        continue;
      }
      inconsistentCount++;
      final existingCompletedAt = progress['completed_at']?.toString().trim();
      final stampUnlockedAt = stampByQuest[questId]?['unlocked_at']
          ?.toString()
          .trim();
      final completedAt = existingCompletedAt?.isNotEmpty == true
          ? existingCompletedAt
          : stampUnlockedAt?.isNotEmpty == true
          ? stampUnlockedAt
          : DateTime.now().toUtc().toIso8601String();
      try {
        final updated = List<Map<String, dynamic>>.from(
          await client
              .from('quest_progress')
              .update({'status': 'COMPLETED', 'completed_at': completedAt})
              .eq('user_id', userId)
              .eq('quest_id', questId)
              .neq('status', 'COMPLETED')
              .select('quest_id'),
        );
        if (updated.isNotEmpty) {
          reconciledIds.add(questId);
          continue;
        }
        final current = await client
            .from('quest_progress')
            .select('status')
            .eq('user_id', userId)
            .eq('quest_id', questId)
            .maybeSingle();
        if (current?['status']?.toString().toUpperCase() != 'COMPLETED') {
          warnings.add(
            'Your Passport stamp is safe, but saved quest progress could not be repaired.',
          );
        }
      } catch (error) {
        debugPrint('Stamped quest reconciliation note: $error');
        warnings.add(
          'Your Passport stamp is safe, but saved quest progress could not be repaired.',
        );
      }
    }

    final disposition = warnings.isNotEmpty
        ? 'locally_completed_with_warning'
        : reconciledIds.isNotEmpty
        ? 'reconciled'
        : inconsistentCount == 0
        ? 'already_consistent'
        : 'locally_completed_with_warning';
    return {
      'disposition': disposition,
      'stamped_quest_ids': stampByQuest.keys.toList(growable: false),
      'reconciled_quest_ids': reconciledIds,
      'warnings': warnings.toSet().toList(growable: false),
    };
  }

  Future<Map<String, dynamic>> _readStampedQuestCompletionStateForUser(
    SupabaseClient client,
    String userId,
  ) async {
    final stampRows = List<Map<String, dynamic>>.from(
      await client
          .from('passport_stamps')
          .select('quest_id')
          .eq('user_id', userId),
    );
    final stampedQuestIds = stampRows
        .map((row) => row['quest_id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return {
      'disposition': 'read_only',
      'stamped_quest_ids': stampedQuestIds,
      'reconciled_quest_ids': const <String>[],
      'warnings': const <String>[],
    };
  }

  Future<Map<String, dynamic>> fetchPassportData() async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view your Heritage Passport.',
    );
    final warnings = <String>[];

    try {
      final reconciliation = await _reconcileStampedQuestProgressForUser(
        client,
        user.id,
      );
      warnings.addAll(
        List<String>.from(reconciliation['warnings'] as List? ?? const []),
      );
    } catch (error) {
      debugPrint('Passport completion reconciliation note: $error');
    }

    Map<String, dynamic>? experienceRow;
    var taskAwardRows = <Map<String, dynamic>>[];
    var stampRows = <Map<String, dynamic>>[];
    var availableQuestRows = <Map<String, dynamic>>[];
    var completedQuestRows = <Map<String, dynamic>>[];
    var xpAvailable = false;
    var taskAwardsAvailable = false;
    var stampsAvailable = false;
    var availableQuestsAvailable = false;
    var questStatisticsAvailable = false;

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

    if (!xpAvailable &&
        !taskAwardsAvailable &&
        !stampsAvailable &&
        !availableQuestsAvailable &&
        !questStatisticsAvailable) {
      throw StateError('Unable to load your Heritage Passport.');
    }

    return {
      'total_xp': experienceRow?['total_xp'] ?? 0,
      'xp_updated_at': experienceRow?['updated_at'],
      'task_awards': taskAwardRows,
      'stamps': stampRows,
      'available_quests': availableQuestRows,
      'completed_quests': completedQuestRows,
      'xp_available': xpAvailable,
      'task_awards_available': taskAwardsAvailable,
      'stamps_available': stampsAvailable,
      'available_quests_available': availableQuestsAvailable,
      'quest_statistics_available': questStatisticsAvailable,
      'warnings': warnings,
    };
  }

  Future<Map<String, dynamic>> fetchTouristMapJourneyData() async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view Heritage Quests.',
    );

    final warnings = <String>[];
    Map<String, dynamic>? completionReconciliation;
    try {
      completionReconciliation = await _readStampedQuestCompletionStateForUser(
        client,
        user.id,
      );
      warnings.addAll(
        List<String>.from(
          completionReconciliation['warnings'] as List? ?? const [],
        ),
      );
    } catch (error) {
      debugPrint('Map completion reconciliation note: $error');
    }
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
      throw StateError('Unable to load Heritage Quests.');
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
      'completion_reconciliation': completionReconciliation,
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
        .select('status, started_at, completed_at')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .maybeSingle();

    return row;
  }

  Future<List<Map<String, dynamic>>> fetchActiveQuestProgressRows() async {
    final data = await fetchActiveQuestStateData();
    return List<Map<String, dynamic>>.from(
      data['active_rows'] as List? ?? const [],
    );
  }

  Future<Map<String, dynamic>> fetchActiveQuestStateData() async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to view your active quest.',
    );
    final reconciliation = await _readStampedQuestCompletionStateForUser(
      client,
      user.id,
    );
    final rows = await _fetchActiveQuestProgressRowsForUser(client, user.id);
    final stampedQuestIds = List<Object?>.from(
      reconciliation['stamped_quest_ids'] as List? ?? const [],
    ).map((value) => value?.toString() ?? '').toSet();
    return {
      'active_rows': rows
          .where(
            (row) => !stampedQuestIds.contains(row['quest_id']?.toString()),
          )
          .toList(growable: false),
      'completion_reconciliation': reconciliation,
    };
  }

  Future<
    ({List<Map<String, dynamic>> rows, Map<String, dynamic> reconciliation})
  >
  _fetchEffectiveActiveQuestRowsForUser(
    SupabaseClient client,
    String userId,
  ) async {
    final reconciliation = await _reconcileStampedQuestProgressForUser(
      client,
      userId,
    );
    final stampedQuestIds = List<Object?>.from(
      reconciliation['stamped_quest_ids'] as List? ?? const [],
    ).map((value) => value?.toString() ?? '').toSet();
    final rows = await _fetchActiveQuestProgressRowsForUser(client, userId);
    return (
      rows: rows
          .where(
            (row) => !stampedQuestIds.contains(row['quest_id']?.toString()),
          )
          .toList(growable: false),
      reconciliation: reconciliation,
    );
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

    var activeSnapshot = await _fetchEffectiveActiveQuestRowsForUser(
      client,
      user.id,
    );
    var activeRows = activeSnapshot.rows;
    if (activeRows.isNotEmpty) {
      if (activeRows.length > 1) {
        return {
          'outcome': 'integrity_conflict',
          'active_rows': activeRows,
          'progress': null,
          'completion_reconciliation': activeSnapshot.reconciliation,
        };
      }
      final activeQuestId = activeRows.first['quest_id']?.toString() ?? '';
      if (activeQuestId != questId) {
        return {
          'outcome': 'blocked',
          'active_rows': activeRows,
          'progress': activeRows.first,
          'completion_reconciliation': activeSnapshot.reconciliation,
        };
      }
      await _ensureTaskProgressRows(client, user.id, taskIds);
      return {
        'outcome': 'resumed',
        'active_rows': activeRows,
        'progress': activeRows.first,
        'completion_reconciliation': activeSnapshot.reconciliation,
      };
    }

    Map<String, dynamic>? stoppedProgress;
    try {
      final stoppedRows = await client
          .from('quest_progress')
          .update({'status': 'IN_PROGRESS'})
          .eq('user_id', user.id)
          .eq('quest_id', questId)
          .eq('status', 'STOPPED')
          .select('quest_id, status, started_at');
      if (stoppedRows.isNotEmpty) {
        stoppedProgress = Map<String, dynamic>.from(stoppedRows.first);
      }
    } catch (_) {
      activeSnapshot = await _fetchEffectiveActiveQuestRowsForUser(
        client,
        user.id,
      );
      activeRows = activeSnapshot.rows;
      if (activeRows.isEmpty) rethrow;
      final activeQuestId = activeRows.first['quest_id']?.toString() ?? '';
      if (activeRows.length > 1) {
        return {
          'outcome': 'integrity_conflict',
          'active_rows': activeRows,
          'progress': null,
          'completion_reconciliation': activeSnapshot.reconciliation,
        };
      }
      if (activeQuestId == questId) {
        await _ensureTaskProgressRows(client, user.id, taskIds);
      }
      return {
        'outcome': activeQuestId == questId ? 'resumed' : 'blocked',
        'active_rows': activeRows,
        'progress': activeRows.first,
        'completion_reconciliation': activeSnapshot.reconciliation,
      };
    }
    if (stoppedProgress != null) {
      await _ensureTaskProgressRows(client, user.id, taskIds);
      activeSnapshot = await _fetchEffectiveActiveQuestRowsForUser(
        client,
        user.id,
      );
      return {
        'outcome': 'resumed',
        'active_rows': activeSnapshot.rows,
        'progress': stoppedProgress,
        'completion_reconciliation': activeSnapshot.reconciliation,
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
      activeSnapshot = await _fetchEffectiveActiveQuestRowsForUser(
        client,
        user.id,
      );
      activeRows = activeSnapshot.rows;
      if (activeRows.isEmpty) rethrow;
      final activeQuestId = activeRows.first['quest_id']?.toString() ?? '';
      if (activeRows.length > 1) {
        return {
          'outcome': 'integrity_conflict',
          'active_rows': activeRows,
          'progress': null,
          'completion_reconciliation': activeSnapshot.reconciliation,
        };
      }
      if (activeQuestId == questId) {
        await _ensureTaskProgressRows(client, user.id, taskIds);
      }
      return {
        'outcome': activeQuestId == questId ? 'resumed' : 'blocked',
        'active_rows': activeRows,
        'progress': activeRows.first,
        'completion_reconciliation': activeSnapshot.reconciliation,
      };
    }

    activeSnapshot = await _fetchEffectiveActiveQuestRowsForUser(
      client,
      user.id,
    );
    activeRows = activeSnapshot.rows;
    final activeQuestId = activeRows.isEmpty
        ? ''
        : activeRows.first['quest_id']?.toString() ?? '';
    if (activeRows.length != 1 || activeQuestId != questId) {
      return {
        'outcome': activeRows.length > 1 ? 'integrity_conflict' : 'blocked',
        'active_rows': activeRows,
        'progress': null,
        'completion_reconciliation': activeSnapshot.reconciliation,
      };
    }

    await _ensureTaskProgressRows(client, user.id, taskIds);
    return {
      'outcome': 'started',
      'active_rows': activeRows,
      'progress': activeRows.first,
      'completion_reconciliation': activeSnapshot.reconciliation,
    };
  }

  Future<Map<String, dynamic>> stopQuest(String questId) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to stop a quest.',
    );
    final current = await client
        .from('quest_progress')
        .select('quest_id, status, started_at')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .maybeSingle();
    if (current == null) {
      throw StateError('This quest has not been started.');
    }

    final status = current['status']?.toString().toUpperCase() ?? '';
    if (status == 'STOPPED') return current;
    if (status == 'COMPLETED') {
      throw StateError('A completed quest cannot be stopped.');
    }
    if (status != 'IN_PROGRESS') {
      throw StateError('This quest is not currently active.');
    }

    final stoppedRows = await client
        .from('quest_progress')
        .update({'status': 'STOPPED'})
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .eq('status', 'IN_PROGRESS')
        .select('quest_id, status, started_at');
    if (stoppedRows.isNotEmpty) {
      return Map<String, dynamic>.from(stoppedRows.first);
    }

    final latest = await client
        .from('quest_progress')
        .select('quest_id, status, started_at')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .maybeSingle();
    if (latest?['status']?.toString().toUpperCase() == 'STOPPED') {
      return latest!;
    }
    throw StateError('The quest could not be stopped safely.');
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

  Future<Map<String, dynamic>> completeArrivalTask({
    required String questId,
    required String taskId,
  }) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to complete the workshop arrival.',
    );
    await _loadApprovedTaskForCompletion(
      client: client,
      questId: questId,
      taskId: taskId,
      expectedSystemTask: true,
      expectedSortOrder: 1,
      invalidTypeMessage: 'This is not the workshop arrival system task.',
    );
    final existing = await _findTaskProgressRow(client, user.id, taskId);
    if (existing?['is_completed'] == true) {
      await _updateQuestRewardAndCompletion(
        client: client,
        userId: user.id,
        questId: questId,
      );
      return _taskCompletionResult(client, user.id, taskId, existing!);
    }
    await _assertExpectedActiveQuest(
      client: client,
      userId: user.id,
      questId: questId,
    );
    await _ensureTaskProgress(client, user.id, taskId);
    return _completeValidatedTask(
      client: client,
      userId: user.id,
      questId: questId,
      taskId: taskId,
      completedProgressSeconds: 0,
    );
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

    final task = await _loadApprovedTaskForCompletion(
      client: client,
      questId: questId,
      taskId: taskId,
      expectedSystemTask: false,
      invalidTypeMessage:
          'System tasks complete automatically and do not require a QR scan.',
    );

    final existing = await _findTaskProgressRow(client, user.id, taskId);
    if (existing?['is_completed'] == true) {
      await _updateQuestRewardAndCompletion(
        client: client,
        userId: user.id,
        questId: questId,
      );
      return _taskCompletionResult(client, user.id, taskId, existing!);
    }

    final questProgressRows = await client
        .from('quest_progress')
        .select('status, started_at')
        .eq('user_id', user.id)
        .eq('quest_id', questId)
        .limit(1);
    final questProgress = questProgressRows.isEmpty
        ? null
        : Map<String, dynamic>.from(questProgressRows.first);
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

    if (canCompleteJourneyTask) {
      await _assertExpectedActiveQuest(
        client: client,
        userId: user.id,
        questId: questId,
      );
    } else {
      final activeSnapshot = await _fetchEffectiveActiveQuestRowsForUser(
        client,
        user.id,
      );
      if (activeSnapshot.rows.isNotEmpty) {
        throw StateError(
          'Complete your active quest before attempting bonus activities.',
        );
      }
    }
    await _ensureTaskProgress(client, user.id, taskId);
    return _completeValidatedTask(
      client: client,
      userId: user.id,
      questId: questId,
      taskId: taskId,
      completedProgressSeconds: 0,
    );
  }

  Future<Map<String, dynamic>> _loadApprovedTaskForCompletion({
    required SupabaseClient client,
    required String questId,
    required String taskId,
    required bool expectedSystemTask,
    int? expectedSortOrder,
    required String invalidTypeMessage,
  }) async {
    final quest = await client
        .from('quests')
        .select('id')
        .eq('id', questId)
        .eq('status', 'APPROVED')
        .maybeSingle();
    if (quest == null) {
      throw StateError('This quest is not available for completion.');
    }
    final task = await client
        .from('heritage_tasks')
        .select('id, quest_id, is_system_task, sort_order, created_at')
        .eq('id', taskId)
        .eq('quest_id', questId)
        .eq('status', 'APPROVED')
        .eq('is_archived', false)
        .maybeSingle();
    if (task == null) {
      throw StateError('This task is not available for completion.');
    }
    if (task['is_system_task'] != expectedSystemTask ||
        (expectedSortOrder != null &&
            task['sort_order'] != expectedSortOrder)) {
      throw StateError(invalidTypeMessage);
    }
    return task;
  }

  Future<Map<String, dynamic>> _completeValidatedTask({
    required SupabaseClient client,
    required String userId,
    required String questId,
    required String taskId,
    required int completedProgressSeconds,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('task_progress')
        .update({
          'is_completed': true,
          'completed_at': now,
          'progress_seconds': completedProgressSeconds,
          'tracking_started_at': null,
          'updated_at': now,
        })
        .eq('user_id', userId)
        .eq('task_id', taskId)
        .eq('is_completed', false);
    final completed = await _fetchTaskProgressRow(client, userId, taskId);
    await _updateQuestRewardAndCompletion(
      client: client,
      userId: userId,
      questId: questId,
    );
    return _taskCompletionResult(client, userId, taskId, completed);
  }

  Future<Map<String, dynamic>> _taskCompletionResult(
    SupabaseClient client,
    String userId,
    String taskId,
    Map<String, dynamic> progress,
  ) async {
    int? xpAwarded;
    try {
      final rows = List<Map<String, dynamic>>.from(
        await client
            .from('user_task_xp_awards')
            .select('xp_awarded')
            .eq('user_id', userId)
            .eq('task_id', taskId)
            .limit(1),
      );
      final value = rows.isEmpty ? null : rows.first['xp_awarded'];
      final parsed = value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '');
      if (parsed != null && parsed >= 0) xpAwarded = parsed;
    } catch (error) {
      debugPrint('Authoritative task XP lookup unavailable: $error');
    }
    return {'progress': progress, 'xp_awarded': xpAwarded};
  }

  Future<void> _updateQuestRewardAndCompletion({
    required SupabaseClient client,
    required String userId,
    required String questId,
  }) async {
    final questProgressRows = await client
        .from('quest_progress')
        .select('status, started_at, completed_at')
        .eq('user_id', userId)
        .eq('quest_id', questId)
        .limit(1);
    final progress = questProgressRows.isEmpty
        ? null
        : Map<String, dynamic>.from(questProgressRows.first);
    if (progress == null) return;

    final existingStampRows = await client
        .from('passport_stamps')
        .select('id, unlocked_at')
        .eq('user_id', userId)
        .eq('quest_id', questId)
        .limit(1);
    final existingStamp = existingStampRows.isEmpty
        ? null
        : Map<String, dynamic>.from(existingStampRows.first);
    if (progress['status']?.toString().toUpperCase() == 'COMPLETED') {
      return;
    }
    if (existingStamp != null) {
      final existingCompletedAt = progress['completed_at']?.toString().trim();
      final stampUnlockedAt = existingStamp['unlocked_at']?.toString().trim();
      await client
          .from('quest_progress')
          .update({
            'status': 'COMPLETED',
            if (existingCompletedAt?.isNotEmpty != true)
              'completed_at': stampUnlockedAt?.isNotEmpty == true
                  ? stampUnlockedAt
                  : DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('quest_id', questId)
          .neq('status', 'COMPLETED');
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
    final taskRow = await client
        .from('heritage_tasks')
        .select('quest_id')
        .eq('id', taskId)
        .maybeSingle();
    final questId = taskRow?['quest_id']?.toString() ?? '';
    if (questId.isEmpty) {
      throw StateError('This task is not available for tracking.');
    }
    await _loadApprovedTaskForCompletion(
      client: client,
      questId: questId,
      taskId: taskId,
      expectedSystemTask: true,
      expectedSortOrder: 2,
      invalidTypeMessage: 'This is not the workshop timer system task.',
    );
    await _assertExpectedActiveQuest(
      client: client,
      userId: user.id,
      questId: questId,
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
    final taskRow = await client
        .from('heritage_tasks')
        .select('quest_id')
        .eq('id', taskId)
        .maybeSingle();
    final questId = taskRow?['quest_id']?.toString() ?? '';
    if (questId.isEmpty) {
      throw StateError('This task is not available for tracking.');
    }
    await _loadApprovedTaskForCompletion(
      client: client,
      questId: questId,
      taskId: taskId,
      expectedSystemTask: true,
      expectedSortOrder: 2,
      invalidTypeMessage: 'This is not the workshop timer system task.',
    );
    await _assertExpectedActiveQuest(
      client: client,
      userId: user.id,
      questId: questId,
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

  Future<Map<String, dynamic>> restoreTimedTaskAsPaused(String taskId) async {
    final client = _requireSupabaseClient();
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to restore workshop timer progress.',
    );
    final taskRow = await client
        .from('heritage_tasks')
        .select('quest_id')
        .eq('id', taskId)
        .maybeSingle();
    final questId = taskRow?['quest_id']?.toString() ?? '';
    if (questId.isEmpty) {
      throw StateError('This task is not available for tracking.');
    }
    await _loadApprovedTaskForCompletion(
      client: client,
      questId: questId,
      taskId: taskId,
      expectedSystemTask: true,
      expectedSortOrder: 2,
      invalidTypeMessage: 'This is not the workshop timer system task.',
    );
    await _assertExpectedActiveQuest(
      client: client,
      userId: user.id,
      questId: questId,
    );
    await _ensureTaskProgress(client, user.id, taskId);
    final current = await _fetchTaskProgressRow(client, user.id, taskId);
    if (current['is_completed'] == true ||
        current['tracking_started_at'] == null) {
      return current;
    }
    final confirmedSeconds =
        ((current['progress_seconds'] as num?)?.toInt() ?? 0).clamp(0, 900);
    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('task_progress')
        .update({
          'progress_seconds': confirmedSeconds,
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
    final taskRow = await client
        .from('heritage_tasks')
        .select('quest_id')
        .eq('id', taskId)
        .maybeSingle();
    final questId = taskRow?['quest_id']?.toString() ?? '';
    if (questId.isEmpty) {
      throw StateError('This task is not available for completion.');
    }
    await _loadApprovedTaskForCompletion(
      client: client,
      questId: questId,
      taskId: taskId,
      expectedSystemTask: true,
      expectedSortOrder: 2,
      invalidTypeMessage: 'This is not the workshop timer system task.',
    );
    final existing = await _findTaskProgressRow(client, user.id, taskId);
    if (existing?['is_completed'] == true) {
      await _updateQuestRewardAndCompletion(
        client: client,
        userId: user.id,
        questId: questId,
      );
      return _taskCompletionResult(client, user.id, taskId, existing!);
    }
    await _assertExpectedActiveQuest(
      client: client,
      userId: user.id,
      questId: questId,
    );
    await _ensureTaskProgress(client, user.id, taskId);
    final current =
        existing ?? await _fetchTaskProgressRow(client, user.id, taskId);

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

    return _completeValidatedTask(
      client: client,
      userId: user.id,
      questId: questId,
      taskId: taskId,
      completedProgressSeconds: 900,
    );
  }

  static const String _taskProgressColumns =
      'user_id, task_id, is_completed, completed_at, progress_seconds, '
      'tracking_started_at';

  Future<void> _assertExpectedActiveQuest({
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
    if (activeQuestIds.length != 1 || !activeQuestIds.contains(questId)) {
      throw StateError(
        activeQuestIds.length > 1
            ? 'Multiple active quests were found. Resolve the conflict before completing activities.'
            : 'Start this quest before completing its activities.',
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

  Future<Map<String, dynamic>?> _findTaskProgressRow(
    SupabaseClient client,
    String userId,
    String taskId,
  ) async {
    final rows = await client
        .from('task_progress')
        .select(_taskProgressColumns)
        .eq('user_id', userId)
        .eq('task_id', taskId)
        .limit(1);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
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

  Future<Map<String, dynamic>> _loadOwnedArtisanTaskForRequestAction({
    required SupabaseClient client,
    required String taskId,
  }) async {
    final user = _requireAuthenticatedUser(
      client,
      'You must be signed in to manage task requests.',
    );
    final artisanProfile = await client
        .from('artisan_profiles')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (artisanProfile == null) {
      throw StateError(
        'No artisan profile is linked to this signed-in account.',
      );
    }

    final task = await client
        .from('heritage_tasks')
        .select('id, quest_id, is_system_task, status, is_archived')
        .eq('id', taskId)
        .maybeSingle();
    if (task == null) {
      throw StateError(
        'This task request is no longer available. Refreshing its latest status.',
      );
    }

    final questId = task['quest_id']?.toString() ?? '';
    final quest = questId.isEmpty
        ? null
        : await client
              .from('quests')
              .select('id, artisan_id')
              .eq('id', questId)
              .maybeSingle();
    if (quest == null ||
        quest['artisan_id']?.toString() != artisanProfile['id']?.toString()) {
      throw StateError('You are not authorized to manage this task request.');
    }
    if (task['is_system_task'] == true) {
      throw StateError('System task requests cannot be cancelled.');
    }
    return Map<String, dynamic>.from(task);
  }

  Future<Map<String, dynamic>> _loadOwnedTaskChangeRequest({
    required SupabaseClient client,
    required String requestId,
    required String taskId,
  }) async {
    _requireAuthenticatedUser(
      client,
      'You must be signed in to manage task requests.',
    );
    final request = await client
        .from('heritage_task_change_requests')
        .select('id, task_id, request_type, status')
        .eq('id', requestId)
        .maybeSingle();
    if (request == null) {
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }
    if (request['task_id']?.toString() != taskId) {
      throw StateError('You are not authorized to manage this task request.');
    }
    final task = await _loadOwnedArtisanTaskForRequestAction(
      client: client,
      taskId: taskId,
    );
    if (task['status']?.toString().toUpperCase() != 'APPROVED' ||
        task['is_archived'] == true) {
      throw StateError(
        'Only requests for an approved active task can be removed.',
      );
    }
    return Map<String, dynamic>.from(request);
  }

  Future<void> deleteUnapprovedHeritageTask({
    required String taskId,
    required String expectedStatus,
  }) async {
    final client = _requireSupabaseClient();
    final normalizedStatus = expectedStatus.toUpperCase();
    if (normalizedStatus != 'PENDING_APPROVAL' &&
        normalizedStatus != 'REJECTED') {
      throw ArgumentError.value(
        expectedStatus,
        'expectedStatus',
        'Only pending or rejected task submissions can be removed.',
      );
    }
    final task = await _loadOwnedArtisanTaskForRequestAction(
      client: client,
      taskId: taskId,
    );
    if (task['status']?.toString().toUpperCase() != normalizedStatus ||
        task['is_archived'] == true) {
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }

    final deletedTask = await client
        .from('heritage_tasks')
        .delete()
        .eq('id', taskId)
        .eq('quest_id', task['quest_id'])
        .eq('is_system_task', false)
        .eq('is_archived', false)
        .eq('status', normalizedStatus)
        .select('id')
        .maybeSingle();
    if (deletedTask == null) {
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }
  }

  Future<void> deleteHeritageTaskChangeRequest({
    required String requestId,
    required String taskId,
    required String expectedRequestType,
    required String expectedStatus,
  }) async {
    final client = _requireSupabaseClient();
    final requestType = expectedRequestType.toUpperCase();
    final status = expectedStatus.toUpperCase();
    if ((requestType != 'EDIT' && requestType != 'DELETE') ||
        (status != 'PENDING_APPROVAL' && status != 'REJECTED')) {
      throw ArgumentError('Unsupported task-request cancellation state.');
    }
    final request = await _loadOwnedTaskChangeRequest(
      client: client,
      requestId: requestId,
      taskId: taskId,
    );
    if (request['request_type']?.toString().toUpperCase() != requestType) {
      throw StateError('This request type cannot be cancelled here.');
    }
    if (request['status']?.toString().toUpperCase() != status) {
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }

    final deletedRequest = await client
        .from('heritage_task_change_requests')
        .delete()
        .eq('id', requestId)
        .eq('task_id', taskId)
        .eq('request_type', requestType)
        .eq('status', status)
        .select('id')
        .maybeSingle();
    if (deletedRequest == null) {
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }
  }

  Future<void> deleteRejectedHeritageTaskEditRequest({
    required String requestId,
    required String taskId,
  }) {
    return deleteHeritageTaskChangeRequest(
      requestId: requestId,
      taskId: taskId,
      expectedRequestType: 'EDIT',
      expectedStatus: 'REJECTED',
    );
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
  }) {
    return deleteHeritageTaskChangeRequest(
      requestId: requestId,
      taskId: taskId,
      expectedRequestType: 'EDIT',
      expectedStatus: 'PENDING_APPROVAL',
    );
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
