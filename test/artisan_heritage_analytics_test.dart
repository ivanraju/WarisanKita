import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/artisan_heritage_analytics.dart';
import 'package:warisan_kita/ui/artisan/artisan_dashboard_tab.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

class _AnalyticsService extends SupabaseService {
  final Future<Map<String, dynamic>> Function() loader;
  int readCount = 0;

  _AnalyticsService(this.loader);

  @override
  Future<Map<String, dynamic>> fetchArtisanHeritageAnalytics({
    required DateTime startedAtUtc,
    required DateTime endedAtUtcExclusive,
  }) {
    readCount++;
    return loader();
  }
}

void main() {
  test(
    'analytics deduplicates visitors, stamps and completed tourists',
    () async {
      final now = DateTime(2026, 9, 9, 12);
      String timestamp(DateTime local) => local.toUtc().toIso8601String();
      final service = _AnalyticsService(
        () async => {
          'visits': [
            {'user_id': 'tourist-1', 'completed_at': timestamp(now)},
            {'user_id': 'tourist-1', 'completed_at': timestamp(now)},
            {
              'user_id': 'tourist-2',
              'completed_at': timestamp(now.subtract(const Duration(days: 1))),
            },
            {'user_id': '', 'completed_at': timestamp(now)},
            {'user_id': 'invalid-date', 'completed_at': null},
          ],
          'stamps': [
            {'user_id': 'tourist-1', 'quest_id': 'quest-1'},
            {'user_id': 'tourist-1', 'quest_id': 'quest-1'},
            {'user_id': 'tourist-1', 'quest_id': 'quest-2'},
          ],
          'completions': [
            {'user_id': 'tourist-1', 'quest_id': 'quest-1'},
            {'user_id': 'tourist-1', 'quest_id': 'quest-2'},
            {'user_id': 'tourist-2', 'quest_id': 'quest-1'},
          ],
          'stamps_available': true,
          'completions_available': true,
          'visitor_source': 'completed_quest',
        },
      );

      final result = await GamificationRepository(
        service: service,
      ).getArtisanHeritageAnalytics(now: now);

      expect(service.readCount, 1);
      expect(result.totalUniqueVisitors, 2);
      expect(result.dailyVisitors, hasLength(7));
      expect(result.dailyVisitors.last.count, 1);
      expect(result.dailyVisitors[5].count, 1);
      expect(
        result.dailyVisitors.take(5).every((day) => day.count == 0),
        isTrue,
      );
      expect(result.passportStampsAwarded, 2);
      expect(result.completedTourists, 2);
      expect(result.completionTarget, isNull);
      expect(result.completionProgress, isNull);
      expect(result.visitorSource, 'completed_quest');
    },
  );

  test('most recent day wins a highest-count tie', () {
    final metrics = ArtisanHeritageAnalytics(
      totalUniqueVisitors: 2,
      dailyVisitors: List.generate(
        7,
        (index) => DailyVerifiedVisitors(
          date: DateTime(2026, 9, 3 + index),
          count: index == 2 || index == 5 ? 2 : 0,
        ),
      ),
      passportStampsAwarded: 0,
      completedTourists: 0,
    );

    expect(metrics.highlightedDayIndex, 5);
  });

  test('completion progress is safe, clamped and handles zero targets', () {
    ArtisanHeritageAnalytics metric(int completed, int target) =>
        ArtisanHeritageAnalytics(
          totalUniqueVisitors: 0,
          dailyVisitors: const [],
          passportStampsAwarded: 0,
          completedTourists: completed,
          completionTarget: target,
        );

    expect(metric(3, 5).completionProgress, 0.6);
    expect(metric(8, 5).completionProgress, 1);
    expect(metric(0, 0).completionProgress, isNull);
  });

  testWidgets('dashboard renders populated analytics on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _AnalyticsService(
      () async => {
        'visits': [
          {
            'user_id': 'tourist-1',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
        'stamps': [
          {'user_id': 'tourist-1', 'quest_id': 'quest-1'},
        ],
        'completions': [
          {'user_id': 'tourist-1', 'quest_id': 'quest-1'},
        ],
        'stamps_available': true,
        'completions_available': true,
      },
    );

    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('1 Visitor'), findsOneWidget);
    expect(find.text('1 Passport Stamps Awarded'), findsOneWidget);
    expect(find.text('Tourist Quest Completions'), findsOneWidget);
    expect(find.text('1 Completed'), findsOneWidget);
    expect(find.textContaining('Craft Hours'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard preserves card layout and retry on read failure', (
    tester,
  ) async {
    final service = _AnalyticsService(() async => throw StateError('blocked'));

    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();

    expect(
      find.text('Heritage analytics are currently unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}

Future<void> _pumpDashboard(WidgetTester tester, _AnalyticsService service) {
  return tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(
          create: (_) => GamificationViewModel(
            repository: GamificationRepository(service: service),
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ArtisanDashboardTab())),
    ),
  );
}
