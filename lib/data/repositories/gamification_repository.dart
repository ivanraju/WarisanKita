import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/active_quest.dart';
import 'package:warisan_kita/domain/models/artisan_quest_profile.dart';
import 'package:warisan_kita/domain/models/badge.dart'
    show CompletedPassportQuest, EarnedTaskXp, HeritageStamp, PassportSnapshot;
import 'package:warisan_kita/domain/models/gamification_moderation_request.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/quest_participation.dart';
import 'package:warisan_kita/domain/models/task_progress.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';
import 'package:warisan_kita/domain/models/artisan_heritage_analytics.dart';

class GamificationRepository {
  final SupabaseService _service;

  GamificationRepository({SupabaseService? service})
    : _service = service ?? SupabaseService();

  Future<ArtisanHeritageAnalytics> getArtisanHeritageAnalytics({
    DateTime? now,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final periodStart = today.subtract(const Duration(days: 6));
    final periodEnd = today.add(const Duration(days: 1));
    final data = await _service.fetchArtisanHeritageAnalytics(
      startedAtUtc: periodStart.toUtc(),
      endedAtUtcExclusive: periodEnd.toUtc(),
    );

    final visitorsByDay = <DateTime, Set<String>>{};
    final visitorIds = <String>{};
    for (final row in List<Map<String, dynamic>>.from(
      data['visits'] as List? ?? const [],
    )) {
      final userId = row['user_id']?.toString().trim() ?? '';
      final completedAtUtc = DateTime.tryParse(
        row['completed_at']?.toString() ?? '',
      );
      if (userId.isEmpty || completedAtUtc == null) continue;
      final completedAt = completedAtUtc.toLocal();
      if (completedAt.isBefore(periodStart) ||
          !completedAt.isBefore(periodEnd)) {
        continue;
      }
      final day = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      visitorIds.add(userId);
      visitorsByDay.putIfAbsent(day, () => <String>{}).add(userId);
    }

    final dailyVisitors = List.generate(7, (index) {
      final date = periodStart.add(Duration(days: index));
      return DailyVerifiedVisitors(
        date: date,
        count: visitorsByDay[date]?.length ?? 0,
      );
    });

    int? stampCount;
    if (data['stamps_available'] == true) {
      final uniqueStamps = <String>{};
      for (final row in List<Map<String, dynamic>>.from(
        data['stamps'] as List? ?? const [],
      )) {
        final userId = row['user_id']?.toString().trim() ?? '';
        final questId = row['quest_id']?.toString().trim() ?? '';
        if (userId.isNotEmpty && questId.isNotEmpty) {
          uniqueStamps.add('$userId|$questId');
        }
      }
      stampCount = uniqueStamps.length;
    }

    int? completedTourists;
    if (data['completions_available'] == true) {
      completedTourists =
          List<Map<String, dynamic>>.from(
                data['completions'] as List? ?? const [],
              )
              .map((row) => row['user_id']?.toString().trim() ?? '')
              .where((userId) => userId.isNotEmpty)
              .toSet()
              .length;
    }

    return ArtisanHeritageAnalytics(
      totalUniqueVisitors: visitorIds.length,
      dailyVisitors: dailyVisitors,
      visitorSource: data['visitor_source']?.toString() ?? 'arrival_task',
      passportStampsAwarded: stampCount,
      completedTourists: completedTourists,
      completionTarget: null,
    );
  }

  Future<PassportSnapshot> getPassportSnapshot() async {
    final data = await _service.fetchPassportData();
    final totalXpValue = data['total_xp'];
    final totalXp = totalXpValue is num
        ? totalXpValue.toInt()
        : int.tryParse(totalXpValue?.toString() ?? '') ?? 0;
    final taskAwardRows = List<Map<String, dynamic>>.from(
      data['task_awards'] as List? ?? const [],
    );
    final stampRows = List<Map<String, dynamic>>.from(
      data['stamps'] as List? ?? const [],
    );
    final availableQuestRows = List<Map<String, dynamic>>.from(
      data['available_quests'] as List? ?? const [],
    );
    final completedQuestRows = List<Map<String, dynamic>>.from(
      data['completed_quests'] as List? ?? const [],
    );
    final plaqueCountValue = data['digital_plaque_count'];
    final plaqueCount = plaqueCountValue is num
        ? plaqueCountValue.toInt()
        : int.tryParse(plaqueCountValue?.toString() ?? '') ?? 0;
    return PassportSnapshot.fromData(
      totalXp: totalXp,
      taskAwards: taskAwardRows.map(EarnedTaskXp.fromMap),
      earnedStamps: stampRows
          .map(HeritageStamp.fromMap)
          .toList(growable: false),
      availableQuests: availableQuestRows,
      completedQuests: completedQuestRows.map(CompletedPassportQuest.fromMap),
      digitalPlaqueCount: plaqueCount,
      hasXpData: data['xp_available'] != false,
      hasStampData: data['stamps_available'] != false,
      hasQuestStatistics: data['quest_statistics_available'] != false,
      hasVisitedStudioData: data['task_awards_available'] != false,
      hasDigitalPlaqueData: data['digital_plaques_available'] != false,
      hasAvailableStampData: data['available_quests_available'] != false,
      warnings: List<String>.from(data['warnings'] as List? ?? const []),
    );
  }

  Future<List<HeritageStamp>> getUserBadges() async {
    return (await getPassportSnapshot()).stamps
        .where((stamp) => stamp.isUnlocked)
        .toList(growable: false);
  }

  Future<TouristJourneySnapshot> getTouristJourneySnapshot() async {
    final data = await _service.fetchTouristMapJourneyData();
    final quests = List<Map<String, dynamic>>.from(
      data['quests'] as List? ?? const [],
    );
    final tasks = List<Map<String, dynamic>>.from(
      data['tasks'] as List? ?? const [],
    );
    final questProgress = List<Map<String, dynamic>>.from(
      data['quest_progress'] as List? ?? const [],
    );
    final taskProgress = List<Map<String, dynamic>>.from(
      data['task_progress'] as List? ?? const [],
    );
    final stamps = List<Map<String, dynamic>>.from(
      data['stamps'] as List? ?? const [],
    );

    final tasksByQuest = <String, List<Map<String, dynamic>>>{};
    for (final task in tasks) {
      final questId = task['quest_id']?.toString() ?? '';
      if (questId.isNotEmpty) {
        tasksByQuest.putIfAbsent(questId, () => []).add(task);
      }
    }
    final completedTaskIds = taskProgress
        .where((row) => row['is_completed'] == true)
        .map((row) => row['task_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final participationByQuest = {
      for (final row in questProgress)
        if ((row['quest_id']?.toString() ?? '').isNotEmpty)
          row['quest_id'].toString(): QuestParticipation.fromMap(row),
    };
    final questById = {
      for (final quest in quests)
        if ((quest['id']?.toString() ?? '').isNotEmpty)
          quest['id'].toString(): quest,
    };
    final activeState = ActiveQuestState.fromRows(
      questProgress
          .where(
            (row) => row['status']?.toString().toUpperCase() == 'IN_PROGRESS',
          )
          .map((row) {
            final quest = questById[row['quest_id']?.toString() ?? ''];
            return <String, dynamic>{
              ...row,
              'quest_title': quest?['title'],
              'artisan_id': quest?['artisan_id'],
            };
          }),
    );
    final activeQuestId = activeState.activeQuest?.questId;
    final stampedQuestIds = stamps
        .map((row) => row['quest_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final journeys = <String, WorkshopQuestJourney>{};

    for (final quest in quests) {
      final questId = quest['id']?.toString() ?? '';
      final workshopId = quest['artisan_id']?.toString() ?? '';
      if (questId.isEmpty || workshopId.isEmpty) continue;

      final questTasks = tasksByQuest[questId] ?? const [];
      final participation = participationByQuest[questId];
      final effectiveRequiredTasks = questTasks
          .where((task) {
            if (task['is_required'] == false) return false;
            return !QuestParticipation.isCreatedAfterStart(
              taskCreatedAt: QuestParticipation.parseTimestamp(
                task['created_at'],
              ),
              participantStartedAt: participation?.startedAt,
            );
          })
          .toList(growable: false);
      final isPermanentlyCompleted =
          stampedQuestIds.contains(questId) ||
          participation?.isCompleted == true;
      final completedCount = isPermanentlyCompleted
          ? effectiveRequiredTasks.length
          : effectiveRequiredTasks
                .where(
                  (task) => completedTaskIds.contains(task['id']?.toString()),
                )
                .length;
      final xpReward = questTasks.fold<int>(0, (sum, task) {
        final value = task['xp_reward'];
        return sum +
            (value is num ? value.toInt() : int.tryParse('$value') ?? 0);
      });
      final progressStatus = participation?.status.toUpperCase();
      final state = isPermanentlyCompleted
          ? WorkshopQuestState.completed
          : progressStatus == 'IN_PROGRESS' && questId == activeQuestId
          ? WorkshopQuestState.inProgress
          : activeQuestId != null
          ? WorkshopQuestState.blockedByOtherQuest
          : WorkshopQuestState.available;

      journeys.putIfAbsent(
        workshopId,
        () => WorkshopQuestJourney(
          workshopId: workshopId,
          questId: questId,
          questTitle: quest['title']?.toString().trim() ?? 'Heritage Quest',
          category: quest['category']?.toString().trim() ?? '',
          stampTitle: quest['stamp_title']?.toString().trim() ?? '',
          stampImageUrl: quest['stamp_image_url']?.toString().trim() ?? '',
          xpReward: xpReward,
          completedTaskCount: completedCount,
          totalTaskCount: effectiveRequiredTasks.length,
          state: state,
        ),
      );
    }

    final xpValue = data['total_xp'];
    final totalXp = xpValue is num
        ? xpValue.toInt()
        : int.tryParse('$xpValue') ?? 0;
    return TouristJourneySnapshot(
      journeysByWorkshopId: Map.unmodifiable(journeys),
      totalXp: totalXp < 0 ? 0 : totalXp,
      earnedStampCount: stampedQuestIds.length,
      hasXpData: data['xp_available'] != false,
      hasStampData: data['stamps_available'] != false,
      warnings: List<String>.from(data['warnings'] as List? ?? const []),
    );
  }

  Future<List<Quest>> getApprovedQuestsForArtisan(
    String artisanProfileId,
  ) async {
    final rows = await _service.fetchApprovedQuestsForArtisan(artisanProfileId);

    return rows.map(Quest.fromMap).toList(growable: false);
  }

  Future<List<HeritageTask>> getHeritageTasks(String questId) async {
    final rows = await _service.fetchHeritageTasks(
      questId,
      approvedOnly: true,
      includeInactive: false,
    );

    return _mapAndSortTasks(rows);
  }

  Future<List<HeritageTask>> getArtisanHeritageTasks(String questId) async {
    final rows = await _service.fetchHeritageTasks(
      questId,
      approvedOnly: false,
      includeInactive: true,
    );

    return _mapAndSortTasks(rows);
  }

  Future<String?> getCurrentQuestProgressStatus(String questId) {
    return _service.fetchCurrentQuestProgressStatus(questId);
  }

  Future<QuestParticipation?> getCurrentQuestParticipation(
    String questId,
  ) async {
    final row = await _service.fetchCurrentQuestProgressSnapshot(questId);
    return row == null ? null : QuestParticipation.fromMap(row);
  }

  Future<ActiveQuestState> getActiveQuestState() async {
    final rows = await _service.fetchActiveQuestProgressRows();
    return ActiveQuestState.fromRows(rows);
  }

  Future<bool> hasEarnedQuestStamp(String questId) {
    return _service.hasEarnedQuestStamp(questId);
  }

  Future<QuestStartResult> startQuest({
    required String questId,
    required List<String> taskIds,
  }) async {
    final row = await _service.startQuest(questId: questId, taskIds: taskIds);
    return QuestStartResult.fromMap(row);
  }

  Future<List<TaskProgress>> getTaskProgress(List<String> taskIds) async {
    final rows = await _service.fetchTaskProgress(taskIds);
    return rows.map(TaskProgress.fromMap).toList(growable: false);
  }

  Future<TaskProgress> completeTask(String taskId) async {
    return TaskProgress.fromMap(await _service.completeTask(taskId));
  }

  Future<TaskProgress> completeTaskWithArtisanQr({
    required String questId,
    required String artisanId,
    required String taskId,
    required String qrPayload,
  }) async {
    return TaskProgress.fromMap(
      await _service.completeTaskWithArtisanQr(
        questId: questId,
        artisanId: artisanId,
        taskId: taskId,
        qrPayload: qrPayload,
      ),
    );
  }

  Future<TaskProgress> startTimedTask(String taskId) async {
    return TaskProgress.fromMap(await _service.startTimedTask(taskId));
  }

  Future<TaskProgress> pauseTimedTask({
    required String taskId,
    required int progressSeconds,
  }) async {
    return TaskProgress.fromMap(
      await _service.pauseTimedTask(
        taskId: taskId,
        progressSeconds: progressSeconds,
      ),
    );
  }

  Future<TaskProgress> completeTimedTask(String taskId) async {
    return TaskProgress.fromMap(await _service.completeTimedTask(taskId));
  }

  List<HeritageTask> _mapAndSortTasks(List<Map<String, dynamic>> rows) {
    final tasks = rows.map(HeritageTask.fromMap).toList();
    tasks.sort((a, b) {
      final aOrder = a.sortOrder;
      final bOrder = b.sortOrder;

      if (aOrder == null && bOrder == null) {
        final aCreatedAt = a.createdAt;
        final bCreatedAt = b.createdAt;

        if (aCreatedAt != null && bCreatedAt != null) {
          return aCreatedAt.compareTo(bCreatedAt);
        }
        if (aCreatedAt == null && bCreatedAt != null) return 1;
        if (aCreatedAt != null && bCreatedAt == null) return -1;

        return a.id.compareTo(b.id);
      }
      if (aOrder == null) return 1;
      if (bOrder == null) return -1;

      return aOrder.compareTo(bOrder);
    });

    return tasks;
  }

  Future<ArtisanQuestProfile?> getCurrentArtisanQuestProfile() async {
    final row = await _service.fetchCurrentArtisanQuestProfile();
    return row == null ? null : ArtisanQuestProfile.fromMap(row);
  }

  Future<List<Quest>> getQuestsForArtisan(String artisanProfileId) async {
    final rows = await _service.fetchQuestsForArtisan(artisanProfileId);
    return rows.map(Quest.fromMap).toList(growable: false);
  }

  Future<Quest?> getQuestForCurrentArtisan() async {
    final profile = await getCurrentArtisanQuestProfile();
    if (profile == null) {
      throw StateError(
        'No artisan profile is linked to this signed-in account.',
      );
    }

    final quests = await getQuestsForArtisan(profile.id);
    if (quests.length > 1) {
      throw StateError('Multiple quests found for this artisan.');
    }

    return quests.singleOrNull;
  }

  Future<HeritageTask> addHeritageTask({
    required String questId,
    required String title,
    required bool isRequired,
    required int xpReward,
    required int sortOrder,
  }) async {
    final row = await _service.insertHeritageTask(
      questId: questId,
      title: title,
      isRequired: isRequired,
      xpReward: xpReward,
      sortOrder: sortOrder,
    );
    return HeritageTask.fromMap(row);
  }

  Future<List<HeritageTaskChangeRequest>> getHeritageTaskChangeRequests(
    List<String> taskIds,
  ) async {
    final rows = await _service.fetchHeritageTaskChangeRequests(taskIds);
    return rows.map(HeritageTaskChangeRequest.fromMap).toList(growable: false);
  }

  Future<HeritageTaskChangeRequest> requestHeritageTaskEdit({
    required String taskId,
    required String proposedTitle,
    required bool proposedIsRequired,
    required int proposedXpReward,
  }) async {
    final row = await _service.insertHeritageTaskChangeRequest(
      taskId: taskId,
      requestType: 'EDIT',
      proposedTitle: proposedTitle,
      proposedIsRequired: proposedIsRequired,
      proposedXpReward: proposedXpReward,
    );
    return HeritageTaskChangeRequest.fromMap(row);
  }

  Future<HeritageTaskChangeRequest> requestHeritageTaskDelete(
    String taskId,
  ) async {
    final row = await _service.insertHeritageTaskChangeRequest(
      taskId: taskId,
      requestType: 'DELETE',
    );
    return HeritageTaskChangeRequest.fromMap(row);
  }

  Future<HeritageTaskChangeRequest> updatePendingHeritageTaskEdit({
    required String requestId,
    required String taskId,
    required String proposedTitle,
    required bool proposedIsRequired,
    required int proposedXpReward,
  }) async {
    final row = await _service.updatePendingHeritageTaskEditRequest(
      requestId: requestId,
      taskId: taskId,
      proposedTitle: proposedTitle,
      proposedIsRequired: proposedIsRequired,
      proposedXpReward: proposedXpReward,
    );
    return HeritageTaskChangeRequest.fromMap(row);
  }

  Future<void> deletePendingHeritageTaskEdit({
    required String requestId,
    required String taskId,
  }) {
    return _service.deletePendingHeritageTaskEditRequest(
      requestId: requestId,
      taskId: taskId,
    );
  }

  Future<HeritageTaskChangeRequest> resubmitRejectedHeritageTaskEdit({
    required String requestId,
    required String taskId,
    required String proposedTitle,
    required bool proposedIsRequired,
    required int proposedXpReward,
  }) async {
    final row = await _service.resubmitRejectedHeritageTaskEditRequest(
      requestId: requestId,
      taskId: taskId,
      proposedTitle: proposedTitle,
      proposedIsRequired: proposedIsRequired,
      proposedXpReward: proposedXpReward,
    );
    return HeritageTaskChangeRequest.fromMap(row);
  }

  Future<HeritageTask> updateUnapprovedHeritageTask({
    required String taskId,
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    final row = await _service.updateUnapprovedHeritageTask(
      taskId: taskId,
      title: title,
      isRequired: isRequired,
      xpReward: xpReward,
    );
    return HeritageTask.fromMap(row);
  }

  Future<void> deleteUnapprovedHeritageTask(String taskId) {
    return _service.deleteUnapprovedHeritageTask(taskId);
  }

  Future<void> deleteRejectedHeritageTaskEditRequest(String requestId) {
    return _service.deleteRejectedHeritageTaskEditRequest(requestId);
  }

  Future<List<GamificationModerationRequest>>
  getPendingGamificationModerationRequests() async {
    final rows = await _service.fetchPendingGamificationModerationRequests();
    return rows
        .map(GamificationModerationRequest.fromMap)
        .toList(growable: false);
  }

  Future<void> reviewNewHeritageTask({
    required String taskId,
    required bool approve,
    String? rejectionReason,
  }) {
    return _service.reviewNewHeritageTask(
      taskId: taskId,
      approve: approve,
      rejectionReason: rejectionReason,
    );
  }

  Future<void> reviewHeritageTaskChange({
    required String requestId,
    required bool approve,
    String? rejectionReason,
  }) {
    return _service.reviewHeritageTaskChange(
      requestId: requestId,
      approve: approve,
      rejectionReason: rejectionReason,
    );
  }

}
