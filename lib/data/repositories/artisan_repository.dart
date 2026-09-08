import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';

class ArtisanRepository {
  final SupabaseService _service;

  ArtisanRepository({SupabaseService? service})
    : _service = service ?? SupabaseService();

  Future<List<ArtisanModel>> getArtisans() => _service.fetchArtisans();

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
