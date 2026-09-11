import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/ui/matchmaker/craft_matchmaker_quiz_wizard.dart';
import 'package:warisan_kita/ui/tourist/tourist_directory_tab.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static final _transparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockArtisanRepository extends ArtisanRepository {
  final List<ArtisanModel> _mockList;
  _MockArtisanRepository(this._mockList);

  @override
  Future<List<ArtisanModel>> getArtisans() async => _mockList;
}

void main() {
  setUp(() {
    HttpOverrides.global = _MockHttpOverrides();
    SharedPreferences.setMockInitialValues({});
  });

  group('Craft Matchmaker Personality Calculation Tests', () {
    const repo = MatchmakerRepository();

    test('Batik & Songket with East Coast creates Royal Textile Connoisseur', () {
      final personality = repo.calculatePersonality({
        0: 'Hands-on Workshop',
        1: 'Indoor Studio',
        2: 'Batik & Songket Textiles',
        3: 'East Coast Heritage (Kelantan, Terengganu)',
      });

      expect(personality.title, 'The Royal Textile Connoisseur');
      expect(personality.primaryCategory, 'Batik & Songket');
      expect(personality.matchingCrafts, contains('Batik Canting'));
      expect(personality.matchingCrafts, contains('Songket Weaving'));
    });

    test('Pottery & Clay with West Coast creates The Earthen Alchemist', () {
      final personality = repo.calculatePersonality({
        0: 'Hands-on Workshop',
        1: 'Outdoor Village',
        2: 'Pottery & Clay',
        3: 'West Coast Historic (Melaka, Perak)',
      });

      expect(personality.title, 'The Earthen Alchemist');
      expect(personality.primaryCategory, 'Pottery & Ceramics');
      expect(personality.matchingCrafts, contains('Labu Sayong'));
    });

    test('Carved Timber & Wood creates The Master Wood Sculptor', () {
      final personality = repo.calculatePersonality({
        0: 'Observing Master Artisans',
        1: 'Indoor Studio',
        2: 'Carved Timber & Wood',
        3: 'Northern Heritage (Kedah, Penang)',
      });

      expect(personality.title, 'The Master Wood Sculptor');
      expect(personality.primaryCategory, 'Wood Carving');
      expect(personality.matchingCrafts, contains('Traditional Ukiran'));
    });

    test('Royal Pewter & Metal creates The Royal Pewter & Blade Artisan', () {
      final personality = repo.calculatePersonality({
        0: 'Hands-on Workshop',
        1: 'Indoor Studio',
        2: 'Royal Pewter & Metal',
        3: 'Central Heritage (Selangor, KL)',
      });

      expect(personality.title, 'The Royal Pewter & Blade Artisan');
      expect(personality.primaryCategory, 'Royal Pewter & Metal');
      expect(personality.matchingCrafts, contains('Keris Forging'));
    });
  });

  group('MatchmakerViewModel State & Persistence Tests', () {
    test('saveQuizResults persists answers and personality to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final vm = MatchmakerViewModel();

      final result = await vm.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Indoor Studio',
        material: 'Batik & Songket Textiles',
        region: 'East Coast Heritage (Kelantan, Terengganu)',
        userEmail: 'tourist@warisankita.my',
      );

      expect(result.title, 'The Royal Textile Connoisseur');
      expect(vm.isQuizCompleted, isTrue);
      expect(vm.primaryCategory, 'Batik & Songket');

      // Create new ViewModel instance to simulate app restart
      final newVm = MatchmakerViewModel(initialUserEmail: 'tourist@warisankita.my');
      await newVm.loadSavedPreferences(userEmail: 'tourist@warisankita.my');

      expect(newVm.isQuizCompleted, isTrue);
      expect(newVm.currentPersonality?.title, 'The Royal Textile Connoisseur');
      expect(newVm.primaryCategory, 'Batik & Songket');
    });

    test('clearAnswers resets preferences', () async {
      final vm = MatchmakerViewModel();
      await vm.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Indoor Studio',
        material: 'Pottery & Clay',
        region: 'West Coast Historic',
        userEmail: 'tourist@warisankita.my',
      );

      expect(vm.isQuizCompleted, isTrue);

      await vm.clearAnswers(userEmail: 'tourist@warisankita.my');
      expect(vm.isQuizCompleted, isFalse);
      expect(vm.currentPersonality, isNull);
    });
  });

  group('CraftMatchmakerQuizWizard Widget Tests', () {
    testWidgets('Wizard renders 4 steps, allows answering, and submits successfully', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();

      List<String>? completedTags;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: matchmakerVM),
            ChangeNotifierProvider.value(value: langVM),
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

      // Step 1: Question 1
      expect(find.text('Question 1 of 4'), findsOneWidget);
      expect(find.text('What type of craft experience do you prefer?'), findsOneWidget);

      // Tap Option 1 (Hands-on)
      await tester.tap(find.text('🛠️ Hands-on Workshop'));
      await tester.pumpAndSettle();

      // Tap Next
      await tester.ensureVisible(find.text('Next Question'));
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Step 2: Question 2
      expect(find.text('Question 2 of 4'), findsOneWidget);
      expect(find.text('Which studio setting do you enjoy most?'), findsOneWidget);

      await tester.tap(find.text('🏠 Indoor Art Studio'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Next Question'));
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Step 3: Question 3
      expect(find.text('Question 3 of 4'), findsOneWidget);
      expect(find.text('What is your favorite craft material?'), findsOneWidget);

      await tester.ensureVisible(find.text('Batik & Songket Textiles'));
      await tester.tap(find.text('Batik & Songket Textiles'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Next Question'));
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Step 4: Question 4
      expect(find.text('Question 4 of 4'), findsOneWidget);
      expect(find.text('Which Malaysian heritage region interests you?'), findsOneWidget);

      await tester.ensureVisible(find.text('🌊 East Coast Heritage (Kelantan & Terengganu)'));
      await tester.tap(find.text('🌊 East Coast Heritage (Kelantan & Terengganu)'));
      await tester.pumpAndSettle();

      // Submit
      expect(find.text('SAVE PREFERENCES'), findsOneWidget);
      await tester.ensureVisible(find.text('SAVE PREFERENCES'));
      await tester.tap(find.text('SAVE PREFERENCES'));
      await tester.pumpAndSettle();

      // Verify quiz completed callback was called with 4 preference tags
      expect(completedTags, isNotNull);
      expect(completedTags!.length, 4);
      expect(matchmakerVM.isQuizCompleted, isTrue);
      expect(matchmakerVM.currentPersonality?.title, 'The Royal Textile Connoisseur');
    });
  });

  group('TouristDirectoryTab Quiz-Based Suggestions Tests', () {
    final mockArtisans = [
      ArtisanModel(
        id: 'artisan_1',
        name: 'Mak Jah',
        craftType: 'Batik Wax Painting',
        state: 'Kelantan',
        description: 'Authentic East Coast hand-drawn batik canting',
        imageUrl: 'https://example.com/jah.png',
        rating: 4.9,
        tags: const ['canting', 'silk', 'kain batik', 'workshop'],
      ),
      ArtisanModel(
        id: 'artisan_2',
        name: 'Uncle Lim',
        craftType: 'Clay Pottery & Ceramics',
        state: 'Perak',
        description: 'Traditional labu sayong pottery',
        imageUrl: 'https://example.com/lim.png',
        rating: 4.8,
        tags: const ['labu sayong', 'pottery', 'clay'],
      ),
    ];

    testWidgets('Shows quiz invitation banner when quiz is not completed', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();
      final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(mockArtisans));
      await dirVM.fetchArtisans();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: matchmakerVM),
            ChangeNotifierProvider.value(value: langVM),
            ChangeNotifierProvider.value(value: dirVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TouristDirectoryTab(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Take the Craft Matchmaker Quiz'), findsOneWidget);
      expect(find.text('START QUIZ'), findsOneWidget);
    });

    testWidgets('Shows personalized recommendations matching quiz choices after quiz completion', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();
      final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(mockArtisans));
      await dirVM.fetchArtisans();

      await matchmakerVM.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Indoor Studio',
        material: 'Batik & Songket Textiles',
        region: 'East Coast Heritage',
        userEmail: 'tourist@warisankita.my',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: matchmakerVM),
            ChangeNotifierProvider.value(value: langVM),
            ChangeNotifierProvider.value(value: dirVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TouristDirectoryTab(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Suggested for You'), findsOneWidget);
      expect(find.textContaining('The Royal Textile Connoisseur'), findsOneWidget);
      expect(find.text('Mak Jah'), findsWidgets);
    });

    testWidgets('Strict craft filtering: does not suggest artisans of different crafts even if state matches', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();
      final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(mockArtisans));
      await dirVM.fetchArtisans();

      // User chooses Pottery & Clay in East Coast
      // Uncle Lim is Pottery in Perak (West Coast)
      // Mak Jah is Batik in Kelantan (East Coast)
      await matchmakerVM.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Outdoor Village',
        material: 'Pottery & Clay',
        region: 'East Coast Heritage',
        userEmail: 'tourist@warisankita.my',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: matchmakerVM),
            ChangeNotifierProvider.value(value: langVM),
            ChangeNotifierProvider.value(value: dirVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TouristDirectoryTab(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Mak Jah is in East Coast, but she does Batik, not Pottery -> Must NOT be in the recommendation header card
      // Uncle Lim is Pottery -> IS suggested!
      expect(find.textContaining('The Clay & Terra Sculptor'), findsOneWidget);
      expect(find.text('Uncle Lim'), findsWidgets);
    });

    testWidgets('Displays empty state when no artisans match chosen craft', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();
      final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(mockArtisans));
      await dirVM.fetchArtisans();

      // User chooses Wood Carving (neither Mak Jah nor Uncle Lim do Wood)
      await matchmakerVM.saveQuizResults(
        experienceType: 'Observing Master Artisans',
        environment: 'Indoor Studio',
        material: 'Carved Timber & Wood',
        region: 'East Coast Heritage',
        userEmail: 'tourist@warisankita.my',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: matchmakerVM),
            ChangeNotifierProvider.value(value: langVM),
            ChangeNotifierProvider.value(value: dirVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TouristDirectoryTab(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No artisans match your quiz choices'), findsOneWidget);
      expect(find.text('Retake Quiz'), findsOneWidget);
    });
  });
}
