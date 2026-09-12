import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';

void main() {
  test('Post and reply snapshots survive current-role changes and edits', () {
    for (final role in ['artisan', 'tourist']) {
      for (final current in ['Artisan', 'Tourist']) {
        final row = <String, dynamic>{
          'id': 'content',
          'user_id': 'stable-user',
          'title': 'title',
          'content': 'body',
          'author_role_at_creation': role,
          'users': {'role': current},
        };
        final post = ForumThread.fromMap(row);
        final reply = ThreadReply.fromMap(row);
        expect(post.isArtisan, role == 'artisan');
        expect(reply.isArtisan, role == 'artisan');
        expect(post.copyWith(title: 'edited').authorRoleAtCreation, role);
        expect(reply.copyWith(text: 'edited').authorRoleAtCreation, role);
        expect(ForumThread.fromMap(post.toMap()).isArtisan, role == 'artisan');
        expect(ThreadReply.fromMap(reply.toMap()).isArtisan, role == 'artisan');
        expect(reply.userId, 'stable-user');
        expect(post.toDbMap()['author_role_at_creation'], role);
        expect(reply.toDbMap('post')['author_role_at_creation'], role);
      }
    }
  });
  test('Legacy remains nullable; active profile normalizes explicitly', () {
    expect(
      ThreadReply.fromMap({
        'id': 'old',
        'users': {'role': 'Artisan'},
      }).authorRoleAtCreation,
      isNull,
    );
    expect(normalizeForumCreationRole('Master Artisan'), 'artisan');
    expect(normalizeForumCreationRole('Cultural Tourist'), 'tourist');
    expect(() => normalizeForumCreationRole(null), throwsStateError);
  });
}
