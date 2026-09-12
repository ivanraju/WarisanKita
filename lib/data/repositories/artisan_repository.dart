import 'package:flutter/foundation.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';

class ArtisanRepository {
  final SupabaseService _service;
  late final GamificationRepository _gamificationRepository;

  ArtisanRepository({
    SupabaseService? service,
    GamificationRepository? gamificationRepository,
  }) : _service = service ?? SupabaseService() {
    _gamificationRepository =
        gamificationRepository ?? GamificationRepository(service: _service);
  }

  Future<List<ArtisanModel>> getArtisans() async {
    final artisans = await _service.fetchArtisans();
    if (artisans.isEmpty) return artisans;

    try {
      // Use the same approved-quest summary as Map. It already excludes
      // pending/archived tasks and selects only one quest per workshop.
      final snapshot = await _gamificationRepository
          .getTouristJourneySnapshot();
      return artisans.map((artisan) {
        final journey = snapshot.journeysByWorkshopId[artisan.id];
        return artisan.copyWith(questPotentialXp: journey?.xpReward);
      }).toList(growable: false);
    } catch (error, stackTrace) {
      // Quest XP is supplementary; never prevent directory cards from loading.
      debugPrint('ArtisanRepository quest XP summary unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return artisans;
    }
  }

  Future<List<WorkshopLocation>> getWorkshopLocations() async {
    final data = await _service.fetchWorkshopLocations();

    return _mapWorkshopLocations(data);
  }

  Stream<List<WorkshopLocation>> watchWorkshopLocations() {
    return _service.watchWorkshopLocations().map(_mapWorkshopLocations);
  }

  List<WorkshopLocation> _mapWorkshopLocations(
    List<Map<String, dynamic>> data,
  ) {
    return data.map((row) {
      return WorkshopLocation(
        id: row['id'] as String,
        name: row['studio_name'] as String,
        craftCategory: row['craft_category'] as String,
        address: row['address'] as String,
        state: row['state'] as String,
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
      );
    }).toList();
  }
}
