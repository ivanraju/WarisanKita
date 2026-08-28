import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/ui/core/settings_screen.dart';
import 'package:warisan_kita/ui/matchmaker/craft_matchmaker_quiz_wizard.dart';
import 'package:warisan_kita/ui/matchmaker/quiz_results_view.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/navigation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MatchmakerRepository matchmakerRepo;
  late MatchmakerViewModel matchmakerVM;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    matchmakerRepo = const MatchmakerRepository();
    matchmakerVM = MatchmakerViewModel(repository: matchmakerRepo);
  });

  group('Craft Matchmaker Personality Calculation Matrix', () {
    test('Batik & Songket + East Coast yields The Royal Textile Connoisseur', () {
      final answers = {
        0: 'Hands-on Workshop',
        1: 'Indoor Studio',
        2: 'Batik & Songket Textiles',
        3: 'East Coast Heritage',
      };

      final personality = matchmakerRepo.calculatePersonality(answers);
      expect(personality.title, 'The Royal Textile Connoisseur');
      expect(personality.primaryCategory, 'Batik & Songket');
      expect(personality.matchingCrafts, contains('Batik & Songket'));
      expect(personality.matchingCrafts, contains('Songket Weaving'));
      expect(personality.preferenceTags, contains('Batik & Songket Textiles'));
      expect(personality.preferenceTags, contains('East Coast Heritage'));
    });

    test('Batik & Songket + West Coast yields The Contemporary Silk Artisan', () {
      final answers = {
        0: 'Observing Master Artisans',
        1: 'Indoor Studio',
        2: 'Batik & Songket Textiles',
        3: 'West Coast Historic',
      };

      final personality = matchmakerRepo.calculatePersonality(answers);
      expect(personality.title, 'The Contemporary Silk Artisan');
      expect(personality.primaryCategory, 'Batik & Songket');
      expect(personality.matchingCrafts, contains('Batik & Songket'));
    });

    test('Pottery & Clay + West Coast yields The Earthen Alchemist', () {
      final answers = {
        0: 'Hands-on Workshop',
        1: 'Outdoor Village',
        2: 'Pottery & Clay',
        3: 'West Coast Historic',
      };

      final personality = matchmakerRepo.calculatePersonality(answers);
      expect(personality.title, 'The Earthen Alchemist');
      expect(personality.primaryCategory, 'Pottery & Ceramics');
      expect(personality.matchingCrafts, contains('Labu Sayong'));
    });

    test('Pottery & Clay + East Coast yields The Clay & Terra Sculptor', () {
      final answers = {
        0: 'Hands-on Workshop',
        1: 'Indoor Studio',
        2: 'Pottery & Clay',
        3: 'East Coast Heritage',
      };

      final personality = matchmakerRepo.calculatePersonality(answers);
      expect(personality.title, 'The Clay & Terra Sculptor');
      expect(personality.primaryCategory, 'Pottery & Ceramics');
    });

    test('Carved Timber & Wood yields The Master Wood Sculptor', () {
      final answers = {
        0: 'Observing Master Artisans',
        1: 'Outdoor Village',
        2: 'Carved Timber & Wood',
        3: 'East Coast Heritage',
      };

      final personality = matchmakerRepo.calculatePersonality(answers);
      expect(personality.title, 'The Master Wood Sculptor');
      expect(personality.primaryCategory, 'Wood Carving');
      expect(personality.matchingCrafts, contains('Traditional Ukiran'));
    });

    test('Royal Pewter & Metal yields The Royal Pewter & Blade Artisan', () {
      final answers = {
        0: 'Hands-on Workshop',
        1: 'Indoor Studio',
        2: 'Royal Pewter & Metal',
        3: 'West Coast Historic',
      };

      final personality = matchmakerRepo.calculatePersonality(answers);
      expect(personality.title, 'The Royal Pewter & Blade Artisan');
      expect(personality.primaryCategory, 'Royal Pewter & Metal');
      expect(personality.matchingCrafts, contains('Keris Forging'));
    });
  });

  group('Matchmaker Persistence & ViewModel Integration', () {
    test('Saving quiz results computes personality and stores in SharedPreferences', () async {
      expect(matchmakerVM.isQuizCompleted, isFalse);

      final result = await matchmakerVM.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Indoor Studio',
        material: 'Batik & Songket Textiles',
        region: 'East Coast Heritage',
        userEmail: 'tourist@warisankita.my',
      );

      expect(result.title, 'The Royal Textile Connoisseur');
      expect(matchmakerVM.isQuizCompleted, isTrue);
      expect(matchmakerVM.currentPersonality?.title, 'The Royal Textile Connoisseur');
      expect(matchmakerVM.primaryCategory, 'Batik & Songket');
      expect(matchmakerVM.preferenceTags, hasLength(4));

      // Create a fresh ViewModel instance to verify persistence restoration
      final newVM = MatchmakerViewModel(
        repository: matchmakerRepo,
        initialUserEmail: 'tourist@warisankita.my',
      );
      await newVM.loadSavedPreferences(userEmail: 'tourist@warisankita.my');

      expect(newVM.isQuizCompleted, isTrue);
      expect(newVM.currentPersonality?.title, 'The Royal Textile Connoisseur');
      expect(newVM.material, 'Batik & Songket Textiles');
      expect(newVM.region, 'East Coast Heritage');
    });

    test('Clearing answers removes saved quiz state', () async {
      await matchmakerVM.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Indoor Studio',
        material: 'Pottery & Clay',
        region: 'West Coast Historic',
        userEmail: 'user@warisankita.my',
      );

      expect(matchmakerVM.isQuizCompleted, isTrue);

      await matchmakerVM.clearAnswers(userEmail: 'user@warisankita.my');
      expect(matchmakerVM.isQuizCompleted, isFalse);
      expect(matchmakerVM.currentPersonality, isNull);
    });
  });

  group('CraftMatchmakerQuizWizard UI Widget Tests', () {
    testWidgets('Wizard renders 4 steps, pre-populates answers, and submits preferences', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      List<String>? completedTags;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageViewModel()),
            ChangeNotifierProvider(create: (_) => ThemeViewModel()),
            ChangeNotifierProvider(create: (_) => AuthViewModel(repository: UserRepository(service: SupabaseService()))),
            ChangeNotifierProvider.value(value: matchmakerVM),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CraftMatchmakerQuizWizard(
                onCompleted: (tags) {
                  completedTags = tags;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Experience Type
      expect(find.text('Question 1 of 4'), findsOneWidget);
      expect(find.text('🛠️ Hands-on Workshop'), findsOneWidget);
      await tester.tap(find.text('🛠️ Hands-on Workshop'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next Question'));
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Step 2: Studio Setting
      expect(find.text('Question 2 of 4'), findsOneWidget);
      expect(find.text('🏠 Indoor Art Studio'), findsOneWidget);
      await tester.tap(find.text('🏠 Indoor Art Studio'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next Question'));
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Step 3: Material Preference
      expect(find.text('Question 3 of 4'), findsOneWidget);
      expect(find.text('Batik & Songket Textiles'), findsOneWidget);
      await tester.tap(find.text('Batik & Songket Textiles'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next Question'));
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Step 4: Heritage Region
      expect(find.text('Question 4 of 4'), findsOneWidget);
      expect(find.text('🌊 East Coast Heritage (Kelantan & Terengganu)'), findsOneWidget);
      await tester.tap(find.text('🌊 East Coast Heritage (Kelantan & Terengganu)'));
      await tester.pumpAndSettle();

      // Submit Quiz
      expect(find.text('SAVE PREFERENCES'), findsOneWidget);
      await tester.ensureVisible(find.text('SAVE PREFERENCES'));
      await tester.tap(find.text('SAVE PREFERENCES'));
      await tester.pumpAndSettle();

      expect(completedTags, isNotNull);
      expect(completedTags, hasLength(4));
      expect(completedTags![0], 'Hands-on Workshop');
      expect(completedTags![1], 'Indoor Studio');
      expect(completedTags![2], 'Batik & Songket Textiles');
      expect(completedTags![3], 'East Coast Heritage');

      expect(matchmakerVM.isQuizCompleted, isTrue);
      expect(matchmakerVM.currentPersonality?.title, 'The Royal Textile Connoisseur');
    });
  });

  group('SettingsScreen Dynamic Quiz Tile Tests', () {
    testWidgets('Settings screen shows Take vs Update Craft Matchmaker Quiz dynamically', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageViewModel()),
            ChangeNotifierProvider(create: (_) => ThemeViewModel()),
            ChangeNotifierProvider(create: (_) => AuthViewModel(repository: UserRepository(service: SupabaseService()))),
            ChangeNotifierProvider.value(value: matchmakerVM),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, quiz not taken -> shows Take / Update Craft Matchmaker Quiz
      expect(find.text('Take / Update Craft Matchmaker Quiz'), findsOneWidget);
      expect(find.text('Customize your cultural preferences'), findsOneWidget);

      // Now complete the quiz
      await matchmakerVM.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Indoor Studio',
        material: 'Batik & Songket Textiles',
        region: 'East Coast Heritage',
      );
      await tester.pumpAndSettle();

      // Should now dynamically show Update Craft Matchmaker Quiz and matched personality
      expect(find.text('Update Craft Matchmaker Quiz'), findsOneWidget);
      expect(find.textContaining('The Royal Textile Connoisseur'), findsOneWidget);
      expect(find.text('MATCHED'), findsOneWidget);
    });
  });

  group('QuizResultsScreen UI Widget Tests', () {
    testWidgets('QuizResultsScreen displays matched personality, tags, and explore action', (tester) async {
      await matchmakerVM.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Indoor Studio',
        material: 'Pottery & Clay',
        region: 'West Coast Historic',
      );

      final directoryVM = DirectoryViewModel(repository: ArtisanRepository());
      final navigationVM = NavigationViewModel();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageViewModel()),
            ChangeNotifierProvider.value(value: matchmakerVM),
            ChangeNotifierProvider.value(value: directoryVM),
            ChangeNotifierProvider.value(value: navigationVM),
          ],
          child: const MaterialApp(
            home: QuizResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('YOUR CRAFT SOUL IS...'), findsOneWidget);
      expect(find.text('The Earthen Alchemist'), findsOneWidget);
      expect(find.textContaining('Labu Sayong'), findsWidgets);
      // Tap EXPLORE MATCHING MASTERS
      await tester.ensureVisible(find.text('EXPLORE MATCHING MASTERS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EXPLORE MATCHING MASTERS'));
      await tester.pumpAndSettle();

      expect(directoryVM.selectedCraft, 'Pottery & Ceramics');
      expect(navigationVM.currentIndex, 1);
    });
  });
}
