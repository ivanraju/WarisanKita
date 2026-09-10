import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/gamification_moderation_request.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/viewmodels/gamification_moderation_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task-only gamification moderation', () {
    test('counts only new, edit, and delete task requests', () async {
      final repository = _ModerationRepository();
      final viewModel = GamificationModerationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.loadRequests();

      expect(viewModel.newTaskCount, 1);
      expect(viewModel.taskChangeCount, 2);
      expect(viewModel.deleteRequestCount, 2);
      expect(viewModel.totalCount, 5);

      viewModel.setFilter(GamificationModerationFilter.newTasks);
      expect(viewModel.filteredRequests, hasLength(1));
      viewModel.setFilter(GamificationModerationFilter.taskChanges);
      expect(viewModel.filteredRequests, hasLength(2));
      viewModel.setFilter(GamificationModerationFilter.deleteRequests);
      expect(viewModel.filteredRequests, hasLength(2));
      viewModel.setFilter(GamificationModerationFilter.all);
      expect(viewModel.filteredRequests, hasLength(viewModel.totalCount));
    });

    test('task approval and rejection routes remain operational', () async {
      final repository = _ModerationRepository();
      final viewModel = GamificationModerationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadRequests();

      for (final request in List.of(viewModel.requests)) {
        final approve =
            request.id == 'new-task' ||
            request.id == 'edit-approve' ||
            request.id == 'delete-approve';
        final reviewed = await viewModel.reviewRequest(
          request,
          approve: approve,
          rejectionReason: approve ? null : 'Does not meet task guidelines.',
        );
        expect(reviewed, isTrue);
      }

      expect(
        repository.newTaskReviews,
        contains(const _ReviewCall('new-task', true)),
      );
      expect(
        repository.taskChangeReviews,
        containsAll(const [
          _ReviewCall('edit-approve', true),
          _ReviewCall('edit-reject', false),
          _ReviewCall('delete-approve', true),
          _ReviewCall('delete-reject', false),
        ]),
      );
      expect(viewModel.totalCount, 0);
      expect(viewModel.newTaskCount, 0);
      expect(viewModel.taskChangeCount, 0);
      expect(viewModel.deleteRequestCount, 0);
    });

    test('legacy quest changes cannot enter the task request model', () {
      expect(
        () => GamificationModerationRequest.fromMap({
          'request_kind': 'QUEST_CHANGE',
        }),
        throwsFormatException,
      );
    });
  });

  group('Removed quest-change workflow source contracts', () {
    test('artisan and admin UIs expose no quest-change controls', () {
      final artisanSource = File(
        'lib/ui/artisan/artisan_heritage_task_management_view.dart',
      ).readAsStringSync();
      final adminSource = File(
        'lib/ui/admin_web/widgets/admin_quest_approvals_tab.dart',
      ).readAsStringSync();

      expect(artisanSource, isNot(contains('Edit Quest')));
      expect(artisanSource, isNot(contains('Quest Settings')));
      expect(artisanSource, isNot(contains('_EditQuestSheet')));
      expect(adminSource, isNot(contains('Quest Changes')));
      expect(adminSource, isNot(contains('_buildQuestChangeCard')));
      expect(
        adminSource,
        contains(
          'Review new heritage tasks and proposed task changes before they go live.',
        ),
      );
    });

    test('application layer does not query or submit legacy quest changes', () {
      final sources = [
        'lib/data/services/supabase_service.dart',
        'lib/data/repositories/gamification_repository.dart',
        'lib/viewmodels/gamification_viewmodel.dart',
        'lib/viewmodels/gamification_moderation_viewmodel.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');

      expect(sources, isNot(contains('quest_change_requests')));
      expect(sources, isNot(contains('requestQuestUpdate')));
      expect(sources, isNot(contains('reviewQuestChange')));
      expect(sources, isNot(contains('QuestChangeRequest')));
    });

    test('sidebar, page, and dashboard use the shared task-only total', () {
      final sidebar = File(
        'lib/ui/admin_web/widgets/admin_sidebar.dart',
      ).readAsStringSync();
      final page = File(
        'lib/ui/admin_web/widgets/admin_quest_approvals_tab.dart',
      ).readAsStringSync();
      final overview = File(
        'lib/ui/admin_web/widgets/admin_overview_tab.dart',
      ).readAsStringSync();

      expect(sidebar, contains('gamificationModVM!.totalCount'));
      expect(page, contains('viewModel.totalCount'));
      expect(overview, contains('gameModVM?.totalCount ?? 0'));
      expect(overview, isNot(contains('pendingFromVM')));
    });
  });
}

