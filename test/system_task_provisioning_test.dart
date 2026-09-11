import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/system_task_provisioning.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Default artisan system-task policy', () {
    test('defines the two canonical required journey slots', () {
      expect(DefaultSystemTaskPolicy.specifications, hasLength(2));
      expect(
        DefaultSystemTaskPolicy.specifications.map(
          (task) => (task.title, task.sortOrder, task.xpReward),
        ),
        [('Go to the workshop', 1, 50), ('Stay for 15 minutes', 2, 50)],
      );
    });

    test('missing tasks are inserted and existing slots are normalized', () {
      final emptyPlan = DefaultSystemTaskPolicy.plan(const []);
      expect(emptyPlan.insertions, hasLength(2));
      expect(emptyPlan.taskIdsToNormalize, isEmpty);

      final partialPlan = DefaultSystemTaskPolicy.plan(const [
        ExistingQuestTaskSlot(
          id: 'arrival',
          sortOrder: 1,
          isSystemTask: true,
          isArchived: false,
        ),
      ]);
      expect(partialPlan.insertions.single.sortOrder, 2);
      expect(partialPlan.taskIdsToNormalize, {1: 'arrival'});
    });

    test('a repeated approval inserts no duplicate system tasks', () {
      final plan = DefaultSystemTaskPolicy.plan(const [
        ExistingQuestTaskSlot(
          id: 'arrival',
          sortOrder: 1,
          isSystemTask: true,
          isArchived: false,
        ),
        ExistingQuestTaskSlot(
          id: 'dwell',
          sortOrder: 2,
          isSystemTask: true,
          isArchived: false,
        ),
      ]);

      expect(plan.insertions, isEmpty);
      expect(plan.taskIdsToNormalize, {1: 'arrival', 2: 'dwell'});
    });

    test('custom tasks are never converted into system tasks', () {
      expect(
        () => DefaultSystemTaskPolicy.plan(const [
          ExistingQuestTaskSlot(
            id: 'custom',
            sortOrder: 1,
            isSystemTask: false,
            isArchived: false,
          ),
        ]),
        throwsStateError,
      );
    });

    test('duplicate canonical slots stop approval', () {
      expect(
        () => DefaultSystemTaskPolicy.plan(const [
          ExistingQuestTaskSlot(
            id: 'arrival-1',
            sortOrder: 1,
            isSystemTask: true,
            isArchived: false,
          ),
          ExistingQuestTaskSlot(
            id: 'arrival-2',
            sortOrder: 1,
            isSystemTask: true,
            isArchived: true,
          ),
        ]),
        throwsStateError,
      );
    });
  });

  group('Artisan approval state', () {
    test('failed provisioning keeps the artisan pending', () async {
      final repository = _ApprovalRepository(failure: StateError('No quest'));
      final viewModel = ModerationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.refreshAllData();
      viewModel.addPendingArtisan(_pendingArtisan);

      expect(await viewModel.approveArtisan(_pendingArtisan.id), isFalse);
      expect(viewModel.filteredArtisans, contains(_pendingArtisan));
      expect(viewModel.activeArtisanMasters, isEmpty);
      expect(viewModel.artisanApprovalError, contains('No quest'));
    });

    test('rapid repeated approval starts one persistence request', () async {
      final completion = Completer<void>();
      final repository = _ApprovalRepository(
        completion: completion,
        failure: StateError('Provisioning stopped for test'),
      );
      final viewModel = ModerationViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.refreshAllData();
      viewModel.addPendingArtisan(_pendingArtisan);

      final first = viewModel.approveArtisan(_pendingArtisan.id);
      expect(viewModel.isApprovingArtisan(_pendingArtisan.id), isTrue);
      expect(await viewModel.approveArtisan(_pendingArtisan.id), isFalse);
      expect(repository.updateCalls, 1);

      completion.complete();
      expect(await first, isFalse);
      expect(viewModel.filteredArtisans, contains(_pendingArtisan));
    });
  });

  test('approval provisions tasks before changing account status', () {
    final source = File(
      'lib/data/services/supabase_service.dart',
    ).readAsStringSync();
    final start = source.indexOf('Future<void> updateArtisanStatusInDb(');
    final end = source.indexOf('Future<void> signOut()', start);
    final approvalFlow = source.substring(start, end);

    expect(
      approvalFlow.indexOf('await _ensureDefaultSystemTasksForApproval('),
      lessThan(approvalFlow.indexOf("client.rpc(")),
    );
    expect(approvalFlow, contains('if (isApproval) {'));
    expect(
      source,
      contains(".inFilter('status', const ['PENDING_APPROVAL', 'APPROVED'])"),
    );
    expect(source, isNot(contains("task['title'] == defaultTask['title']")));
  });
}

const _pendingArtisan = PendingArtisanProfile(
  id: 'artisan-pending',
  name: 'Test Heritage Studio',
  craftCategory: 'Woodwork',
  state: 'Melaka',
  dateSubmitted: '2026-09-10T10:00:00Z',
  imageUrl: '',
  email: 'artisan@example.com',
  experience: '10 years',
  phone: '+60123456789',
);

class _ApprovalRepository extends UserRepository {
  final Object? failure;
  final Completer<void>? completion;
  int updateCalls = 0;

  _ApprovalRepository({this.failure, this.completion});

  @override
  Future<List<Map<String, dynamic>>> getPendingArtisans() async => const [];

  @override
  Future<List<ActiveArtisanMaster>> getActiveArtisans() async => const [];

  @override
  Future<List<UserModel>> getAllUsers() async => const [];

  @override
  Future<void> updateArtisanStatus({
    required String email,
    required String newStatus,
    required String newRole,
    bool updateArtisanProfileOnly = false,
    bool ensureSystemTasks = false,
    String? suspensionReason,
    String? rejectionReason,
  }) async {
    updateCalls++;
    if (failure != null) throw failure!;
    if (completion != null) await completion!.future;
  }
}
