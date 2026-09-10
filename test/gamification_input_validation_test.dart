import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gamification management input validation', () {
    test(
      'published Potential XP excludes pending and archived tasks',
      () async {
        final repository = _ManagementRepository();
        repository.tasks.addAll([
          _task(
            'pending-task',
            'Pending activity',
            5,
            xpReward: 300,
            status: 'PENDING_APPROVAL',
          ),
          _task(
            'archived-task',
            'Archived activity',
            6,
            xpReward: 400,
            isArchived: true,
          ),
        ]);
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.loadArtisanQuestAndTasks();

        expect(viewModel.artisanTasks, hasLength(3));
        expect(viewModel.artisanTotalPotentialXp, 100);
      },
    );

    test('task XP is restricted to the inclusive 0 to 500 range', () async {
      final repository = _ManagementRepository();
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadArtisanQuestAndTasks();

      expect(
        await viewModel.addHeritageTask(
          title: 'Valid new activity',
          isRequired: true,
          xpReward: 501,
        ),
        isFalse,
      );
      expect(viewModel.artisanTaskError, contains('between 0 and 500'));
      expect(repository.addCalls, 0);

      expect(
        await viewModel.addHeritageTask(
          title: 'Maximum reward activity',
          isRequired: false,
          xpReward: 500,
        ),
        isTrue,
      );
      expect(repository.addCalls, 1);
    });

    test(
      'task titles reject excessive length and control characters',
      () async {
        final repository = _ManagementRepository();
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.loadArtisanQuestAndTasks();

        expect(
          await viewModel.addHeritageTask(
            title: 'A' * 81,
            isRequired: true,
            xpReward: 50,
          ),
          isFalse,
        );
        expect(viewModel.artisanTaskError, contains('80 characters or fewer'));

        expect(
          await viewModel.addHeritageTask(
            title: 'Invalid\u0007title',
            isRequired: true,
            xpReward: 50,
          ),
          isFalse,
        );
        expect(viewModel.artisanTaskError, contains('control characters'));
        expect(repository.addCalls, 0);
      },
    );

    test('new tasks reject case and whitespace equivalent titles', () async {
      final repository = _ManagementRepository();
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadArtisanQuestAndTasks();

      expect(
        await viewModel.addHeritageTask(
          title: '  CLAY   shaping  ',
          isRequired: true,
          xpReward: 50,
        ),
        isFalse,
      );
      expect(viewModel.artisanTaskError, contains('already exists'));
      expect(repository.addCalls, 0);
    });

    test(
      'task edits exclude themselves but reject another task title',
      () async {
        final repository = _ManagementRepository();
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.loadArtisanQuestAndTasks();
        final clayTask = viewModel.artisanTasks.first;

        expect(
          await viewModel.requestHeritageTaskEdit(
            task: clayTask,
            title: 'weaving',
            isRequired: clayTask.isRequired,
            xpReward: 75,
          ),
          isFalse,
        );
        expect(viewModel.artisanTaskError, contains('already exists'));
        expect(repository.editCalls, 0);

        expect(
          await viewModel.requestHeritageTaskEdit(
            task: clayTask,
            title: ' clay   shaping ',
            isRequired: clayTask.isRequired,
            xpReward: 75,
          ),
          isTrue,
        );
        expect(repository.editCalls, 1);
      },
    );
  });
}

class _ManagementRepository extends GamificationRepository {
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
    _task('task-1', 'Clay Shaping', 3),
    _task('task-2', 'Weaving', 4),
  ];

  int addCalls = 0;
  int editCalls = 0;

  @override
  Future<Quest?> getQuestForCurrentArtisan() async => quest;

  @override
  Future<List<HeritageTask>> getArtisanHeritageTasks(String questId) async =>
      tasks;

  @override
  Future<List<HeritageTaskChangeRequest>> getHeritageTaskChangeRequests(
    List<String> taskIds,
  ) async => const [];

  @override
  Future<HeritageTask> addHeritageTask({
    required String questId,
    required String title,
    required bool isRequired,
    required int xpReward,
    required int sortOrder,
  }) async {
    addCalls++;
    return _task('added', title, sortOrder, xpReward: xpReward);
  }

  @override
  Future<HeritageTaskChangeRequest> requestHeritageTaskEdit({
    required String taskId,
    required String proposedTitle,
    required bool proposedIsRequired,
    required int proposedXpReward,
  }) async {
    editCalls++;
    return HeritageTaskChangeRequest(
      id: 'request-$editCalls',
      taskId: taskId,
      requestType: 'EDIT',
      proposedTitle: proposedTitle,
      proposedIsRequired: proposedIsRequired,
      proposedXpReward: proposedXpReward,
      status: 'PENDING_APPROVAL',
      rejectionReason: null,
      submittedAt: DateTime.utc(2026, 9, 10),
      reviewedAt: null,
      reviewedBy: null,
    );
  }
}

HeritageTask _task(
  String id,
  String title,
  int sortOrder, {
  int xpReward = 50,
  String status = 'APPROVED',
  bool isArchived = false,
}) => HeritageTask(
  id: id,
  questId: 'quest-1',
  title: title,
  isRequired: true,
  xpReward: xpReward,
  sortOrder: sortOrder,
  createdAt: DateTime.utc(2026, 1, 1),
  status: status,
  rejectionReason: null,
  reviewedAt: null,
  reviewedBy: null,
  isSystemTask: false,
  isArchived: isArchived,
);
