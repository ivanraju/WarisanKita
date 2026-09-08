import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/nearby_artisan.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/artisan_match_card.dart';

class _ReadOnlyJourneyService extends SupabaseService {
  int readCount = 0;

  @override
  Future<Map<String, dynamic>> fetchTouristMapJourneyData() async {
    readCount++;
    return {
      'total_xp': 450,
      'quests': [
        _quest('available', 'studio-a'),
        _quest('active', 'studio-b'),
        _quest('complete', 'studio-c'),
      ],
      'tasks': [
        _task('a1', 'available', 50),
        _task('a2', 'available', 50),
        _task('b1', 'active', 100),
        _task('b2', 'active', 100),
        _task('c1', 'complete', 150),
      ],
      'quest_progress': [
        {'quest_id': 'active', 'status': 'IN_PROGRESS'},
        {'quest_id': 'complete', 'status': 'COMPLETED'},
      ],
      'task_progress': [
        {'task_id': 'b1', 'is_completed': true},
        {'task_id': 'c1', 'is_completed': true},
      ],
      'stamps': [
        {'quest_id': 'complete'},
      ],
      'xp_available': true,
      'stamps_available': true,
      'warnings': <String>[],
    };
  }

  static Map<String, dynamic> _quest(String id, String studio) => {
    'id': id,
    'artisan_id': studio,
    'title': '$id quest',
    'category': 'Woodwork',
    'stamp_title': '$id stamp',
    'stamp_image_url': '',
  };

  static Map<String, dynamic> _task(String id, String questId, int xp) => {
    'id': id,
    'quest_id': questId,
    'xp_reward': xp,
  };
}

void main() {
  group('Tourist map journey data', () {
    test(
      'maps available, active, and completed states from persisted data',
      () async {
        final service = _ReadOnlyJourneyService();
        final snapshot = await GamificationRepository(
          service: service,
        ).getTouristJourneySnapshot();

        expect(service.readCount, 1);
        expect(snapshot.totalXp, 450);
        expect(snapshot.earnedStampCount, 1);
        expect(
          snapshot.journeysByWorkshopId['studio-a']!.state,
          WorkshopQuestState.available,
        );
        expect(
          snapshot.journeysByWorkshopId['studio-b']!.state,
          WorkshopQuestState.inProgress,
        );
        expect(
          snapshot.journeysByWorkshopId['studio-c']!.state,
          WorkshopQuestState.completed,
        );
        expect(
          snapshot.journeysByWorkshopId['studio-b']!.progressLabel,
          '1/2 activities',
        );
        expect(snapshot.journeysByWorkshopId['studio-b']!.xpReward, 200);
      },
    );

    testWidgets(
      'journey cards present available, active, and completed actions',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 1600);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        const journey = WorkshopQuestJourney(
          workshopId: 'studio-b',
          questId: 'active',
          questTitle: 'Woodwork Journey',
          category: 'Woodwork',
          stampTitle: 'Cengal Keeper',
          stampImageUrl: '',
          xpReward: 200,
          completedTaskCount: 1,
          totalTaskCount: 2,
          state: WorkshopQuestState.inProgress,
        );
        const availableJourney = WorkshopQuestJourney(
          workshopId: 'studio-a',
          questId: 'available',
          questTitle: 'New Woodwork Journey',
          category: 'Woodwork',
          stampTitle: 'Woodwork Explorer',
          stampImageUrl: '',
          xpReward: 100,
          completedTaskCount: 0,
          totalTaskCount: 2,
          state: WorkshopQuestState.available,
        );
        const completedJourney = WorkshopQuestJourney(
          workshopId: 'studio-c',
          questId: 'complete',
          questTitle: 'Completed Woodwork Journey',
          category: 'Woodwork',
          stampTitle: 'Woodwork Guardian',
          stampImageUrl: '',
          xpReward: 150,
          completedTaskCount: 1,
          totalTaskCount: 1,
          state: WorkshopQuestState.completed,
        );
        const workshop = WorkshopLocation(
          id: 'studio-b',
          name: 'Cengal Heritage Studio',
          craftCategory: 'Woodwork',
          address: 'Kampung Losong',
          state: 'Terengganu',
          latitude: 5.33,
          longitude: 103.14,
        );
        final artisans = [
          NearbyArtisan.fromWorkshop(
            workshop: workshop,
            distanceMeters: 320,
            journey: availableJourney,
          ),
          NearbyArtisan.fromWorkshop(
            workshop: workshop,
            distanceMeters: 320,
            journey: journey,
          ),
          NearbyArtisan.fromWorkshop(
            workshop: workshop,
            distanceMeters: 320,
            journey: completedJourney,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (final artisan in artisans)
                        ArtisanMatchCard(
                          artisan: artisan,
                          isSelected:
                              artisan.journey?.state ==
                              WorkshopQuestState.inProgress,
                          onTap: () {},
                          onViewProfile: () {},
                          onViewQuest: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('IN PROGRESS'), findsOneWidget);
        expect(find.text('NEW QUEST'), findsOneWidget);
        expect(find.text('STAMP COLLECTED'), findsOneWidget);
        expect(find.text('1/2 activities'), findsOneWidget);
        expect(find.text('+200 XP'), findsOneWidget);
        expect(find.text('START JOURNEY'), findsOneWidget);
        expect(find.text('CONTINUE JOURNEY'), findsOneWidget);
        expect(find.text('VIEW STAMP'), findsOneWidget);
        expect(
          find.byIcon(Icons.workspace_premium_rounded),
          findsAtLeastNWidgets(3),
        );
        expect(find.text('VERIFIED'), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
