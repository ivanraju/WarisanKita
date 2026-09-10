import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/active_quest.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/quest_participation.dart';
import 'package:warisan_kita/domain/models/task_progress.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Active quest selection', () {
    test('no active rows produces an unlocked state', () {
      const state = ActiveQuestState.empty();

      expect(state.hasActiveQuest, isFalse);
      expect(state.hasDataIntegrityWarning, isFalse);
    });

    test('most recent valid start wins and older rows are reported', () {
      final state = ActiveQuestState.fromRows([
        _activeRow('older', '2026-09-01T09:00:00Z'),
        _activeRow('malformed', 'not-a-date'),
        _activeRow('newest', '2026-09-02T09:00:00+00:00'),
      ]);

      expect(state.activeQuest!.questId, 'newest');
      expect(state.conflictingQuests, hasLength(2));
      expect(state.warningMessage, contains('Multiple active journeys'));
    });

    test('malformed dates have a deterministic quest-id fallback', () {
      final state = ActiveQuestState.fromRows([
        _activeRow('quest-b', null),
        _activeRow('quest-a', 'invalid'),
      ]);

      expect(state.activeQuest!.questId, 'quest-a');
      expect(state.hasDataIntegrityWarning, isTrue);
    });
  });

  group('Gamification active-quest guard', () {
    test('no active quest permits a normal start', () async {
      final repository = _QuestFlowRepository(
        initialActiveState: const ActiveQuestState.empty(),
        startResult: _successfulStart(QuestStartDisposition.started),
      );
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.selectQuest(_quest('quest-1'));
      final started = await viewModel.startSelectedQuest();

      expect(started, isTrue);
      expect(repository.startCalls, 1);
      expect(repository.arrivalCompletionCalls, 1);
      expect(repository.timedStartCalls, 1);
      expect(viewModel.activeQuest!.questId, 'quest-1');
    });

    test(
      'same active quest resumes without replaying arrival or dwell start',
      () async {
        final repository = _QuestFlowRepository(
          initialActiveState: _stateFor('quest-1'),
          startResult: _successfulStart(QuestStartDisposition.resumed),
          progressRows: [
            _progress('arrival', completed: true),
            _progress('dwell', progressSeconds: 120),
          ],
        );
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.selectQuest(_quest('quest-1'));
        final resumed = await viewModel.startSelectedQuest();

        expect(resumed, isTrue);
        expect(repository.startCalls, 1);
        expect(repository.arrivalCompletionCalls, 0);
        expect(repository.timedStartCalls, 0);
        expect(viewModel.displayedDwellSeconds, 120);
      },
    );

    test('a different active quest blocks all task side effects', () async {
      final activeState = _stateFor('quest-2');
      final repository = _QuestFlowRepository(
        initialActiveState: activeState,
        startResult: QuestStartResult(
          disposition: QuestStartDisposition.blockedByOtherQuest,
          participation: activeState.activeQuest!.participation,
          activeState: activeState,
        ),
      );
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.selectQuest(_quest('quest-1'));
      final started = await viewModel.startSelectedQuest();

      expect(started, isFalse);
      expect(viewModel.canStartQuest('quest-1'), isFalse);
      expect(viewModel.canStartQuest('quest-2'), isTrue);
      expect(viewModel.startQuestError, contains('Quest quest-2'));
      expect(repository.arrivalCompletionCalls, 0);
      expect(repository.timedStartCalls, 0);
    });

    test('rapid double tap sends only one start request', () async {
      final pending = Completer<QuestStartResult>();
      final repository = _QuestFlowRepository(
        initialActiveState: const ActiveQuestState.empty(),
        startLoader: () => pending.future,
      );
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.selectQuest(_quest('quest-1'));
      final first = viewModel.startSelectedQuest();
      final second = await viewModel.startSelectedQuest();

      expect(second, isFalse);
      expect(repository.startCalls, 1);
      pending.complete(_successfulStart(QuestStartDisposition.started));
      expect(await first, isTrue);
      expect(repository.startCalls, 1);
    });

    test('restart restoration exposes the persisted active quest', () async {
      final repository = _QuestFlowRepository(
        initialActiveState: _stateFor('quest-2'),
        startResult: _successfulStart(QuestStartDisposition.started),
      );
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.loadActiveQuestState();

      expect(viewModel.hasActiveQuest, isTrue);
      expect(viewModel.activeQuest!.questId, 'quest-2');
      expect(viewModel.canStartQuest('quest-1'), isFalse);
    });

    test(
      'restored journey stays paused until the tourist explicitly resumes',
      () async {
        final qrTask = HeritageTask(
          id: 'qr-task',
          questId: 'quest-1',
          title: 'Meet the artisan',
          isRequired: true,
          xpReward: 50,
          sortOrder: 3,
          createdAt: DateTime.utc(2026, 8, 1),
          status: 'APPROVED',
          rejectionReason: null,
          reviewedAt: null,
          reviewedBy: null,
          isSystemTask: false,
          isArchived: false,
        );
        final repository = _QuestFlowRepository(
          initialActiveState: _stateFor('quest-1'),
          startResult: _successfulStart(QuestStartDisposition.resumed),
          progressRows: [
            _progress('arrival', completed: true),
            _progress('dwell', completed: true, progressSeconds: 900),
          ],
          heritageTasks: [
            _task(id: 'arrival', sortOrder: 1),
            _task(id: 'dwell', sortOrder: 2),
            qrTask,
          ],
        );
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.selectQuest(_quest('quest-1'));
        await viewModel.handleQuestProximityChanged(true);

        expect(viewModel.requiresJourneyResume, isTrue);
        expect(viewModel.canResumeDwellTracking, isTrue);
        expect(viewModel.canVerifyTaskWithQr(qrTask), isFalse);
        expect(viewModel.qrVerificationLabel(qrTask), 'Resume Quest to Scan');

        expect(await viewModel.resumeSelectedQuest(), isTrue);
        expect(viewModel.requiresJourneyResume, isFalse);
        expect(viewModel.canVerifyTaskWithQr(qrTask), isTrue);
        expect(repository.timedStartCalls, 0);
      },
    );

    test('completed active quest refresh releases the start lock', () async {
      final repository = _QuestFlowRepository(
        initialActiveState: _stateFor('quest-1'),
        startResult: _successfulStart(QuestStartDisposition.started),
      );
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.loadActiveQuestState();
      expect(viewModel.canStartQuest('quest-2'), isFalse);

      repository.activeState = const ActiveQuestState.empty();
      await viewModel.loadActiveQuestState();

      expect(viewModel.hasActiveQuest, isFalse);
      expect(viewModel.canStartQuest('quest-2'), isTrue);
    });

    test('running or paused dwell state cannot unlock another quest', () async {
      final repository = _QuestFlowRepository(
        initialActiveState: _stateFor('quest-1'),
        startResult: _successfulStart(QuestStartDisposition.resumed),
        progressRows: [
          _progress('arrival', completed: true),
          _progress(
            'dwell',
            progressSeconds: 300,
            trackingStartedAt: DateTime.now().toUtc(),
          ),
        ],
      );
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.selectQuest(_quest('quest-1'));

      expect(viewModel.canStartQuest('quest-2'), isFalse);
      expect(viewModel.displayedDwellSeconds, greaterThanOrEqualTo(300));
    });

    test('re-entering range requires an explicit resume tap', () async {
      final repository = _QuestFlowRepository(
        initialActiveState: const ActiveQuestState.empty(),
        startResult: _successfulStart(QuestStartDisposition.started),
      );
      final viewModel = GamificationViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.selectQuest(_quest('quest-1'));
      expect(await viewModel.startSelectedQuest(), isTrue);
      expect(viewModel.isDwellTracking, isTrue);
      expect(repository.timedStartCalls, 1);

      await viewModel.handleQuestProximityChanged(false);
      expect(viewModel.isDwellTracking, isFalse);
      expect(viewModel.canResumeDwellTracking, isFalse);
      expect(repository.pauseCalls, 1);

      await viewModel.handleQuestProximityChanged(true);
      expect(viewModel.isDwellTracking, isFalse);
      expect(viewModel.canResumeDwellTracking, isTrue);
      expect(repository.timedStartCalls, 1);

      expect(await viewModel.resumeSelectedQuest(), isTrue);
      expect(viewModel.isDwellTracking, isTrue);
      expect(viewModel.canResumeDwellTracking, isFalse);
      expect(repository.timedStartCalls, 2);
    });

    test(
      'bonus completion is blocked when another device has an active quest',
      () async {
        final repository = _QuestFlowRepository(
          initialActiveState: _stateFor('quest-2'),
          startResult: _successfulStart(QuestStartDisposition.started),
          participation: QuestParticipation(
            status: 'COMPLETED',
            startedAt: DateTime.utc(2026, 8, 1),
          ),
          hasEarnedStamp: true,
          heritageTasks: [_bonusTask()],
        );
        final viewModel = GamificationViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.selectQuest(_quest('quest-1'));
        final bonusTask = viewModel.heritageTasks.single;

        expect(viewModel.isBonusTask(bonusTask), isTrue);
        expect(viewModel.canVerifyTaskWithQr(bonusTask), isTrue);

        final completed = await viewModel.verifyArtisanQrForTask(
          task: bonusTask,
          qrPayload: 'WK_ARTISAN:artisan-quest-1:secret',
        );

        expect(completed, isFalse);
        expect(repository.qrCompletionCalls, 0);
        expect(viewModel.activeQuest?.questId, 'quest-2');
        expect(
          viewModel.startQuestError,
          contains('Complete your active journey'),
        );
      },
    );
  });

  test(
    'service contract checks active rows before writing and uses auth user',
    () {
      final source = File(
        'lib/data/services/supabase_service.dart',
      ).readAsStringSync();
      final startOffset = source.indexOf(
        'Future<Map<String, dynamic>> startQuest',
      );
      final taskProgressOffset = source.indexOf(
        "from('task_progress')",
        startOffset,
      );
      final activeCheckOffset = source.indexOf(
        '_fetchActiveQuestProgressRowsForUser',
        startOffset,
      );
      final endOffset = source.indexOf(
        'Future<void> _ensureTaskProgressRows',
        startOffset,
      );
      final startMethodSource = source.substring(startOffset, endOffset);

      expect(startOffset, greaterThanOrEqualTo(0));
      expect(activeCheckOffset, greaterThan(startOffset));
      expect(activeCheckOffset, lessThan(taskProgressOffset));
      expect(startMethodSource, contains('_requireAuthenticatedUser'));
      expect(
        startMethodSource,
        contains('You must be signed in to start a quest.'),
      );
      expect(startMethodSource, isNot(contains('required String userId')));
    },
  );

  test('all task completion boundaries enforce the cross-quest guard', () {
    final source = File(
      'lib/data/services/supabase_service.dart',
    ).readAsStringSync();

    String methodSource(String signature, String nextSignature) {
      final start = source.indexOf(signature);
      final end = source.indexOf(nextSignature, start + signature.length);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      return source.substring(start, end);
    }

    expect(
      methodSource(
        'Future<Map<String, dynamic>> completeTask(String taskId)',
        'Future<Map<String, dynamic>> completeTaskWithArtisanQr',
      ),
      contains('_assertNoDifferentActiveQuest'),
    );
    expect(
      methodSource(
        'Future<Map<String, dynamic>> startTimedTask(String taskId)',
        'Future<Map<String, dynamic>> pauseTimedTask',
      ),
      contains('_assertNoDifferentActiveQuest'),
    );
    expect(
      methodSource(
        'Future<Map<String, dynamic>> completeTimedTask(String taskId)',
        'static const String _taskProgressColumns',
      ),
      contains('_assertNoDifferentActiveQuest'),
    );
  });
}

