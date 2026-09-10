import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';

class DirectoryViewModel extends ChangeNotifier {
  final ArtisanRepository _repository;

  DirectoryViewModel({ArtisanRepository? repository})
      : _repository = repository ?? ArtisanRepository() {
    fetchArtisans();
  }
  
  List<ArtisanModel> _allArtisans = [];
  List<ArtisanModel> _filteredArtisans = [];
  
  List<ArtisanModel> get artisans => _filteredArtisans;
  
  // Neo-Traditional UX: Provide a curated list for high-impact home sections
  List<ArtisanModel> get featuredArtisans => 
      _allArtisans.where((a) => a.rating >= 4.8).take(5).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String _selectedCraft = 'All Crafts';
  String _selectedState = 'All States';
  
  String get selectedCraft => _selectedCraft;
  String get selectedState => _selectedState;

  Future<void> fetchArtisans() async {
    // Prevent double-loading
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allArtisans = await _repository.getArtisans();
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching artisans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Functional Gap: Support for multi-criteria filtering (Craft + State)
  void updateFilter({String? craft, String? state}) {
    if (craft != null) _selectedCraft = craft;
    if (state != null) _selectedState = state;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCraft = 'All Crafts';
    _selectedState = 'All States';
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase().trim();
    final craftQ = _selectedCraft.toLowerCase().trim();
    final stateQ = _selectedState.toLowerCase().trim();

    _filteredArtisans = _allArtisans.where((artisan) {
      final name = artisan.name.toLowerCase();
      final craft = artisan.craftType.toLowerCase();
      final desc = artisan.description.toLowerCase();
      final state = artisan.state.toLowerCase();
      final tags = artisan.tags.map((t) => t.toLowerCase()).toList();

      final matchesSearch = q.isEmpty ||
          name.contains(q) ||
          craft.contains(q) ||
          desc.contains(q) ||
          state.contains(q) ||
          tags.any((t) => t.contains(q));

      final matchesCraft = craftQ == 'all crafts' ||
          craft == craftQ ||
          craft.contains(craftQ) ||
          craftQ.contains(craft) ||
          tags.any((t) => t.contains(craftQ) || craftQ.contains(t));

      final matchesState = stateQ == 'all states' || state == stateQ;

      return matchesSearch && matchesCraft && matchesState;
    }).toList();

    // Premium UI Tip: Sort by rating to ensure masters appear first
    _filteredArtisans.sort((a, b) => b.rating.compareTo(a.rating));
    
    notifyListeners();
  }
}
