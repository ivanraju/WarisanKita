import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/quest_change_request.dart';

enum GamificationModerationRequestType { newTask, taskChange, questChange }

class GamificationModerationRequest {
  final GamificationModerationRequestType type;
  final String id;
  final String artisanName;
  final Quest quest;
  final HeritageTask? task;
  final HeritageTaskChangeRequest? taskChange;
  final QuestChangeRequest? questChange;
  final DateTime? submittedAt;

  const GamificationModerationRequest({
    required this.type,
    required this.id,
    required this.artisanName,
    required this.quest,
    required this.task,
    required this.taskChange,
    required this.questChange,
    required this.submittedAt,
  });

  bool get isNewTask => type == GamificationModerationRequestType.newTask;
  bool get isTaskChange => type == GamificationModerationRequestType.taskChange;
  bool get isQuestChange =>
      type == GamificationModerationRequestType.questChange;
  bool get isDeleteRequest => taskChange?.requestType.toUpperCase() == 'DELETE';

  factory GamificationModerationRequest.fromMap(Map<String, dynamic> map) {
    final type = switch (map['request_kind']) {
      'NEW_TASK' => GamificationModerationRequestType.newTask,
      'TASK_CHANGE' => GamificationModerationRequestType.taskChange,
      'QUEST_CHANGE' => GamificationModerationRequestType.questChange,
      _ => throw FormatException(
        'Unknown gamification request type: ${map['request_kind']}',
      ),
    };
    final taskMap = map['task'];
    final taskChangeMap = map['task_change'];
    final questChangeMap = map['quest_change'];

    return GamificationModerationRequest(
      type: type,
      id: map['request_id'].toString(),
      artisanName: (map['artisan_name'] ?? 'Artisan Studio').toString(),
      quest: Quest.fromMap(Map<String, dynamic>.from(map['quest'] as Map)),
      task: taskMap is Map
          ? HeritageTask.fromMap(Map<String, dynamic>.from(taskMap))
          : null,
      taskChange: taskChangeMap is Map
          ? HeritageTaskChangeRequest.fromMap(
              Map<String, dynamic>.from(taskChangeMap),
            )
          : null,
      questChange: questChangeMap is Map
          ? QuestChangeRequest.fromMap(
              Map<String, dynamic>.from(questChangeMap),
            )
          : null,
      submittedAt: _optionalDateTime(map['submitted_at']),
    );
  }

  static DateTime? _optionalDateTime(dynamic value) {
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
