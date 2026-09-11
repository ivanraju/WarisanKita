import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/badge.dart' show EarnedTaskXp;
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/task_completion_result.dart';

void main() {
  group('Task XP award contract', () {
    test(
      'historical XP remains immutable after the current reward is edited',
      () {
        final historicalAward = EarnedTaskXp.fromMap({
          'task_id': 'task-1',
          'xp_awarded': 100,
          'awarded_at': '2026-09-01T00:00:00Z',
          'heritage_tasks': {
            'quest_id': 'quest-1',
            'is_system_task': false,
            'sort_order': 3,
            'quests': {'artisan_id': 'artisan-1'},
          },
        });
        final currentTask = HeritageTask.fromMap({
          'id': 'task-1',
          'quest_id': 'quest-1',
          'title': 'Carve a motif',
          'is_required': true,
          'xp_reward': 50,
          'sort_order': 3,
          'created_at': '2026-08-01T00:00:00Z',
          'status': 'APPROVED',
          'rejection_reason': null,
          'reviewed_at': null,
          'reviewed_by': null,
          'is_system_task': false,
          'is_archived': false,
        });

        expect(historicalAward.xpAwarded, 100);
        expect(currentTask.xpReward, 50);
      },
    );

    test(
      'completion paths retain idempotency guards and do not award XP in Flutter',
      () {
        final source = File(
          'lib/data/services/supabase_service.dart',
        ).readAsStringSync();

        expect(source, contains(".eq('is_completed', false)"));
        expect(source, contains("existing?['is_completed'] == true"));
        expect(source, contains('_taskCompletionResult'));
        expect(source, contains("onConflict: 'user_id,quest_id'"));
        expect(source, contains('ignoreDuplicates: true'));
        expect(source, isNot(contains(".from('user_task_xp_awards').insert")));
        expect(source, isNot(contains(".from('user_task_xp_awards').upsert")));
        expect(source, isNot(contains(".from('user_experience').update")));
      },
    );

    test('completion result uses recorded XP and permits an unknown award', () {
      final recorded = TaskCompletionResult.fromMap({
        'progress': {
          'user_id': 'tourist-1',
          'task_id': 'task-1',
          'is_completed': true,
          'progress_seconds': 0,
        },
        'xp_awarded': 50,
      });
      final unavailable = TaskCompletionResult.fromMap({
        'progress': {
          'user_id': 'tourist-1',
          'task_id': 'task-1',
          'is_completed': true,
          'progress_seconds': 0,
        },
        'xp_awarded': null,
      });

      expect(recorded.xpAwarded, 50);
      expect(unavailable.xpAwarded, isNull);
    });
  });
}
