class HeritageTier {
  final int level;
  final String title;
  final int minimumXp;

  const HeritageTier({
    required this.level,
    required this.title,
    required this.minimumXp,
  });
}

class HeritageProgress {
  final int totalXp;
  final HeritageTier currentTier;
  final HeritageTier? nextTier;
  final int currentTierXp;
  final int xpForNextTier;
  final double progress;

  const HeritageProgress({
    required this.totalXp,
    required this.currentTier,
    required this.nextTier,
    required this.currentTierXp,
    required this.xpForNextTier,
    required this.progress,
  });
}

class HeritageProgression {
  static const List<HeritageTier> tiers = [
    HeritageTier(level: 1, title: 'Heritage Observer', minimumXp: 0),
    HeritageTier(level: 2, title: 'Heritage Explorer', minimumXp: 200),
    HeritageTier(level: 3, title: 'Heritage Apprentice', minimumXp: 500),
    HeritageTier(level: 4, title: 'Heritage Guardian', minimumXp: 1000),
    HeritageTier(level: 5, title: 'Heritage Champion', minimumXp: 2000),
  ];

  static HeritageProgress fromXp(int earnedXp) {
    final totalXp = earnedXp < 0 ? 0 : earnedXp;
    var tierIndex = 0;
    for (var index = 0; index < tiers.length; index++) {
      if (totalXp >= tiers[index].minimumXp) tierIndex = index;
    }

    final current = tiers[tierIndex];
    final next = tierIndex + 1 < tiers.length ? tiers[tierIndex + 1] : null;
    if (next == null) {
      return HeritageProgress(
        totalXp: totalXp,
        currentTier: current,
        nextTier: null,
        currentTierXp: totalXp - current.minimumXp,
        xpForNextTier: 0,
        progress: 1,
      );
    }

    final tierSpan = next.minimumXp - current.minimumXp;
    final currentTierXp = totalXp - current.minimumXp;
    return HeritageProgress(
      totalXp: totalXp,
      currentTier: current,
      nextTier: next,
      currentTierXp: currentTierXp,
      xpForNextTier: tierSpan,
      progress: tierSpan <= 0 ? 1 : (currentTierXp / tierSpan).clamp(0.0, 1.0),
    );
  }
}

class EarnedTaskXp {
  final String taskId;
  final String questId;
  final int xpAwarded;
  final DateTime? awardedAt;
  final String workshopId;
  final bool isWorkshopVisit;

  const EarnedTaskXp({
    required this.taskId,
    required this.questId,
    required this.xpAwarded,
    this.awardedAt,
    this.workshopId = '',
    this.isWorkshopVisit = false,
  });

  factory EarnedTaskXp.fromMap(Map<String, dynamic> map) {
    final taskValue = map['heritage_tasks'];
    final task = taskValue is Map
        ? Map<String, dynamic>.from(taskValue)
        : const <String, dynamic>{};
    final questValue = task['quests'];
    final quest = questValue is Map
        ? Map<String, dynamic>.from(questValue)
        : const <String, dynamic>{};
    return EarnedTaskXp(
      taskId: map['task_id']?.toString() ?? '',
      questId: task['quest_id']?.toString() ?? '',
      xpAwarded: _nonNegativeInt(map['xp_awarded']),
      awardedAt: DateTime.tryParse(map['awarded_at']?.toString() ?? ''),
      workshopId: quest['artisan_id']?.toString() ?? '',
      isWorkshopVisit:
          task['is_system_task'] == true &&
          _nonNegativeInt(task['sort_order']) == 1,
    );
  }
}

class HeritageStamp {
  final String id;
  final String questId;
  final String stampCode;
  final String title;
  final String iconUrl;
  final bool isUnlocked;
  final String description;
  final String questTitle;
  final String category;
  final DateTime? earnedAt;

  const HeritageStamp({
    required this.id,
    this.questId = '',
    this.stampCode = '',
    required this.title,
    required this.iconUrl,
    this.isUnlocked = false,
    this.description = '',
    this.questTitle = '',
    this.category = '',
    this.earnedAt,
  });

  factory HeritageStamp.fromMap(Map<String, dynamic> map) {
    final questValue = map['quests'];
    final quest = questValue is Map
        ? Map<String, dynamic>.from(questValue)
        : const <String, dynamic>{};
    final questTitle = quest['title']?.toString().trim() ?? '';
    final stampTitle = quest['stamp_title']?.toString().trim() ?? '';
    return HeritageStamp(
      id: map['id']?.toString() ?? '',
      questId: map['quest_id']?.toString() ?? '',
      stampCode: map['stamp_code']?.toString().trim() ?? '',
      title: stampTitle.isEmpty ? 'Heritage Stamp' : stampTitle,
      iconUrl: quest['stamp_image_url']?.toString().trim() ?? '',
      isUnlocked: true,
      description: questTitle.isEmpty ? 'Heritage quest completed' : questTitle,
      questTitle: questTitle,
      category: quest['category']?.toString().trim() ?? '',
      earnedAt: DateTime.tryParse(map['unlocked_at']?.toString() ?? ''),
    );
  }

