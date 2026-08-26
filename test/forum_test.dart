import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/forum_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';

void main() {
  group('Forum Thread & Reply Model Parsing Tests', () {
    test('ForumThread.fromMap parses numbers, strings, and missing fields safely', () {
      final map = {
        'id': 'thread-123',
        'title': 'How to preserve Songket?',
        'community': 'c/Songket',
        'author_name': 'Pak Ali',
        'author_email': 'ali@songket.my',
        'upvotes': 5,
        'user_vote': 1,
        'replies_count': 2,
        'timestamp': '2026-08-26T00:00:00Z',
        'is_solved': false,
      };

      final thread = ForumThread.fromMap(map);
      expect(thread.id, 'thread-123');
      expect(thread.title, 'How to preserve Songket?');
      expect(thread.upvotes, 5);
      expect(thread.userVote, 1);
      expect(thread.authorName, 'Pak Ali');
    });

    test('ThreadReply.fromMap parses numbers and missing user safely', () {
      final replyMap = {
        'id': 'reply-456',
        'sender': 'Siti Artisan',
        'author_email': 'siti@crafts.my',
        'content': 'Store it in acid-free paper away from direct sunlight.',
        'upvotes': 12,
        'user_vote': -1,
        'is_verified_answer': true,
        'timestamp': '10 mins ago',
      };

      final reply = ThreadReply.fromMap(replyMap);
      expect(reply.id, 'reply-456');
      expect(reply.upvotes, 12);
      expect(reply.userVote, -1);
      expect(reply.isVerifiedAnswer, true);
    });
  });

  group('Forum Upvote, Downvote, & Self-Voting Prevention Tests', () {
    late SupabaseService service;
    late ForumRepository repository;
    late ForumViewModel viewModel;

    setUp(() {
      service = SupabaseService();
      repository = ForumRepository(service: service);
      viewModel = ForumViewModel(repository: repository);
    });

    test('Creating a thread initializes score to 0 and neutral vote 0 (StackOverflow/Quora standard)', () async {
      await viewModel.createThread(
        community: 'c/Batik',
        title: 'Best wax for canting technique?',
        authorName: 'Ahmad',
        authorEmail: 'ahmad@test.my',
        isArtisan: false,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Best wax for canting technique?');
      expect(thread.upvotes, 0);
      expect(thread.userVote, 0);
    });

    test('Community members voting on a thread applies +1, toggle off (0), and downvote (-1)', () async {
      await viewModel.createThread(
        community: 'c/Wau',
        title: 'Bamboo curing for Wau Bulan',
        authorName: 'Karim',
        authorEmail: 'karim@test.my',
        isArtisan: true,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Bamboo curing for Wau Bulan');
      expect(thread.upvotes, 0);

      // Community member upvotes (+1)
      await viewModel.voteThread(thread.id, 1);
      final upvotedThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(upvotedThread.userVote, 1);
      expect(upvotedThread.upvotes, 1);

      // Community member clicks Upvote again -> toggles off (0)
      await viewModel.voteThread(thread.id, 1);
      final toggledThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(toggledThread.userVote, 0);
      expect(toggledThread.upvotes, 0);

      // Community member downvotes (-1)
      await viewModel.voteThread(thread.id, -1);
      final downvotedThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(downvotedThread.userVote, -1);
      expect(downvotedThread.upvotes, -1);
    });

    test('Switching vote directly from Upvote (+1) to Downvote (-1) applies -2 score delta', () async {
      await viewModel.createThread(
        community: 'c/Keris',
        title: 'Lok 7 forging process',
        authorName: 'Empu',
        authorEmail: 'empu@test.my',
        isArtisan: true,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Lok 7 forging process');

      // Member upvotes (+1)
      await viewModel.voteThread(thread.id, 1);
      expect(viewModel.threads.firstWhere((t) => t.id == thread.id).upvotes, 1);

      // Member switches directly to Downvote (-1)
      await viewModel.voteThread(thread.id, -1);
      final downvoted = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(downvoted.userVote, -1);
      expect(downvoted.upvotes, -1); // 1 -> -1 = delta -2

      // Switch back to Upvote (+1)
      await viewModel.voteThread(thread.id, 1);
      final upvotedAgain = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(upvotedAgain.userVote, 1);
      expect(upvotedAgain.upvotes, 1); // -1 -> 1 = delta +2
    });

    test('Reply voting starts at 0 and correctly handles upvoting, cancelling, and downvoting', () async {
      await viewModel.createThread(
        community: 'c/Woodcarving',
        title: 'Chengal wood grain selection',
        authorName: 'Tukang',
        authorEmail: 'tukang@test.my',
        isArtisan: true,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Chengal wood grain selection');
      await viewModel.postReply(
        threadId: thread.id,
        text: 'Select matured core wood with tight grain patterns.',
        authorName: 'Master Rosli',
        authorEmail: 'rosli@wood.my',
        isArtisan: true,
      );

      final updatedThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      final reply = updatedThread.replies.first;
      expect(reply.upvotes, 0);
      expect(reply.userVote, 0);

      // Community member upvotes (+1)
      await viewModel.voteReply(thread.id, reply.id, 1);
      final upvotedReply = viewModel.threads.firstWhere((t) => t.id == thread.id).replies.first;
      expect(upvotedReply.userVote, 1);
      expect(upvotedReply.upvotes, 1);

      // Toggle off (0)
      await viewModel.voteReply(thread.id, reply.id, 1);
      final toggledReply = viewModel.threads.firstWhere((t) => t.id == thread.id).replies.first;
      expect(toggledReply.userVote, 0);
      expect(toggledReply.upvotes, 0);

      // Downvote reply (-1)
      await viewModel.voteReply(thread.id, reply.id, -1);
      final downvotedReply = viewModel.threads.firstWhere((t) => t.id == thread.id).replies.first;
      expect(downvotedReply.userVote, -1);
      expect(downvotedReply.upvotes, -1);
    });
  });

  group('Forum Content Reporting & Admin Moderation Tests', () {
    late SupabaseService service;
    late ForumRepository repository;
    late ForumViewModel viewModel;

    setUp(() {
      service = SupabaseService();
      repository = ForumRepository(service: service);
      viewModel = ForumViewModel(repository: repository);
    });

    test('Reporting a thread sets isReported and dynamically populates reportQueue', () async {
      await viewModel.createThread(
        community: 'c/Heritage',
        title: 'Unauthorized craft workshop in Melaka',
        authorName: 'BadActor',
        authorEmail: 'bad@actor.my',
        isArtisan: false,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Unauthorized craft workshop in Melaka');
      expect(thread.isReported, false);

      final result = await viewModel.reportThread(
        thread.id,
        'Misinformation',
        'Selling unauthorized factory items.',
      );

      expect(result['success'], true);
      final reportedThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(reportedThread.isReported, true);
      expect(reportedThread.reportReason, 'Misinformation');

      // Verify report appears in reportQueue
      expect(viewModel.reportQueue.any((r) => r['postId'] == thread.id), true);
    });

    test('Reporting a reply sets isReported and dynamically populates reportQueue', () async {
      await viewModel.createThread(
        community: 'c/Batik',
        title: 'Traditional dyes inquiry',
        authorName: 'Tourist1',
        authorEmail: 'tourist1@test.my',
        isArtisan: false,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Traditional dyes inquiry');
      await viewModel.postReply(
        threadId: thread.id,
        text: 'Inappropriate advertisement message http://spam.com',
        authorName: 'Spammer',
        authorEmail: 'spam@test.my',
        isArtisan: false,
      );

      final threadWithReply = viewModel.threads.firstWhere((t) => t.id == thread.id);
      final reply = threadWithReply.replies.first;

      final result = await viewModel.reportReply(
        thread.id,
        reply.id,
        'Spam/Off-topic',
        'Automated bot spam link.',
      );

      expect(result['success'], true);
      final updatedThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      final reportedReply = updatedThread.replies.firstWhere((r) => r.id == reply.id);
      expect(reportedReply.isReported, true);
      expect(reportedReply.reportReason, 'Spam/Off-topic');

      expect(viewModel.reportQueue.any((r) => r['replyId'] == reply.id), true);
    });

    test('Dismissing a report clears isReported and removes it from reportQueue', () async {
      await viewModel.createThread(
        community: 'c/Wau',
        title: 'Valid Wau building discussion',
        authorName: 'ArtisanWau',
        authorEmail: 'wau@artisan.my',
        isArtisan: true,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Valid Wau building discussion');
      await viewModel.reportThread(thread.id, 'Inappropriate Content', 'False alarm report');

      expect(viewModel.reportQueue.any((r) => r['postId'] == thread.id), true);

      // Admin dismisses report
      await viewModel.dismissReport(thread.id);
      final dismissedThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(dismissedThread.isReported, false);
      expect(viewModel.reportQueue.any((r) => r['postId'] == thread.id), false);
    });

    test('Admin deleting reported thread removes it completely from threads and queue', () async {
      await viewModel.createThread(
        community: 'c/Songket',
        title: 'Offensive thread content',
        authorName: 'TrollUser',
        authorEmail: 'troll@test.my',
        isArtisan: false,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Offensive thread content');
      await viewModel.reportThread(thread.id, 'Harassment', 'Severe harassment content');

      await viewModel.adminDeleteForumPost(thread.id, 'Violated community guidelines on harassment');

      expect(viewModel.threads.any((t) => t.id == thread.id), false);
      expect(viewModel.reportQueue.any((r) => r['postId'] == thread.id), false);
    });
  });
}
