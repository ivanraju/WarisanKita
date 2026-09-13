import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';

const postId = '11111111-1111-4111-8111-111111111111';
const replyId = '22222222-2222-4222-8222-222222222222';
const bodyPostId = '33333333-3333-4333-8333-333333333333';

class VoteBackend {
  final votes = <String, List<int>>{
    'post': [...List.filled(5, 1), ...List.filled(6, -1)],
    'reply': [...List.filled(5, 1), ...List.filled(6, -1)],
  };
  final selected = {'post': 0, 'reply': 0};
  final countRequests = <String, int>{};
  bool failCounts = false;
  bool failContent = false;
  bool includePostBody = false;

  Future<http.Response> handle(http.Request request) async {
    final name = request.url.pathSegments.last;
    final target = name.contains('reply') || name == 'forum_replies'
        ? 'reply' : 'post';
    final targetId = target == 'post' ? postId : replyId;
    Object result;
    final headers = {'content-type': 'application/json'};
    if ((failCounts && name.endsWith('_votes')) ||
        (failContent && (name == 'forum_posts' || name == 'forum_replies'))) {
      return http.Response(jsonEncode({'code': '42501', 'message': 'Denied'}),
          403, request: request, headers: headers);
    }
    if (name.startsWith('vote_forum_')) {
      expect(jsonDecode(request.body)['p_${target}_id'], targetId);
      final direction = jsonDecode(request.body)['p_vote'] as int;
      final old = selected[target]!;
      final next = old == direction ? 0 : direction;
      if (old != 0) votes[target]!.remove(old);
      if (next != 0) votes[target]!.add(next);
      selected[target] = next;
      result = {'upvotes': votes[target]!.fold<int>(0, (a, b) => a + b),
        'user_vote': next};
    } else if (name.endsWith('_votes')) {
      if ((request.url.queryParameters['reply_id'] ?? '').contains('_content')) {
        return http.Response(jsonEncode({
          'code': '22P02', 'message': 'invalid input syntax for type uuid',
        }), 400, request: request, headers: headers);
      }
      // Production uses target/user keys, not an id column.
      expect(request.url.queryParameters['order'], contains('user_id'));
      expect(request.url.queryParameters['order']!.split(','),
          isNot(contains('id.asc')));
      countRequests.update(target, (n) => n + 1, ifAbsent: () => 1);
      final offset = int.parse(request.url.queryParameters['offset'] ?? '0');
      final limit = int.parse(request.url.queryParameters['limit'] ?? '500');
      final rows = votes[target]!.skip(offset).take(limit).toList();
      headers['content-range'] = rows.isEmpty
          ? '*/${votes[target]!.length}'
          : '$offset-${offset + rows.length - 1}/${votes[target]!.length}';
      expect(request.url.queryParameters['${target}_id'], contains(targetId));
      result = rows.map((v) => {'${target}_id': targetId, 'vote': v}).toList();
    } else {
      result = [{'id': targetId, 'title': 'Content', 'content': 'Content',
        'upvotes': votes[target]!.fold<int>(0, (a, b) => a + b)}];
      if (includePostBody && name == 'forum_posts') {
        (result as List).add({'id': bodyPostId, 'title': 'Title', 'content': 'Body'});
      }
      if (includePostBody && name == 'forum_replies' &&
          request.url.queryParameters['post_id'] == 'eq.$bodyPostId') {
        result = [];
      }
    }
    return http.Response(jsonEncode(result), 200,
        request: request, headers: headers);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VoteBackend backend;
  late SupabaseService service;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = VoteBackend();
    final client = SupabaseClient('https://example.test', 'test',
        httpClient: MockClient(backend.handle));
    service = SupabaseService(client: client);
    addTearDown(client.dispose);
  });

  test('5 up / 6 down, local toggle and switch transitions for both targets', () async {
    final initial = (await service.fetchThreads()).single;
    expect(initial.upvoteCount, 5);
    expect(initial.downvoteCount, 6);
    expect(initial.upvotes, -1);
    expect(initial.replies.single.upvoteCount, 5);
    expect(initial.replies.single.downvoteCount, 6);
    expect(backend.countRequests, {'post': 1, 'reply': 1});
    // Fetch fallback exposes the local updates independently of count rereads.
    backend.failContent = true;
    for (final direction in [1, -1, 1, 1, -1, -1]) {
      await service.voteThread(postId, direction);
      await service.voteReply(postId, replyId, direction);
      final post = (await service.fetchThreads()).single;
      for (final entry in {'post': post.toMap(),
        'reply': post.replies.single.toMap()}.entries) {
        expect(entry.value['upvoteCount'],
            backend.votes[entry.key]!.where((v) => v == 1).length);
        expect(entry.value['downvoteCount'],
            backend.votes[entry.key]!.where((v) => v == -1).length);
        expect(entry.value['userVote'], backend.selected[entry.key]);
      }
    }
  });

  test('Count failure retains freshly fetched posts and replies with zero counts', () async {
    backend.failCounts = true;
    final post = (await service.fetchThreads()).single;
    expect(post.id, postId);
    expect(post.title, 'Content');
    expect(post.upvotes, -1);
    expect(post.upvoteCount, 0);
    expect(post.downvoteCount, 0);
    expect(post.replies.single.id, replyId);
    expect(post.replies.single.text, 'Content');
    expect(post.replies.single.upvoteCount, 0);
    expect(post.replies.single.downvoteCount, 0);
  });

  test('Pagination uses real keys and preserves all counts', () async {
    backend.votes['post'] = [...List.filled(505, 1), ...List.filled(6, -1)];
    final post = (await service.fetchThreads()).single;
    expect(post.upvoteCount, 505);
    expect(post.downvoteCount, 6);
    expect(backend.countRequests, {'post': 2, 'reply': 1});
  });

  test('Synthetic post body cannot break real reply counts after voting', () async {
    backend.includePostBody = true;
    final initial = await service.fetchThreads();
    expect(initial.firstWhere((p) => p.id == bodyPostId).replies.single.id,
        '${bodyPostId}_content');
    expect(initial.firstWhere((p) => p.id == postId).replies.single.upvoteCount, 5);
    await service.voteReply(postId, replyId, 1);
    final refreshed = await service.fetchThreads();
    final reply = refreshed.firstWhere((p) => p.id == postId).replies.single;
    expect(reply.userVote, 1);
    expect(reply.upvoteCount, 6);
    expect(reply.downvoteCount, 6);
    expect(refreshed.length, 2);
  });
}
