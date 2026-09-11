import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/active_quest.dart';
import 'package:warisan_kita/domain/models/quest_completion_reconciliation.dart';

void main() {
  test('stamped in-progress quest is excluded from the active lock', () {
    final reconciliation = QuestCompletionReconciliationResult.fromMap({
      'disposition': 'reconciled',
      'stamped_quest_ids': ['quest-1'],
      'reconciled_quest_ids': ['quest-1'],
      'warnings': <String>[],
    });
    final rows = [
      {
        'quest_id': 'quest-1',
        'status': 'IN_PROGRESS',
        'started_at': '2026-09-01T00:00:00Z',
      },
    ].where((row) => !reconciliation.stampedQuestIds.contains(row['quest_id']));

    expect(ActiveQuestState.fromRows(rows).hasActiveQuest, isFalse);
    expect(reconciliation.reconciledQuestIds, contains('quest-1'));
  });

  test('failed repair preserves local completion and exposes a warning', () {
    final reconciliation = QuestCompletionReconciliationResult.fromMap({
      'disposition': 'locally_completed_with_warning',
      'stamped_quest_ids': ['quest-1'],
      'reconciled_quest_ids': <String>[],
      'warnings': ['Your Passport stamp is safe.'],
    });
    final state = ActiveQuestState.fromRows(
      const [],
      reconciliationWarning: reconciliation.warnings.first,
    );

    expect(reconciliation.stampedQuestIds, contains('quest-1'));
    expect(state.hasActiveQuest, isFalse);
    expect(state.warningMessage, contains('stamp is safe'));
  });

  test('already-completed reconciliation is idempotent', () {
    final first = QuestCompletionReconciliationResult.fromMap({
      'disposition': 'already_consistent',
      'stamped_quest_ids': ['quest-1', 'quest-1'],
      'reconciled_quest_ids': <String>[],
      'warnings': <String>[],
    });
    final second = QuestCompletionReconciliationResult.fromMap({
      'disposition': 'already_consistent',
      'stamped_quest_ids': first.stampedQuestIds.toList(),
      'reconciled_quest_ids': <String>[],
      'warnings': <String>[],
    });

    expect(first.stampedQuestIds, {'quest-1'});
    expect(second.stampedQuestIds, first.stampedQuestIds);
    expect(second.hasWarning, isFalse);
  });
}
