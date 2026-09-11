enum WorkshopQuestState {
  available,
  inProgress,
  stopped,
  blockedByOtherQuest,
  completed,
  unavailable,
}

class WorkshopQuestJourney {
  final String workshopId;
  final String questId;
  final String questTitle;
  final String category;
  final String stampTitle;
  final String stampImageUrl;
  final int xpReward;
  final int completedTaskCount;
  final int totalTaskCount;
  final WorkshopQuestState state;

  const WorkshopQuestJourney({
    required this.workshopId,
    required this.questId,
    required this.questTitle,
    required this.category,
    required this.stampTitle,
    required this.stampImageUrl,
    required this.xpReward,
    required this.completedTaskCount,
    required this.totalTaskCount,
    required this.state,
  });

  double get progress => totalTaskCount == 0
      ? (state == WorkshopQuestState.completed ? 1 : 0)
      : (completedTaskCount / totalTaskCount).clamp(0, 1);

  String get progressLabel => totalTaskCount == 0
      ? 'Activities not published'
      : '$completedTaskCount/$totalTaskCount activities';

  String get stateLabel => switch (state) {
    WorkshopQuestState.available => 'NEW QUEST',
    WorkshopQuestState.inProgress => 'IN PROGRESS',
    WorkshopQuestState.stopped => 'QUEST STOPPED',
    WorkshopQuestState.blockedByOtherQuest => 'ANOTHER JOURNEY ACTIVE',
    WorkshopQuestState.completed => 'STAMP COLLECTED',
    WorkshopQuestState.unavailable => 'UNAVAILABLE',
  };

  String get actionLabel => 'VIEW QUEST';
}

class TouristJourneySnapshot {
  final Map<String, WorkshopQuestJourney> journeysByWorkshopId;
  final int totalXp;
  final int earnedStampCount;
  final bool hasXpData;
  final bool hasStampData;
  final List<String> warnings;

  const TouristJourneySnapshot({
    required this.journeysByWorkshopId,
    required this.totalXp,
    required this.earnedStampCount,
    required this.hasXpData,
    required this.hasStampData,
    this.warnings = const [],
  });

  static const empty = TouristJourneySnapshot(
    journeysByWorkshopId: {},
    totalXp: 0,
    earnedStampCount: 0,
    hasXpData: false,
    hasStampData: false,
  );
}