class _ModerationRepository extends GamificationRepository {
  final List<_ReviewCall> newTaskReviews = [];
  final List<_ReviewCall> taskChangeReviews = [];

  late final Quest quest = Quest(
    id: 'quest-1',
    artisanId: 'artisan-1',
    title: 'Living Heritage Journey',
    description: 'Visit the workshop and learn the craft.',
    category: 'Woodwork',
    geofenceRadiusMeters: 50,
    stampTitle: 'Woodwork Stamp',
    stampImageUrl: 'stamp.png',
    status: 'APPROVED',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  late final HeritageTask task = HeritageTask(
    id: 'task-1',
    questId: quest.id,
    title: 'Carve a motif',
    isRequired: true,
    xpReward: 50,
    sortOrder: 3,
    createdAt: DateTime.utc(2026, 1, 2),
    status: 'APPROVED',
    rejectionReason: null,
    reviewedAt: null,
    reviewedBy: null,
    isSystemTask: false,
    isArchived: false,
  );

  @override
  Future<List<GamificationModerationRequest>>
  getPendingGamificationModerationRequests() async => [
    _newTaskRequest(),
    _changeRequest('edit-approve', 'EDIT'),
    _changeRequest('edit-reject', 'EDIT'),
    _changeRequest('delete-approve', 'DELETE'),
    _changeRequest('delete-reject', 'DELETE'),
  ];

  GamificationModerationRequest _newTaskRequest() {
    return GamificationModerationRequest(
      type: GamificationModerationRequestType.newTask,
      id: 'new-task',
      artisanName: 'Test Artisan',
      quest: quest,
      task: task,
      taskChange: null,
      submittedAt: DateTime.utc(2026, 9, 10),
    );
  }

  GamificationModerationRequest _changeRequest(String id, String type) {
    return GamificationModerationRequest(
      type: GamificationModerationRequestType.taskChange,
      id: id,
      artisanName: 'Test Artisan',
      quest: quest,
      task: task,
      taskChange: HeritageTaskChangeRequest(
        id: id,
        taskId: task.id,
        requestType: type,
        proposedTitle: type == 'EDIT' ? 'Refined carving activity' : null,
        proposedIsRequired: type == 'EDIT' ? false : null,
        proposedXpReward: type == 'EDIT' ? 75 : null,
        status: 'PENDING_APPROVAL',
        rejectionReason: null,
        submittedAt: DateTime.utc(2026, 9, 10),
        reviewedAt: null,
        reviewedBy: null,
      ),
      submittedAt: DateTime.utc(2026, 9, 10),
    );
  }

  @override
  Future<void> reviewNewHeritageTask({
    required String taskId,
    required bool approve,
    String? rejectionReason,
  }) async {
    newTaskReviews.add(_ReviewCall(taskId, approve));
  }

  @override
  Future<void> reviewHeritageTaskChange({
    required String requestId,
    required bool approve,
    String? rejectionReason,
  }) async {
    taskChangeReviews.add(_ReviewCall(requestId, approve));
  }
}

class _ReviewCall {
  final String id;
  final bool approved;

  const _ReviewCall(this.id, this.approved);

  @override
  bool operator ==(Object other) =>
      other is _ReviewCall && other.id == id && other.approved == approved;

  @override
  int get hashCode => Object.hash(id, approved);
}
