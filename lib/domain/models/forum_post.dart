class ForumThread {
  final String id;
  final String? userId;
  final String community;
  final String title;
  final String authorName;
  final String authorEmail;
  final bool isArtisan;
  final int upvotes;
  final int userVote; // -1, 0, 1
  final int replyCount;
  final String timestamp;
  final bool isSolved;
  final bool isEdited;
  final bool isReported;
  final String? reportReason;
  final String? reportNotes;
  final List<ThreadReply> replies;

  ForumThread({
    required this.id,
    this.userId,
    required this.community,
    required this.title,
    required this.authorName,
    required this.authorEmail,
    this.isArtisan = false,
    this.upvotes = 0,
    this.userVote = 0,
    this.replyCount = 0,
    required this.timestamp,
    this.isSolved = false,
    this.isEdited = false,
    this.isReported = false,
    this.reportReason,
    this.reportNotes,
    this.replies = const [],
  });

  String get authorAvatar => 'https://api.dicebear.com/7.x/bottts/png?seed=${Uri.encodeComponent(authorName.isNotEmpty ? authorName : "User")}';
  List<String> get tags => [community.replaceAll('c/', '')];
  DateTime get createdAt {
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return DateTime.now();
    }
  }

  ForumThread copyWith({
    String? id,
    String? userId,
    String? community,
    String? title,
    String? authorName,
    String? authorEmail,
    bool? isArtisan,
    int? upvotes,
    int? userVote,
    int? replyCount,
    String? timestamp,
    bool? isSolved,
    bool? isEdited,
    bool? isReported,
    String? reportReason,
    String? reportNotes,
    List<ThreadReply>? replies,
  }) {
    return ForumThread(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      community: community ?? this.community,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      isArtisan: isArtisan ?? this.isArtisan,
      upvotes: upvotes ?? this.upvotes,
      userVote: userVote ?? this.userVote,
      replyCount: replyCount ?? this.replyCount,
      timestamp: timestamp ?? this.timestamp,
      isSolved: isSolved ?? this.isSolved,
      isEdited: isEdited ?? this.isEdited,
      isReported: isReported ?? this.isReported,
      reportReason: reportReason ?? this.reportReason,
      reportNotes: reportNotes ?? this.reportNotes,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'community': community,
      'title': title,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'isArtisan': isArtisan,
      'upvotes': upvotes,
      'userVote': userVote,
      'repliesCount': replies.length,
      'timestamp': timestamp,
      'isSolved': isSolved,
      'isEdited': isEdited,
      'isReported': isReported,
      'reportReason': reportReason,
      'reportNotes': reportNotes,
      'messages': replies.map((r) => r.toMap()).toList(),
    };
  }

  Map<String, dynamic> toDbMap() {
    final String bodyContent = replies.isNotEmpty ? replies.first.text : title;
    final String tagValue = community.replaceAll('c/', '');
    final Map<String, dynamic> map = {
      'id': id,
      'community': community,
      'tag': tagValue,
      'title': title,
      'content': bodyContent,
      'author_name': authorName,
      'author_email': authorEmail,
      'is_artisan': isArtisan,
      'upvotes': upvotes,
      'user_vote': userVote,
      'replies_count': replies.length,
      'timestamp': timestamp,
      'is_solved': isSolved,
      'is_edited': isEdited,
      'is_reported': isReported,
      'report_reason': reportReason,
      'report_notes': reportNotes,
    };
    if (userId != null && userId!.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
  }

  factory ForumThread.fromMap(Map<String, dynamic> map) {
    final List<dynamic> msgList = map['messages'] ?? map['replies'] ?? [];
    final String comm = map['community'] ?? (map['tag'] != null ? 'c/${map['tag']}' : 'c/TravelQnA');
    final String? contentText = map['content'] as String?;
    final List<ThreadReply> parsedReplies = msgList.map((r) => ThreadReply.fromMap(Map<String, dynamic>.from(r))).toList();
    if (parsedReplies.isEmpty && contentText != null && contentText.isNotEmpty && contentText != map['title']) {
      parsedReplies.add(
        ThreadReply(
          id: '${map['id']}_content',
          sender: map['author_name'] ?? map['authorName'] ?? 'Anonymous',
          authorEmail: map['author_email'] ?? map['authorEmail'] ?? '',
          isMe: false,
          isArtisan: map['is_artisan'] ?? map['isArtisan'] ?? false,
          timestamp: map['timestamp'] ?? 'Just now',
          text: contentText,
        ),
      );
    }

    return ForumThread(
      id: map['id'] ?? '',
      userId: map['userId'] ?? map['user_id'],
      community: comm,
      title: map['title'] ?? '',
      authorName: map['authorName'] ?? map['author_name'] ?? 'Anonymous',
      authorEmail: map['authorEmail'] ?? map['author_email'] ?? '',
      isArtisan: map['isArtisan'] ?? map['is_artisan'] ?? false,
      upvotes: map['upvotes'] ?? 0,
      userVote: map['userVote'] ?? map['user_vote'] ?? 0,
      replyCount: map['repliesCount'] ?? map['replies_count'] ?? parsedReplies.length,
      timestamp: map['timestamp'] ?? 'Just now',
      isSolved: map['isSolved'] ?? map['is_solved'] ?? false,
      isEdited: map['isEdited'] ?? map['is_edited'] ?? false,
      isReported: map['isReported'] ?? map['is_reported'] ?? false,
      reportReason: map['reportReason'] ?? map['report_reason'],
      reportNotes: map['reportNotes'] ?? map['report_notes'],
      replies: parsedReplies,
    );
  }
}

