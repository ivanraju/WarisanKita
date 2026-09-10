import 'package:warisan_kita/domain/models/quest_participation.dart';

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

  const ActiveQuestState({
    required this.activeQuest,
    this.conflictingQuests = const [],
  });

  const ActiveQuestState.empty()
    : activeQuest = null,
      conflictingQuests = const [];

  bool get hasActiveQuest => activeQuest != null;
  bool get hasDataIntegrityWarning => conflictingQuests.isNotEmpty;

  String? get warningMessage => hasDataIntegrityWarning
      ? 'Multiple active journeys were found. The most recently started '
            'journey is being used. Please contact support before starting '
            'another journey.'
      : null;

  factory ActiveQuestState.fromRows(Iterable<Map<String, dynamic>> rows) {
    final quests =
        rows
            .map(ActiveQuestSummary.fromMap)
            .where((quest) => quest.questId.isNotEmpty)
            .toList(growable: true)
          ..sort(_compareActiveQuests);
    if (quests.isEmpty) return const ActiveQuestState.empty();
    return ActiveQuestState(
      activeQuest: quests.first,
      conflictingQuests: List.unmodifiable(quests.skip(1)),
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
      activeState: ActiveQuestState.fromRows(activeRows),
    );
  }
}
