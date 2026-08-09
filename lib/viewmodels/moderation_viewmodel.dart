import 'package:flutter/material.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';

class ModerationViewModel extends ChangeNotifier {
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
    ),
    const PendingArtisanProfile(
      id: 'p5',
      name: 'Rajan Royal Pewter',
      craftCategory: 'Pewter Craft',
      state: 'Kuala Lumpur',
      dateSubmitted: 'Jul 30, 2026',
      imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80',
      email: 'rajan.pewter@example.com',
      experience: '10 Years',
      phone: '+60 16-789 0123',
    ),
  ];

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

  List<UserModel> get registeredUsers => _registeredUsers;

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

  void approveArtisan(String id) {
    _pendingArtisans.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void rejectArtisan(String id) {
    _pendingArtisans.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void suspendUser(String id) {
    final idx = _registeredUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _registeredUsers[idx] = _registeredUsers[idx].copyWith(isSuspended: true);
      notifyListeners();
    }
  }

  void reactivateUser(String id) {
    final idx = _registeredUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _registeredUsers[idx] = _registeredUsers[idx].copyWith(isSuspended: false);
      notifyListeners();
    }
  }
}
