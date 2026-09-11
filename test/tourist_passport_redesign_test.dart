import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/ui/tourist/tourist_profile_tab.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

void main() {
  group('Tourist Passport redesign', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/ui/tourist/tourist_profile_tab.dart',
      ).readAsStringSync();
    });

    test('uses the registered low-opacity heritage background', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final asset = File('assets/images/heritage_passport_background.png');

      expect(asset.existsSync(), isTrue);
      expect(
        pubspec,
        contains('assets/images/heritage_passport_background.png'),
      );
      expect(
        source,
        contains("'assets/images/heritage_passport_background.png'"),
      );
      expect(source, contains('opacity: isDark ? 0.55 : 0.62'));
      expect(source, contains('BlendMode.modulate'));
    });

    test('removes the Preservation Impact card and visitor copy', () {
      expect(source, isNot(contains('Preservation Impact')));
      expect(source, isNot(contains('Your visits directly supported')));
      expect(source, isNot(contains('Icons.nature_people_rounded')));
    });

    test('keeps real passport counters and prominent progression', () {
      expect(source, contains("'Quests Done'"));
      expect(source, contains("'Studios Visited'"));
      expect(source, contains("'Passport Stamps'"));
      expect(source, contains('gameStat.totalEarnedXp'));
      expect(source, contains('rankProgress'));
      expect(source, contains('nextTier.minimumXp'));
      expect(source, contains('minHeight: 10'));
      expect(source, contains('Icons.shield_outlined'));
    });

    test('uses real collection totals without inventing a reward', () {
      expect(source, contains('state.availablePassportStamps'));
      expect(source, contains('state.earnedPassportStamps.length'));
      expect(
        source,
        contains('Complete another cultural quest to grow your Passport.'),
      );
      expect(source, isNot(contains('Next reward at')));
    });

    test(
      'earned and locked stamp states remain independently identifiable',
      () {
        expect(source, contains('stamp.isUnlocked'));
        expect(source, contains('stamp.iconUrl'));
        expect(source, contains('_stampImageFallback'));
        expect(source, contains('COMPLETE QUEST TO UNLOCK'));
        expect(source, contains('locked. Complete quest to unlock'));
        expect(source, contains('stamp.earnedAt'));
      },
    );

    test('tier values continue to come from the progression model', () {
      final progress = HeritageProgression.fromXp(650);

      expect(progress.currentTier.level, 3);
      expect(progress.currentTier.title, 'Heritage Apprentice');
      expect(progress.nextTier?.title, 'Heritage Guardian');
      expect(progress.nextTier!.minimumXp - progress.totalXp, 350);
      expect(progress.progress, closeTo(150 / 500, 0.0001));
    });

    test('uses increasing cumulative XP thresholds at every boundary', () {
      expect(
        HeritageProgression.tiers.map((tier) => tier.minimumXp),
        orderedEquals([0, 200, 500, 1000, 2000]),
      );
      expect(HeritageProgression.fromXp(199).currentTier.level, 1);
      expect(HeritageProgression.fromXp(200).currentTier.level, 2);
      expect(HeritageProgression.fromXp(499).currentTier.level, 2);
      expect(HeritageProgression.fromXp(500).currentTier.level, 3);
      expect(HeritageProgression.fromXp(999).currentTier.level, 3);
      expect(HeritageProgression.fromXp(1000).currentTier.level, 4);
      expect(HeritageProgression.fromXp(1999).currentTier.level, 4);
      expect(HeritageProgression.fromXp(2000).currentTier.level, 5);
    });

    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'renders without overflow at 320px in ${brightness.name} mode',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final gameStat = GamificationViewModel(
            repository: _PassportRepository(),
          );
          addTearDown(gameStat.dispose);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => AuthViewModel()),
                ChangeNotifierProvider(create: (_) => LanguageViewModel()),
                ChangeNotifierProvider.value(value: gameStat),
              ],
              child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: const Scaffold(body: TouristProfileTab()),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final renderingException = tester.takeException();
          expect(
            renderingException,
            isNull,
            reason: renderingException is FlutterError
                ? renderingException.toStringDeep()
                : renderingException?.toString(),
          );
          expect(find.text('Heritage Passport Stamps'), findsOneWidget);
        },
      );
    }
  });
}

class _PassportRepository extends GamificationRepository {
  @override
  Future<PassportSnapshot> getPassportSnapshot() async {
    return PassportSnapshot.fromData(
      totalXp: 650,
      taskAwards: const [],
      earnedStamps: [
        HeritageStamp(
          id: 'stamp-1',
          questId: 'quest-1',
          stampCode: 'WK-001',
          title: 'Wood Carving Heritage Stamp',
          iconUrl: '',
          isUnlocked: true,
          questTitle: 'Cengal Wood Carving Quest',
          category: 'Woodwork',
          earnedAt: DateTime.utc(2026, 9, 8),
        ),
      ],
      availableQuests: const [
        {
          'id': 'quest-1',
          'title': 'Cengal Wood Carving Quest',
          'stamp_title': 'Wood Carving Heritage Stamp',
          'category': 'Woodwork',
        },
        {
          'id': 'quest-2',
          'title': 'Traditional Batik Quest',
          'stamp_title': 'Traditional Batik Heritage Stamp',
          'category': 'Batik & Textiles',
        },
      ],
      completedQuests: const [
        CompletedPassportQuest(questId: 'quest-1', artisanId: 'artisan-1'),
      ],
    );
  }
}
