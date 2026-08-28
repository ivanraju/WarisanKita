import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/artisan_quest_profile.dart';
import 'package:warisan_kita/domain/models/badge.dart' show HeritageStamp;
import 'package:warisan_kita/domain/models/gamification_moderation_request.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/quest_change_request.dart';
import 'package:warisan_kita/domain/models/task_progress.dart';

class GamificationRepository {
  final SupabaseService _service;

  GamificationRepository({SupabaseService? service})
    : _service = service ?? SupabaseService();

  Future<List<HeritageStamp>> getUserBadges(String userId) =>
      _service.fetchUserStamps(userId);

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

  Future<bool> hasEarnedQuestStamp(String questId) {
    return _service.hasEarnedQuestStamp(questId);
  }

  Future<String> startQuest({
    required String questId,
    required List<String> taskIds,
  }) {
    return _service.startQuest(questId: questId, taskIds: taskIds);
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

  Future<List<QuestChangeRequest>> getQuestChangeRequests(
    String questId,
  ) async {
    final rows = await _service.fetchQuestChangeRequests(questId);
    return rows.map(QuestChangeRequest.fromMap).toList(growable: false);
  }

  Future<QuestChangeRequest> requestQuestUpdate({
    required String questId,
    required String proposedTitle,
    required String proposedDescription,
    required String proposedCategory,
  }) async {
    final row = await _service.insertQuestChangeRequest(
      questId: questId,
      proposedTitle: proposedTitle,
      proposedDescription: proposedDescription,
      proposedCategory: proposedCategory,
    );
    return QuestChangeRequest.fromMap(row);
  }

  Future<Quest> updateCurrentArtisanQuest({
    required String questId,
    required String title,
    required String description,
    required String category,
  }) async {
    final row = await _service.updateCurrentArtisanQuest(
      questId: questId,
      title: title,
      description: description,
      category: category,
    );
    return Quest.fromMap(row);
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

  Future<void> reviewQuestChange({
    required String requestId,
    required bool approve,
    String? rejectionReason,
  }) {
    return _service.reviewQuestChange(
      requestId: requestId,
      approve: approve,
      rejectionReason: rejectionReason,
    );
  }
}
