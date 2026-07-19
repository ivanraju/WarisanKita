class ForumThread {
  final String id;
  final String title;
  final String authorName;
  final String authorAvatar;
  final DateTime createdAt;
  final int replyCount;
  final List<String> tags;
  final List<ThreadReply> replies;

  ForumThread({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorAvatar,
    required this.createdAt,
    this.replyCount = 0,
    this.tags = const [],
    this.replies = const [],
  });
}

class ThreadReply {
  final String id;
  final String authorName;
  final String content;
  final String timestamp;
  final bool isVerifiedArtisan;

  ThreadReply({
    required this.id,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.isVerifiedArtisan = false,
  });
}