Map<String, dynamic> _activeRow(String questId, String? startedAt) => {
  'quest_id': questId,
  'quest_title': 'Quest $questId',
  'artisan_id': 'artisan-$questId',
  'studio_name': 'Studio $questId',
  'status': 'IN_PROGRESS',
  'started_at': startedAt,
};

ActiveQuestState _stateFor(String questId) =>
    ActiveQuestState.fromRows([_activeRow(questId, '2026-09-01T00:00:00Z')]);

QuestStartResult _successfulStart(QuestStartDisposition disposition) {
  final state = _stateFor('quest-1');
  return QuestStartResult(
    disposition: disposition,
    participation: state.activeQuest!.participation,
    activeState: state,
  );
}

Quest _quest(String id) => Quest(
  id: id,
  artisanId: 'artisan-$id',
  title: 'Quest $id',
  description: 'A guided heritage journey.',
  category: 'Woodwork',
  geofenceRadiusMeters: 50,
  stampTitle: 'Heritage Stamp',
  stampImageUrl: '',
  status: 'APPROVED',
  createdAt: DateTime.utc(2026, 8, 1),
);

HeritageTask _task({required String id, required int sortOrder}) =>
    HeritageTask(
      id: id,
      questId: 'quest-1',
      title: id,
      isRequired: true,
      xpReward: 50,
      sortOrder: sortOrder,
      createdAt: DateTime.utc(2026, 8, 1),
      status: 'APPROVED',
      rejectionReason: null,
      reviewedAt: null,
      reviewedBy: null,
      isSystemTask: true,
      isArchived: false,
    );

