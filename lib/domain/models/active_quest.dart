import 'package:warisan_kita/domain/models/quest_participation.dart';
import 'package:warisan_kita/domain/models/quest_completion_reconciliation.dart';

class ActiveQuestSummary {
  final String questId;
  final String questTitle;
  final String artisanId;
  final String studioName;
  final QuestParticipation participation;

  const ActiveQuestSummary({
    required this.questId,
    required this.questTitle,
    required this.artisanId,
    required this.studioName,
    required this.participation,
  });

  factory ActiveQuestSummary.fromMap(Map<String, dynamic> map) {
    return ActiveQuestSummary(
      questId: map['quest_id']?.toString().trim() ?? '',
      questTitle: map['quest_title']?.toString().trim() ?? 'Cultural Quest',
      artisanId: map['artisan_id']?.toString().trim() ?? '',
      studioName: map['studio_name']?.toString().trim() ?? 'Artisan Studio',
      participation: QuestParticipation.fromMap(map),
    );
  }
}

class ActiveQuestState {
  final ActiveQuestSummary? activeQuest;
  final List<ActiveQuestSummary> conflictingQuests;
  final String? reconciliationWarning;

  const ActiveQuestState({
    required this.activeQuest,
    this.conflictingQuests = const [],
    this.reconciliationWarning,
  });

  const ActiveQuestState.empty()
    : activeQuest = null,
      conflictingQuests = const [],
      reconciliationWarning = null;

  bool get hasActiveQuest => activeQuest != null;
  bool get hasDataIntegrityWarning => conflictingQuests.isNotEmpty;

  String? get warningMessage {
    final conflictWarning = hasDataIntegrityWarning
        ? 'Multiple active quests were found. No quest will be changed '
              'until the conflict is resolved.'
        : null;
    if (conflictWarning == null) return reconciliationWarning;
    if (reconciliationWarning == null) return conflictWarning;
    return '$conflictWarning $reconciliationWarning';
  }

  factory ActiveQuestState.fromRows(
    Iterable<Map<String, dynamic>> rows, {
    String? reconciliationWarning,
  }) {
    final quests =
        rows
            .map(ActiveQuestSummary.fromMap)
            .where((quest) => quest.questId.isNotEmpty)
            .toList(growable: true)
          ..sort(_compareActiveQuests);
    if (quests.isEmpty) {
      return ActiveQuestState(
        activeQuest: null,
        reconciliationWarning: reconciliationWarning,
      );
    }
    return ActiveQuestState(
      activeQuest: quests.first,
      conflictingQuests: List.unmodifiable(quests.skip(1)),
      reconciliationWarning: reconciliationWarning,
    );
  }

  static int _compareActiveQuests(
    ActiveQuestSummary first,
    ActiveQuestSummary second,
  ) {
    final firstStarted = first.participation.startedAt;
    final secondStarted = second.participation.startedAt;
    if (firstStarted != null && secondStarted != null) {
      final newestFirst = secondStarted.compareTo(firstStarted);
      if (newestFirst != 0) return newestFirst;
    } else if (firstStarted != null) {
      return -1;
    } else if (secondStarted != null) {
      return 1;
    }
    return first.questId.compareTo(second.questId);
  }
}

enum QuestStartDisposition {
  started,
  resumed,
  blockedByOtherQuest,
  dataIntegrityConflict,
}

class QuestStartResult {
  final QuestStartDisposition disposition;
  final QuestParticipation? participation;
  final ActiveQuestState activeState;

  const QuestStartResult({
    required this.disposition,
    required this.participation,
    required this.activeState,
  });

  bool get isSuccessful =>
      disposition == QuestStartDisposition.started ||
      disposition == QuestStartDisposition.resumed;

  bool get wasResumed => disposition == QuestStartDisposition.resumed;

  factory QuestStartResult.fromMap(Map<String, dynamic> map) {
    final activeRows = List<Map<String, dynamic>>.from(
      map['active_rows'] as List? ?? const [],
    );
    final progressValue = map['progress'];
    final progress = progressValue is Map
        ? Map<String, dynamic>.from(progressValue)
        : null;
    final reconciliationValue = map['completion_reconciliation'];
    final reconciliation = reconciliationValue is Map
        ? QuestCompletionReconciliationResult.fromMap(
            Map<String, dynamic>.from(reconciliationValue),
          )
        : null;
    return QuestStartResult(
      disposition: switch (map['outcome']?.toString()) {
        'started' => QuestStartDisposition.started,
        'resumed' => QuestStartDisposition.resumed,
        'integrity_conflict' => QuestStartDisposition.dataIntegrityConflict,
        _ => QuestStartDisposition.blockedByOtherQuest,
      },
      participation: progress == null
          ? null
          : QuestParticipation.fromMap(progress),
      activeState: ActiveQuestState.fromRows(
        activeRows,
        reconciliationWarning: reconciliation?.hasWarning == true
            ? reconciliation!.warnings.first
            : null,
      ),
    );
  }
}
