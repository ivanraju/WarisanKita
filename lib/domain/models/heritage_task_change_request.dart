class HeritageTaskChangeRequest {
  final String id;
  final String taskId;
  final String requestType;
  final String? proposedTitle;
  final bool? proposedIsRequired;
  final int? proposedXpReward;
  final String status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const HeritageTaskChangeRequest({
    required this.id,
    required this.taskId,
    required this.requestType,
    required this.proposedTitle,
    required this.proposedIsRequired,
    required this.proposedXpReward,
    required this.status,
    required this.rejectionReason,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewedBy,
  });

  factory HeritageTaskChangeRequest.fromMap(Map<String, dynamic> map) {
    return HeritageTaskChangeRequest(
      id: _requiredString(map, 'id'),
      taskId: _requiredString(map, 'task_id'),
      requestType: _requiredString(map, 'request_type'),
      proposedTitle: _optionalString(map['proposed_title']),
      proposedIsRequired: map['proposed_is_required'] as bool?,
      proposedXpReward: _optionalInt(map['proposed_xp_reward']),
      status: _requiredString(map, 'status'),
      rejectionReason: _optionalString(map['rejection_reason']),
      submittedAt: _optionalDateTime(map['submitted_at']),
      reviewedAt: _optionalDateTime(map['reviewed_at']),
      reviewedBy: _optionalString(map['reviewed_by']),
    );
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Task change request field "$key" is invalid.');
    }
    return value;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _optionalInt(dynamic value) =>
      value is num ? value.toInt() : null;

  static DateTime? _optionalDateTime(dynamic value) {
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
