import 'package:warisan_kita/data/services/supabase_service.dart';

class UserRepository {
  final SupabaseService _service;

  UserRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  Future<void> signOut() => _service.signOut();
}
