import 'package:file_picker/file_picker.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/user.dart';

class UserRepository {
  final SupabaseService _service;

  UserRepository({SupabaseService? service})
    : _service = service ?? SupabaseService();

  Future<bool> isUsernameAvailable(String username, {String? excludeEmail}) {
    return _service.isUsernameAvailable(username, excludeEmail: excludeEmail);
  }

  Future<bool> isSsmRegistered(
    String ssmNumber, {
    String? excludeEmail,
    String? excludeUserId,
  }) {
    return _service.isSsmRegistered(
      ssmNumber,
      excludeEmail: excludeEmail,
      excludeUserId: excludeUserId,
    );
  }

  Future<bool> isPhoneRegistered(
    String phone, {
    String? excludeEmail,
    String? excludeUserId,
  }) {
    return _service.isPhoneRegistered(
      phone,
      excludeEmail: excludeEmail,
      excludeUserId: excludeUserId,
    );
  }

  Future<ExistingAccountCheck> checkExistingAccount(String email) {
    return _service.checkExistingAccount(email);
  }

  Future<UserModel> signIn(String email, String password) {
    return _service.signIn(email, password);
  }

  Future<UserModel?> getCurrentUser() {
    return _service.getCurrentUser();
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
  }) {
    return _service.signUp(
      email: email,
      password: password,
      role: role,
      username: username,
      displayName: displayName,
      studioName: studioName,
      craftCategory: craftCategory,
      ssmNumber: ssmNumber,
      ssmFileName: ssmFileName,
      certFileName: certFileName,
      photos: photos,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _service.sendPasswordResetEmail(email);
  }

  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _service.resetPasswordWithToken(
      email: email,
      token: token,
      newPassword: newPassword,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<UserModel> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _service.verifyEmailOtp(email: email, token: token);
  }

  Future<void> resendVerificationOtp({required String email}) {
    return _service.resendVerificationOtp(email: email);
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
  }) {
    return _service.linkArtisanRoleToTourist(
      email: email,
      studioName: studioName,
      craftCategory: craftCategory,
      ssmNumber: ssmNumber,
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
  }) {
    return _service.updateUserProfile(
      email: email,
      username: username,
      displayName: displayName,
      studioName: studioName,
      bio: bio,
      experience: experience,
      phone: phone,
      state: state,
      address: address,
      latitude: latitude,
      longitude: longitude,
      craftCategory: craftCategory,
      toolsAndMaterials: toolsAndMaterials,
      avatarUrl: avatarUrl,
      isLiveOpen: isLiveOpen,
      workshopCount: workshopCount,
    );
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
  }) {
    return _service.submitRelocationRequest(
      email: email,
      address: address,
      state: state,
      latitude: latitude,
      longitude: longitude,
      reason: reason,
      certUrl: certUrl,
      certName: certName,
    );
  }

  Future<UserModel> cancelRelocationRequest({required String email}) {
    return _service.cancelRelocationRequest(email: email);
  }

  Future<UserModel> approveRelocationRequest({
    required String email,
    String? newAddress,
    String? newState,
    double? newLat,
    double? newLng,
  }) {
    return _service.approveRelocationRequest(
      email: email,
      proposedAddress: newAddress,
      proposedState: newState,
      proposedLat: newLat,
      proposedLng: newLng,
    );
  }

  Future<UserModel> rejectRelocationRequest({
    required String email,
    String? feedback,
  }) {
    return _service.rejectRelocationRequest(email: email, feedback: feedback);
  }

  Future<String?> uploadUserAvatar(String userIdOrEmail, PlatformFile file) {
    return _service.uploadUserAvatar(userIdOrEmail, file);
  }

  Future<List<Map<String, dynamic>>> getPendingArtisans() {
    return _service.getPendingArtisans();
  }

  Future<List<ActiveArtisanMaster>> getActiveArtisans() {
    return _service.getActiveArtisans();
  }

  Future<List<UserModel>> getAllUsers() {
    return _service.getAllUsers();
  }

  Future<void> updateArtisanStatus({
    required String email,
    required String newStatus,
    required String newRole,
    bool updateArtisanProfileOnly = false,
    bool ensureSystemTasks = false,
    String? suspensionReason,
    String? rejectionReason,
  }) {
    return _service.updateArtisanStatusInDb(
      email: email,
      newStatus: newStatus,
      newRole: newRole,
      updateArtisanProfileOnly: updateArtisanProfileOnly,
      ensureSystemTasks: ensureSystemTasks,
      suspensionReason: suspensionReason,
      rejectionReason: rejectionReason,
    );
  }

  Future<void> signOut() => _service.signOut();

  Future<UserModel> deactivateArtisanStudio() =>
      _service.deactivateArtisanStudio();

  Future<void> deleteAccount({
    required String userId,
    required String email,
    String? username,
    String? password,
  }) => _service.deleteAccount(
    userId: userId,
    email: email,
    username: username,
    password: password,
  );
}
