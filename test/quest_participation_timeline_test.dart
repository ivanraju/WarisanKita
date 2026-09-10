import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/quest_participation.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';

class _TimelineJourneyService extends SupabaseService {
  _TimelineJourneyService(this.data);

  final Map<String, dynamic> data;

  @override
  Future<Map<String, dynamic>> fetchTouristMapJourneyData() async => data;
}

void main() {
  group('Quest participation timeline', () {
    test(
      'completed quest remains complete after a new required task',
      () async {
        final snapshot = await _snapshot(
          status: 'COMPLETED',
          startedAt: '2026-09-02T00:00:00Z',
          completedTaskIds: const ['original'],
          stampRows: const [
            {'quest_id': 'quest-1'},
          ],
        );
        final journey = snapshot.journeysByWorkshopId['artisan-1']!;

        expect(journey.state, WorkshopQuestState.completed);
        expect(journey.completedTaskCount, 1);
        expect(journey.totalTaskCount, 1);
        expect(journey.progress, 1);
        expect(snapshot.earnedStampCount, 1);
      },
    );

    test('an existing stamp permanently preserves completion', () async {
      final snapshot = await _snapshot(
        status: 'IN_PROGRESS',
        startedAt: '2026-09-02T00:00:00Z',
        completedTaskIds: const [],
        stampRows: const [
          {'quest_id': 'quest-1'},
          {'quest_id': 'quest-1'},
        ],
      );
      final journey = snapshot.journeysByWorkshopId['artisan-1']!;

      expect(journey.state, WorkshopQuestState.completed);
      expect(journey.progress, 1);
      expect(snapshot.earnedStampCount, 1);
    });

    test(
      'a later required task is bonus and does not block an existing participant',
      () async {
        final snapshot = await _snapshot(
          status: 'IN_PROGRESS',
          startedAt: '2026-09-02T00:00:00Z',
          completedTaskIds: const ['original'],
        );
        final journey = snapshot.journeysByWorkshopId['artisan-1']!;

        expect(journey.completedTaskCount, 1);
        expect(journey.totalTaskCount, 1);
        expect(journey.progress, 1);
      },
    );

    test(
      'participants who start later receive the latest requirements',
      () async {
        final snapshot = await _snapshot(
          status: 'IN_PROGRESS',
          startedAt: '2026-09-06T00:00:00Z',
          completedTaskIds: const ['original'],
        );
        final journey = snapshot.journeysByWorkshopId['artisan-1']!;

        expect(journey.completedTaskCount, 1);
        expect(journey.totalTaskCount, 2);
        expect(journey.progress, 0.5);
      },
    );

    test('tasks created after start are classified as bonus activities', () {
      final participation = QuestParticipation.fromMap({
        'status': 'IN_PROGRESS',
        'started_at': '2026-09-02T08:00:00+08:00',
      });
      final original = _heritageTask(
        id: 'original',
        createdAt: '2026-09-02T00:00:00Z',
      );
      final bonus = _heritageTask(
        id: 'bonus',
        createdAt: '2026-09-02T00:00:01Z',
      );

      expect(participation.isEffectiveRequiredTask(original), isTrue);
      expect(participation.isBonusTask(original), isFalse);
      expect(participation.isBonusTask(bonus), isTrue);
      expect(participation.isEffectiveRequiredTask(bonus), isFalse);
    });

    test('malformed and missing timestamps are handled conservatively', () {
      final malformedStart = QuestParticipation.fromMap({
        'status': 'IN_PROGRESS',
        'started_at': 'not-a-timestamp',
      });
      final malformedTask = _heritageTask(
        id: 'malformed',
        createdAt: 'not-a-timestamp',
      );

      expect(malformedStart.startedAt, isNull);
      expect(malformedStart.isBonusTask(malformedTask), isFalse);
      expect(malformedStart.isEffectiveRequiredTask(malformedTask), isTrue);
    });

    test('timestamp comparison normalizes offsets to UTC', () {
      final start = QuestParticipation.parseTimestamp(
        '2026-09-02T08:00:00+08:00',
      );
      final sameInstant = QuestParticipation.parseTimestamp(
        '2026-09-02T00:00:00Z',
      );
      final laterInstant = QuestParticipation.parseTimestamp(
        '2026-09-02T00:00:00.001Z',
      );

      expect(
        QuestParticipation.isCreatedAfterStart(
          taskCreatedAt: sameInstant,
          participantStartedAt: start,
        ),
        isFalse,
      );
      expect(
        QuestParticipation.isCreatedAfterStart(
          taskCreatedAt: laterInstant,
          participantStartedAt: start,
        ),
        isTrue,
      );
    });
  });
}

Future<TouristJourneySnapshot> _snapshot({
  required String status,
  required String startedAt,
  required List<String> completedTaskIds,
  List<Map<String, dynamic>> stampRows = const [],
}) {
  return GamificationRepository(
    service: _TimelineJourneyService({
      'total_xp': 0,
      'quests': [
        {
          'id': 'quest-1',
          'artisan_id': 'artisan-1',
          'title': 'Woodwork Journey',
          'category': 'Woodwork',
          'stamp_title': 'Woodwork Keeper',
          'stamp_image_url': '',
        },
      ],
      'tasks': [
        {
          'id': 'original',
          'quest_id': 'quest-1',
          'is_required': true,
          'xp_reward': 100,
          'created_at': '2026-09-01T00:00:00Z',
        },
        {
          'id': 'later',
          'quest_id': 'quest-1',
          'is_required': true,
          'xp_reward': 50,
          'created_at': '2026-09-05T00:00:00Z',
        },
      ],
      'quest_progress': [
        {'quest_id': 'quest-1', 'status': status, 'started_at': startedAt},
      ],
      'task_progress': [
        for (final taskId in completedTaskIds)
          {'task_id': taskId, 'is_completed': true},
      ],
      'stamps': stampRows,
      'xp_available': true,
      'stamps_available': true,
      'warnings': <String>[],
    }),
  ).getTouristJourneySnapshot();
}

HeritageTask _heritageTask({required String id, required String createdAt}) {
  return HeritageTask.fromMap({
    'id': id,
    'quest_id': 'quest-1',
    'title': id,
    'is_required': true,
    'xp_reward': 50,
    'sort_order': 3,
    'created_at': createdAt,
    'status': 'APPROVED',
    'rejection_reason': null,
    'reviewed_at': null,
    'reviewed_by': null,
    'is_system_task': false,
    'is_archived': false,
  });
}
