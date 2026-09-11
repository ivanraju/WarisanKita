class DefaultSystemTaskSpecification {
  final String title;
  final int sortOrder;
  final int xpReward;

  const DefaultSystemTaskSpecification({
    required this.title,
    required this.sortOrder,
    this.xpReward = 50,
  });
}

class ExistingQuestTaskSlot {
  final String id;
  final int? sortOrder;
  final bool isSystemTask;
  final bool isArchived;

  const ExistingQuestTaskSlot({
    required this.id,
    required this.sortOrder,
    required this.isSystemTask,
    required this.isArchived,
  });
}

class SystemTaskProvisioningPlan {
  final List<DefaultSystemTaskSpecification> insertions;
  final Map<int, String> taskIdsToNormalize;

  const SystemTaskProvisioningPlan({
    required this.insertions,
    required this.taskIdsToNormalize,
  });
}

class DefaultSystemTaskPolicy {
  static const specifications = <DefaultSystemTaskSpecification>[
    DefaultSystemTaskSpecification(title: 'Go to the workshop', sortOrder: 1),
    DefaultSystemTaskSpecification(title: 'Stay for 15 minutes', sortOrder: 2),
  ];

  static SystemTaskProvisioningPlan plan(
    Iterable<ExistingQuestTaskSlot> existingTasks,
  ) {
    final tasks = existingTasks.toList(growable: false);
    final insertions = <DefaultSystemTaskSpecification>[];
    final taskIdsToNormalize = <int, String>{};

    for (final specification in specifications) {
      final matchingSystemTasks = tasks
          .where(
            (task) =>
                task.isSystemTask && task.sortOrder == specification.sortOrder,
          )
          .toList(growable: false);
      if (matchingSystemTasks.length > 1) {
        throw StateError(
          'Approval cannot continue because system task order '
          '${specification.sortOrder} is duplicated.',
        );
      }

      if (matchingSystemTasks.isEmpty) {
        final occupiedByCustomTask = tasks.any(
          (task) =>
              !task.isSystemTask &&
              !task.isArchived &&
              task.sortOrder == specification.sortOrder,
        );
        if (occupiedByCustomTask) {
          throw StateError(
            'Approval cannot continue because task order '
            '${specification.sortOrder} is occupied by a custom task.',
          );
        }
        insertions.add(specification);
      } else {
        taskIdsToNormalize[specification.sortOrder] =
            matchingSystemTasks.single.id;
      }
    }

    return SystemTaskProvisioningPlan(
      insertions: List.unmodifiable(insertions),
      taskIdsToNormalize: Map.unmodifiable(taskIdsToNormalize),
    );
  }
}
