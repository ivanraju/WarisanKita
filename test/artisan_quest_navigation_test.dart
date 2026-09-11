import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';

void main() {
  test('an unavailable studio action is labelled View Quest', () {
    const journey = WorkshopQuestJourney(
      workshopId: 'studio-1',
      questId: 'quest-1',
      questTitle: 'Unavailable Quest',
      category: 'Woodwork',
      stampTitle: 'Woodwork Stamp',
      stampImageUrl: '',
      xpReward: 0,
      completedTaskCount: 0,
      totalTaskCount: 0,
      state: WorkshopQuestState.unavailable,
    );

    expect(journey.actionLabel, 'VIEW QUEST');
  });

  test('all workshop journey states use the View Quest action', () {
    for (final state in WorkshopQuestState.values) {
      final journey = WorkshopQuestJourney(
        workshopId: 'studio-1',
        questId: 'quest-1',
        questTitle: 'Cultural Quest',
        category: 'Woodwork',
        stampTitle: 'Woodwork Stamp',
        stampImageUrl: '',
        xpReward: 50,
        completedTaskCount: 0,
        totalTaskCount: 2,
        state: state,
      );

      expect(journey.actionLabel, 'VIEW QUEST');
    }
  });

  test('artisan profile no longer opens the hardcoded completion screen', () {
    final source = File(
      'lib/ui/tourist/artisan_detail_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('QuestCompletionScreen')));
    expect(source, isNot(contains("'START QUEST'")));
    expect(source, contains('final VoidCallback? onViewQuest'));
    expect(source, contains("'VIEW QUEST'"));
  });

  test('map cards always route their quest action to the quest handler', () {
    final source = File(
      'lib/ui/matchmaker/tourist_matchmaker_view.dart',
    ).readAsStringSync();
    final cardOffset = source.indexOf('Widget _buildArtisanCard');
    final cardSource = source.substring(cardOffset);

    expect(cardSource, contains('_handleViewQuest(context, artisan)'));
    expect(cardSource, isNot(contains('if (artisan.journey == null)')));
    expect(source, isNot(contains('showActiveQuestConflictDialog')));
  });

  test('Explore quest actions use the live quest flow', () {
    final source = File(
      'lib/ui/tourist/tourist_directory_tab.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('QuestCompletionScreen')));
    expect(source, contains('openWorkshopQuest(context, workshop)'));
    expect(source, contains('_openArtisanQuest(context, artisan)'));
    expect(source, contains('id: id'));
  });

  test('journey refresh is deferred until after the widget update frame', () {
    final source = File(
      'lib/ui/matchmaker/tourist_matchmaker_view.dart',
    ).readAsStringSync();
    final updateOffset = source.indexOf('void didUpdateWidget');
    final disposeOffset = source.indexOf('void dispose()', updateOffset);
    final updateSource = source.substring(updateOffset, disposeOffset);

    expect(updateSource, contains('addPostFrameCallback'));
    expect(updateSource, contains('if (!mounted || !widget.isActive) return;'));
    expect(updateSource, contains('loadJourneyData()'));
  });
}
