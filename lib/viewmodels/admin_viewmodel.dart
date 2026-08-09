import 'package:flutter/foundation.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';

/// Presentation state for the web-only artisan approval workflow.
class AdminViewModel extends ChangeNotifier {
  final List<ArtisanModel> _pendingArtisans = [];

  List<ArtisanModel> get pendingArtisans => List.unmodifiable(_pendingArtisans);

  void approveArtisan(String artisanId) {
    _pendingArtisans.removeWhere((artisan) => artisan.id == artisanId);
    notifyListeners();
  }
}
