import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/domain/models/user.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final bool requiresRoleSelection;
  final List<String> availableRoles;
  final String? route;
  final bool requiresEmailVerification;
  final String? unverifiedEmail;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
    this.requiresRoleSelection = false,
    this.availableRoles = const [],
    this.route,
    this.requiresEmailVerification = false,
    this.unverifiedEmail,
  });
}

class AuthViewModel extends ChangeNotifier {
  final UserRepository _repository;

  AuthViewModel({UserRepository? repository})
    : _repository = repository ?? UserRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  String? _activeRole;
  String? get activeRole => _activeRole ?? _currentUser?.role;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  bool _requiresRoleSelection = false;
  bool get requiresRoleSelection => _requiresRoleSelection;

  List<String> _availableRoles = [];
  List<String> get availableRoles => _availableRoles;

  Future<UserModel?> restoreSession() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        if (user.status != 'SUSPENDED' && !user.isSuspended) {
          _currentUser = user;
          _activeRole = user.role;
          notifyListeners();
          return user;
        }
      }
      _currentUser = null;
      _activeRole = null;
      notifyListeners();
    } catch (e) {
      debugPrint('restoreSession note: $e');
      _currentUser = null;
      _activeRole = null;
      notifyListeners();
    }
    return null;
  }

  void clearError() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  Future<bool> checkUsernameAvailable(String username) async {
    if (username.trim().isEmpty) return false;
    return _repository.isUsernameAvailable(username.trim());
  }

  Future<bool> isUsernameAvailable(
    String username, {
    String? excludeEmail,
  }) async {
    if (username.trim().isEmpty) return false;
    return _repository.isUsernameAvailable(
      username.trim(),
      excludeEmail: excludeEmail,
    );
  }

  Future<ExistingAccountCheck> checkExistingAccount(String email) async {
    if (email.trim().isEmpty) return const ExistingAccountCheck(exists: false);
    return _repository.checkExistingAccount(email.trim());
  }

  Future<void> updateProfile({
    String? username,
    String? displayName,
    String? studioName,
    String? bio,
    String? phone,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    String? craftCategory,
    List<String>? toolsAndMaterials,
    String? avatarUrl,
  }) async {
    final email = _currentUser?.email ?? 'tourist@warisankita.my';
    final cleanUsername = username?.trim().replaceAll('@', '');
    final newUsername = (cleanUsername != null && cleanUsername.isNotEmpty)
        ? cleanUsername
        : _currentUser?.username;
    final newDisplayName =
        (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (newUsername ?? _currentUser?.displayName);
    final newStudioName = (studioName != null && studioName.trim().isNotEmpty)
        ? studioName.trim()
        : _currentUser?.studioName;
    final newAvatarUrl = avatarUrl ?? _currentUser?.avatarUrl;

    try {
      final updated = await _repository.updateUserProfile(
        email: email,
        username: newUsername,
        displayName: newDisplayName,
        studioName: newStudioName,
        bio: bio,
        phone: phone,
        state: state,
        address: address,
        latitude: latitude,
        longitude: longitude,
        craftCategory: craftCategory,
        toolsAndMaterials: toolsAndMaterials,
        avatarUrl: newAvatarUrl,
      );
      _currentUser = updated;
    } catch (e) {
      if (e.toString().contains('USERNAME ALREADY TAKEN')) {
        rethrow;
      }
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          username: newUsername ?? _currentUser!.username,
          displayName: newDisplayName ?? _currentUser!.displayName,
          studioName: newStudioName ?? _currentUser!.studioName,
          bio: bio ?? _currentUser!.bio,
          phone: phone ?? _currentUser!.phone,
          state: state ?? _currentUser!.state,
          craftCategory: craftCategory ?? _currentUser!.craftCategory,
          avatarUrl: newAvatarUrl,
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<String?> uploadAvatar(PlatformFile file) async {
    final email = _currentUser?.email ?? 'tourist@warisankita.my';
    final userId = _currentUser?.id ?? email;
    _isLoading = true;
    notifyListeners();

    try {
      final url = await _repository.uploadUserAvatar(userId, file);
      if (url != null && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(avatarUrl: url);
        try {
          await _repository.updateUserProfile(
            email: email,
            avatarUrl: url,
          );
        } catch (e) {
          debugPrint('updateUserProfile avatarUrl sync note: $e');
        }
      }
      return url;
    } catch (e) {
      debugPrint('uploadAvatar error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UC001_USER_LOGIN
  Future<AuthResult> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    _isLoading = true;
    _errorMessage = null;
    _statusMessage = null;
    _requiresRoleSelection = false;
    notifyListeners();

    try {
      // Constraint C1: Password length > 7 characters (Regex / Length Check)
      if (cleanPassword.length <= 7) {
        _errorMessage = 'PASSWORD MUST BE GREATER THAN 7 CHARACTERS';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Alternate Flow A1: Email format validation (only if attempting email login)
      final isEmailAttempt =
          cleanEmail.contains('@') && !cleanEmail.startsWith('@');
      if (isEmailAttempt) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(cleanEmail)) {
          _errorMessage = 'INVALID CREDENTIALS: Enter a valid email format';
          _isLoading = false;
          notifyListeners();
          return AuthResult(success: false, message: _errorMessage);
        }
      }

      // Step 4: Query DB & Verify RBAC
      final user = await _repository.signIn(cleanEmail, cleanPassword);

      // Alternate Flow A3: Account Suspended Check
      if (user.status == 'SUSPENDED' || user.isSuspended) {
        _errorMessage = 'ACCOUNT SUSPENDED BY ADMINISTRATOR: CONTACT SUPPORT';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // 🌐 UC102: Web Moderation Portal Strict RBAC Guard
      if (kIsWeb && user.role != 'Admin') {
        _errorMessage =
            'ACCESS DENIED: The Web Portal is exclusively for Administrators.';
        _isLoading = false;
        _currentUser = null;
        _activeRole = null;
        notifyListeners();
        return AuthResult(success: false, user: user, message: _errorMessage);
      }

      _currentUser = user;

      // Alternate Flow A5: Artisan Active Mode Selection (Master Artisan vs Cultural Tourist)
      if (user.isArtisan || user.isApprovedArtisan || user.isPendingArtisan) {
        _requiresRoleSelection = true;
        _availableRoles = const ['Master Artisan', 'Cultural Tourist'];
        _statusMessage = 'SELECT YOUR ACTIVE ROLE MODE';
        _isLoading = false;
        notifyListeners();
        return AuthResult(
          success: true,
          user: user,
          requiresRoleSelection: true,
          availableRoles: _availableRoles,
          message: _statusMessage,
        );
      }

      // Alternate Flow A4: Artisan Pending Approval
      String targetRoute = '/tourist';
      if (user.role == 'Admin') {
        targetRoute = '/admin';
      } else if (user.role == 'Artisan' || user.role == 'Master Artisan') {
        if (!user.isApprovedArtisan) {
          targetRoute = 'pending_artisan';
        } else {
          targetRoute = '/artisan';
        }
      }

      _activeRole = user.role;
      _statusMessage = 'LOGIN SUCCESSFUL';
      _isLoading = false;
      notifyListeners();

      return AuthResult(
        success: true,
        user: user,
        route: targetRoute,
        message: _statusMessage,
      );
    } catch (e) {
      final rawError = e.toString().replaceAll('Exception: ', '');
      final lower = rawError.toLowerCase();
      _isLoading = false;

      if (lower.contains('email not confirmed') ||
          lower.contains('email_not_confirmed') ||
          lower.contains('not confirmed') ||
          lower.contains('not verified')) {
        _errorMessage = 'EMAIL NOT VERIFIED: Please enter the 6-digit verification code sent to your email.';
        notifyListeners();
        return AuthResult(
          success: false,
          requiresEmailVerification: true,
          unverifiedEmail: cleanEmail,
          message: _errorMessage,
        );
      }

      _errorMessage = rawError;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String token,
    String? targetRoute,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    if (cleanToken.length != 6) {
      _errorMessage = 'PLEASE ENTER A 6-DIGIT VERIFICATION CODE';
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.verifyEmailOtp(
        email: cleanEmail,
        token: cleanToken,
      );
      _currentUser = user;
      _activeRole = user.role;
      _statusMessage = 'EMAIL VERIFIED SUCCESSFULLY: WELCOME TO WARISAN KITA';
      _isLoading = false;
      notifyListeners();

      final route = targetRoute ?? (user.role.contains('Artisan') ? 'pending_artisan' : '/tourist');
      return AuthResult(
        success: true,
        user: user,
        route: route,
        message: _statusMessage,
      );
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('INVALID_OTP: ', '')
          .replaceAll('OTP_EXPIRED: ', '');
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  Future<bool> resendVerificationOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;
    try {
      await _repository.resendVerificationOtp(email: cleanEmail);
      _statusMessage = 'A new 6-digit verification code has been sent to your email.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to resend verification code. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // UC001 - A5: Select Active Session Role
  void selectActiveRole(String role) {
    if (role.contains('Artisan') &&
        _currentUser != null &&
        !_currentUser!.isApprovedArtisan) {
      // Security guard: Cannot select Master Artisan role unless approved by admin
      return;
    }
    _activeRole = role;
    _requiresRoleSelection = false;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: role);
    }
    notifyListeners();
  }

  // UC002_USER_REGISTRATION: Cultural Tourist
  Future<AuthResult> registerTourist({
    required String username,
    String? fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanEmail = email.trim();
    final cleanUsername = username.trim();
    final cleanFullName = fullName?.trim();
    final cleanPassword = password.trim();
    final cleanConfirm = confirmPassword.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Constraint C1: Password length > 7 characters
      if (cleanPassword.length <= 7) {
        _errorMessage = 'PASSWORD MUST BE GREATER THAN 7 CHARACTERS';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Constraint C2: Passwords match
      if (cleanPassword != cleanConfirm) {
        _errorMessage = 'PASSWORDS DO NOT MATCH';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        _errorMessage = 'PLEASE ENTER A VALID EMAIL ADDRESS';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      final user = await _repository.signUp(
        email: cleanEmail,
        password: cleanPassword,
        role: 'Tourist',
        username: cleanUsername.isNotEmpty ? cleanUsername : null,
        displayName: (cleanFullName != null && cleanFullName.isNotEmpty)
            ? cleanFullName
            : null,
      );

      _statusMessage = 'REGISTRATION SUCCESSFUL: PLEASE VERIFY YOUR EMAIL';
      _isLoading = false;
      notifyListeners();

      return AuthResult(
        success: true,
        user: user,
        requiresEmailVerification: true,
        unverifiedEmail: cleanEmail,
        route: '/tourist',
        message: _statusMessage,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  // Generic signUp handler for legacy/direct views
  Future<AuthResult> signUp(
    String email,
    String password,
    String role, {
    String? username,
    String? displayName,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.signUp(
        email: cleanEmail,
        password: cleanPassword,
        role: role,
        username: username?.trim(),
        displayName: displayName?.trim(),
      );
      _currentUser = user;
      _activeRole = role;
      _statusMessage = 'REGISTRATION SUCCESSFUL';
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: true, user: user, message: _statusMessage);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  // UC002_USER_REGISTRATION: Master Artisan
  Future<AuthResult> registerArtisan({
    required String email,
    required String password,
    required String confirmPassword,
    required String studioName,
    required String craftCategory,
    required String ssmNumber,
    String? username,
    String? fullName,
    String? ssmFileName,
    String? certFileName,
    List<String>? photos,
    String role = 'Artisan',
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final cleanConfirm = confirmPassword.trim();
    final cleanStudio = studioName.trim();
    final cleanSsm = ssmNumber.trim();
    final cleanFullName = fullName?.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Constraint C1: Password length > 7 characters
      if (cleanPassword.length <= 7) {
        _errorMessage = 'PASSWORD MUST BE GREATER THAN 7 CHARACTERS';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Constraint C2: Passwords match
      if (cleanPassword != cleanConfirm) {
        _errorMessage = 'PASSWORDS DO NOT MATCH';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Alternate Flow A4-1: Missing proof documents
      if (ssmFileName == null && cleanSsm.isEmpty) {
        _errorMessage =
            'PLEASE PROVIDE REQUIRED VERIFICATION PROOFS (SSM OR CERTIFICATE)';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Constraint C3: Artisan account status MUST initialize strictly as 'PENDING_APPROVAL'
      final user = await _repository.signUp(
        email: cleanEmail,
        password: cleanPassword,
        role: role,
        username: username,
        displayName: (cleanFullName != null && cleanFullName.isNotEmpty)
            ? cleanFullName
            : null,
        studioName: cleanStudio.isNotEmpty
            ? cleanStudio
            : 'MASTER ARTISAN STUDIO',
        craftCategory: craftCategory,
        ssmNumber: cleanSsm.isNotEmpty ? cleanSsm : 'SSM-PENDING-VERIFY',
        ssmFileName: ssmFileName,
        certFileName: certFileName,
        photos: photos,
      );

      _currentUser = user;
      _activeRole = role;
      _statusMessage = 'ARTISAN APPLICATION SUBMITTED: PENDING ADMIN APPROVAL';
      _isLoading = false;
      notifyListeners();

      return AuthResult(
        success: true,
        user: user,
        requiresEmailVerification: true,
        unverifiedEmail: cleanEmail,
        route: 'pending_artisan',
        message: _statusMessage,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  // UC002 - A4-2: Link Existing Tourist Account
  Future<AuthResult> linkArtisanToExistingTourist({
    required String email,
    required String studioName,
    required String craftCategory,
    required String ssmNumber,
    String? bio,
    String? phone,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    List<String> toolsAndMaterials = const [],
    String? ssmFileName,
    String? certFileName,
    PlatformFile? ssmFile,
    PlatformFile? certFile,
    List<PlatformFile>? photos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.linkArtisanRoleToTourist(
        email: email,
        studioName: studioName,
        craftCategory: craftCategory,
        ssmNumber: ssmNumber,
        bio: bio,
        phone: phone,
        state: state,
        address: address,
        latitude: latitude,
        longitude: longitude,
        toolsAndMaterials: toolsAndMaterials,
        ssmFile: ssmFile,
        certFile: certFile,
        photos: photos,
      );

      _currentUser = user;
      _statusMessage = 'ARTISAN PROFILE LINKED: Status set to PENDING_APPROVAL';
      _isLoading = false;
      notifyListeners();

      return AuthResult(
        success: true,
        user: user,
        route: 'pending_artisan',
        message: _statusMessage,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  // UC003_RESET_PASSWORD: Step 1 - Send reset token email
  Future<AuthResult> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        _errorMessage = 'PLEASE ENTER A VALID EMAIL ADDRESS';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Step 4 & 5: Validate email in DB & generate 15-min token (C1)
      await _repository.sendPasswordResetEmail(cleanEmail);

      _statusMessage = 'PASSWORD RESET LINK HAS BEEN SENT TO YOUR EMAIL';
      _isLoading = false;
      notifyListeners();

      return AuthResult(success: true, message: _statusMessage);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  // UC003_RESET_PASSWORD: Step 9-11 - Confirm password reset
  Future<AuthResult> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final cleanEmail = email.trim();
    final cleanToken = token.trim();
    final cleanPassword = newPassword.trim();
    final cleanConfirm = confirmPassword.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Constraint C2: Password length > 7 characters
      if (cleanPassword.length <= 7) {
        _errorMessage = 'PASSWORD MUST BE GREATER THAN 7 CHARACTERS';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Constraint C3: Passwords match
      if (cleanPassword != cleanConfirm) {
        _errorMessage = 'PASSWORDS DO NOT MATCH';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Step 11: Update encrypted password & invalidate token (C4)
      await _repository.resetPasswordWithToken(
        email: cleanEmail,
        token: cleanToken,
        newPassword: cleanPassword,
      );

      _statusMessage = 'PASSWORD RESET SUCCESSFUL: YOU MAY NOW LOGIN';
      _isLoading = false;
      notifyListeners();

      return AuthResult(success: true, message: _statusMessage);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  Future<void> logout() async {
    try {
      await _repository.signOut();
      _currentUser = null;
      _activeRole = null;
      _requiresRoleSelection = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      notifyListeners();
    }
  }
}
