import 'dart:math';
import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/forum_repository.dart';
import 'package:warisan_kita/data/services/content_safety_service.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';

class ForumViewModel extends ChangeNotifier {
  final ForumRepository _repository;

  ForumViewModel({ForumRepository? repository})
      : _repository = repository ?? ForumRepository() {
    fetchThreads();
  }

  List<ForumThread> _threads = [];
  List<ForumThread> get threads => _threads;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _generateUuid() {
    final Random rng = Random();
    final String hex = List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-8${hex.substring(17, 20)}-${hex.substring(20, 32)}';
  }

  Future<void> fetchThreads() async {
    _isLoading = true;
    notifyListeners();

    _threads = await _repository.getThreads();

    _isLoading = false;
    notifyListeners();
  }

  Future<ContentSafetyResult> createThread({
    required String community,
    required String title,
    required String authorName,
    required String authorEmail,
    required bool isArtisan,
    String? initialMessage,
  }) async {
    final safety = ContentSafetyService.evaluate(title: title, body: initialMessage ?? '');
    if (safety.isBlocked) {
      return safety;
    }

    final threadId = _generateUuid();
    final List<ThreadReply> initialReplies = [];
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      initialReplies.add(
        ThreadReply(
          id: _generateUuid(),
          sender: authorName,
          authorEmail: authorEmail,
          isMe: true,
          isArtisan: isArtisan,
          upvotes: 1,
          userVote: 1,
          isVerifiedAnswer: false,
          timestamp: 'Just now',
          text: initialMessage.trim(),
        ),
      );
    }

    final newThread = ForumThread(
      id: threadId,
      community: community,
      title: title,
      authorName: authorName,
      authorEmail: authorEmail,
      isArtisan: isArtisan,
      upvotes: 1,
      userVote: 1,
      replyCount: initialReplies.length,
      timestamp: 'Just now',
      isSolved: false,
      isReported: safety.isAutoFlagged,
      reportReason: safety.isAutoFlagged ? safety.flagReason : null,
      reportNotes: safety.isAutoFlagged ? 'Automated system flag triggered upon thread creation.' : null,
      replies: initialReplies,
    );

    await _repository.createThread(newThread);
    await fetchThreads();
    return safety;
  }

  Future<ContentSafetyResult> postReply({
    required String threadId,
    required String text,
    required String authorName,
    required String authorEmail,
    required bool isArtisan,
  }) async {
    final safety = ContentSafetyService.evaluate(title: text);
    if (safety.isBlocked) {
      return safety;
    }

    final reply = ThreadReply(
      id: _generateUuid(),
      sender: isArtisan ? '$authorName (Master Artisan)' : authorName,
      authorEmail: authorEmail,
      isMe: true,
      isArtisan: isArtisan,
      upvotes: 1,
      userVote: 1,
      isVerifiedAnswer: isArtisan,
      timestamp: 'Just now',
      text: text,
    );

    await _repository.postReply(threadId, reply);
    if (safety.isAutoFlagged) {
      await _repository.reportThread(
        threadId,
        safety.flagReason ?? 'Automated reply flag',
        'Flagged reply posted by $authorName: "$text"',
      );
    }
    await fetchThreads();
    return safety;
  }

  Future<void> voteThread(String threadId, int voteDirection) async {
    await _repository.voteThread(threadId, voteDirection);
    _threads = await _repository.getThreads();
    notifyListeners();
  }

  Future<void> voteReply(String threadId, String replyId, int voteDirection) async {
    await _repository.voteReply(threadId, replyId, voteDirection);
    _threads = await _repository.getThreads();
    notifyListeners();
  }

  Future<ContentSafetyResult> editThread(String threadId, String newTitle) async {
    final safety = ContentSafetyService.evaluate(title: newTitle);
    if (safety.isBlocked) {
      return safety;
    }
    await _repository.editThread(threadId, newTitle);
    if (safety.isAutoFlagged) {
      await _repository.reportThread(
        threadId,
        safety.flagReason ?? 'Automated title edit flag',
        'Thread title edited with sensitive keywords.',
      );
    }
    await fetchThreads();
    return safety;
  }

  Future<void> deleteThread(String threadId) async {
    await _repository.deleteThread(threadId);
    await fetchThreads();
  }

  Future<ContentSafetyResult> editReply(String threadId, String replyId, String newText) async {
    final safety = ContentSafetyService.evaluate(title: newText);
    if (safety.isBlocked) {
      return safety;
    }
    await _repository.editReply(threadId, replyId, newText);
    if (safety.isAutoFlagged) {
      await _repository.reportThread(
        threadId,
        safety.flagReason ?? 'Automated reply edit flag',
        'Reply edited with sensitive keywords.',
      );
    }
    await fetchThreads();
    return safety;
  }

  Future<void> deleteReply(String threadId, String replyId) async {
    await _repository.deleteReply(threadId, replyId);
    await fetchThreads();
  }

  Future<void> reportThread(String threadId, String reason, String notes) async {
    await _repository.reportThread(threadId, reason, notes);
    await fetchThreads();
  }

  Future<void> dismissReport(String threadId) async {
    await _repository.dismissReport(threadId);
    await fetchThreads();
  }
}
