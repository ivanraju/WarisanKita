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
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/domain/validators/ssm_validator.dart';
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

    testWidgets('Strict craft and region filtering: does not suggest artisans of different crafts or non-matching regions', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();
      final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(mockArtisans));
      await dirVM.fetchArtisans();

      // User chooses Pottery & Clay in West Coast Historic
      // Uncle Lim is Pottery in Perak (West Coast) -> MATCHES
      // Mak Jah is Batik in Kelantan (East Coast) -> DOES NOT MATCH
      await matchmakerVM.saveQuizResults(
        experienceType: 'Hands-on Workshop',
        environment: 'Outdoor Village',
        material: 'Pottery & Clay',
        region: 'West Coast Historic',
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

      // Uncle Lim is Pottery in Perak (West Coast) -> Suggested
      expect(find.textContaining('The Earthen Alchemist'), findsOneWidget);
      expect(find.text('Uncle Lim'), findsWidgets);
    });

    testWidgets('East Coast region selection strictly excludes artisans from West Coast (Melaka/Perak)', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();
      // Artisan list with Batik in Melaka and Batik in Kelantan
      final regionalArtisans = [
        ArtisanModel(
          id: 'artisan_kelantan',
          name: 'Che Minah Kelantan',
          craftType: 'Batik Canting',
          state: 'Kelantan',
          description: 'East coast batik',
          imageUrl: 'https://example.com/minah.png',
          rating: 4.9,
          tags: const ['batik', 'canting'],
        ),
        ArtisanModel(
          id: 'artisan_melaka',
          name: 'Madam Tan Melaka',
          craftType: 'Batik Nyonya',
          state: 'Melaka',
          description: 'West coast heritage batik',
          imageUrl: 'https://example.com/tan.png',
          rating: 4.8,
          tags: const ['batik', 'nyonya'],
        ),
      ];

      final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(regionalArtisans));
      await dirVM.fetchArtisans();

      // User selects Batik & Songket in East Coast (Kelantan & Terengganu)
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

      // Che Minah (Kelantan) MUST be suggested
      expect(find.text('Che Minah Kelantan'), findsWidgets);
      // Madam Tan (Melaka) must NOT be suggested in the recommendation section
      // In the whole tree, Madam Tan is only in the bottom directory, not in the horizontal recommendation cards
      expect(find.textContaining('The Royal Textile Connoisseur'), findsOneWidget);
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

    testWidgets('Strict 4-question match: only suggests artisans matching Experience, Environment, Material, and Region', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final authVM = AuthViewModel();
      final matchmakerVM = MatchmakerViewModel();
      final langVM = LanguageViewModel();

      final fourMatchArtisans = [
        ArtisanModel(
          id: 'artisan_hands_on_studio',
          name: 'Siti Hands-On Batik Studio',
          craftType: 'Batik Canting',
          state: 'Kelantan',
          description: 'Hands-on indoor workshop studio in Kota Bharu',
          imageUrl: 'https://example.com/siti.png',
          rating: 4.9,
          workshopCount: 5,
          tags: const ['batik', 'canting', 'workshop', 'studio'],
        ),
        ArtisanModel(
          id: 'artisan_outdoor_village',
          name: 'Pak Hassan Kampong Potter',
          craftType: 'Clay Pottery & Ceramics',
          state: 'Perak',
          description: 'Outdoor traditional village pottery workshop',
          imageUrl: 'https://example.com/hassan.png',
          rating: 4.8,
          tags: const ['labu sayong', 'pottery', 'clay', 'village', 'outdoor'],
        ),
      ];

      final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(fourMatchArtisans));
      await dirVM.fetchArtisans();

      // User chooses: Hands-on (Q1), Indoor Studio (Q2), Batik (Q3), East Coast (Q4)
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

      // Siti matches ALL 4 questions -> Suggested
      expect(find.text('Siti Hands-On Batik Studio'), findsWidgets);
      // Pak Hassan does NOT match material/region/env -> Not suggested in recommendations
      expect(find.textContaining('The Royal Textile Connoisseur'), findsOneWidget);
    });
  });

  group('QA Test Suite: Profile Validator Constraints & Character Counts', () {
    test('Username character count, pattern, and reserved keyword validation', () {
      // Empty
      expect(ProfileValidator.validateUsername(''), 'Username handle cannot be empty');
      expect(ProfileValidator.validateUsername(null), 'Username handle cannot be empty');

      // Min length: < 3 chars
      expect(ProfileValidator.validateUsername('ab'), 'Username must be at least 3 characters');

      // Max length: > 20 chars
      expect(ProfileValidator.validateUsername('a_very_long_username_exceeding_twenty'), 'Username cannot exceed 20 characters');

      // Invalid characters
      expect(ProfileValidator.validateUsername('user!name'), 'Username can only contain letters, numbers, and underscores');
      expect(ProfileValidator.validateUsername('user name'), 'Username can only contain letters, numbers, and underscores');
      expect(ProfileValidator.validateUsername('user-name'), 'Username can only contain letters, numbers, and underscores');

      // Must contain at least one letter
      expect(ProfileValidator.validateUsername('12345'), 'Username must contain at least one letter');
      expect(ProfileValidator.validateUsername('____'), 'Username must contain at least one letter');

      // Reserved keywords
      expect(ProfileValidator.validateUsername('admin'), 'This username is reserved and cannot be used');
      expect(ProfileValidator.validateUsername('system'), 'This username is reserved and cannot be used');
      expect(ProfileValidator.validateUsername('null'), 'This username is reserved and cannot be used');
      expect(ProfileValidator.validateUsername('test'), 'This username is reserved and cannot be used');

      // Valid handles
      expect(ProfileValidator.validateUsername('ahmad_craft'), isNull);
      expect(ProfileValidator.validateUsername('batik_master99'), isNull);
      expect(ProfileValidator.validateUsername('@tourist_ali'), isNull);
    });

    test('Full name length, pattern, and character count validation', () {
      expect(ProfileValidator.validateFullName(''), 'Full name cannot be empty');
      expect(ProfileValidator.validateFullName('A'), 'Full name must be at least 2 characters');
      expect(ProfileValidator.validateFullName('A' * 51), 'Full name cannot exceed 50 characters');
      expect(ProfileValidator.validateFullName('Ali123'), 'Full name can only contain letters, spaces, hyphens, and apostrophes');
      expect(ProfileValidator.validateFullName('Dato\' Sri Dr. Haji Ismail-Ali'), isNull);
    });

    test('Studio name length and placeholder blocklist validation', () {
      expect(ProfileValidator.validateStudioName(''), 'Studio name cannot be empty');
      expect(ProfileValidator.validateStudioName('AB'), 'Studio name must be at least 3 characters');
      expect(ProfileValidator.validateStudioName('S' * 61), 'Studio name cannot exceed 60 characters');

      // Blocklist
      expect(ProfileValidator.validateStudioName('na'), 'Studio name must be at least 3 characters');
      expect(ProfileValidator.validateStudioName('none'), 'Please enter a genuine, recognizable studio or workshop name');
      expect(ProfileValidator.validateStudioName('test'), 'Please enter a genuine, recognizable studio or workshop name');
      expect(ProfileValidator.validateStudioName('tiada'), 'Please enter a genuine, recognizable studio or workshop name');
      expect(ProfileValidator.validateStudioName('dummy'), 'Please enter a genuine, recognizable studio or workshop name');

      expect(ProfileValidator.validateStudioName('Adiguru Batik Studio Heritage'), isNull);
    });

    test('Phone number validation for Malaysian and International formats', () {
      // Required check
      expect(ProfileValidator.validatePhone('', isRequired: true), 'Phone number is required');
      expect(ProfileValidator.validatePhone(null, isRequired: false), isNull);

      // Repetitive dummy sequences
      expect(ProfileValidator.validatePhone('0000000000'), 'Please provide a valid, active contact phone number');
      expect(ProfileValidator.validatePhone('1111111111'), 'Please provide a valid, active contact phone number');
      expect(ProfileValidator.validatePhone('12345678'), 'Please provide a valid, active contact phone number');

      // Valid Malaysian formats
      expect(ProfileValidator.validatePhone('012-3456789'), isNull);
      expect(ProfileValidator.validatePhone('+60198765432'), isNull);
      expect(ProfileValidator.validatePhone('03-87654321'), isNull);

      // Valid International formats
      expect(ProfileValidator.validatePhone('+65 9123 4567'), isNull);
      expect(ProfileValidator.validatePhone('+44 20 7183 8750'), isNull);

      // Invalid
      expect(ProfileValidator.validatePhone('12345'), 'Invalid phone format (e.g. +60 12-345 6789 or 012-3456789)');
    });

    test('Bio character count limits (10 to 1000 characters)', () {
      expect(ProfileValidator.validateBio('', isRequired: true), 'Please enter a biography or craft story');
      expect(ProfileValidator.validateBio('Short', isRequired: true), 'Bio must be at least 10 characters');
      expect(ProfileValidator.validateBio('B' * 1001, isRequired: true), 'Bio cannot exceed 1000 characters');
      expect(ProfileValidator.validateBio('Authentic heritage woodcarver creating traditional Malay panels.'), isNull);
    });

    test('SSM registration number validation (Old and New format)', () {
      expect(SsmValidator.isValid(''), isFalse);
      // Old format (6-8 digits + letter)
      expect(SsmValidator.isValid('123456-A'), isTrue);
      expect(SsmValidator.isValid('9876543-X'), isTrue);
      // New 12-digit format
      expect(SsmValidator.isValid('202101012345'), isTrue);
      // Invalid
      expect(SsmValidator.isValid('INVALIDSSM'), isFalse);
    });

    test('Password complexity and confirmation match validation', () {
      expect(ProfileValidator.validatePassword(''), 'Password cannot be empty');
      expect(ProfileValidator.validatePassword('short1'), 'Password must be at least 8 characters');
      expect(ProfileValidator.validatePassword('12345678'), 'Password must contain at least one letter');
      expect(ProfileValidator.validatePassword('abcdefgh'), 'Password must contain at least one number');
      expect(ProfileValidator.validatePassword('Secret123'), isNull);

      expect(ProfileValidator.validateConfirmPassword('Pass123', 'Pass456'), 'Passwords do not match');
      expect(ProfileValidator.validateConfirmPassword('Pass123', 'Pass123'), isNull);
    });
  });
}
