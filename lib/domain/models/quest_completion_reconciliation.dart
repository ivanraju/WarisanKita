enum QuestCompletionReconciliationDisposition {
  noStampedProgress,
  alreadyConsistent,
  reconciled,
  locallyCompletedWithWarning,
}

class QuestCompletionReconciliationResult {
  final QuestCompletionReconciliationDisposition disposition;
  final Set<String> stampedQuestIds;
  final Set<String> reconciledQuestIds;
  final List<String> warnings;

  const QuestCompletionReconciliationResult({
    required this.disposition,
    this.stampedQuestIds = const {},
    this.reconciledQuestIds = const {},
    this.warnings = const [],
  });

  bool get hasWarning => warnings.isNotEmpty;

  factory QuestCompletionReconciliationResult.fromMap(
    Map<String, dynamic> map,
  ) {
    final stamped = Set<String>.unmodifiable(
      List<Object?>.from(map['stamped_quest_ids'] as List? ?? const [])
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty),
    );
    final reconciled = Set<String>.unmodifiable(
      List<Object?>.from(map['reconciled_quest_ids'] as List? ?? const [])
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty),
    );
    final warnings = List<String>.unmodifiable(
      List<Object?>.from(map['warnings'] as List? ?? const [])
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty),
    );
    final disposition = switch (map['disposition']?.toString()) {
      'already_consistent' =>
        QuestCompletionReconciliationDisposition.alreadyConsistent,
      'reconciled' => QuestCompletionReconciliationDisposition.reconciled,
      'locally_completed_with_warning' =>
        QuestCompletionReconciliationDisposition.locallyCompletedWithWarning,
      _ => QuestCompletionReconciliationDisposition.noStampedProgress,
    };
    return QuestCompletionReconciliationResult(
      disposition: disposition,
      stampedQuestIds: stamped,
      reconciledQuestIds: reconciled,
      warnings: warnings,
    );
  }
}
