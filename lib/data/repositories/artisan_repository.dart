import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';

class ArtisanRepository {
  final SupabaseService _service;

  ArtisanRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  Future<List<ArtisanModel>> getArtisans() => _service.fetchArtisans();
}
