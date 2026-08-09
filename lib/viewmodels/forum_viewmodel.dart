import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/forum_repository.dart';
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

  Future<void> fetchThreads() async {
    _isLoading = true;
    notifyListeners();

    _threads = await _repository.getThreads();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> postReply(String threadId, String content) async {
    // Functional Gap: Real-time UI update for the Forum
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      final newReply = ThreadReply(
        id: DateTime.now().toString(),
        authorName: 'You (Guest)',
        content: content,
        timestamp: 'Just now',
      );
      
      _threads[index].replies.add(newReply);
      notifyListeners();
    }
  }
}
