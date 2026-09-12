import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/ssm_validator.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/services/supabase_service.dart'
    show EmailVerificationRequired;

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

  static String _friendlyError(Object error) {
    if (error is AuthException) {
      if (error.code == 'invalid_credentials' ||
          error.message.toLowerCase().contains('invalid login credentials')) {
        return 'Incorrect email, username, or password. Please try again.';
      }
      return error.message;
    }
    final raw = error.toString();
    final match = RegExp(r'message:\s*([^,\)]+)').firstMatch(raw);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return raw
        .replaceFirst('Exception: ', '')
        .replaceFirst('AuthException: ', '');
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel?>? _currentUserRefresh;

  @visibleForTesting
  void setCurrentUserForTesting(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

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
        _currentUser = user;
        _activeRole = user.role;
        if (user.status == 'SUSPENDED' || user.isSuspended) {
          _errorMessage = 'ACCOUNT SUSPENDED BY ADMINISTRATOR: CONTACT SUPPORT';
        }
        notifyListeners();
        return user;
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

  String? _relocationResolutionNotice;
  String? get relocationResolutionNotice => _relocationResolutionNotice;

  void clearRelocationResolutionNotice() {
    _relocationResolutionNotice = null;
    notifyListeners();
  }

  Future<UserModel?> refreshCurrentUser() {
    final existingRefresh = _currentUserRefresh;
    if (existingRefresh != null) return existingRefresh;

    late final Future<UserModel?> refresh;
    refresh = _refreshCurrentUserOnce().whenComplete(() {
      if (identical(_currentUserRefresh, refresh)) {
        _currentUserRefresh = null;
      }
    });
    _currentUserRefresh = refresh;
    return refresh;
  }

  Future<UserModel?> _refreshCurrentUserOnce() async {
    final previousUser = _currentUser;
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        if (_currentUser != null &&
            _currentUser!.id != user.id &&
            _currentUser!.email.isNotEmpty &&
            user.email.isNotEmpty &&
            _currentUser!.email.toLowerCase() != user.email.toLowerCase()) {
          return _currentUser;
        }
        if (_currentUser?.hasPendingRelocation == true &&
            !user.hasPendingRelocation) {
          if (user.address == _currentUser?.pendingRelocationAddress) {
            _relocationResolutionNotice = 'APPROVED';
          } else {
            _relocationResolutionNotice = 'REJECTED';
          }
        }
        var resolvedUser = user;
        if (_currentUser?.artisanStatus?.toUpperCase() == 'CLOSED' &&
            user.artisanStatus?.toUpperCase() != 'CLOSED') {
          resolvedUser = user.copyWith(
            role: 'Tourist',
            roles: const ['Tourist'],
            artisanStatus: 'CLOSED',
            clearStudioDetails: true,
          );
        }
        _currentUser = resolvedUser;
        if (_currentUser!.isArtisanStudioSuspended &&
            (_activeRole == 'Artisan' || _activeRole == 'Master Artisan')) {
          _activeRole = 'Cultural Tourist';
        }
        if (resolvedUser.status == 'SUSPENDED' || resolvedUser.isSuspended) {
          _errorMessage = 'ACCOUNT SUSPENDED BY ADMINISTRATOR: CONTACT SUPPORT';
        }
        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      debugPrint('refreshCurrentUser note: $e');
      if (e is AuthRetryableFetchException && previousUser != null) {
        return previousUser;
      }
    }
    _currentUser = null;
    _activeRole = null;
    notifyListeners();
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
    final email = _currentUser?.email ?? '';
    if (email.isEmpty) return;
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
        experience: experience,
        phone: phone,
        state: state,
        address: address,
        latitude: latitude,
        longitude: longitude,
        craftCategory: craftCategory,
        toolsAndMaterials: toolsAndMaterials,
        avatarUrl: newAvatarUrl,
        isLiveOpen: isLiveOpen,
        workshopCount: workshopCount,
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
          experience: experience ?? _currentUser!.experience,
          phone: phone ?? _currentUser!.phone,
          state: state ?? _currentUser!.state,
          craftCategory: craftCategory ?? _currentUser!.craftCategory,
          avatarUrl: newAvatarUrl,
          isLiveOpen: isLiveOpen ?? _currentUser!.isLiveOpen,
          workshopCount: workshopCount ?? _currentUser!.workshopCount,
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> submitRelocationRequest({
    required String address,
    required String state,
    required double latitude,
    required double longitude,
    required String reason,
    String? certUrl,
    String? certName,
  }) async {
    final email = _currentUser?.email ?? '';
    if (email.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _repository.submitRelocationRequest(
        email: email,
        address: address,
        state: state,
        latitude: latitude,
        longitude: longitude,
        reason: reason,
        certUrl: certUrl,
        certName: certName,
      );
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          pendingRelocationAddress: address.trim(),
          pendingRelocationState: state.trim(),
          pendingRelocationLatitude: latitude,
          pendingRelocationLongitude: longitude,
          pendingRelocationReason: reason.trim(),
          pendingRelocationDate:
              updated.pendingRelocationDate ?? DateTime.now().toIso8601String(),
          pendingRelocationCertUrl: certUrl,
          pendingRelocationCertName: certName,
        );
      } else {
        _currentUser = updated;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelRelocationRequest() async {
    final email = _currentUser?.email ?? '';
    if (email.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.cancelRelocationRequest(email: email);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(clearPendingRelocation: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadAvatar(PlatformFile file) async {
    final user = _currentUser;
    if (user == null) return null;
    final userId = user.id;
    final email = user.email;
    _isLoading = true;
    notifyListeners();

    try {
      final url = await _repository.uploadUserAvatar(userId, file);
      if (url != null && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(avatarUrl: url);
        try {
          await _repository.updateUserProfile(email: email, avatarUrl: url);
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
    _currentUser = null;
    _activeRole = null;
    _availableRoles = [];
    notifyListeners();

    try {
      // Constraint C1: Password cannot be empty
      if (cleanPassword.isEmpty) {
        _errorMessage = 'PLEASE ENTER YOUR PASSWORD';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // Alternate Flow A1: Email format validation (only if attempting email login)
      final isEmailAttempt =
          cleanEmail.contains('@') && !cleanEmail.startsWith('@');
      if (isEmailAttempt) {
        if (ProfileValidator.validateEmail(cleanEmail) != null) {
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
        await _repository.signOut();
        _errorMessage = 'ACCOUNT SUSPENDED BY ADMINISTRATOR: CONTACT SUPPORT';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      // 🌐 UC102: Web Moderation Portal Strict RBAC Guard
      if (kIsWeb && user.role != 'Admin') {
        await _repository.signOut();
        _errorMessage =
            'ACCESS DENIED: The Web Portal is exclusively for Administrators.';
        _isLoading = false;
        _currentUser = null;
        _activeRole = null;
        notifyListeners();
        return AuthResult(success: false, user: user, message: _errorMessage);
      }

      _currentUser = user;

      // Dedicated Admin routing
      if (user.role == 'Admin') {
        _activeRole = 'Admin';
        _statusMessage = 'LOGIN SUCCESSFUL';
        _isLoading = false;
        notifyListeners();
        return AuthResult(
          success: true,
          user: user,
          route: '/admin',
          message: _statusMessage,
        );
      }

      // Alternate Flow A5: Artisan Active Mode Selection (Master Artisan vs Cultural Tourist)
      final bool isDualRoleEligible = (user.isApprovedArtisan ||
              (user.isArtisan &&
                  !user.isPendingArtisan &&
                  user.artisanStatus?.toUpperCase() != 'CLOSED' &&
                  user.artisanStatus?.toUpperCase() != 'REJECTED')) &&
          user.artisanStatus?.toUpperCase() != 'CLOSED';

      if (isDualRoleEligible) {
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

      // Route pending artisan directly to pending screen
      if (user.isPendingArtisan) {
        _activeRole = 'Tourist';
        _statusMessage = 'LOGIN SUCCESSFUL';
        _isLoading = false;
        notifyListeners();
        return AuthResult(
          success: true,
          user: user,
          route: 'pending_artisan',
          message: _statusMessage,
        );
      }

      // Default Tourist routing
      String targetRoute = '/tourist';
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
      final rawError = _friendlyError(e);
      final lower = rawError.toLowerCase();
      _isLoading = false;

      if (lower.contains('email not confirmed') ||
          lower.contains('email_not_confirmed') ||
          lower.contains('not confirmed') ||
          lower.contains('not verified')) {
        _errorMessage =
            'EMAIL NOT VERIFIED: Please enter the 6-digit verification code sent to your email.';
        notifyListeners();
        return AuthResult(
          success: false,
          requiresEmailVerification: true,
          unverifiedEmail: e is EmailVerificationRequired
              ? e.email
              : cleanEmail,
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
      if (user.isSuspended ||
          user.status.toUpperCase() == 'SUSPENDED' ||
          (kIsWeb && !user.isAdmin)) {
        await _repository.signOut();
        throw Exception(
          'ACCESS DENIED: This account cannot access this application.',
        );
      }
      _currentUser = user;
      _activeRole = user.role;
      _statusMessage = 'EMAIL VERIFIED SUCCESSFULLY: WELCOME TO WARISAN KITA';
      _isLoading = false;
      notifyListeners();

      final route = user.isAdmin
          ? '/admin'
          : user.isArtisan
          ? (user.isApprovedArtisan ? '/artisan' : 'pending_artisan')
          : '/tourist';
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
      _statusMessage =
          'A new 6-digit verification code has been sent to your email.';
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
        (!_currentUser!.isApprovedArtisan ||
            _currentUser!.isArtisanStudioSuspended)) {
      // Security guard: Cannot select Master Artisan role unless approved by admin and studio is not suspended
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
  Future<AuthResult> _finishRegistration(UserModel user, String route) async {
    // Supabase can be configured to confirm email immediately. Only a real,
    // validated session may skip the verification screen in that configuration.
    final authenticated = await _repository.getCurrentUser();
    _currentUser = authenticated;
    _activeRole = authenticated?.role;
    notifyListeners();
    return AuthResult(
      success: true,
      user: authenticated ?? user,
      requiresEmailVerification: authenticated == null,
      unverifiedEmail: authenticated == null ? user.email : null,
      route: route,
      message: _statusMessage,
    );
  }

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

      if (ProfileValidator.validateEmail(cleanEmail) != null) {
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

      return await _finishRegistration(user, '/tourist');
    } catch (e) {
      _errorMessage = _friendlyError(e);
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
      _statusMessage = 'REGISTRATION SUCCESSFUL: PLEASE VERIFY YOUR EMAIL';
      _isLoading = false;
      notifyListeners();
      return await _finishRegistration(
        user,
        user.isArtisan ? 'pending_artisan' : '/tourist',
      );
    } catch (e) {
      _errorMessage = _friendlyError(e);
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

      // Alternate Flow A4-1: Missing proof documents or invalid SSM
      if (cleanSsm.isEmpty && ssmFileName == null) {
        _errorMessage =
            'PLEASE PROVIDE REQUIRED VERIFICATION PROOFS (SSM OR CERTIFICATE)';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      final ssmError = SsmValidator.validate(cleanSsm);
      if (ssmError != null) {
        _errorMessage = 'INVALID SSM REGISTRATION NUMBER: $ssmError';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      final isSsmDuplicate = await _repository.isSsmRegistered(cleanSsm);
      if (isSsmDuplicate) {
        _errorMessage =
            'DUPLICATE SSM: An artisan studio is already registered with SSM number "$cleanSsm"';
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

      _statusMessage = 'ARTISAN APPLICATION SUBMITTED: PENDING ADMIN APPROVAL';
      _isLoading = false;
      notifyListeners();

      return await _finishRegistration(user, 'pending_artisan');
    } catch (e) {
      _errorMessage = _friendlyError(e);
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
    String? experience,
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
    String? premiseType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String targetEmail = email.trim();
      if (targetEmail.isEmpty &&
          _currentUser != null &&
          _currentUser!.email.trim().isNotEmpty) {
        targetEmail = _currentUser!.email.trim();
      }
      if (targetEmail.isEmpty) {
        final restored = await restoreSession();
        if (restored != null && restored.email.trim().isNotEmpty) {
          targetEmail = restored.email.trim();
        }
      }

      if (targetEmail.isEmpty) {
        _errorMessage =
            'Authentication required: Please sign in with your tourist account or enter your account email to submit an artisan application.';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      final bool isVillage = premiseType != null &&
          (premiseType.contains('Village') ||
              premiseType.contains('Desa') ||
              premiseType.contains('Home') ||
              premiseType.contains('Kediaman'));

      final cleanSsm = ssmNumber.trim();
      if (cleanSsm.isNotEmpty) {
        final ssmError = SsmValidator.validate(cleanSsm);
        if (ssmError != null) {
          _errorMessage = 'INVALID SSM REGISTRATION NUMBER: $ssmError';
          _isLoading = false;
          notifyListeners();
          return AuthResult(success: false, message: _errorMessage);
        }

        final isSsmDuplicate = await _repository.isSsmRegistered(
          cleanSsm,
          excludeEmail: targetEmail,
          excludeUserId: _currentUser?.id,
        );
        if (isSsmDuplicate) {
          _errorMessage =
              'DUPLICATE SSM: An artisan studio is already registered with SSM number "$cleanSsm"';
          _isLoading = false;
          notifyListeners();
          return AuthResult(success: false, message: _errorMessage);
        }
      } else if (!isVillage) {
        _errorMessage = 'SSM registration number is mandatory for Commercial Studios.';
        _isLoading = false;
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      final user = await _repository.linkArtisanRoleToTourist(
        email: targetEmail,
        studioName: studioName,
        craftCategory: craftCategory,
        ssmNumber: cleanSsm,
        experience: experience,
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
        premiseType: premiseType,
      );

      _currentUser = user;
      _activeRole = 'Tourist';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('dismissed_rejection_banner_${user.id}');
        await prefs.remove('shown_rejection_dialog_${user.id}');
      } catch (_) {}
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
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  Future<bool> isSsmAvailable(
    String ssmNumber, {
    String? excludeEmail,
    String? excludeUserId,
  }) async {
    final clean = ssmNumber.trim();
    if (!SsmValidator.isValid(clean)) return false;
    final isRegistered = await _repository.isSsmRegistered(
      clean,
      excludeEmail: excludeEmail ?? _currentUser?.email,
      excludeUserId: excludeUserId ?? _currentUser?.id,
    );
    return !isRegistered;
  }

  // UC003_RESET_PASSWORD: Step 1 - Send reset token email
  Future<AuthResult> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (ProfileValidator.validateEmail(cleanEmail) != null) {
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
      _errorMessage = _friendlyError(e);
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
      _currentUser = null;
      _activeRole = null;
      _requiresRoleSelection = false;

      _statusMessage = 'PASSWORD RESET SUCCESSFUL: YOU MAY NOW LOGIN';
      _isLoading = false;
      notifyListeners();

      return AuthResult(success: true, message: _statusMessage);
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final cleanCurrent = currentPassword.trim();
    final cleanNew = newPassword.trim();
    final cleanConfirm = confirmPassword.trim();

    if (cleanCurrent.isEmpty) {
      _errorMessage = 'PLEASE ENTER YOUR CURRENT PASSWORD';
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }

    if (cleanNew.length <= 7) {
      _errorMessage = 'PASSWORD MUST BE GREATER THAN 7 CHARACTERS';
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }

    if (cleanNew != cleanConfirm) {
      _errorMessage = 'PASSWORDS DO NOT MATCH';
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }

    if (cleanCurrent.toLowerCase() == cleanNew.toLowerCase()) {
      _errorMessage =
          'NEW PASSWORD IS TOO SIMILAR TO YOUR CURRENT PASSWORD: Please choose a completely new password, not just a change in uppercase or lowercase.';
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.changePassword(
        currentPassword: cleanCurrent,
        newPassword: cleanNew,
      );

      _statusMessage = 'PASSWORD CHANGED SUCCESSFULLY';
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: true, message: _statusMessage);
    } catch (e) {
      _errorMessage = _friendlyError(e);
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
      _errorMessage = null;
      _statusMessage = null;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _errorMessage = null;
      _statusMessage = null;
      notifyListeners();
    }
  }

  Future<AuthResult> deactivateArtisanStudio() async {
    if (_currentUser == null) {
      return const AuthResult(
        success: false,
        message: 'No active user session found.',
      );
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.deactivateArtisanStudio();
      _currentUser = updatedUser.copyWith(
        role: 'Tourist',
        roles: const ['Tourist'],
        artisanStatus: 'CLOSED',
        clearStudioDetails: true,
      );
      _activeRole = 'Tourist';
      _requiresRoleSelection = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return const AuthResult(
        success: true,
        message:
            'Your artisan studio has been deactivated. You are now exploring as a Cultural Explorer.',
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = _friendlyError(e);
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }

  Future<AuthResult> deleteCurrentAccount({String? password}) async {
    if (_currentUser == null) {
      return const AuthResult(
        success: false,
        message: 'No active user session to delete.',
      );
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _currentUser!.id;
      final email = _currentUser!.email;
      final username = _currentUser!.username;
      await _repository.deleteAccount(
        userId: userId,
        email: email,
        username: username,
        password: password,
      );

      _currentUser = null;
      _activeRole = null;
      _requiresRoleSelection = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return const AuthResult(
        success: true,
        message: 'Account successfully deleted.',
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = _friendlyError(e);
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }
}