HeritageTask _bonusTask() => HeritageTask(
  id: 'bonus',
  questId: 'quest-1',
  title: 'Bonus activity',
  isRequired: true,
  xpReward: 50,
  sortOrder: 3,
  createdAt: DateTime.utc(2026, 9, 1),
  status: 'APPROVED',
  rejectionReason: null,
  reviewedAt: null,
  reviewedBy: null,
  isSystemTask: false,
  isArchived: false,
);

TaskProgress _progress(
  String taskId, {
  bool completed = false,
  int progressSeconds = 0,
  DateTime? trackingStartedAt,
}) => TaskProgress(
  userId: 'tourist-1',
  taskId: taskId,
  isCompleted: completed,
  completedAt: completed ? DateTime.utc(2026, 9, 1) : null,
  progressSeconds: progressSeconds,
  trackingStartedAt: trackingStartedAt,
);

class _QuestFlowRepository extends GamificationRepository {
  _QuestFlowRepository({
    required this.initialActiveState,
    QuestStartResult? startResult,
    Future<QuestStartResult> Function()? startLoader,
    this.progressRows = const [],
    this.participation,
    this.hasEarnedStamp = false,
    List<HeritageTask>? heritageTasks,
  }) : _startResult = startResult,
       _startLoader = startLoader,
       heritageTasks =
           heritageTasks ??
           [
             _task(id: 'arrival', sortOrder: 1),
             _task(id: 'dwell', sortOrder: 2),
           ];

