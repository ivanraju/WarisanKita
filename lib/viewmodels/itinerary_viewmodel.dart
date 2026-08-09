import 'package:flutter/material.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';

class ItineraryViewModel extends ChangeNotifier {
  final List<ArtisanModel> _savedArtisans = [];
  List<ArtisanModel> get savedArtisans => _savedArtisans;

  void toggleSave(ArtisanModel artisan) {
    if (_savedArtisans.any((a) => a.id == artisan.id)) {
      _savedArtisans.removeWhere((a) => a.id == artisan.id);
    } else {
      _savedArtisans.add(artisan);
    }
    notifyListeners();
  }

  bool isSaved(String id) {
    return _savedArtisans.any((a) => a.id == id);
  }
}
