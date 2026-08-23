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

  Map<String, dynamic> toDbMap({String? authorUserId}) {
    final String bodyContent = replies.isNotEmpty ? replies.first.text : title;
    final String tagValue = community.replaceAll('c/', '');
    final String? effectiveUid = userId ?? authorUserId;
    final Map<String, dynamic> map = {
      'id': id,
      'community': community,
      'tag': tagValue,
      'title': title,
      'content': bodyContent,
      'upvotes': upvotes,
      'is_solved': isSolved,
      'is_edited': isEdited,
    };
    if (effectiveUid != null && effectiveUid.isNotEmpty) {
      map['user_id'] = effectiveUid;
    }
    return map;
  }

  factory ForumThread.fromMap(Map<String, dynamic> map) {
    final List<dynamic> msgList = map['messages'] ?? map['replies'] ?? [];
    final String comm = map['community'] ?? (map['tag'] != null ? 'c/${map['tag']}' : 'c/TravelQnA');
    final String? contentText = (map['content'] ?? map['text']) as String?;
    
    // Extract dynamic user profile if joined via users(id, full_name, username, avatar_url, role)
    final userMap = map['users'] is Map<String, dynamic> ? map['users'] as Map<String, dynamic> : null;
    final String resolvedAuthor = userMap?['display_name'] ??
        userMap?['full_name'] ??
        userMap?['username'] ??
        map['authorName'] ??
        map['author_name'] ??
        'Anonymous';
    final String resolvedEmail = userMap?['email'] ?? map['authorEmail'] ?? map['author_email'] ?? '';
    final bool resolvedIsArtisan = (userMap?['role']?.toString().toLowerCase().contains('artisan') == true) ||
        (map['isArtisan'] ?? map['is_artisan'] ?? false);

    final List<ThreadReply> parsedReplies = msgList.map((r) => ThreadReply.fromMap(Map<String, dynamic>.from(r))).toList();
    if (parsedReplies.isEmpty && contentText != null && contentText.isNotEmpty && contentText != map['title']) {
      parsedReplies.add(
        ThreadReply(
          id: '${map['id']}_content',
          sender: resolvedAuthor,
          authorEmail: resolvedEmail,
          isMe: false,
          isArtisan: resolvedIsArtisan,
          timestamp: map['created_at']?.toString() ?? map['timestamp'] ?? 'Just now',
          text: contentText,
        ),
      );
    }

    return ForumThread(
      id: map['id']?.toString() ?? '',
      userId: map['userId'] ?? map['user_id'],
      community: comm,
      title: map['title'] ?? '',
      authorName: resolvedAuthor,
      authorEmail: resolvedEmail,
      isArtisan: resolvedIsArtisan,
      upvotes: map['upvotes'] ?? 0,
      userVote: map['userVote'] ?? map['user_vote'] ?? 0,
      replyCount: map['repliesCount'] ?? map['replies_count'] ?? parsedReplies.length,
      timestamp: map['created_at']?.toString() ?? map['timestamp'] ?? 'Just now',
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

  Map<String, dynamic> toDbMap(String threadId, {String? userId}) {
    return {
      'id': id,
      'post_id': threadId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'content': text,
      'upvotes': upvotes,
      'is_verified_answer': isVerifiedAnswer,
      'is_edited': isEdited,
    };
  }

  factory ThreadReply.fromMap(Map<String, dynamic> map) {
    // Extract dynamic user profile if joined via users(id, full_name, username, avatar_url, role)
    final userMap = map['users'] is Map<String, dynamic> ? map['users'] as Map<String, dynamic> : null;
    final String senderName = userMap?['display_name'] ??
        userMap?['full_name'] ??
        userMap?['username'] ??
        map['sender'] ??
        map['authorName'] ??
        map['author_name'] ??
        'Anonymous';
    final String userEmail = userMap?['email'] ?? map['authorEmail'] ?? map['author_email'] ?? '';
    final bool isArtisanUser = (userMap?['role']?.toString().toLowerCase().contains('artisan') == true) ||
        (map['isArtisan'] ?? map['is_artisan'] ?? false);

    return ThreadReply(
      id: map['id']?.toString() ?? '',
      sender: senderName,
      authorEmail: userEmail,
      isMe: map['isMe'] ?? map['is_me'] ?? false,
      isArtisan: isArtisanUser,
      upvotes: map['upvotes'] ?? 0,
      userVote: map['userVote'] ?? map['user_vote'] ?? 0,
      isVerifiedAnswer: map['isVerifiedAnswer'] ?? map['is_verified_answer'] ?? false,
      isEdited: map['isEdited'] ?? map['is_edited'] ?? false,
      timestamp: map['created_at']?.toString() ?? map['time'] ?? map['timestamp'] ?? 'Just now',
      text: map['content'] ?? map['text'] ?? '',
    );
  }
}