class ThreadReply {
  final String id;
  final String sender;
  final String authorEmail;
  final bool isMe;
  final bool isArtisan;
  final int upvotes;
  final int userVote;
  final bool isVerifiedAnswer;
  final bool isEdited;
  final String timestamp;
  final String text;

  ThreadReply({
    required this.id,
    required this.sender,
    required this.authorEmail,
    this.isMe = false,
    this.isArtisan = false,
    this.upvotes = 0,
    this.userVote = 0,
    this.isVerifiedAnswer = false,
    this.isEdited = false,
    required this.timestamp,
    required this.text,
  });

  String get authorName => sender;
  String get content => text;
  String get authorAvatar => 'https://api.dicebear.com/7.x/bottts/png?seed=${Uri.encodeComponent(sender.isNotEmpty ? sender : "User")}';
  DateTime get createdAt {
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return DateTime.now();
    }
  }

  ThreadReply copyWith({
    String? id,
    String? sender,
    String? authorEmail,
    bool? isMe,
    bool? isArtisan,
    int? upvotes,
    int? userVote,
    bool? isVerifiedAnswer,
    bool? isEdited,
    String? timestamp,
    String? text,
  }) {
    return ThreadReply(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      authorEmail: authorEmail ?? this.authorEmail,
      isMe: isMe ?? this.isMe,
      isArtisan: isArtisan ?? this.isArtisan,
      upvotes: upvotes ?? this.upvotes,
      userVote: userVote ?? this.userVote,
      isVerifiedAnswer: isVerifiedAnswer ?? this.isVerifiedAnswer,
      isEdited: isEdited ?? this.isEdited,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'authorEmail': authorEmail,
      'isMe': isMe,
      'isArtisan': isArtisan,
      'upvotes': upvotes,
      'userVote': userVote,
      'isVerifiedAnswer': isVerifiedAnswer,
      'isEdited': isEdited,
      'time': timestamp,
      'text': text,
    };
  }

  Map<String, dynamic> toDbMap(String threadId) {
    return {
      'id': id,
      'thread_id': threadId,
      'sender': sender,
      'author_email': authorEmail,
      'is_me': isMe,
      'is_artisan': isArtisan,
      'upvotes': upvotes,
      'user_vote': userVote,
      'is_verified_answer': isVerifiedAnswer,
      'is_edited': isEdited,
      'timestamp': timestamp,
      'text': text,
    };
  }

  factory ThreadReply.fromMap(Map<String, dynamic> map) {
    return ThreadReply(
      id: map['id'] ?? '',
      sender: map['sender'] ?? map['authorName'] ?? map['author_name'] ?? 'Anonymous',
      authorEmail: map['authorEmail'] ?? map['author_email'] ?? '',
      isMe: map['isMe'] ?? map['is_me'] ?? false,
      isArtisan: map['isArtisan'] ?? map['is_artisan'] ?? false,
      upvotes: map['upvotes'] ?? 0,
      userVote: map['userVote'] ?? map['user_vote'] ?? 0,
      isVerifiedAnswer: map['isVerifiedAnswer'] ?? map['is_verified_answer'] ?? false,
      isEdited: map['isEdited'] ?? map['is_edited'] ?? false,
      timestamp: map['time'] ?? map['timestamp'] ?? 'Just now',
      text: map['text'] ?? map['content'] ?? '',
    );
  }
}
