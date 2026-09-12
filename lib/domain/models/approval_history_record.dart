class ApprovalHistoryRecord {
  final String id;
  final String title;
  final String targetName;
  final String targetEmail;
  final String approvalType; // 'Artisan Profile' or 'Premise Relocation'
  final String craftCategory;
  final String state;
  final String details;
  final String? previousPremise;
  final String? newPremise;
  final String? ssmNumber;
  final DateTime approvedAt;
  final String approvedBy;
  final String status; // 'APPROVED'

  const ApprovalHistoryRecord({
    required this.id,
    required this.title,
    required this.targetName,
    required this.targetEmail,
    required this.approvalType,
    required this.craftCategory,
    required this.state,
    required this.details,
    this.previousPremise,
    this.newPremise,
    this.ssmNumber,
    required this.approvedAt,
    this.approvedBy = 'Admin Moderator',
    this.status = 'APPROVED',
  });

  bool get isRelocation => approvalType == 'Premise Relocation';

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[approvedAt.month - 1];
    return '${approvedAt.day.toString().padLeft(2, '0')} $m ${approvedAt.year}';
  }

  String get formattedTime {
    final hour = approvedAt.hour.toString().padLeft(2, '0');
    final minute = approvedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDateTime => '$formattedDate at $formattedTime';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetName': targetName,
      'targetEmail': targetEmail,
      'approvalType': approvalType,
      'craftCategory': craftCategory,
      'state': state,
      'details': details,
      'previousPremise': previousPremise,
      'newPremise': newPremise,
      'ssmNumber': ssmNumber,
      'approvedAt': approvedAt.toIso8601String(),
      'approvedBy': approvedBy,
      'status': status,
    };
  }

  factory ApprovalHistoryRecord.fromMap(Map<String, dynamic> map) {
    return ApprovalHistoryRecord(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Approved Record',
      targetName: map['targetName']?.toString() ?? 'Artisan Studio',
      targetEmail: map['targetEmail']?.toString() ?? '',
      approvalType: map['approvalType']?.toString() ?? 'Artisan Profile',
      craftCategory: map['craftCategory']?.toString() ?? 'Heritage Craft',
      state: map['state']?.toString() ?? 'Malaysia',
      details: map['details']?.toString() ?? '',
      previousPremise: map['previousPremise']?.toString(),
      newPremise: map['newPremise']?.toString(),
      ssmNumber: map['ssmNumber']?.toString(),
      approvedAt:
          DateTime.tryParse(map['approvedAt']?.toString() ?? '') ??
          DateTime.now(),
      approvedBy: map['approvedBy']?.toString() ?? 'Admin Moderator',
      status: map['status']?.toString() ?? 'APPROVED',
    );
  }
}
