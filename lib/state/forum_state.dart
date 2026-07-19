import 'package:flutter/material.dart';
import 'package:warisan_kita/models/forum_models.dart';
import 'package:warisan_kita/services/supabase_service.dart';

class ForumState extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<ForumThread> _threads = [];
  List<ForumThread> get threads => _threads;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ForumState() {
    fetchThreads();
  }

  Future<void> fetchThreads() async {
    _isLoading = true;
    notifyListeners();

    // Functional Gap: Mocking rich data with replies for the Neo-Traditional UI
    await Future.delayed(const Duration(seconds: 1));

    _threads = [
      ForumThread(
        id: '1',
        title: 'How to differentiate authentic Terengganu Batik from factory prints?',
        authorName: 'Aminah Bakar',
        authorAvatar: 'https://i.pravatar.cc/150?u=1',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        replyCount: 12,
        tags: ['Batik', 'Authenticity'],
        replies: [
          ThreadReply(
            id: 'r1',
            authorName: 'Master Zaid',
            content: 'A true hand-drawn Batik (Batik Tulis) will always have slight variations in the lines. If it is too perfect, it is likely a copper-block stamp or a machine print.',
            timestamp: '1h ago',
            isVerifiedArtisan: true,
          ),
          ThreadReply(
            id: 'r2',
            authorName: 'HeritageHunter',
            content: 'Also, look at the back of the cloth. For authentic batik, the dye should be just as vibrant on the reverse side.',
            timestamp: '45m ago',
          ),
        ],
      ),
      ForumThread(
        id: '2',
        title: 'The symbolism of Keris patterns in Melaka history',
        authorName: 'Ahmad Fauzi',
        authorAvatar: 'https://i.pravatar.cc/150?u=2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        replyCount: 45,
        tags: ['Keris', 'History'],
        replies: [],
      ),
    ];

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
