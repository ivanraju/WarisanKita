import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String methodSource(String source, String start, String end) {
    final startOffset = source.indexOf(start);
    final endOffset = source.indexOf(end, startOffset + start.length);
    expect(startOffset, greaterThanOrEqualTo(0));
    expect(endOffset, greaterThan(startOffset));
    return source.substring(startOffset, endOffset);
  }

  group('Artisan Task Management presentation', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/ui/artisan/artisan_heritage_task_management_view.dart',
      ).readAsStringSync();
    });

    test('shows reward and workshop QR without quest settings editor', () {
      final body = methodSource(
        source,
        'Widget _body(',
        'Widget _questRewardCard(',
      );
      final reward = methodSource(
        source,
        'Widget _questRewardCard(',
        'Widget _buildStampFallback(',
      );

      expect(body, contains("'QUEST REWARD'"));
      expect(reward, contains('quest.stampTitle'));
      expect(reward, contains('quest.stampImageUrl'));
      expect(reward, contains("'Workshop passport stamp'"));
      expect(reward, contains("'View Workshop QR'"));
      expect(source, isNot(contains('class _EditQuestSheet')));
      expect(body, isNot(contains('Interaction Radius')));
      expect(body, isNot(contains('Edit quest information')));
    });

    test(
      'keeps task summary, status labels, task actions, and system lock',
      () {
        final body = methodSource(
          source,
          'Widget _body(',
          'Widget _questRewardCard(',
        );
        final taskCard = methodSource(
          source,
          'Widget _taskCard(',
          'Widget _emptyTasks(',
        );

        expect(body, contains("'TASKS'"));
        expect(body, contains("'Potential XP'"));
        expect(body, contains('artisanTotalPotentialXp'));
        expect(source, contains("'Add Task'"));
        expect(taskCard, contains('task.isSystemTask'));
        expect(taskCard, contains("'SYSTEM TASK · EDITING LOCKED'"));
        expect(taskCard, contains("'EDIT PENDING'"));
        expect(taskCard, contains("'DELETE PENDING'"));
        expect(taskCard, contains("'REJECTED'"));
        expect(taskCard, contains("'Edit & Resubmit'"));
        expect(taskCard, contains("'Dismiss Request'"));
        expect(taskCard, contains("'Cancel Request'"));
      },
    );
  });

  group('Tourist Cultural Quest presentation', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/ui/gamification/quest_detail_view.dart',
      ).readAsStringSync();
    });

    test('top card contains only studio and required progress summary', () {
      final header = methodSource(
        source,
        'Widget _buildQuestHeader(',
        'Widget _buildLocationSection(',
      );

      expect(header, contains('workshop.name'));
      expect(header, contains('Potential XP'));
      expect(header, contains('Required'));
      expect(header, contains('LinearProgressIndicator'));
      expect(header, contains('isPermanentlyCompleted ? 1.0 : 0.0'));
      expect(header, isNot(contains('quest.title')));
      expect(header, isNot(contains('quest.description')));
      expect(header, isNot(contains('quest.category')));
      expect(header, isNot(contains('CULTURAL QUEST')));
      expect(header, isNot(contains('Heritage Stamp')));
    });

    test('does not render quest title, description, or category', () {
      expect(source, isNot(contains('_buildJourneyIntroduction')));
      expect(source, isNot(contains('About this Heritage Journey')));
      expect(source, isNot(contains('quest.title')));
      expect(source, isNot(contains('quest.description')));
      expect(source, isNot(contains('quest.category')));
    });

    test(
      'location, journey status, reward, and action labels stay explicit',
      () {
        final location = methodSource(
          source,
          'Widget _buildLocationSection(',
          'Widget _buildActivitiesSection(',
        );
        final activities = methodSource(
          source,
          'Widget _buildActivitiesSection(',
          'Widget _buildTaskRow(',
        );
        final reward = methodSource(
          source,
          'Widget _buildStampPreview(',
          'Widget _buildStampFallback(',
        );
        final action = methodSource(
          source,
          'Widget _buildStartBar(',
          'Future<void> _resumeQuest(',
        );

        expect(location, contains('workshop.locationName'));
        expect(location, contains('quest.geofenceRadiusMeters'));
        expect(location, contains("'Within quest zone'"));
        expect(location, contains("'Outside quest zone'"));
        expect(location, contains('Location required'));
        expect(activities, contains("title: 'Heritage Quest'"));
        expect(source, contains("'QR REQUIRED'"));
        expect(source, contains("'WAITING FOR ARRIVAL'"));
        expect(source, contains("'PAUSED'"));
        expect(reward, contains('Total Quest XP:'));
        expect(reward, contains('Complete all required activities to unlock'));
        expect(reward, contains('UNLOCKED · ADDED TO PASSPORT'));
        expect(reward, contains('ColorFiltered'));
        for (final label in [
          'Start Quest',
          'Move Within Quest Zone',
          'Resume Quest',
          'Quest In Progress',
          'Return to Quest Area',
          'Quest Completed',
          'Another Quest Active',
        ]) {
          expect(action, contains(label));
        }
      },
    );
  });
}
