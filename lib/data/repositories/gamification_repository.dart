import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/badge.dart';

class GamificationRepository {
  final SupabaseService _service;

  GamificationRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  Future<List<HeritageStamp>> getUserBadges(String userId) => _service.fetchUserStamps(userId);
}
