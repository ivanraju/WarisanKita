import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/ui/tourist/tourist_profile_tab.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class _PassportService extends SupabaseService {
  final Future<Map<String, dynamic>> Function() loader;
  int loadCount = 0;

  _PassportService(this.loader);

  @override
  Future<Map<String, dynamic>> fetchPassportData() {
    loadCount++;
    return loader();
  }
}

void main() {
  group('Heritage Passport progression', () {
    test('zero XP begins at the first tier with safe progress', () {
      final progress = HeritageProgression.fromXp(0);

      expect(progress.totalXp, 0);
      expect(progress.currentTier.level, 1);
      expect(progress.currentTierXp, 0);
      expect(progress.progress, 0);
    });

    test('tier boundaries are deterministic', () {
      expect(HeritageProgression.fromXp(99).currentTier.level, 1);
      expect(HeritageProgression.fromXp(100).currentTier.level, 2);
      expect(HeritageProgression.fromXp(300).currentTier.level, 3);
      expect(HeritageProgression.fromXp(600).currentTier.level, 4);
      expect(HeritageProgression.fromXp(1000).currentTier.level, 5);
    });

    test('maximum tier has no next tier and clamps progress to one', () {
      final progress = HeritageProgression.fromXp(5000);

      expect(progress.currentTier.level, 5);
      expect(progress.nextTier, isNull);
      expect(progress.progress, 1);
    });

    test('stored total XP is authoritative while awards drive statistics', () {
      final snapshot = PassportSnapshot.fromData(
        totalXp: 2450,
        taskAwards: const [
          EarnedTaskXp(
            taskId: 'task-1',
            questId: 'quest-1',
            xpAwarded: 50,
            workshopId: 'artisan-1',
            isWorkshopVisit: true,
          ),
          EarnedTaskXp(
            taskId: 'task-1',
            questId: 'quest-1',
            xpAwarded: 50,
            workshopId: 'artisan-1',
            isWorkshopVisit: true,
          ),
          EarnedTaskXp(
            taskId: 'task-2',
            questId: 'quest-2',
            xpAwarded: 70,
            workshopId: 'artisan-2',
            isWorkshopVisit: true,
          ),
        ],
        completedQuests: const [
          CompletedPassportQuest(questId: 'quest-1', artisanId: 'artisan-1'),
          CompletedPassportQuest(questId: 'quest-2', artisanId: 'artisan-2'),
        ],
        earnedStamps: const [],
      );

      expect(snapshot.totalXp, 2450);
      expect(snapshot.completedTaskCount, 2);
      expect(snapshot.visitedQuestCount, 2);
    });

    test('missing or malformed total XP safely becomes zero', () async {
      final repository = GamificationRepository(
        service: _PassportService(
          () async => {
            'task_awards': <Map<String, dynamic>>[],
            'stamps': <Map<String, dynamic>>[],
          },
        ),
      );

      expect((await repository.getPassportSnapshot()).totalXp, 0);
    });

    test('earned stamp maps quest title, image, and earned date', () {
      final stamp = HeritageStamp.fromMap({
        'id': 'stamp-1',
        'quest_id': 'quest-1',
        'stamp_code': 'BATIK-KEEPER',
        'unlocked_at': '2026-09-07T12:00:00Z',
        'quests': {
          'title': 'Batik Discovery',
          'category': 'Demonstration & Lore',
          'stamp_title': 'Batik Heritage Keeper',
          'stamp_image_url': 'https://example.com/batik.webp',
        },
      });

      expect(stamp.isUnlocked, isTrue);
      expect(stamp.stampCode, 'BATIK-KEEPER');
      expect(stamp.title, 'Batik Heritage Keeper');
      expect(stamp.questTitle, 'Batik Discovery');
      expect(stamp.category, 'Demonstration & Lore');
      expect(stamp.iconUrl, 'https://example.com/batik.webp');
      expect(stamp.earnedAt, DateTime.utc(2026, 9, 7, 12));
    });

    test('earned stamps are newest first regardless of response order', () {
      final snapshot = PassportSnapshot.fromData(
        totalXp: 0,
        taskAwards: const [],
        earnedStamps: [
          HeritageStamp.fromMap({
            'id': 'older',
            'quest_id': 'quest-1',
            'unlocked_at': '2026-09-06T12:00:00Z',
            'quests': {'stamp_title': 'Older'},
          }),
          HeritageStamp.fromMap({
            'id': 'newer',
            'quest_id': 'quest-2',
            'unlocked_at': '2026-09-07T12:00:00Z',
            'quests': {'stamp_title': 'Newer'},
          }),
        ],
      );

      expect(snapshot.stamps.map((stamp) => stamp.id), ['newer', 'older']);
    });

    test(
      'earned badge API excludes approved but unearned quest slots',
      () async {
        final repository = GamificationRepository(
          service: _PassportService(
            () async => {
              'total_xp': 0,
              'task_awards': <Map<String, dynamic>>[],
              'stamps': [
                {
                  'id': 'earned',
                  'quest_id': 'quest-earned',
                  'unlocked_at': '2026-09-07T12:00:00Z',
                  'quests': {'stamp_title': 'Earned Stamp'},
                },
              ],
              'available_quests': [
                {'id': 'quest-earned', 'stamp_title': 'Earned Stamp'},
                {'id': 'quest-locked', 'stamp_title': 'Locked Stamp'},
              ],
            },
          ),
        );

        final earned = await repository.getUserBadges();

        expect(earned.map((stamp) => stamp.title), ['Earned Stamp']);
        expect(earned.every((stamp) => stamp.isUnlocked), isTrue);
      },
    );
  });

  group('Heritage Passport UI states', () {
    testWidgets('shows a loading state', (tester) async {
      final pending = Completer<Map<String, dynamic>>();
      await _pumpPassport(tester, _PassportService(() => pending.future));

      expect(find.byKey(const Key('passport-loading')), findsOneWidget);
    });

    testWidgets('shows an actionable empty state', (tester) async {
      await _pumpPassport(
        tester,
        _PassportService(
          () async => {
            'total_xp': 0,
            'task_awards': <Map<String, dynamic>>[],
            'stamps': <Map<String, dynamic>>[],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your first stamp awaits'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('0 / 100 XP (100 XP to Tier 2)'), findsOneWidget);
    });

    testWidgets('shows a retry action when loading fails', (tester) async {
      await _pumpPassport(
        tester,
        _PassportService(() => Future.error(StateError('network failed'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passport unavailable'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows partial data warning and safe unavailable values', (
      tester,
    ) async {
      await _pumpPassport(
        tester,
        _PassportService(
          () async => {
            'total_xp': 0,
            'task_awards': <Map<String, dynamic>>[],
            'stamps': <Map<String, dynamic>>[],
            'xp_available': false,
            'task_awards_available': false,
            'stamps_available': false,
            'quest_statistics_available': false,
            'digital_plaques_available': false,
            'warnings': ['xp', 'task_awards', 'stamps', 'quest_statistics'],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Some Passport information could not be refreshed.'),
        findsOneWidget,
      );
      expect(find.text('XP unavailable • Pull to refresh'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('renders live totals, stamps, and image fallbacks', (
      tester,
    ) async {
      await _pumpPassport(
        tester,
        _PassportService(
          () async => {
            'total_xp': 2450,
            'task_awards': [
              {
                'task_id': 'task-1',
                'xp_awarded': 50,
                'heritage_tasks': {
                  'quest_id': 'quest-1',
                  'is_system_task': true,
                  'sort_order': 1,
                  'quests': {'artisan_id': 'artisan-1'},
                },
              },
              {
                'task_id': 'task-2',
                'xp_awarded': 70,
                'heritage_tasks': {
                  'quest_id': 'quest-2',
                  'is_system_task': false,
                  'sort_order': 3,
                  'quests': {'artisan_id': 'artisan-2'},
                },
              },
            ],
            'stamps': [
              {
                'id': 'stamp-1',
                'quest_id': 'quest-1',
                'unlocked_at': '2026-09-07T12:00:00Z',
                'quests': {
                  'title': 'Batik Discovery',
                  'category': 'Demonstration & Lore',
                  'stamp_title': 'Batik Keeper',
                  'stamp_image_url': '',
                },
              },
              {
                'id': 'stamp-2',
                'quest_id': 'quest-2',
                'unlocked_at': '2026-09-07T13:00:00Z',
                'quests': {
                  'title': 'Woodwork Discovery',
                  'category': 'Hands-on Crafting',
                  'stamp_title': 'Woodwork Keeper',
                  'stamp_image_url': 'not a valid image URL',
                },
              },
            ],
            'available_quests': [
              {
                'id': 'quest-1',
                'title': 'Batik Discovery',
                'category': 'Demonstration & Lore',
                'stamp_title': 'Batik Keeper',
                'stamp_image_url': '',
              },
              {
                'id': 'quest-2',
                'title': 'Woodwork Discovery',
                'category': 'Hands-on Crafting',
                'stamp_title': 'Woodwork Keeper',
                'stamp_image_url': '',
              },
              {
                'id': 'quest-3',
                'title': 'Pottery Discovery',
                'category': 'Pottery & Ceramics',
                'stamp_title': 'Pottery Keeper',
                'stamp_image_url': '',
              },
            ],
            'completed_quests': [
              {
                'quest_id': 'quest-1',
                'quests': {'artisan_id': 'artisan-1'},
              },
              {
                'quest_id': 'quest-2',
                'quests': {'artisan_id': 'artisan-2'},
              },
            ],
            'digital_plaque_count': 4,
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2,450 XP • Maximum tier reached'), findsOneWidget);
      expect(find.text('Batik Keeper'), findsOneWidget);
      expect(find.text('Woodwork Keeper'), findsOneWidget);
      expect(find.text('2 / 3 STAMPS'), findsOneWidget);
      expect(find.text('Studios Visited'), findsOneWidget);
      expect(find.text('Heritage Passport Stamps'), findsNWidgets(2));
      expect(find.text('Digital Plaques'), findsNothing);
      expect(find.text('Pottery Keeper'), findsOneWidget);
      expect(
        find.byKey(const Key('stamp-image-fallback-stamp-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('stamp-image-fallback-stamp-2')),
        findsOneWidget,
      );
      expect(find.byTooltip('Edit Explorer Profile'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);

      await tester.tap(find.text('Batik Keeper'));
      await tester.pumpAndSettle();

      expect(find.text('Quest: Batik Discovery'), findsOneWidget);
      expect(find.text('Demonstration & Lore'), findsOneWidget);
      expect(find.text('Earned: 07 SEP 2026'), findsOneWidget);
    });

    testWidgets('refresh replaces XP and earned stamps without creating data', (
      tester,
    ) async {
      var response = 0;
      final service = _PassportService(() async {
        response++;
        if (response == 1) {
          return {
            'total_xp': 50,
            'task_awards': <Map<String, dynamic>>[],
            'stamps': <Map<String, dynamic>>[],
          };
        }
        return {
          'total_xp': 150,
          'task_awards': <Map<String, dynamic>>[],
          'stamps': [
            {
              'id': 'stamp-refresh',
              'quest_id': 'quest-refresh',
              'stamp_code': 'REFRESHED',
              'unlocked_at': '2026-09-07T14:00:00Z',
              'quests': {
                'title': 'Refreshed Quest',
                'category': 'Cultural Storytelling',
                'stamp_title': 'Refreshed Stamp',
                'stamp_image_url': '',
              },
            },
          ],
        };
      });
      await _pumpPassport(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('50 / 100 XP (50 XP to Tier 2)'), findsOneWidget);
      final refresh = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refresh.onRefresh();
      await tester.pumpAndSettle();

      expect(find.text('150 / 300 XP (150 XP to Tier 3)'), findsOneWidget);
      expect(find.text('Refreshed Stamp'), findsOneWidget);
      expect(service.loadCount, 2);
    });

    testWidgets('long locked stamp titles do not overflow their cards', (
      tester,
    ) async {
      await _pumpPassport(
        tester,
        _PassportService(
          () async => {
            'total_xp': 0,
            'task_awards': <Map<String, dynamic>>[],
            'stamps': <Map<String, dynamic>>[],
            'available_quests': [
              {
                'id': 'quest-long-title',
                'title': 'Wood Carving Discovery',
                'category': 'Woodwork',
                'stamp_title':
                    'Cengal Traditional Heritage Wood Carving Master Artisan Workshop Stamp',
                'stamp_image_url': '',
              },
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Cengal Traditional Heritage Wood Carving Master Artisan Workshop Stamp',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening Passport performs one read-only load', (tester) async {
      final service = _PassportService(
        () async => {
          'total_xp': 0,
          'task_awards': <Map<String, dynamic>>[],
          'stamps': <Map<String, dynamic>>[],
        },
      );

      await _pumpPassport(tester, service);
      await tester.pumpAndSettle();

      expect(service.loadCount, 1);
    });
  });
}

Future<void> _pumpPassport(WidgetTester tester, SupabaseService service) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final viewModel = GamificationViewModel(
    repository: GamificationRepository(service: service),
  );
  addTearDown(viewModel.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: viewModel),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
      ],
      child: const MaterialApp(home: Scaffold(body: TouristProfileTab())),
    ),
  );
  await tester.pump();
}
