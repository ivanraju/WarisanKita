import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/ui/matchmaker/widgets/heritage_map_chrome.dart';

String translate(String value) => value;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('summary uses real totals, plural forms, and unavailable states', () {
    expect(heritageJourneySummary(1), '1 quest available');
    expect(heritageJourneySummary(2), '2 quests available');
    expect(heritageJourneySummary(0), '0 quests available');
    expect(HeritageSheetHeader.minimumExtent(720, 1), 0.18);
    expect(
      HeritageSheetHeader.minimumExtent(400, 1) * 400,
      greaterThanOrEqualTo(HeritageSheetHeader.heightFor(1)),
    );
  });

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('compact chrome at 320px in $brightness, text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var settings = 0;
        var opens = 0;
        var toggles = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Column(
                  children: [
                    HeritageMapControls(
                      translate: translate,
                      onSettings: () => settings++,
                    ),
                    HeritageNearbyBanner(
                      title: 'Test Quest with a very long workshop title',
                      distanceMeters: 13,
                      onTap: () => opens++,
                      translate: translate,
                    ),
                    HeritageSheetHeader(
                      nearbyCount: 2,
                      questCount: 2,
                      expanded: false,
                      onToggle: () => toggles++,
                      translate: translate,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Heritage Trails Near You'), findsOneWidget);
        expect(find.text('Slide Studios'), findsNothing);
        expect(find.text('Nearby Quest Journeys'), findsNothing);
        expect(find.textContaining('13 m away'), findsOneWidget);
        expect(find.text('2 quests available'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('heritage-map-controls')),
            matching: find.byType(Chip),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('heritage-map-controls')),
            matching: find.byType(IconButton),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('map-settings')));
        await tester.tap(find.byKey(const Key('heritage-nearby-banner')));
        await tester.tap(find.byTooltip('Expand heritage trails'));
        expect([settings, opens, toggles], [1, 1, 1]);
      });
    }
  }

  // Wiring guards supplement widget tests; native map gestures still require
  // device verification because Google Maps uses a platform view.
  test(
    'map wiring preserves selection, discovery, settings and read-only rewards',
    () {
      final view = File(
        'lib/ui/matchmaker/tourist_matchmaker_view.dart',
      ).readAsStringSync();
      final map = File(
        'lib/ui/map/widgets/google_map_widget.dart',
      ).readAsStringSync();
      final nav = File(
        'lib/ui/tourist/tourist_main_scaffold.dart',
      ).readAsStringSync();
      expect(view, isNot(contains('_buildJourneyHud')));
      expect(view, isNot(contains('Slide Studios')));
      expect(view, isNot(contains('Nearby Quest Journeys')));
      for (final retained in [
        'TranslationLanguageDialog(',
        '_triggerMoodCheckin(context)',
        'refreshWorkshops()',
        '_revealWorkshopCard(',
        '_discoveredQuestIds',
        'onVerticalDragUpdate: _updateSheetHeaderDrag',
        '_reportActiveQuestProximity(',
      ]) {
        expect(view, contains(retained));
      }
      expect(map, contains('alpha: 0.11'));
      expect(map, contains('radius: widget.interactionRadiusMeters'));
      expect(map, contains('selected ? 52 : 46'));
      expect(map, contains('selected ? 65.5 : 58'));
      expect(map, contains('selected: true'));
      expect(nav, contains('if (isSelected)'));
      expect(nav, contains('body: IndexedStack('));
      expect(nav, contains('horizontal: isSelected ?'));
      expect(view, contains('bottom: 0,'));
      expect(view, contains('clipBehavior: Clip.antiAlias'));
      for (final source in [view, map, nav]) {
        expect(source, isNot(contains('Supabase.instance')));
        expect(source, isNot(contains('.awardXp(')));
        expect(source, isNot(contains('.awardStamp(')));
      }
    },
  );
}
