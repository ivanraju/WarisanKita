import 'package:flutter/material.dart';
import 'package:warisan_kita/models/artisan_model.dart';
import 'package:warisan_kita/services/supabase_service.dart';

class DirectoryState extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  
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

  DirectoryState() {
    fetchArtisans();
  }

  Future<void> fetchArtisans() async {
    // Prevent double-loading
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 4-Layer Architecture: State calls Service to get raw data
      _allArtisans = await _service.fetchArtisans();
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
    _filteredArtisans = _allArtisans.where((artisan) {
      final matchesSearch = artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           artisan.craftType.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCraft = _selectedCraft == 'All Crafts' || artisan.craftType == _selectedCraft;
      final matchesState = _selectedState == 'All States' || artisan.state == _selectedState;
      
      return matchesSearch && matchesCraft && matchesState;
    }).toList();
    
    // Premium UI Tip: Sort by rating to ensure masters appear first
    _filteredArtisans.sort((a, b) => b.rating.compareTo(a.rating));
    
    notifyListeners();
  }
}
