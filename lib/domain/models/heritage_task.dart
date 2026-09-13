class HeritageTask {
  final String id;
  final String questId;
  final String title;
  final bool isRequired;
  final int xpReward;
  final int? sortOrder;
  final DateTime? createdAt;
  final String status;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final bool isSystemTask;
  final bool isArchived;
  final String? qrCodeSecret;

  const HeritageTask({
    required this.id,
    required this.questId,
    required this.title,
    required this.isRequired,
    required this.xpReward,
    required this.sortOrder,
    required this.createdAt,
    required this.status,
    required this.rejectionReason,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.isSystemTask,
    required this.isArchived,
    this.qrCodeSecret,
  });

  factory HeritageTask.fromMap(Map<String, dynamic> map) {
    return HeritageTask(
      id: _requiredString(map, 'id'),
      questId: _requiredString(map, 'quest_id'),
      title: _requiredString(map, 'title'),
      isRequired: _requiredBool(map, 'is_required'),
      xpReward: _requiredInt(map, 'xp_reward'),
      sortOrder: _optionalInt(map['sort_order']),
      createdAt: _optionalDateTime(map['created_at']),
      status: _requiredString(map, 'status'),
      rejectionReason: _optionalString(map['rejection_reason']),
      reviewedAt: _optionalDateTime(map['reviewed_at']),
      reviewedBy: _optionalString(map['reviewed_by']),
      isSystemTask: _requiredBool(map, 'is_system_task'),
      isArchived: _requiredBool(map, 'is_archived'),
      qrCodeSecret: _optionalString(map['qr_code_secret']),
    );
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Heritage task field "$key" is missing or invalid.',
      );
    }

    return value;
  }

  static bool _requiredBool(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is bool) {
      return value;
    }

    throw FormatException('Heritage task field "$key" is missing or invalid.');
  }

  static int _requiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is num) {
      return value.toInt();
    }

    throw FormatException('Heritage task field "$key" is missing or invalid.');
  }

  static int? _optionalInt(dynamic value) {
    return value is num ? value.toInt() : null;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _optionalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
