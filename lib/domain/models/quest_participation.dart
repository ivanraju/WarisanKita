import 'package:warisan_kita/domain/models/heritage_task.dart';

class QuestParticipation {
  final String status;
  final DateTime? startedAt;

  const QuestParticipation({required this.status, required this.startedAt});

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isStopped => status.toUpperCase() == 'STOPPED';

  factory QuestParticipation.fromMap(Map<String, dynamic> map) {
    return QuestParticipation(
      status: map['status']?.toString().trim() ?? '',
      startedAt: parseTimestamp(map['started_at']),
    );
  }

  bool isBonusTask(HeritageTask task) {
    return isCreatedAfterStart(
      taskCreatedAt: task.createdAt,
      participantStartedAt: startedAt,
    );
  }

  bool isEffectiveRequiredTask(HeritageTask task) {
    return task.isRequired && !isBonusTask(task);
  }

  static DateTime? parseTimestamp(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toUtc();
  }

  static bool isCreatedAfterStart({
    required DateTime? taskCreatedAt,
    required DateTime? participantStartedAt,
  }) {
    if (taskCreatedAt == null || participantStartedAt == null) return false;
    return taskCreatedAt.toUtc().isAfter(participantStartedAt.toUtc());
  }
}
