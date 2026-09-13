import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/forum_repository.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';

class FlagRepository extends ForumRepository {
  ForumThread? created;
  ThreadReply? added;
  final targets = <String>[];
  List<ForumThread> loaded = [];
  @override
  Future<void> createThread(ForumThread thread) async { created = thread; }
  @override
  Future<void> postReply(String threadId, ThreadReply reply) async { added = reply; }
  @override
  Future<List<ForumThread>> getThreads() async => loaded;
  @override
  Future<List<Map<String, dynamic>>> fetchForumModerationHistory() async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchForumReportQueue() async => [];
  @override
  Future<Map<String, dynamic>> reportThread(String id, String reason, String notes,
      {bool isAutomated = false}) async {
    expect(isAutomated, isTrue);
    targets.add(id);
    return {'success': true};
  }
  @override
  Future<Map<String, dynamic>> reportReply(String postId, String replyId,
      String reason, String notes, {bool isAutomated = false}) async {
    expect(isAutomated, isTrue);
    targets.add(replyId);
    return {'success': true};
  }
}

void main() {
  test('Quarantined post blocks replies', () async {
    final repo = FlagRepository();
    repo.loaded = [ForumThread(id: 'post', community: 'c/Test', title: 'scam',
      authorName: 'Test', authorEmail: '', timestamp: '', isReported: true)];
    final vm = ForumViewModel(repository: repo);
    await vm.fetchThreads();
    final result = await vm.postReply(threadId: 'post', text: 'Hello',
      authorName: 'Test', authorEmail: '', isArtisan: false,
      authorRoleAtCreation: 'tourist', authorUserId: 'author');
    expect(result.isBlocked, isTrue);
    expect(repo.added, isNull);
    vm.dispose();
  });
  for (final flagPost in [false, true]) {
    for (final flagReply in [false, true]) {
      test('Creation targets: post=$flagPost reply=$flagReply', () async {
        final repo = FlagRepository();
        final vm = ForumViewModel(repository: repo);
        await vm.createThread(
          community: 'c/Test', title: flagPost ? 'scam' : 'Hi there',
          initialMessage: flagReply ? 'scam' : 'Hello',
          authorName: 'Test', authorEmail: '', isArtisan: false,
          authorRoleAtCreation: 'tourist', authorUserId: 'author',
        );
        final post = repo.created!;
        expect(post.isReported, flagPost);
        expect(post.upvotes, 0);
        expect(post.upvoteCount, 0);
        expect(post.userVote, 0);
        expect(post.replies.single.isReported, flagReply);
        expect(repo.targets, [
          if (flagPost) post.id,
          if (flagReply) post.replies.single.id,
        ]);
        vm.dispose();
      });
    }
  }
  test('Reply in existing post flags only the reply', () async {
    final repo = FlagRepository();
    final vm = ForumViewModel(repository: repo);
    await vm.postReply(threadId: 'existing', text: 'scam', authorName: 'Test',
      authorEmail: '', isArtisan: false, authorRoleAtCreation: 'tourist',
      authorUserId: 'author');
    expect(repo.targets, [repo.added!.id]);
    expect(repo.added!.isReported, isTrue);
    vm.dispose();
  });
}
