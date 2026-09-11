import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/ui/gamification/quest_detail_view.dart';
import 'package:warisan_kita/ui/gamification/quest_view.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

Future<void> openWorkshopQuest(
  BuildContext context,
  WorkshopLocation workshop,
) async {
  final navigator = Navigator.of(context);
  final viewModel = context.read<GamificationViewModel>();
  final browsingViewModel = GamificationViewModel(
    repository: context.read<GamificationRepository>(),
  );
  final loadingRoute = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  unawaited(navigator.push(loadingRoute));
  try {
    await viewModel.loadActiveQuestState();
    await browsingViewModel.loadQuestsForArtisan(workshop.id);
  } finally {
    if (loadingRoute.isActive) navigator.removeRoute(loadingRoute);
  }

  try {
    if (!context.mounted) return;
    if (browsingViewModel.error != null) {
      await _showQuestUnavailable(context, browsingViewModel.error!);
      return;
    }

    final quests = browsingViewModel.availableQuests;
    if (quests.isEmpty) {
      await _showQuestUnavailable(
        context,
        'This studio does not currently have an approved cultural quest.',
      );
      return;
    }

    if (quests.length > 1) {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<GamificationViewModel>.value(
            value: browsingViewModel,
            child: QuestView(
              workshop: workshop,
              questsAlreadyLoaded: true,
              onQuestSelected: (selectorContext, quest) => _openSelectedQuest(
                selectorContext,
                workshop,
                quest,
                viewModel,
              ),
            ),
          ),
          settings: const RouteSettings(name: 'workshop-quest-selection'),
        ),
      );
      return;
    }

    await _openSelectedQuest(context, workshop, quests.single, viewModel);
  } finally {
    browsingViewModel.dispose();
  }
}

Future<void> _openSelectedQuest(
  BuildContext context,
  WorkshopLocation workshop,
  Quest quest,
  GamificationViewModel primaryViewModel,
) async {
  final activeQuest = primaryViewModel.activeQuest;
  final locallyActiveQuestId =
      primaryViewModel.questProgressStatus?.toUpperCase() == 'IN_PROGRESS'
      ? primaryViewModel.selectedQuest?.id
      : null;
  final protectedActiveQuestId = activeQuest?.questId ?? locallyActiveQuestId;
  final needsIsolatedPreview =
      protectedActiveQuestId != null && protectedActiveQuestId != quest.id;

  if (!needsIsolatedPreview) {
    await primaryViewModel.selectQuest(quest);
    if (!context.mounted) return;
    if (primaryViewModel.error != null) {
      await _showQuestUnavailable(context, primaryViewModel.error!);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestDetailView(quest: quest, workshop: workshop),
      ),
    );
    return;
  }

  final previewViewModel = GamificationViewModel(
    repository: context.read<GamificationRepository>(),
  );
  try {
    await previewViewModel.loadActiveQuestState();
    await previewViewModel.selectQuest(quest);
    if (!context.mounted) return;
    if (previewViewModel.error != null) {
      await _showQuestUnavailable(context, previewViewModel.error!);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<GamificationViewModel>.value(
          value: previewViewModel,
          child: QuestDetailView(quest: quest, workshop: workshop),
        ),
      ),
    );
  } finally {
    previewViewModel.dispose();
  }
}

Future<void> _showQuestUnavailable(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Quest unavailable'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
