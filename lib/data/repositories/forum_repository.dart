import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';

class ForumRepository {
  final SupabaseService _service;

  ForumRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  Future<List<ForumThread>> getThreads() => _service.fetchThreads();
}
