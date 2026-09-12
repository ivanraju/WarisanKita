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
  final String? ssmFileName;
  final String? ssmFileUrl;
  final String? certFileName;
  final String? certFileUrl;
  final List<String> photos;
  final String? relocationCertFileName;
  final String? relocationCertFileUrl;
  final List<Map<String, dynamic>> documents;
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
    this.ssmFileName,
    this.ssmFileUrl,
    this.certFileName,
    this.certFileUrl,
    this.photos = const [],
    this.relocationCertFileName,
    this.relocationCertFileUrl,
    this.documents = const [],
    required this.approvedAt,
    this.approvedBy = 'Admin Moderator',
    this.status = 'APPROVED',
  });

  bool get isRelocation => approvalType == 'Premise Relocation';

  bool get hasDocuments =>
      (ssmFileUrl != null && ssmFileUrl!.isNotEmpty) ||
      (certFileUrl != null && certFileUrl!.isNotEmpty) ||
      (relocationCertFileUrl != null && relocationCertFileUrl!.isNotEmpty) ||
      photos.isNotEmpty ||
      documents.isNotEmpty;

  List<Map<String, dynamic>> get allDocuments {
    final List<Map<String, dynamic>> list = [];
    if (documents.isNotEmpty) {
      for (final doc in documents) {
        list.add(Map<String, dynamic>.from(doc));
      }
    }
    if (ssmFileUrl != null && ssmFileUrl!.isNotEmpty) {
      final isVillage = details.toLowerCase().contains('village') ||
          (ssmNumber != null && ssmNumber!.toLowerCase().contains('exempt'));
      final already = list.any((d) => d['url'] == ssmFileUrl);
      if (!already) {
        list.add({
          'name': ssmFileName ??
              (isVillage ? 'Crafting Proof Photo' : 'SSM Registration Certificate'),
          'url': ssmFileUrl!,
          'type': isVillage ? 'crafting_proof' : 'ssm',
        });
      }
    }
    if (certFileUrl != null && certFileUrl!.isNotEmpty) {
      final already = list.any((d) => d['url'] == certFileUrl);
      if (!already) {
        list.add({
          'name': certFileName ?? 'Kraftangan Master Certificate',
          'url': certFileUrl!,
          'type': 'certificate',
        });
      }
    }
    if (relocationCertFileUrl != null && relocationCertFileUrl!.isNotEmpty) {
      final already = list.any((d) => d['url'] == relocationCertFileUrl);
      if (!already) {
        list.add({
          'name': relocationCertFileName ?? 'Updated Premise Certificate',
          'url': relocationCertFileUrl!,
          'type': 'relocation_certificate',
        });
      }
    }
    for (int i = 0; i < photos.length; i++) {
      final photoUrl = photos[i];
      if (photoUrl.isNotEmpty && !list.any((d) => d['url'] == photoUrl)) {
        list.add({
          'name': 'Studio Photo ${i + 1}',
          'url': photoUrl,
          'type': 'photo',
        });
      }
    }
    return list;
  }

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
      'ssmFileName': ssmFileName,
      'ssmFileUrl': ssmFileUrl,
      'certFileName': certFileName,
      'certFileUrl': certFileUrl,
      'photos': photos,
      'relocationCertFileName': relocationCertFileName,
      'relocationCertFileUrl': relocationCertFileUrl,
      'documents': documents,
      'approvedAt': approvedAt.toIso8601String(),
      'approvedBy': approvedBy,
      'status': status,
    };
  }

  factory ApprovalHistoryRecord.fromMap(Map<String, dynamic> map) {
    List<String> parsedPhotos = [];
    if (map['photos'] is List) {
      parsedPhotos = (map['photos'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<Map<String, dynamic>> parsedDocs = [];
    if (map['documents'] is List) {
      for (final doc in (map['documents'] as List)) {
        if (doc is Map<String, dynamic>) {
          parsedDocs.add(doc);
        } else if (doc is Map) {
          parsedDocs.add(Map<String, dynamic>.from(doc));
        }
      }
    }

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
      ssmFileName: map['ssmFileName']?.toString(),
      ssmFileUrl: map['ssmFileUrl']?.toString(),
      certFileName: map['certFileName']?.toString(),
      certFileUrl: map['certFileUrl']?.toString(),
      photos: parsedPhotos,
      relocationCertFileName: map['relocationCertFileName']?.toString(),
      relocationCertFileUrl: map['relocationCertFileUrl']?.toString(),
      documents: parsedDocs,
      approvedAt:
          DateTime.tryParse(map['approvedAt']?.toString() ?? '') ??
          DateTime.now(),
      approvedBy: map['approvedBy']?.toString() ?? 'Admin Moderator',
      status: map['status']?.toString() ?? 'APPROVED',
    );
  }
}
