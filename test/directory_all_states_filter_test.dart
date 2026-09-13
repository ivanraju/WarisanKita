import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
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
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  final testArtisans = [
    ArtisanModel(
      id: 'ns_artisan',
      name: 'Tok Wan Seri Menanti',
      craftType: 'Traditional Woodcarving',
      state: 'Negeri Sembilan',
      description: 'Istana Lama woodcarving',
      imageUrl: 'https://example.com/ns.png',
      rating: 4.9,
    ),
    ArtisanModel(
      id: 'perlis_artisan',
      name: 'Pak Cik Kangar',
      craftType: 'Clay Pottery & Ceramics',
      state: 'Perlis',
      description: 'Handcrafted pottery in Kangar',
      imageUrl: 'https://example.com/perlis.png',
      rating: 4.8,
    ),
    ArtisanModel(
      id: 'kl_artisan',
      name: 'Master Ahmad KL',
      craftType: 'Batik Wax Painting',
      state: 'Kuala Lumpur',
      description: 'Central Market boutique batik',
      imageUrl: 'https://example.com/kl.png',
      rating: 4.7,
    ),
    ArtisanModel(
      id: 'putrajaya_artisan',
      name: 'Putrajaya Pewter Crafts',
      craftType: 'Metalwork & Pewter',
      state: 'Putrajaya',
      description: 'Modern Malaysian pewter craft',
      imageUrl: 'https://example.com/pj.png',
      rating: 4.6,
    ),
    ArtisanModel(
      id: 'labuan_artisan',
      name: 'Labuan Pearl & Shell Art',
      craftType: 'Handicraft & Heritage',
      state: 'Labuan',
      description: 'Traditional pearl and shell creations',
      imageUrl: 'https://example.com/labuan.png',
      rating: 4.5,
    ),
  ];

  test('ProfileValidator.supportedStates includes all 13 states and 3 Federal Territories', () {
    const expectedStates = [
      'Johor',
      'Kedah',
      'Kelantan',
      'Melaka',
      'Negeri Sembilan',
      'Pahang',
      'Penang',
      'Perak',
      'Perlis',
      'Sabah',
      'Sarawak',
      'Selangor',
      'Terengganu',
      'Kuala Lumpur',
      'Putrajaya',
      'Labuan',
    ];

    for (final st in expectedStates) {
      expect(
        ProfileValidator.supportedStates.contains(st),
        isTrue,
        reason: ' must be supported in ProfileValidator.supportedStates',
      );
      expect(
        ProfileValidator.validateState(st),
        isNull,
        reason: ' must pass ProfileValidator.validateState',
      );
    }
    expect(ProfileValidator.supportedStates.length, 16);
  });

  testWidgets('Filter Heritage Directory modal contains all 13 states and 3 Federal Territories', (tester) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final authVM = AuthViewModel();
    final matchmakerVM = MatchmakerViewModel();
    final langVM = LanguageViewModel();
    final dirVM = DirectoryViewModel(repository: _MockArtisanRepository(testArtisans));
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
    await tester.pump(const Duration(milliseconds: 300));

    final filterBtn = find.byIcon(Icons.tune_rounded);
    expect(filterBtn, findsOneWidget);
    await tester.tap(filterBtn);
    await tester.pumpAndSettle();

    expect(find.text('Filter Heritage Directory'), findsOneWidget);

    const allExpectedInFilter = [
      'All States',
      'Melaka',
      'Kelantan',
      'Terengganu',
      'Perak',
      'Selangor',
      'Johor',
      'Penang',
      'Kedah',
      'Pahang',
      'Negeri Sembilan',
      'Perlis',
      'Kuala Lumpur',
      'Putrajaya',
      'Labuan',
      'Sabah',
      'Sarawak',
    ];

    for (final st in allExpectedInFilter) {
      expect(find.text(st), findsWidgets, reason: ' must be present in Filter Heritage Directory modal');
    }

    final nsChip = find.widgetWithText(ChoiceChip, 'Negeri Sembilan');
    expect(nsChip, findsOneWidget);
    await tester.tap(nsChip);
    await tester.pumpAndSettle();

    final closeBtn = find.byIcon(Icons.close);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tok Wan Seri Menanti'), findsOneWidget);
    expect(find.text('Pak Cik Kangar'), findsNothing);
    expect(find.text('Master Ahmad KL'), findsNothing);
  });
}