  factory HeritageStamp.fromQuestMap(Map<String, dynamic> map) {
    final questId = map['id']?.toString() ?? '';
    final stampTitle = map['stamp_title']?.toString().trim() ?? '';
    final questTitle = map['title']?.toString().trim() ?? '';
    return HeritageStamp(
      id: 'locked-$questId',
      questId: questId,
      title: stampTitle.isNotEmpty
          ? stampTitle
          : (questTitle.isNotEmpty ? questTitle : 'Heritage Stamp'),
      iconUrl: map['stamp_image_url']?.toString().trim() ?? '',
      questTitle: questTitle,
      category: map['category']?.toString().trim() ?? '',
    );
  }
}

class CompletedPassportQuest {
  final String questId;
  final String artisanId;

  const CompletedPassportQuest({
    required this.questId,
    required this.artisanId,
  });

  factory CompletedPassportQuest.fromMap(Map<String, dynamic> map) {
    final questValue = map['quests'];
    final quest = questValue is Map
        ? Map<String, dynamic>.from(questValue)
        : const <String, dynamic>{};
    return CompletedPassportQuest(
      questId: map['quest_id']?.toString() ?? '',
      artisanId: quest['artisan_id']?.toString() ?? '',
    );
  }
}

class PassportSnapshot {
  final int totalXp;
  final int completedTaskCount;
  final int completedQuestCount;
  final int visitedQuestCount;
  final int availableStampCount;
  final bool hasXpData;
  final bool hasStampData;
  final bool hasQuestStatistics;
  final bool hasVisitedStudioData;
  final bool hasAvailableStampData;
  final List<String> warnings;
  final List<HeritageStamp> stamps;

  int get earnedStampCount => stamps.where((stamp) => stamp.isUnlocked).length;

  const PassportSnapshot({
    required this.totalXp,
    required this.completedTaskCount,
    required this.completedQuestCount,
    required this.visitedQuestCount,
    required this.availableStampCount,
    required this.hasXpData,
    required this.hasStampData,
    required this.hasQuestStatistics,
    this.hasVisitedStudioData = true,
    required this.hasAvailableStampData,
    this.warnings = const [],
    required this.stamps,
  });

  factory PassportSnapshot.fromData({
    required int totalXp,
    required Iterable<EarnedTaskXp> taskAwards,
    required List<HeritageStamp> earnedStamps,
    Iterable<Map<String, dynamic>> availableQuests = const [],
    Iterable<CompletedPassportQuest> completedQuests = const [],
    bool hasXpData = true,
    bool hasStampData = true,
    bool hasQuestStatistics = true,
    bool hasVisitedStudioData = true,
    bool hasAvailableStampData = true,
    List<String> warnings = const [],
  }) {
    final uniqueTasks = <String, EarnedTaskXp>{};
    for (final task in taskAwards) {
      if (task.taskId.isNotEmpty) uniqueTasks[task.taskId] = task;
    }
    final validTasks = uniqueTasks.values
        .where((task) => task.questId.isNotEmpty)
        .toList(growable: false);
    final uniqueStamps = <String, HeritageStamp>{};
    for (final stamp in earnedStamps) {
      final key = stamp.questId.isEmpty ? stamp.id : stamp.questId;
      uniqueStamps.putIfAbsent(key, () => stamp);
    }
    final sortedEarnedStamps = uniqueStamps.values.toList(growable: false)
      ..sort((a, b) {
        final aDate = a.earnedAt;
        final bDate = b.earnedAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    final availableByQuest = <String, HeritageStamp>{};
    for (final row in availableQuests) {
      final stamp = HeritageStamp.fromQuestMap(row);
      if (stamp.questId.isNotEmpty) availableByQuest[stamp.questId] = stamp;
    }
    final lockedStamps =
        availableByQuest.entries
            .where((entry) => !uniqueStamps.containsKey(entry.key))
            .map((entry) => entry.value)
            .toList(growable: false)
          ..sort((a, b) => a.title.compareTo(b.title));
    final completedByQuest = <String, CompletedPassportQuest>{};
    for (final quest in completedQuests) {
      if (quest.questId.isNotEmpty) completedByQuest[quest.questId] = quest;
    }
    final visitedStudios = <String>{
      ...validTasks
          .where((task) => task.isWorkshopVisit)
          .map((task) => task.workshopId)
          .where((id) => id.isNotEmpty),
    };
    return PassportSnapshot(
      totalXp: totalXp < 0 ? 0 : totalXp,
      completedTaskCount: validTasks.length,
      completedQuestCount: completedByQuest.length,
      visitedQuestCount: visitedStudios.length,
      availableStampCount: availableByQuest.length,
      hasXpData: hasXpData,
      hasStampData: hasStampData,
      hasQuestStatistics: hasQuestStatistics,
      hasVisitedStudioData: hasVisitedStudioData,
      hasAvailableStampData: hasAvailableStampData,
      warnings: List.unmodifiable(warnings),
      stamps: List.unmodifiable([...sortedEarnedStamps, ...lockedStamps]),
    );
  }
}

int _nonNegativeInt(dynamic value) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  return parsed < 0 ? 0 : parsed;
}

class HeritageTask {
  final String id;
  final String workshopId;
  final String title;
  final bool isCompleted;
  final bool isRequired;
  final String xpReward;

  HeritageTask({
    required this.id,
    required this.workshopId,
    required this.title,
    this.isCompleted = false,
    this.isRequired = true,
    this.xpReward = '50 XP',
  });
}
