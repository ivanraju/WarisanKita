class QuestChangeRequest {
  final String id;
  final String questId;
  final String proposedTitle;
  final String proposedDescription;
  final String proposedCategory;
  final String status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const QuestChangeRequest({
    required this.id,
    required this.questId,
    required this.proposedTitle,
    required this.proposedDescription,
    required this.proposedCategory,
    required this.status,
    required this.rejectionReason,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewedBy,
  });

  bool get isPending => status.toUpperCase() == 'PENDING_APPROVAL';

  factory QuestChangeRequest.fromMap(Map<String, dynamic> map) {
    return QuestChangeRequest(
      id: _requiredString(map, 'id'),
      questId: _requiredString(map, 'quest_id'),
      proposedTitle: _requiredString(map, 'proposed_title'),
      proposedDescription: _requiredString(map, 'proposed_description'),
      proposedCategory: _requiredString(map, 'proposed_category'),
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
      throw FormatException('Quest change request field "$key" is invalid.');
    }
    return value.trim();
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _optionalDateTime(dynamic value) {
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
