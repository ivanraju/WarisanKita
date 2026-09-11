import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Artisan task-request cancellation', () {
    test(
      'pending new task is removed without changing published tasks',
      () async {
        final repository = _CancellationRepository();
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.loadArtisanQuestAndTasks();
        final pendingTask = viewModel.artisanTasks.firstWhere(
          (task) => task.id == 'new-pending',
        );
        final approvedBefore = repository.tasks.firstWhere(
          (task) => task.id == 'published-task',
        );

        expect(await viewModel.cancelNewTaskSubmission(pendingTask), isTrue);

        expect(
          repository.tasks.any((task) => task.id == pendingTask.id),
          isFalse,
        );
        expect(repository.tasks, contains(same(approvedBefore)));
        expect(repository.deletedNewTaskStatus, 'PENDING_APPROVAL');
        expect(
          viewModel.myRequests.any((item) => item.id == pendingTask.id),
          isFalse,
        );
        expect(repository.touristHistoryMutationCalls, 0);
      },
    );

    test('rejected new task can be removed', () async {
      final repository = _CancellationRepository();
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadArtisanQuestAndTasks();
      final rejectedTask = viewModel.artisanTasks.firstWhere(
        (task) => task.id == 'new-rejected',
      );

      expect(await viewModel.cancelNewTaskSubmission(rejectedTask), isTrue);
      expect(repository.deletedNewTaskStatus, 'REJECTED');
      expect(
        repository.tasks.any((task) => task.id == rejectedTask.id),
        isFalse,
      );
    });

    test('pending edit cancellation leaves approved task unchanged', () async {
      final repository = _CancellationRepository();
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadArtisanQuestAndTasks();
      final task = viewModel.artisanTaskById('published-task')!;
      final request = viewModel.artisanTaskChangeRequests.firstWhere(
        (item) => item.id == 'edit-pending',
      );

      expect(await viewModel.cancelPendingTaskChange(task, request), isTrue);

      final unchanged = repository.tasks.singleWhere(
        (item) => item.id == task.id,
      );
      expect(unchanged.title, task.title);
      expect(unchanged.isRequired, task.isRequired);
      expect(unchanged.xpReward, task.xpReward);
      expect(unchanged.status, 'APPROVED');
      expect(repository.requests.any((item) => item.id == request.id), isFalse);
      expect(repository.lastDeletedRequestType, 'EDIT');
      expect(repository.lastDeletedRequestStatus, 'PENDING_APPROVAL');
      expect(repository.touristHistoryMutationCalls, 0);
    });

    test('pending deletion cancellation keeps approved task active', () async {
      final repository = _CancellationRepository();
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadArtisanQuestAndTasks();
      final task = viewModel.artisanTaskById('delete-task')!;
      final request = viewModel.artisanTaskChangeRequests.firstWhere(
        (item) => item.id == 'delete-pending',
      );

      expect(await viewModel.cancelPendingTaskChange(task, request), isTrue);

      final unchanged = repository.tasks.singleWhere(
        (item) => item.id == task.id,
      );
      expect(unchanged.status, 'APPROVED');
      expect(unchanged.isArchived, isFalse);
      expect(repository.lastDeletedRequestType, 'DELETE');
      expect(repository.lastDeletedRequestStatus, 'PENDING_APPROVAL');
    });

    test('rejected edit and deletion requests can be dismissed', () async {
      final repository = _CancellationRepository();
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadArtisanQuestAndTasks();

      final editTask = viewModel.artisanTaskById('edit-rejected-task')!;
      final edit = viewModel.artisanTaskChangeRequests.firstWhere(
        (item) => item.id == 'edit-rejected',
      );
      expect(await viewModel.dismissRejectedTaskChange(editTask, edit), isTrue);
      expect(repository.lastDeletedRequestType, 'EDIT');
      expect(repository.lastDeletedRequestStatus, 'REJECTED');

      final deleteTask = viewModel.artisanTaskById('delete-rejected-task')!;
      final deletion = viewModel.artisanTaskChangeRequests.firstWhere(
        (item) => item.id == 'delete-rejected',
      );
      expect(
        await viewModel.dismissRejectedTaskChange(deleteTask, deletion),
        isTrue,
      );
      expect(repository.lastDeletedRequestType, 'DELETE');
      expect(repository.lastDeletedRequestStatus, 'REJECTED');
      expect(repository.tasks.every((task) => !task.isArchived), isTrue);
    });

    test('system and reviewed task requests cannot be cancelled', () async {
      final repository = _CancellationRepository();
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadArtisanQuestAndTasks();
      final systemTask = viewModel.artisanTaskById('system-task')!;
      final systemRequest = _request(
        id: 'system-request',
        taskId: systemTask.id,
        type: 'EDIT',
        status: 'PENDING_APPROVAL',
      );
      final reviewed = _request(
        id: 'reviewed-request',
        taskId: 'published-task',
        type: 'EDIT',
        status: 'APPROVED',
      );

      expect(
        await viewModel.cancelPendingTaskChange(systemTask, systemRequest),
        isFalse,
      );
      expect(
        await viewModel.cancelPendingTaskChange(
          viewModel.artisanTaskById('published-task')!,
          reviewed,
        ),
        isFalse,
      );
      expect(repository.deleteChangeCalls, 0);
    });

    test(
      'admin-review race refreshes latest state instead of false success',
      () async {
        final repository = _CancellationRepository()..simulateReviewRace = true;
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.loadArtisanQuestAndTasks();
        final task = viewModel.artisanTaskById('delete-task')!;
        final request = viewModel.artisanTaskChangeRequests.firstWhere(
          (item) => item.id == 'delete-pending',
        );

        expect(await viewModel.cancelPendingTaskChange(task, request), isFalse);
        expect(
          viewModel.artisanTaskError,
          'This request has already been reviewed. Refreshing its latest status.',
        );
        expect(viewModel.pendingChangeForTask(task.id), isNull);
        expect(
          repository.tasks.singleWhere((item) => item.id == task.id).status,
          'APPROVED',
        );
      },
    );

    test(
      'double taps trigger one cancellation and repeated removal is safe',
      () async {
        final repository = _CancellationRepository();
        final gate = Completer<void>();
        repository.cancellationGate = gate;
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.loadArtisanQuestAndTasks();
        final task = viewModel.artisanTaskById('published-task')!;
        final request = viewModel.artisanTaskChangeRequests.firstWhere(
          (item) => item.id == 'edit-pending',
        );

        final first = viewModel.cancelPendingTaskChange(task, request);
        await Future<void>.delayed(Duration.zero);
        expect(await viewModel.cancelPendingTaskChange(task, request), isFalse);
        expect(repository.deleteChangeCalls, 1);
        gate.complete();
        expect(await first, isTrue);

        repository.cancellationGate = null;
        expect(await viewModel.cancelPendingTaskChange(task, request), isFalse);
        expect(repository.deleteChangeCalls, 2);
        expect(viewModel.artisanTaskError, contains('already been reviewed'));
      },
    );
  });

  group('Cancellation ownership and UI contracts', () {
    test(
      'service verifies the complete owner chain before conditional deletion',
      () {
        final source = File(
          'lib/data/services/supabase_service.dart',
        ).readAsStringSync();

        expect(source, contains(".from('artisan_profiles')"));
        expect(source, contains(".eq('user_id', user.id)"));
        expect(source, contains(".from('quests')"));
        expect(source, contains("quest['artisan_id']"));
        expect(source, contains(".from('heritage_tasks')"));
        expect(source, contains("request['task_id']?.toString() != taskId"));
        expect(source, contains(".eq('is_system_task', false)"));
        expect(source, contains(".eq('status', normalizedStatus)"));
        expect(source, contains(".eq('status', status)"));
        expect(source, contains(".select('id')"));
        expect(source, contains('.maybeSingle()'));
      },
    );

    test('task-management UI exposes all required cancellation actions', () {
      final source = File(
        'lib/ui/artisan/artisan_heritage_task_management_view.dart',
      ).readAsStringSync();

      expect(source, contains('Cancel New Task Submission?'));
      expect(source, contains('Cancel Task Edit Request?'));
      expect(source, contains('Cancel Task Deletion Request?'));
      expect(source, contains('Remove Rejected Request?'));
      expect(source, contains("const Text('Cancel Request')"));
      expect(source, contains("const Text('Dismiss Request')"));
      expect(source, contains("'Edit & Resubmit'"));
      expect(source, contains("'Remove Request'"));
      expect(source, contains("label: 'Retry'"));
    });
  });
}

