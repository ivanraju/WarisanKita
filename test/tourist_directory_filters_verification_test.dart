import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
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
      id: 'potter_perak',
      name: 'Uncle Lim Pottery',
      craftType: 'Clay Pottery & Ceramics',
      state: 'Perak',
      description: 'Labu sayong and clay pottery',
      imageUrl: 'https://example.com/pottery.png',
      rating: 4.8,
      tags: const ['clay', 'pottery'],
    ),
    ArtisanModel(
      id: 'batik_kelantan',
      name: 'Mak Jah Batik',
      craftType: 'Batik Wax Painting',
      state: 'Kelantan',
      description: 'Authentic batik canting',
      imageUrl: 'https://example.com/batik.png',
      rating: 4.9,
      tags: const ['batik', 'canting'],
    ),
    ArtisanModel(
      id: 'wood_terengganu',
      name: 'Pak Wan Woodcarver',
      craftType: 'Traditional Woodcarving',
      state: 'Terengganu',
      description: 'Fine Malay ukiran kayu',
      imageUrl: 'https://example.com/wood.png',
      rating: 4.7,
      tags: const ['wood', 'ukiran'],
    ),
    ArtisanModel(
      id: 'potter_kelantan',
      name: 'Kak Som Tembikar',
      craftType: 'Clay Pottery & Ceramics',
      state: 'Kelantan',
      description: 'Kelantan traditional terracotta and pottery',
      imageUrl: 'https://example.com/kaksom.png',
      rating: 4.6,
      tags: const ['clay', 'tembikar'],
    ),
  ];

  testWidgets('Filters truly work for Category and Region/State chips', (tester) async {
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

    // Initially "All Crafts" and "All States" -> all 4 artisans should be present in the directory
    expect(find.text('Uncle Lim Pottery'), findsOneWidget);
    expect(find.text('Mak Jah Batik'), findsOneWidget);
    expect(find.text('Pak Wan Woodcarver'), findsOneWidget);
    expect(find.text('Kak Som Tembikar'), findsOneWidget);

    // 1. Filter by Craft Category: Tap "Clay Pottery & Ceramics"
    final potteryChip = find.text('Clay Pottery & Ceramics').first;
    await tester.tap(potteryChip);
    await tester.pumpAndSettle();

    // Now ONLY Pottery artisans should be shown (Uncle Lim in Perak, Kak Som in Kelantan)
    expect(find.text('Uncle Lim Pottery'), findsOneWidget);
    expect(find.text('Kak Som Tembikar'), findsOneWidget);
    expect(find.text('Mak Jah Batik'), findsNothing);
    expect(find.text('Pak Wan Woodcarver'), findsNothing);

    // 2. Filter by State while Pottery is selected: Tap "Perak"
    final perakChip = find.text('Perak').first;
    await tester.tap(perakChip);
    await tester.pumpAndSettle();

    // Only Uncle Lim in Perak should be shown; Kak Som (Kelantan) should be filtered out!
    expect(find.text('Uncle Lim Pottery'), findsOneWidget);
    expect(find.text('Kak Som Tembikar'), findsNothing);
    expect(find.text('Mak Jah Batik'), findsNothing);
    expect(find.text('Pak Wan Woodcarver'), findsNothing);

    // 3. Switch state to "Kelantan" while Pottery is selected
    final kelantanChip = find.text('Kelantan').first;
    await tester.tap(kelantanChip);
    await tester.pumpAndSettle();

    // Only Kak Som (Kelantan Pottery) should be shown; Uncle Lim (Perak) should be filtered out!
    expect(find.text('Kak Som Tembikar'), findsOneWidget);
    expect(find.text('Uncle Lim Pottery'), findsNothing);
    expect(find.text('Mak Jah Batik'), findsNothing);

    // 4. Switch category to "All Crafts" while "Kelantan" is selected
    final allCraftsChip = find.text('All Crafts').first;
    await tester.tap(allCraftsChip);
    await tester.pumpAndSettle();

    // Now both Kelantan artisans should be shown (Kak Som and Mak Jah)
    expect(find.text('Kak Som Tembikar'), findsOneWidget);
    expect(find.text('Mak Jah Batik'), findsOneWidget);
    expect(find.text('Uncle Lim Pottery'), findsNothing);
    expect(find.text('Pak Wan Woodcarver'), findsNothing);

    // 5. Select a combination with NO artisans (e.g. "Terengganu" + "Clay Pottery & Ceramics")
    await tester.tap(find.text('Clay Pottery & Ceramics').first);
    await tester.pumpAndSettle();
    final terengganuChip = find.text('Terengganu').first;
    await tester.tap(terengganuChip);
    await tester.pumpAndSettle();

    // Should show "No Results Found"
    expect(find.text('No Results Found'), findsOneWidget);
    expect(find.text('Uncle Lim Pottery'), findsNothing);
    expect(find.text('Kak Som Tembikar'), findsNothing);
    expect(find.text('Pak Wan Woodcarver'), findsNothing);
  });
}