  ActiveQuestState initialActiveState;
  ActiveQuestState get activeState => initialActiveState;
  set activeState(ActiveQuestState value) => initialActiveState = value;
  final QuestStartResult? _startResult;
  final Future<QuestStartResult> Function()? _startLoader;
  final List<TaskProgress> progressRows;
  final QuestParticipation? participation;
  final bool hasEarnedStamp;
  final List<HeritageTask> heritageTasks;
  int startCalls = 0;
  int arrivalCompletionCalls = 0;
  int timedStartCalls = 0;
  int pauseCalls = 0;
  int qrCompletionCalls = 0;

  @override
  Future<ActiveQuestState> getActiveQuestState() async => initialActiveState;

  @override
  Future<List<HeritageTask>> getHeritageTasks(String questId) async =>
      heritageTasks;

  @override
  Future<QuestParticipation?> getCurrentQuestParticipation(
    String questId,
  ) async {
    if (participation != null) return participation;
    if (initialActiveState.activeQuest?.questId != questId) return null;
    return initialActiveState.activeQuest!.participation;
  }

  @override
  Future<bool> hasEarnedQuestStamp(String questId) async => hasEarnedStamp;

  @override
  Future<List<TaskProgress>> getTaskProgress(List<String> taskIds) async =>
      progressRows;

  @override
  Future<QuestStartResult> startQuest({
    required String questId,
    required List<String> taskIds,
  }) {
    startCalls++;
    return _startLoader?.call() ?? Future.value(_startResult!);
  }

  @override
  Future<TaskProgress> completeTask(String taskId) async {
    arrivalCompletionCalls++;
    return _progress(taskId, completed: true);
  }

  @override
  Future<TaskProgress> completeTaskWithArtisanQr({
    required String questId,
    required String artisanId,
    required String taskId,
    required String qrPayload,
  }) async {
    qrCompletionCalls++;
    return _progress(taskId, completed: true);
  }

  @override
  Future<TaskProgress> startTimedTask(String taskId) async {
    timedStartCalls++;
    return _progress(taskId, trackingStartedAt: DateTime.now().toUtc());
  }

  @override
  Future<TaskProgress> pauseTimedTask({
    required String taskId,
    required int progressSeconds,
  }) async {
    pauseCalls++;
    return _progress(taskId, progressSeconds: progressSeconds);
  }
}