class _CancellationRepository extends GamificationRepository {
  final quest = Quest(
    id: 'quest-1',
    artisanId: 'artisan-1',
    title: 'Cultural Quest',
    description: 'Learn a traditional craft.',
    category: 'Guided Workshop',
    geofenceRadiusMeters: 50,
    stampTitle: 'Craft Stamp',
    stampImageUrl: '',
    status: 'APPROVED',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  late final List<HeritageTask> tasks = [
    _task('new-pending', status: 'PENDING_APPROVAL'),
    _task('new-rejected', status: 'REJECTED'),
    _task('published-task'),
    _task('delete-task'),
    _task('edit-rejected-task'),
    _task('delete-rejected-task'),
    _task('system-task', isSystemTask: true),
  ];

  late final List<HeritageTaskChangeRequest> requests = [
    _request(
      id: 'edit-pending',
      taskId: 'published-task',
      type: 'EDIT',
      status: 'PENDING_APPROVAL',
    ),
    _request(
      id: 'delete-pending',
      taskId: 'delete-task',
      type: 'DELETE',
      status: 'PENDING_APPROVAL',
    ),
    _request(
      id: 'edit-rejected',
      taskId: 'edit-rejected-task',
      type: 'EDIT',
      status: 'REJECTED',
    ),
    _request(
      id: 'delete-rejected',
      taskId: 'delete-rejected-task',
      type: 'DELETE',
      status: 'REJECTED',
    ),
  ];

  String? deletedNewTaskStatus;
  String? lastDeletedRequestType;
  String? lastDeletedRequestStatus;
  int deleteChangeCalls = 0;
  int touristHistoryMutationCalls = 0;
  bool simulateReviewRace = false;
  Completer<void>? cancellationGate;

  @override
  Future<Quest?> getQuestForCurrentArtisan() async => quest;

  @override
  Future<List<HeritageTask>> getArtisanHeritageTasks(String questId) async =>
      List<HeritageTask>.of(tasks);

  @override
  Future<List<HeritageTaskChangeRequest>> getHeritageTaskChangeRequests(
    List<String> taskIds,
  ) async => List<HeritageTaskChangeRequest>.of(requests);

  @override
  Future<void> deleteUnapprovedHeritageTask({
    required String taskId,
    required String expectedStatus,
  }) async {
    deletedNewTaskStatus = expectedStatus;
    final index = tasks.indexWhere(
      (task) =>
          task.id == taskId &&
          !task.isSystemTask &&
          task.status.toUpperCase() == expectedStatus.toUpperCase(),
    );
    if (index < 0) {
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }
    tasks.removeAt(index);
  }

  @override
  Future<void> deleteHeritageTaskChangeRequest({
    required String requestId,
    required String taskId,
    required String expectedRequestType,
    required String expectedStatus,
  }) async {
    deleteChangeCalls++;
    await cancellationGate?.future;
    final index = requests.indexWhere(
      (request) =>
          request.id == requestId &&
          request.taskId == taskId &&
          request.requestType.toUpperCase() ==
              expectedRequestType.toUpperCase() &&
          request.status.toUpperCase() == expectedStatus.toUpperCase(),
    );
    if (simulateReviewRace && index >= 0) {
      requests[index] = _request(
        id: requestId,
        taskId: taskId,
        type: expectedRequestType,
        status: 'APPROVED',
      );
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }
    if (index < 0) {
      throw StateError(
        'This request has already been reviewed. Refreshing its latest status.',
      );
    }
    lastDeletedRequestType = expectedRequestType;
    lastDeletedRequestStatus = expectedStatus;
    requests.removeAt(index);
  }
}

HeritageTask _task(
  String id, {
  String status = 'APPROVED',
  bool isSystemTask = false,
}) => HeritageTask(
  id: id,
  questId: 'quest-1',
  title: 'Task $id',
  isRequired: true,
  xpReward: 50,
  sortOrder: isSystemTask ? 1 : 3,
  createdAt: DateTime.utc(2026, 1, 1),
  status: status,
  rejectionReason: status == 'REJECTED' ? 'Please revise.' : null,
  reviewedAt: null,
  reviewedBy: null,
  isSystemTask: isSystemTask,
  isArchived: false,
);

HeritageTaskChangeRequest _request({
  required String id,
  required String taskId,
  required String type,
  required String status,
}) => HeritageTaskChangeRequest(
  id: id,
  taskId: taskId,
  requestType: type,
  proposedTitle: type == 'EDIT' ? 'Updated task' : null,
  proposedIsRequired: type == 'EDIT' ? false : null,
  proposedXpReward: type == 'EDIT' ? 75 : null,
  status: status,
  rejectionReason: status == 'REJECTED' ? 'Not approved.' : null,
  submittedAt: DateTime.utc(2026, 9, 10),
  reviewedAt: status == 'PENDING_APPROVAL' ? null : DateTime.utc(2026, 9, 11),
  reviewedBy: status == 'PENDING_APPROVAL' ? null : 'admin-1',
);
