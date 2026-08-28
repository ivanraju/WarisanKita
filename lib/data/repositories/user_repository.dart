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

  Future<UserModel> linkArtisanRoleToTourist({
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
    PlatformFile? ssmFile,
    PlatformFile? certFile,
    List<PlatformFile>? photos,
  }) {
    return _service.linkArtisanRoleToTourist(
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
      ssmFile: ssmFile,
      certFile: certFile,
      photos: photos,
    );
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
  }) {
    return _service.updateUserProfile(
      email: email,
      username: username,
      displayName: displayName,
      studioName: studioName,
      bio: bio,
      phone: phone,
      state: state,
      craftCategory: craftCategory,
    );
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
  }) {
    return _service.updateArtisanStatusInDb(
      email: email,
      newStatus: newStatus,
      newRole: newRole,
    );
  }

  Future<void> signOut() => _service.signOut();
}
