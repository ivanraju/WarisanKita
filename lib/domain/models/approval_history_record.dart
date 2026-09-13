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

  ApprovalHistoryRecord copyWith({
    String? id,
    String? title,
    String? targetName,
    String? targetEmail,
    String? approvalType,
    String? craftCategory,
    String? state,
    String? details,
    String? previousPremise,
    String? newPremise,
    String? ssmNumber,
    String? ssmFileName,
    String? ssmFileUrl,
    String? certFileName,
    String? certFileUrl,
    List<String>? photos,
    String? relocationCertFileName,
    String? relocationCertFileUrl,
    List<Map<String, dynamic>>? documents,
    DateTime? approvedAt,
    String? approvedBy,
    String? status,
  }) {
    return ApprovalHistoryRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      targetName: targetName ?? this.targetName,
      targetEmail: targetEmail ?? this.targetEmail,
      approvalType: approvalType ?? this.approvalType,
      craftCategory: craftCategory ?? this.craftCategory,
      state: state ?? this.state,
      details: details ?? this.details,
      previousPremise: previousPremise ?? this.previousPremise,
      newPremise: newPremise ?? this.newPremise,
      ssmNumber: ssmNumber ?? this.ssmNumber,
      ssmFileName: ssmFileName ?? this.ssmFileName,
      ssmFileUrl: ssmFileUrl ?? this.ssmFileUrl,
      certFileName: certFileName ?? this.certFileName,
      certFileUrl: certFileUrl ?? this.certFileUrl,
      photos: photos ?? this.photos,
      relocationCertFileName: relocationCertFileName ?? this.relocationCertFileName,
      relocationCertFileUrl: relocationCertFileUrl ?? this.relocationCertFileUrl,
      documents: documents ?? this.documents,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      status: status ?? this.status,
    );
  }

  bool get isRelocation => approvalType == 'Premise Relocation';

  bool get hasDocuments =>
      (ssmFileUrl != null && ssmFileUrl!.trim().isNotEmpty) ||
      (certFileUrl != null && certFileUrl!.trim().isNotEmpty) ||
      (relocationCertFileUrl != null && relocationCertFileUrl!.trim().isNotEmpty) ||
      photos.isNotEmpty ||
      documents.isNotEmpty;

  List<Map<String, dynamic>> get allDocuments {
    final List<Map<String, dynamic>> list = [];
    if (documents.isNotEmpty) {
      for (final doc in documents) {
        final rawName = doc['name'] ?? doc['file_name'] ?? doc['fileName'] ?? doc['title'];
        final rawUrl = doc['url'] ?? doc['file_url'] ?? doc['fileUrl'] ?? doc['link'];
        final rawType = doc['type'] ?? doc['doc_type'] ?? doc['docType'] ?? '';

        final url = (rawUrl?.toString() ?? '').trim();
        String name = (rawName?.toString() ?? '').trim();
        final type = rawType.toString().trim();

        if (name.isEmpty || name.toLowerCase() == 'document') {
          final upperType = type.toUpperCase();
          if (upperType.contains('SSM')) {
            name = 'SSM Registration Certificate';
          } else if (upperType.contains('KRAFTANGAN') || upperType.contains('CERT')) {
            name = 'Kraftangan Master Certificate';
          } else if (upperType.contains('CRAFTING') || upperType.contains('PHOTO')) {
            name = 'Crafting Proof Photo';
          } else if (url.isNotEmpty) {
            final fileName = url.split('?').first.split('/').last;
            name = fileName.isNotEmpty ? fileName : 'Verification Document';
          } else {
            name = 'Verification Document';
          }
        }

        if (url.isEmpty || !list.any((d) => d['url'] == url)) {
          list.add({
            'name': name,
            'file_name': name,
            'url': url,
            'file_url': url,
            'type': type,
            'doc_type': type,
          });
        }
      }
    }
    if (ssmFileUrl != null && ssmFileUrl!.trim().isNotEmpty) {
      final cleanUrl = ssmFileUrl!.trim();
      final isVillage = details.toLowerCase().contains('village') ||
          (ssmNumber != null && ssmNumber!.toLowerCase().contains('exempt'));
      final already = list.any((d) => d['url'] == cleanUrl);
      if (!already) {
        final docName = ssmFileName ??
            (isVillage ? 'Crafting Proof Photo' : 'SSM Registration Certificate');
        list.add({
          'name': docName,
          'file_name': docName,
          'url': cleanUrl,
          'file_url': cleanUrl,
          'type': isVillage ? 'crafting_proof' : 'ssm',
          'doc_type': isVillage ? 'CRAFTING_PHOTO' : 'SSM_BUSINESS_CERT',
        });
      }
    }
    if (certFileUrl != null && certFileUrl!.trim().isNotEmpty) {
      final cleanUrl = certFileUrl!.trim();
      final already = list.any((d) => d['url'] == cleanUrl);
      if (!already) {
        final docName = certFileName ?? 'Kraftangan Master Certificate';
        list.add({
          'name': docName,
          'file_name': docName,
          'url': cleanUrl,
          'file_url': cleanUrl,
          'type': 'certificate',
          'doc_type': 'KRAFTANGAN_MASTER_CERT',
        });
      }
    }
    if (relocationCertFileUrl != null && relocationCertFileUrl!.trim().isNotEmpty) {
      final cleanUrl = relocationCertFileUrl!.trim();
      final already = list.any((d) => d['url'] == cleanUrl);
      if (!already) {
        final docName = relocationCertFileName ?? 'Updated Premise Certificate';
        list.add({
          'name': docName,
          'file_name': docName,
          'url': cleanUrl,
          'file_url': cleanUrl,
          'type': 'relocation_certificate',
          'doc_type': 'RELOCATION_CERT',
        });
      }
    }
    for (int i = 0; i < photos.length; i++) {
      final photoUrl = photos[i].trim();
      if (photoUrl.isNotEmpty && !list.any((d) => d['url'] == photoUrl)) {
        final docName = 'Studio Photo ${i + 1}';
        list.add({
          'name': docName,
          'file_name': docName,
          'url': photoUrl,
          'file_url': photoUrl,
          'type': 'photo',
          'doc_type': 'STUDIO_PHOTO',
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
