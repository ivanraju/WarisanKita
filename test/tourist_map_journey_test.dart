import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/repositories/location_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/nearby_artisan.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/domain/models/workshop_quest_journey.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/artisan_match_card.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/heritage_map_chrome.dart';
import 'package:warisan_kita/viewmodels/map_viewmodel.dart';

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

class _MapRefreshService extends _ReadOnlyJourneyService {
  List<Map<String, dynamic>> workshopRows = [_workshopRow('studio-a', 'Old')];
  Completer<void>? workshopGate;
  int workshopReadCount = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchWorkshopLocations() async {
    workshopReadCount++;
    final gate = workshopGate;
    if (gate != null) {
      await gate.future;
      workshopGate = null;
    }
    return workshopRows.map(Map<String, dynamic>.from).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchWorkshopLocations() =>
      const Stream.empty();

  static Map<String, dynamic> _workshopRow(String id, String suffix) => {
    'id': id,
    'studio_name': 'Studio $suffix',
    'craft_category': 'Woodwork',
    'address': 'Heritage Street',
    'state': 'Melaka',
    'latitude': 2.2,
    'longitude': 102.2,
  };
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Timed out while waiting for asynchronous map state.');
}

void main() {
  group('Tourist map journey data', () {
    test('uses the first saved workshop picture and preserves it', () async {
      final service = _MapRefreshService();
      service.workshopRows = [
        {
          ..._MapRefreshService._workshopRow('studio-a', 'Photos'),
          'artisan_documents': [
            {
              'doc_type': 'PORTFOLIO_IMAGE',
              'file_name': '200_second.webp',
              'file_url': 'https://example.com/second.webp',
            },
            {
              'doc_type': 'BUSINESS_LICENSE',
              'file_name': '050_private.pdf',
              'file_url': 'https://example.com/private.pdf',
            },
            {
              'doc_type': 'STUDIO_PHOTO',
              'file_name': '100_first.webp',
              'file_url': 'https://example.com/first.webp',
            },
          ],
        },
      ];
      final repository = ArtisanRepository(service: service);

      final initialWorkshop = (await repository.getWorkshopLocations()).single;
      expect(initialWorkshop.primaryImageUrl, 'https://example.com/first.webp');
      expect(
        NearbyArtisan.fromWorkshop(
          workshop: initialWorkshop,
          distanceMeters: 10,
        ).imageUrl,
        'https://example.com/first.webp',
      );

      service.workshopRows = [
        _MapRefreshService._workshopRow('studio-a', 'Updated'),
      ];
      final realtimeStyleWorkshop =
          (await repository.getWorkshopLocations()).single;
      expect(
        realtimeStyleWorkshop.primaryImageUrl,
        'https://example.com/first.webp',
      );
    });

    test('map menu is removed and only the independent refresh remains', () {
      final viewSource = File(
        'lib/ui/matchmaker/tourist_matchmaker_view.dart',
      ).readAsStringSync();
      final controlsSource = File(
        'lib/ui/matchmaker/widgets/heritage_map_chrome.dart',
      ).readAsStringSync();

      expect(viewSource, isNot(contains('Mood & craft preferences')));
      expect(viewSource, isNot(contains('TranslationLanguageDialog')));
      expect(viewSource, isNot(contains('DailyMoodCheckinDialog')));
      expect(viewSource, isNot(contains('_showMapSettings')));
      expect(controlsSource, isNot(contains('map-settings')));
      expect(controlsSource, contains('map-refresh-studios'));
      expect(controlsSource, contains("label: 'Refresh studios'"));
    });

    testWidgets('refresh control disables and spins while busy', (
      tester,
    ) async {
      var refreshCalls = 0;

      Widget controls({required bool refreshing}) => MaterialApp(
        home: Scaffold(
          body: HeritageMapControls(
            translate: (value) => value,
            isRefreshing: refreshing,
            onRefresh: refreshing ? null : () => refreshCalls++,
          ),
        ),
      );

      await tester.pumpWidget(controls(refreshing: false));
      expect(find.byKey(const Key('map-refresh-studios')), findsOneWidget);
      expect(find.byTooltip('Refresh studios'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
      await tester.tap(find.byKey(const Key('map-refresh-studios')));
      expect(refreshCalls, 1);

      await tester.pumpWidget(controls(refreshing: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('map-refresh-studios')));
      expect(refreshCalls, 1);
    });

    test(
      'refresh is single-flight and reconciles the selected workshop',
      () async {
        final service = _MapRefreshService();
        final viewModel = MapViewModel(
          artisanRepository: ArtisanRepository(service: service),
          gamificationRepository: GamificationRepository(service: service),
          locationRepository: LocationRepository(),
        );
        addTearDown(viewModel.dispose);

        await _waitFor(
          () => !viewModel.isLoading && !viewModel.isLoadingJourneys,
        );
        viewModel.focusWorkshop(viewModel.workshops.single);

        service.workshopRows = [
          _MapRefreshService._workshopRow('studio-a', 'Updated'),
        ];
        final gate = Completer<void>();
        service.workshopGate = gate;
        final firstRefresh = viewModel.refreshWorkshops();

        expect(viewModel.isRefreshing, isTrue);
        expect(await viewModel.refreshWorkshops(), isFalse);
        expect(service.workshopReadCount, 2);

        gate.complete();
        expect(await firstRefresh, isTrue);
        expect(viewModel.isRefreshing, isFalse);
        expect(viewModel.selectedWorkshop?.id, 'studio-a');
        expect(viewModel.selectedWorkshop?.name, 'Studio Updated');

        service.workshopRows = [];
        expect(await viewModel.refreshWorkshops(), isTrue);
        expect(viewModel.selectedWorkshop, isNull);
      },
    );

    test('dark heritage sheet keeps a visible filtered motif', () {
      final source = File(
        'lib/ui/matchmaker/tourist_matchmaker_view.dart',
      ).readAsStringSync();

      expect(source, contains('opacity: isDark ? 0.34 : 0.14'));
      expect(source, contains('Color(0xFF286A5E)'));
      expect(source, contains('BlendMode.modulate'));
    });

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
          WorkshopQuestState.blockedByOtherQuest,
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
          NearbyArtisan.fromWorkshop(workshop: workshop, distanceMeters: 320),
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
        expect(find.text('START JOURNEY'), findsNothing);
        expect(find.text('CONTINUE JOURNEY'), findsNothing);
        expect(find.text('VIEW STAMP'), findsNothing);
        expect(find.text('VIEW QUEST'), findsNWidgets(4));
        expect(
          find.byIcon(Icons.workspace_premium_rounded),
          findsAtLeastNWidgets(3),
        );
        expect(find.text('VERIFIED'), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
