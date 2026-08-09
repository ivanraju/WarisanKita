import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/viewmodels/craft_personality.dart';
import 'package:warisan_kita/domain/models/nearby_artisan.dart';

class MatchmakerViewModel extends ChangeNotifier {
  final MatchmakerRepository _repository;

  MatchmakerViewModel({MatchmakerRepository? repository})
      : _repository = repository ?? const MatchmakerRepository() {
    initTouristMatchmaker();
  }

  // Quiz State
  final Map<int, String> _answers = {};
  
  void setAnswer(int questionIndex, String optionLabel) {
    _answers[questionIndex] = optionLabel;
    notifyListeners();
  }

  CraftPersonality calculateResult() {
    return _repository.calculatePersonality(_answers);
  }

  // Tourist Matchmaker State
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<NearbyArtisan> _nearbyArtisans = [];
  List<NearbyArtisan> get nearbyArtisans => _nearbyArtisans;

  NearbyArtisan? _selectedArtisan;
  NearbyArtisan? get selectedArtisan => _selectedArtisan;

  /// Initializes mock tourist matchmaker data with a 2-second loading delay
  Future<void> initTouristMatchmaker() async {
    _isLoading = true;
    _selectedArtisan = null;
    notifyListeners();

    // 2-second delay for shimmer effect demo
    await Future.delayed(const Duration(seconds: 2));

    _nearbyArtisans = [
      const NearbyArtisan(
        id: 'artisan_1',
        name: 'Pak Mat Pottery Studio',
        craftCategory: 'Pottery & Ceramics',
        walkingTime: '12 mins away',
        distance: '800m',
        imageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
        rating: 4.9,
        reviewCount: 128,
        mapXRatio: 0.38,
        mapYRatio: 0.35,
        isOpenNow: true,
        locationName: 'Central Market Alley, KL',
      ),
      const NearbyArtisan(
        id: 'artisan_2',
        name: 'Kak Lina Silk Batik',
        craftCategory: 'Batik Weaving',
        walkingTime: '5 mins away',
        distance: '350m',
        imageUrl: 'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
        rating: 4.8,
        reviewCount: 94,
        mapXRatio: 0.68,
        mapYRatio: 0.22,
        isOpenNow: true,
        locationName: 'Heritage Walk, Lot 14',
      ),
      const NearbyArtisan(
        id: 'artisan_3',
        name: 'Uncle Tan Woodcraft',
        craftCategory: 'Wood Carving',
        walkingTime: '18 mins away',
        distance: '1.2 km',
        imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
        rating: 4.9,
        reviewCount: 210,
        mapXRatio: 0.48,
        mapYRatio: 0.65,
        isOpenNow: false,
        locationName: 'Old Town Square, Block C',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void selectArtisan(NearbyArtisan? artisan) {
    if (_selectedArtisan?.id == artisan?.id) {
      _selectedArtisan = null;
    } else {
      _selectedArtisan = artisan;
    }
    notifyListeners();
  }

  void refreshMatchmaker() {
    initTouristMatchmaker();
  }
}
