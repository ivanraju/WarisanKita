import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/domain/models/badge.dart';

/// Read-only public passport data for the selected Forum author.
class ForumPublicPassport {
  final HeritageProgress progress;
  final List<HeritageStamp> stamps;

  ForumPublicPassport._(this.progress, this.stamps);

  static Future<ForumPublicPassport> load(
    SupabaseClient client,
    String userId,
  ) async {
    final result = await client.rpc(
      'fetch_forum_public_passport',
      params: {'target_user_id': userId},
    );
    if (result is! Map) {
      throw StateError('User profile unavailable');
    }
    final data = Map<String, dynamic>.from(result);
    return ForumPublicPassport._(
      HeritageProgression.fromXp((data['total_xp'] as num).toInt()),
      (data['stamps'] as List)
          .map((row) => HeritageStamp.fromMap(Map<String, dynamic>.from(row)))
          .toList(growable: false),
    );
  }
}
