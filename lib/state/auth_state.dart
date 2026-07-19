import 'package:flutter/material.dart';
import 'package:warisan_kita/models/user_model.dart';

class AuthState extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real implementation, you would call the service:
      // final response = await _supabaseService.signIn(email, password);
      
      // For the "Functional Gap" priority and UI demonstration, we maintain mock successful login:
      await Future.delayed(const Duration(seconds: 2));
      
      _currentUser = UserModel(
        id: 'mock-uuid-123',
        email: email,
        role: email.contains('artisan') ? 'Artisan' : 'Tourist',
        displayName: email.split('@')[0],
      );
    } catch (e) {
      debugPrint('Login error: $e');
      // Handle error state if necessary
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      // final response = await _supabaseService.signUp(email, password, role);
      await Future.delayed(const Duration(seconds: 2));

      _currentUser = UserModel(
        id: 'mock-uuid-456',
        email: email,
        role: role,
        displayName: email.split('@')[0],
      );
    } catch (e) {
      debugPrint('SignUp error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      // await _supabaseService.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      notifyListeners();
    }
  }
}
