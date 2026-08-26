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

  group('Forum Upvote & Downvote Toggle Tests', () {
    late SupabaseService service;
    late ForumRepository repository;
    late ForumViewModel viewModel;

    setUp(() {
      service = SupabaseService();
      repository = ForumRepository(service: service);
      viewModel = ForumViewModel(repository: repository);
    });

    test('Creating a thread initializes upvotes to 1 and userVote to 1 for author', () async {
      await viewModel.createThread(
        community: 'c/Batik',
        title: 'Best wax for canting technique?',
        authorName: 'Ahmad',
        authorEmail: 'ahmad@test.my',
        isArtisan: false,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Best wax for canting technique?');
      expect(thread.upvotes, 1);
      expect(thread.userVote, 1);
    });

    test('Upvoting a thread that is already upvoted toggles off (cancels) vote', () async {
      await viewModel.createThread(
        community: 'c/Wau',
        title: 'Bamboo curing for Wau Bulan',
        authorName: 'Karim',
        authorEmail: 'karim@test.my',
        isArtisan: true,
      );

      final thread = viewModel.threads.firstWhere((t) => t.title == 'Bamboo curing for Wau Bulan');
      final initialScore = thread.upvotes;

      // User already has userVote = 1. Clicking Upvote (1) again should toggle off (0)
      await viewModel.voteThread(thread.id, 1);
      final toggledThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(toggledThread.userVote, 0);
      expect(toggledThread.upvotes, initialScore - 1);

      // Clicking Upvote (1) again sets userVote = 1 and score + 1
      await viewModel.voteThread(thread.id, 1);
      final reUpvotedThread = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(reUpvotedThread.userVote, 1);
      expect(reUpvotedThread.upvotes, initialScore);
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
      final initialScore = thread.upvotes; // starts with 1 upvote

      // Switch to Downvote (-1)
      await viewModel.voteThread(thread.id, -1);
      final downvoted = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(downvoted.userVote, -1);
      expect(downvoted.upvotes, initialScore - 2); // 1 -> -1 = delta -2

      // Switch back to Upvote (+1)
      await viewModel.voteThread(thread.id, 1);
      final upvotedAgain = viewModel.threads.firstWhere((t) => t.id == thread.id);
      expect(upvotedAgain.userVote, 1);
      expect(upvotedAgain.upvotes, initialScore); // -1 -> 1 = delta +2
    });

    test('Reply voting correctly handles upvoting, cancelling, and downvoting', () async {
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
      final initialReplyScore = reply.upvotes;

      // Author of reply starts with userVote = 1. Click upvote (1) to toggle off (0)
      await viewModel.voteReply(thread.id, reply.id, 1);
      final toggledReply = viewModel.threads.firstWhere((t) => t.id == thread.id).replies.first;
      expect(toggledReply.userVote, 0);
      expect(toggledReply.upvotes, initialReplyScore - 1);

      // Downvote reply (-1)
      await viewModel.voteReply(thread.id, reply.id, -1);
      final downvotedReply = viewModel.threads.firstWhere((t) => t.id == thread.id).replies.first;
      expect(downvotedReply.userVote, -1);
      expect(downvotedReply.upvotes, initialReplyScore - 2);
    });
  });
}
