import 'support/auth_backend.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/admin_web/widgets/artisan_review_dialog.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:cross_file/cross_file.dart';
import 'package:warisan_kita/ui/core/edit_profile_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

final class _TestPlatformFile extends PlatformFile {
  @override
  final String name;
  final Uint8List _data;

  _TestPlatformFile({required this.name, required Uint8List data})
      : _data = data;

  @override
  Uri get uri => Uri.parse('file:///$name');

  @override
  XFile get xFile => XFile.fromData(_data, name: name);

  @override
  Future<int> length() async => _data.length;

  @override
  Future<Uint8List> readAsBytes() async => _data;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_data);
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();
  SharedPreferences.setMockInitialValues({});

  group('ProfileValidator Domain Tests', () {
    test('validateUsername accepts valid handles and rejects invalid ones', () {
      expect(ProfileValidator.validateUsername('siti_crafts'), isNull);
      expect(ProfileValidator.validateUsername('@siti_crafts'), isNull);
      expect(ProfileValidator.validateUsername('artisan99'), isNull);

      expect(ProfileValidator.validateUsername(''), isNotNull);
      expect(ProfileValidator.validateUsername('ab'), isNotNull);
      expect(ProfileValidator.validateUsername('a' * 25), isNotNull);
      expect(ProfileValidator.validateUsername('admin'), isNotNull);
      expect(ProfileValidator.validateUsername('moderator'), isNotNull);
      expect(ProfileValidator.validateUsername('12345'), isNotNull);
      expect(ProfileValidator.validateUsername('user!name'), isNotNull);
    });

    test('validateFullName enforces length and valid characters', () {
      expect(ProfileValidator.validateFullName('Ahmad bin Abdullah'), isNull);
      expect(ProfileValidator.validateFullName("Mary O'Connor"), isNull);
      expect(ProfileValidator.validateFullName('Tan-Lim Ah Seng'), isNull);

      expect(ProfileValidator.validateFullName(''), isNotNull);
      expect(ProfileValidator.validateFullName('A'), isNotNull);
      expect(ProfileValidator.validateFullName('Ahmad 123'), isNotNull);
      expect(ProfileValidator.validateFullName('Ahmad@Craft'), isNotNull);
    });

    test('validateStudioName rejects empty, too short, and placeholder names', () {
      expect(ProfileValidator.validateStudioName('Melaka Heritage Pottery'), isNull);
      expect(ProfileValidator.validateStudioName('Siti Batik Studio'), isNull);

      expect(ProfileValidator.validateStudioName(''), isNotNull);
      expect(ProfileValidator.validateStudioName('ab'), isNotNull);
      expect(ProfileValidator.validateStudioName('none'), isNotNull);
      expect(ProfileValidator.validateStudioName('n/a'), isNotNull);
      expect(ProfileValidator.validateStudioName('test'), isNotNull);
      expect(ProfileValidator.validateStudioName('dummy'), isNotNull);
    });

    test('validatePhone correctly validates Malaysian telephone formats', () {
      expect(ProfileValidator.validatePhone('+60 12-345 6789'), isNull);
      expect(ProfileValidator.validatePhone('012-3456789'), isNull);
      expect(ProfileValidator.validatePhone('+60198765432'), isNull);
      expect(ProfileValidator.validatePhone('01123456789'), isNull);

      expect(ProfileValidator.validatePhone('', isRequired: false), isNull);
      expect(ProfileValidator.validatePhone('', isRequired: true), isNotNull);
      expect(ProfileValidator.validatePhone('12345'), isNotNull);
      expect(ProfileValidator.validatePhone('abcdefghijk'), isNotNull);
      expect(ProfileValidator.validatePhone('+123'), isNotNull);
    });

    test('validateBio checks minimum and maximum length bounds', () {
      expect(
        ProfileValidator.validateBio('Master ceramicist preserving Melaka pottery with 12 years experience.'),
        isNull,
      );

      expect(ProfileValidator.validateBio('', isRequired: false), isNull);
      expect(ProfileValidator.validateBio('', isRequired: true), isNotNull);
      expect(ProfileValidator.validateBio('Too short'), isNotNull);
      expect(ProfileValidator.validateBio('A' * 1001), isNotNull);
    });

    test('validateState validates supported Malaysian states', () {
      expect(ProfileValidator.validateState('Melaka'), isNull);
      expect(ProfileValidator.validateState('Terengganu'), isNull);
      expect(ProfileValidator.validateState('Selangor'), isNull);

      expect(ProfileValidator.validateState(''), isNotNull);
      expect(ProfileValidator.validateState('California'), isNotNull);
    });

    test('validateTag enforces length and prevents duplicates', () {
      final existing = ['Clay', 'Kiln'];
      expect(ProfileValidator.validateTag('Glaze', existing), isNull);
      expect(ProfileValidator.validateTag('clay', existing), isNotNull);
      expect(ProfileValidator.validateTag('A', existing), isNotNull);
      expect(ProfileValidator.validateTag('', existing), isNotNull);
    });
  });

  group('UserModel & Relocation Request Serialization', () {
    test('UserModel serialization preserves pending relocation fields', () {
      const user = UserModel(
        id: 'u123',
        email: 'artisan@warisankita.my',
        displayName: 'Pak Mat',
        role: 'Artisan',
        address: 'Old Premise, Melaka',
        state: 'Melaka',
        latitude: 2.19,
        longitude: 102.25,
        pendingRelocationAddress: 'New Premise, Jonker St, Melaka',
        pendingRelocationState: 'Melaka',
        pendingRelocationLatitude: 2.20,
        pendingRelocationLongitude: 102.26,
        pendingRelocationReason: 'Expanded workshop capacity',
        pendingRelocationDate: '2026-09-08',
      );

      expect(user.hasPendingRelocation, isTrue);

      final map = user.toMap();
      expect(map['pending_relocation_address'], 'New Premise, Jonker St, Melaka');
      expect(map['pending_relocation_reason'], 'Expanded workshop capacity');

      final fromMapUser = UserModel.fromMap(map);
      expect(fromMapUser.hasPendingRelocation, isTrue);
      expect(fromMapUser.pendingRelocationAddress, 'New Premise, Jonker St, Melaka');
      expect(fromMapUser.pendingRelocationLatitude, 2.20);

      final cleared = fromMapUser.copyWith(clearPendingRelocation: true);
      expect(cleared.hasPendingRelocation, isFalse);
      expect(cleared.pendingRelocationAddress, isNull);
    });

    test('UserModel dynamically resolves joinedDate from created_at and formats to Mmm yyyy', () {
      final userWithTimestamp = UserModel.fromMap({
        'id': 'u456',
        'email': 'tourist@example.com',
        'created_at': '2025-08-15T14:22:10.000Z',
      });
      expect(userWithTimestamp.joinedDate, 'Aug 2025');

      final userWithJoinedDate = UserModel.fromMap({
        'id': 'u789',
        'email': 'artisan@example.com',
        'joined_date': 'Mar 2024',
      });
      expect(userWithJoinedDate.joinedDate, 'Mar 2024');

      final userDefault = UserModel.fromMap({
        'id': 'u999',
        'email': 'newuser@example.com',
      });
      final now = DateTime.now();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final expectedCurrentMonthYear = '${months[now.month - 1]} ${now.year}';
      expect(userDefault.joinedDate, expectedCurrentMonthYear);
    });
  });

  group('Relocation Service and Repository Lifecycle', () {
    late SupabaseService service;
    late UserRepository repository;

    setUp(() {
      service = SupabaseService();
      repository = UserRepository(service: service);
    });

    test('Artisan submits, cancels, and admin approves/rejects relocation', () async {
      const email = 'reloc.artisan@warisankita.my';

      // Submit
      final submitted = await repository.submitRelocationRequest(
        email: email,
        address: 'Lot 42, Cultural Street, Melaka',
        state: 'Melaka',
        latitude: 2.201,
        longitude: 102.251,
        reason: 'Relocating to larger artisan studio',
      );
      expect(submitted.hasPendingRelocation, isTrue);

      // Cancel
      final cancelled = await repository.cancelRelocationRequest(email: email);
      expect(cancelled.hasPendingRelocation, isFalse);

      // Re-submit
      await repository.submitRelocationRequest(
        email: email,
        address: 'Lot 88, Heritage Lane, Melaka',
        state: 'Melaka',
        latitude: 2.205,
        longitude: 102.255,
        reason: 'Upgrading studio facilities',
      );

      // Approve
      final approved = await repository.approveRelocationRequest(email: email);
      expect(approved.hasPendingRelocation, isFalse);
      expect(approved.address, 'Lot 88, Heritage Lane, Melaka');

      // Reject
      final rejected = await repository.rejectRelocationRequest(email: email);
      expect(rejected.hasPendingRelocation, isFalse);
    });

    test('ModerationViewModel processes relocation approval and updates store', () async {
      final modVM = ModerationViewModel(repository: repository);
      const testProfile = PendingArtisanProfile(
        id: 'reloc_test_1',
        name: 'Pak Mat Ceramic',
        craftCategory: 'Pottery & Ceramics',
        state: 'Melaka',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/artisan.jpg',
        email: 'pakmat.clay@example.com',
        experience: '25 Years',
        phone: '+60 12-345 6789',
        isUpgradeFromTourist: false,
        isRelocationRequest: true,
        currentAddress: 'Old Studio 1',
        proposedAddress: 'New Jonker Studio 2',
        proposedState: 'Melaka',
        proposedLatitude: 2.20,
        proposedLongitude: 102.25,
        relocationReason: 'Expanding weaving loom space',
      );

      modVM.addRelocationRequest(testProfile);
      expect(modVM.pendingArtisans.any((p) => p.id == 'reloc_test_1'), isTrue);

      await modVM.approveArtisan('reloc_test_1');
      expect(modVM.pendingArtisans.any((p) => p.id == 'reloc_test_1'), isFalse);
    });

    test('ModerationViewModel filters between all, new profiles, and relocations', () {
      final modVM = ModerationViewModel(repository: repository);
      const relocProfile = PendingArtisanProfile(
        id: 'reloc_filter_1',
        name: 'Relocating Weaver',
        craftCategory: 'Songket Weaving',
        state: 'Terengganu',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/artisan.jpg',
        email: 'weaver.reloc@example.com',
        experience: 'Accredited Studio',
        phone: '+60 12-345 6789',
        isUpgradeFromTourist: false,
        isRelocationRequest: true,
      );

      modVM.addRelocationRequest(relocProfile);

      expect(modVM.pendingRelocationCount, greaterThanOrEqualTo(1));

      // When filter is 'All'
      modVM.setApplicationTypeFilter('All');
      expect(modVM.filteredArtisans.any((p) => p.id == 'reloc_filter_1'), isTrue);

      // When filter is 'Relocations'
      modVM.setApplicationTypeFilter('Relocations');
      expect(modVM.filteredArtisans.every((p) => p.isRelocationRequest), isTrue);
      expect(modVM.filteredArtisans.any((p) => p.id == 'reloc_filter_1'), isTrue);

      // When filter is 'New Profiles'
      modVM.setApplicationTypeFilter('New Profiles');
      expect(modVM.filteredArtisans.any((p) => p.id == 'reloc_filter_1'), isFalse);
    });

    test('Pending relocation persists across AuthViewModel.refreshCurrentUser and getAllUsers', () async {
      const email = 'persist.artisan@warisankita.my';
      final authVM = AuthViewModel(repository: repository);
      authVM.setCurrentUserForTesting(
        const UserModel(
          id: 'u_persist_artisan',
          email: email,
          displayName: 'Mak Cik Kiah',
          role: 'Artisan',
          address: 'Original Workshop, Pasir Mas',
          state: 'Kelantan',
          latitude: 6.04,
          longitude: 102.14,
        ),
      );

      // Submit relocation
      await authVM.submitRelocationRequest(
        address: 'New Craft Hub, Kota Bharu',
        state: 'Kelantan',
        latitude: 6.13,
        longitude: 102.25,
        reason: 'Relocating to tourist accessible hub',
      );

      expect(authVM.currentUser?.hasPendingRelocation, isTrue);
      expect(authVM.currentUser?.pendingRelocationAddress, 'New Craft Hub, Kota Bharu');

      // Simulate periodic background polling (which previously wiped out pending state)
      await authVM.refreshCurrentUser();
      expect(authVM.currentUser?.hasPendingRelocation, isTrue);
      expect(authVM.currentUser?.pendingRelocationAddress, 'New Craft Hub, Kota Bharu');

      // Verify admin getAllUsers also sees the pending relocation
      final users = await repository.getAllUsers();
      final artisanInList = users.firstWhere((u) => u.email.toLowerCase() == email);
      expect(artisanInList.hasPendingRelocation, isTrue);
      expect(artisanInList.pendingRelocationAddress, 'New Craft Hub, Kota Bharu');

      // Cancel relocation
      await authVM.cancelRelocationRequest();
      expect(authVM.currentUser?.hasPendingRelocation, isFalse);
      expect(authVM.currentUser?.pendingRelocationAddress, isNull);

      // Refresh again
      await authVM.refreshCurrentUser();
      expect(authVM.currentUser?.hasPendingRelocation, isFalse);
    });
  });

  group('Widget Tests for Verified Location Lock and Review', () {
    setUp(() {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.library == 'image resource service' ||
            details.exceptionAsString().contains('HTTP request failed')) {
          return;
        }
        originalOnError?.call(details);
      };
    });

    testWidgets('ProfileBuilderTab renders Location Locked badge and verified premise indicator', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final modVM = ModerationViewModel(repository: userRepo);

        authVM.setCurrentUserForTesting(
          const UserModel(
            id: 'artisan_tester',
            email: 'tester@warisankita.my',
            displayName: 'Che Minah Songket',
            role: 'Artisan',
            address: 'Verified Heritage Premise, Kota Bharu',
            state: 'Kelantan',
            latitude: 6.12,
            longitude: 102.24,
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authVM),
              ChangeNotifierProvider.value(value: modVM),
            ],
            child: const MaterialApp(
              home: ProfileBuilderTab(),
            ),
          ),
        );
        await tester.pump();
        while (tester.takeException() != null) {}

        expect(find.text('Verified Premise'), findsOneWidget);
        expect(find.text('Location Locked'), findsOneWidget);
        expect(find.text('Request Workshop Relocation'), findsOneWidget);
      }, createHttpClient: (context) => _MockHttpClient());
    });

    testWidgets('ProfileBuilderTab displays full craft category as read-only / locked', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final modVM = ModerationViewModel(repository: userRepo);

        authVM.setCurrentUserForTesting(
          const UserModel(
            id: 'artisan_tester_craft',
            email: 'puppet_master@warisankita.my',
            displayName: 'Pak Dollah Wayang Kulit',
            role: 'Artisan',
            craftCategory: 'Wayang Kulit & Puppetry',
            state: 'Kelantan',
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authVM),
              ChangeNotifierProvider.value(value: modVM),
            ],
            child: const MaterialApp(
              home: ProfileBuilderTab(),
            ),
          ),
        );
        await tester.pump();
        while (tester.takeException() != null) {}

        // Find the Craft Category field
        final craftFieldFinder = find.widgetWithText(TextFormField, 'Accredited Heritage Craft Category');
        expect(craftFieldFinder, findsOneWidget);

        final TextField textField = tester.widget<TextField>(
          find.descendant(of: craftFieldFinder, matching: find.byType(TextField)),
        );
        expect(textField.controller?.text, equals('Wayang Kulit & Puppetry'));
        expect(textField.readOnly, isTrue);

        // Verify helper text
        expect(find.text('Official Kraftangan Malaysia accredited craft category (Locked)'), findsOneWidget);
      }, createHttpClient: (context) => _MockHttpClient());
    });

    testWidgets('ProfileBuilderTab displays pending relocation request banner when relocation requested', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final modVM = ModerationViewModel(repository: userRepo);

        authVM.setCurrentUserForTesting(
          const UserModel(
            id: 'artisan_tester_pending',
            email: 'tester@warisankita.my',
            displayName: 'Che Minah Songket',
            role: 'Artisan',
            address: 'Verified Heritage Premise, Kota Bharu',
            state: 'Kelantan',
            latitude: 6.12,
            longitude: 102.24,
            pendingRelocationAddress: 'Proposed Lot 10, Jonker Street, Melaka',
            pendingRelocationState: 'Melaka',
            pendingRelocationLatitude: 2.20,
            pendingRelocationLongitude: 102.25,
            pendingRelocationReason: 'Opening cultural tourist workshop gallery',
            pendingRelocationDate: '2026-09-08',
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authVM),
              ChangeNotifierProvider.value(value: modVM),
            ],
            child: const MaterialApp(
              home: ProfileBuilderTab(),
            ),
          ),
        );
        await tester.pump();
        while (tester.takeException() != null) {}

        expect(find.text('Relocation Request Pending Administrative Review'), findsOneWidget);
        expect(find.text('Withdraw Request'), findsOneWidget);
        expect(find.textContaining('Proposed Lot 10, Jonker Street, Melaka'), findsOneWidget);
        expect(find.textContaining('Opening cultural tourist workshop gallery'), findsOneWidget);
      }, createHttpClient: (context) => _MockHttpClient());
    });

    testWidgets('ArtisanReviewDialog renders relocation review layout for relocation requests', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const relocationProfile = PendingArtisanProfile(
        id: 'reloc_rev_1',
        name: 'Master Wong Woodcraft',
        craftCategory: 'Wood Carving',
        state: 'Perak',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/wong.jpg',
        email: 'wong.wood@example.com',
        experience: '25 Years',
        phone: '+60 17-234 5678',
        isUpgradeFromTourist: false,
        isRelocationRequest: true,
        currentAddress: 'Old Workshop, Taiping, Perak',
        proposedAddress: 'Lot 15, Heritage Street, Taiping, Perak',
        proposedState: 'Perak',
        proposedLatitude: 4.85,
        proposedLongitude: 100.74,
        relocationReason: 'Relocating to larger lot to accommodate master apprentices',
      );

      bool approved = false;
      bool rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtisanReviewDialog(
              artisan: relocationProfile,
              onApprove: () => approved = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Review Workshop Premise Relocation'), findsOneWidget);
      expect(find.text('Current Accredited Premise'), findsOneWidget);
      expect(find.text('Proposed New Premise'), findsOneWidget);
      expect(find.text('Reject Relocation'), findsOneWidget);
      expect(find.text('Approve Relocation & Update Map'), findsOneWidget);
      expect(find.textContaining('Relocating to larger lot to accommodate master apprentices'), findsOneWidget);

      await tester.tap(find.text('Approve Relocation & Update Map'));
      await tester.pump();
      expect(approved, isTrue);
      expect(rejected, isFalse);
    });
  });

  group('Hardcoded Profile Elimination Tests', () {
    test('ModerationViewModel state contains no hardcoded mock profiles', () {
      final service = SupabaseService();
      final repository = UserRepository(service: service);
      final modVM = ModerationViewModel(repository: repository);

      // Verify no hardcoded mock profiles exist in pending list
      expect(modVM.pendingArtisans.any((p) => p.name == 'Ahmad Razak Ceramic'), isFalse);
      expect(modVM.pendingArtisans.any((p) => p.name == 'Siti Nurhaliza Batik Studio'), isFalse);
      expect(modVM.pendingArtisans.any((p) => p.name == 'Master Wong Woodcraft'), isFalse);
      expect(modVM.pendingArtisans.any((p) => p.name == 'Che Minah Heritage Songket'), isFalse);
      expect(modVM.pendingArtisans.any((p) => p.name == 'Aiman Haziq Woodcraft Studio'), isFalse);

      // Verify no hardcoded active master profiles exist
      expect(modVM.activeArtisanMasters.any((a) => a.name == 'Pak Mat Pottery Studio'), isFalse);
      expect(modVM.activeArtisanMasters.any((a) => a.name == 'Tok Guru Crafts'), isFalse);
      expect(modVM.activeArtisanMasters.any((a) => a.name == 'Kak Lina Silk Batik'), isFalse);
      expect(modVM.activeArtisanMasters.any((a) => a.name == 'Sayong Black Clay Master'), isFalse);
      expect(modVM.activeArtisanMasters.any((a) => a.name == 'Mah Meri Heritage Woodcraft'), isFalse);

      // Verify no hardcoded registered users exist
      expect(modVM.registeredUsers.any((u) => u.email == 'aiman.haziq@example.com'), isFalse);
      expect(modVM.registeredUsers.any((u) => u.email == 'pakmat.clay@example.com'), isFalse);
      expect(modVM.registeredUsers.any((u) => u.email == 'mei.ling@example.com'), isFalse);
      expect(modVM.registeredUsers.any((u) => u.email == 'kaklina.silk@example.com'), isFalse);
    });

    test('SupabaseService does not provide default mock seed profiles in user list', () async {
      final service = SupabaseService();
      final users = await service.getAllUsers();

      expect(users.any((u) => u.email == 'tourist@warisankita.my'), isFalse);
      expect(users.any((u) => u.email == 'user@warisankita.my'), isFalse);
      expect(users.any((u) => u.email == 'artisan@warisankita.my'), isFalse);
      expect(users.any((u) => u.email == 'pending.artisan@warisankita.my'), isFalse);
      expect(users.any((u) => u.email == 'suspended@warisankita.my'), isFalse);
      expect(users.any((u) => u.email == 'artisan.sarah@warisankita.my'), isFalse);
    });
  });

  group('Account Deletion, Cache & Re-Registration Lifecycle Tests', () {
    test('Deleting an account frees username, email and excludes user from getAllUsers & getCurrentUser', () async {
      final backend = AuthBackend();
      addTearDown(backend.client.dispose);
      final service = SupabaseService(client: backend.client);
      final repo = UserRepository(service: service);

      const testEmail = 'deletetest@example.com';
      const testUsername = 'deletetestuser';
      const testPassword = 'Password123!';

      // 1. Sign up user
      final signupUser = await service.signUp(
        email: testEmail,
        password: testPassword,
        role: 'Tourist',
        username: testUsername,
        displayName: 'Delete Test User',
      );
      expect(signupUser.email, testEmail);
      await service.verifyEmailOtp(email: testEmail, token: '654321');

      // Verify username is taken
      final availableBefore = await service.isUsernameAvailable(testUsername);
      expect(availableBefore, isFalse);

      // Verify email exists
      final checkBefore = await service.checkExistingAccount(testEmail);
      expect(checkBefore.exists, isTrue);

      // Verify user appears in all users
      final usersBefore = await service.getAllUsers();
      expect(usersBefore.any((u) => u.email == testEmail), isTrue);

      // 2. Delete account
      await repo.deleteAccount(
        userId: signupUser.id,
        email: testEmail,
        username: testUsername,
      );

      // 3. Verify username is FREED immediately without restarting app
      final availableAfter = await service.isUsernameAvailable(testUsername);
      expect(availableAfter, isTrue);

      // 4. Verify checkExistingAccount reports exists: false
      final checkAfter = await service.checkExistingAccount(testEmail);
      expect(checkAfter.exists, isFalse);

      // 5. Verify user is EXCLUDED from getAllUsers
      final usersAfter = await service.getAllUsers();
      expect(usersAfter.any((u) => u.email == testEmail), isFalse);

      // 6. Verify getCurrentUser returns null and does not restore deleted account
      final current = await service.getCurrentUser();
      expect(current, isNull);

      // 7. Verify user can re-register immediately with the same email and username without app restart
      final reRegisteredUser = await service.signUp(
        email: testEmail,
        password: testPassword,
        role: 'Tourist',
        username: testUsername,
        displayName: 'Re-Registered User',
      );
      expect(reRegisteredUser.email, testEmail);
      expect(reRegisteredUser.status, 'ACTIVE');

      // Clean up after test
      await repo.deleteAccount(
        userId: reRegisteredUser.id,
        email: testEmail,
        username: testUsername,
      );
    });
  });

  group('Admin Dashboard Dynamic Metrics Tests', () {
    test('approvedTodayCount and averageReviewTime update dynamically on artisan approval', () async {
      final service = SupabaseService();
      final repo = UserRepository(service: service);
      final vm = ModerationViewModel(repository: repo, service: service);

      final initialApproved = vm.approvedTodayCount;
      final testArtisan = PendingArtisanProfile(
        id: 'test_artisan_metric_1',
        name: 'Pak Din Wayang',
        craftCategory: 'Puppetry',
        state: 'Kelantan',
        dateSubmitted: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        imageUrl: 'https://example.com/artisan.jpg',
        email: 'pakdin_metric@test.my',
        experience: '20 Years',
        phone: '+60 12-345 6789',
      );

      vm.addPendingArtisan(testArtisan);
      expect(vm.totalPendingCount, greaterThan(0));

      await vm.approveArtisan(testArtisan.id);

      expect(vm.approvedTodayCount, initialApproved + 1);
      expect(vm.approvedTodaySubtitle, contains('approved today'));
      expect(vm.averageReviewTime, isNotEmpty);
      expect(vm.averageReviewTime, isNot(equals('1.4 days')));
    });
  });

  group('Password Reset Security Policy Tests', () {
    test('backend enforces password reuse and valid recovery can update password', () async {
      final backend = AuthBackend();
      addTearDown(backend.client.dispose);
      final service = SupabaseService(client: backend.client);
      final vm = AuthViewModel(repository: UserRepository(service: service));
      const email = 'resetpolicy@test.com';
      backend.add(email, password: 'OriginalPassword123!');
      await service.signIn(email, 'OriginalPassword123!');
      service.acceptPasswordRecovery(backend.client.auth.currentSession!);

      final reused = await vm.confirmPasswordReset(email: email, token: '',
        newPassword: 'OriginalPassword123!', confirmPassword: 'OriginalPassword123!');
      expect(reused.success, isFalse);
      expect(reused.message, contains('should be different'));
      expect(backend.passwordUpdates, 0);

      final changed = await vm.confirmPasswordReset(email: email, token: '',
        newPassword: 'BrandNewPassword456!', confirmPassword: 'BrandNewPassword456!');
      expect(changed.success, isTrue);
      expect(backend.passwordUpdates, 1);
      expect(vm.currentUser, isNull);
      expect(backend.client.auth.currentSession, isNull);
    });
  });

  group('Account Suspension and Moderation Lifecycle Tests', () {

    test('ModerationViewModel.suspendUser synchronizes both registeredUsers and activeArtisanMasters', () async {
      final backend = AuthBackend();
      addTearDown(backend.client.dispose);
      final record = backend.add('master.artisan@warisankita.my', role: 'Master Artisan', username: 'masterhassan');
      final artisanId = record['id'] as String;
      final service = SupabaseService(client: backend.client);
      final repo = UserRepository(service: service);
      final modVM = ModerationViewModel(repository: repo);
      await Future.delayed(const Duration(milliseconds: 100));

      modVM.activeArtisanMasters.add(
        ActiveArtisanMaster(
          id: artisanId,
          name: 'Master Hassan',
          email: 'master.artisan@warisankita.my',
          category: 'Wood Carving',
          state: 'Terengganu',
          experience: '25 Years',
          plaques: 5,
          isLiveOpen: true,
          licenseNo: 'SSM-12345',
          verifiedDate: '2024-01-01',
          imageUrl: '',
          bio: 'Wood carving master',
          phone: '+60123456789',
          isSuspended: false,
        ),
      );

      // Suspend user
      await modVM.suspendUser(artisanId);

      final userInList = modVM.registeredUsers.firstWhere((u) => u.id == artisanId);
      expect(userInList.isSuspended, isTrue);
      expect(userInList.status, 'SUSPENDED');

      final masterInList = modVM.activeArtisanMasters.firstWhere((a) => a.id == artisanId);
      expect(masterInList.isSuspended, isTrue);
      expect(masterInList.isLiveOpen, isFalse);

      // Reactivate user
      await modVM.reactivateUser(artisanId);

      final reactivatedUser = modVM.registeredUsers.firstWhere((u) => u.id == artisanId);
      expect(reactivatedUser.isSuspended, isFalse);
      expect(reactivatedUser.status, 'ACTIVE');

      final reactivatedMaster = modVM.activeArtisanMasters.firstWhere((a) => a.id == artisanId);
      expect(reactivatedMaster.isSuspended, isFalse);
      expect(reactivatedMaster.isLiveOpen, isTrue);
    });

    test('Artisan application rejection excludes profile from pending approvals across refresh', () async {
      final backend = AuthBackend();
      addTearDown(backend.client.dispose);
      const applicantEmail = 'applicant.test@warisankita.my';
      final record = backend.add(applicantEmail, role: 'Tourist', username: 'applicantstudio');
      final applicantId = record['id'] as String;

      final service = SupabaseService(client: backend.client);
      final repo = UserRepository(service: service);
      final modVM = ModerationViewModel(repository: repo);
      await Future.delayed(const Duration(milliseconds: 100));

      final pendingProfile = PendingArtisanProfile(
        id: applicantId,
        name: 'Applicant Studio',
        craftCategory: 'Batik Weaving',
        state: 'Kelantan',
        dateSubmitted: '2026-09-11',
        imageUrl: 'https://example.com/avatar.jpg',
        email: applicantEmail,
        experience: '5 Years',
        phone: '+60123456789',
        ssmNumber: 'SSM-999888',
        isUpgradeFromTourist: true,
      );

      modVM.addPendingArtisan(pendingProfile);

      expect(modVM.filteredArtisans.any((p) => p.email == applicantEmail), isTrue);
      expect(modVM.totalPendingCount, greaterThanOrEqualTo(1));

      // 2. Admin rejects the artisan application
      await modVM.rejectArtisan(applicantId);

      // Immediately removed from in-memory lists
      expect(modVM.filteredArtisans.any((p) => p.email == applicantEmail), isFalse);
      expect(modVM.pendingArtisans.any((p) => p.email == applicantEmail), isFalse);

      // Registered user state preserved as active Tourist with artisanStatus REJECTED
      final userAfterReject = modVM.registeredUsers.firstWhere((u) => u.email == applicantEmail);
      expect(userAfterReject.status, 'ACTIVE');
      expect(userAfterReject.role, 'Tourist');
      expect(userAfterReject.artisanStatus, 'REJECTED');

      // 3. Admin refreshes or fetches data again
      await modVM.refreshAllData();

      // Application remains strictly excluded from pending approvals queue
      expect(modVM.filteredArtisans.any((p) => p.email == applicantEmail), isFalse);
      expect(modVM.pendingArtisans.any((p) => p.email == applicantEmail), isFalse);

      // 4. Tourist updates documents and re-applies
      final reapplyProfile = PendingArtisanProfile(
        id: applicantId,
        name: 'Applicant Studio Updated',
        craftCategory: 'Batik Weaving',
        state: 'Kelantan',
        dateSubmitted: '2026-09-12',
        imageUrl: 'https://example.com/avatar_new.jpg',
        email: applicantEmail,
        experience: '6 Years',
        phone: '+60123456789',
        ssmNumber: 'SSM-999888',
        isUpgradeFromTourist: true,
      );
      modVM.addPendingArtisan(reapplyProfile);

      // Re-application immediately appears in approvals queue
      expect(modVM.filteredArtisans.any((p) => p.email == applicantEmail), isTrue);
      expect(modVM.pendingArtisans.any((p) => p.email == applicantEmail), isTrue);

      // 5. Admin approves the re-application
      await modVM.approveArtisan(applicantId);

      // Application removed from approvals queue and user promoted to Active Artisan
      expect(modVM.filteredArtisans.any((p) => p.email == applicantEmail), isFalse);
      final approvedUser = modVM.registeredUsers.firstWhere((u) => u.email == applicantEmail);
      expect(approvedUser.status, 'ACTIVE');
      expect(approvedUser.role, 'Artisan');
      expect(approvedUser.artisanStatus, 'APPROVED');
      expect(modVM.activeArtisanMasters.any((a) => a.email == applicantEmail), isTrue);
    });

    test('Tourist upgrade approval promotes role to Artisan and artisanStatus to APPROVED in UserModel.fromMap and session', () async {
      // 1. UserModel.fromMap promotion test
      final rawRowApproved = {
        'id': 'user-test-appr',
        'email': 'tourist.upgrade@warisankita.my',
        'role': 'Tourist',
        'roles': ['Tourist'],
        'status': 'ACTIVE',
        'artisan_profiles': {
          'status': 'APPROVED',
          'studio_name': 'Silver Studio',
          'craft_category': 'Pewter Craft',
        },
      };
      final user = UserModel.fromMap(rawRowApproved);
      expect(user.role, 'Artisan');
      expect(user.roles, ['Artisan']);
      expect(user.artisanStatus, 'APPROVED');
      expect(user.isApprovedArtisan, isTrue);
      expect(user.isRejectedArtisan, isFalse);

      // 2. updateArtisanStatusInDb approval test
      final backend = AuthBackend();
      addTearDown(backend.client.dispose);
      const targetEmail = 'tourist.upgrade@warisankita.my';
      backend.add(targetEmail, role: 'Tourist');
      final service = SupabaseService(client: backend.client);
      await service.updateArtisanStatusInDb(
        email: targetEmail,
        newStatus: 'ACTIVE',
        newRole: 'Artisan',
      );
      final users = await service.getAllUsers();
      final updatedUser = users.firstWhere((u) => u.email == targetEmail);
      expect(updatedUser.role, 'Artisan');
      expect(updatedUser.artisanStatus, 'APPROVED');
      expect(updatedUser.isApprovedArtisan, isTrue);
    });

    test('Tourist application rejection preserves role Tourist and sets artisanStatus to REJECTED in UserModel.fromMap and session', () async {
      // 1. UserModel.fromMap rejection test
      final rawRowRejected = {
        'id': 'user-test-rej',
        'email': 'tourist.rejected@warisankita.my',
        'role': 'Tourist',
        'roles': ['Tourist'],
        'status': 'ACTIVE',
        'artisan_profiles': {
          'status': 'REJECTED',
          'studio_name': 'Clay Studio',
          'craft_category': 'Pottery & Ceramics',
        },
      };
      final user = UserModel.fromMap(rawRowRejected);
      expect(user.role, 'Tourist');
      expect(user.roles, ['Tourist']);
      expect(user.status, 'ACTIVE');
      expect(user.artisanStatus, 'REJECTED');
      expect(user.isRejectedArtisan, isTrue);
      expect(user.isApprovedArtisan, isFalse);

      // 2. updateArtisanStatusInDb rejection test
      final backend = AuthBackend();
      addTearDown(backend.client.dispose);
      const targetEmail = 'tourist.rejected@warisankita.my';
      backend.add(targetEmail, role: 'Tourist');
      final service = SupabaseService(client: backend.client);
      await service.updateArtisanStatusInDb(
        email: targetEmail,
        newStatus: 'REJECTED',
        newRole: 'Tourist',
        updateArtisanProfileOnly: true,
      );
      final users = await service.getAllUsers();
      final updatedUser = users.firstWhere((u) => u.email == targetEmail);
      expect(updatedUser.role, 'Tourist');
      expect(updatedUser.status, 'ACTIVE');
      expect(updatedUser.artisanStatus, 'REJECTED');
      expect(updatedUser.isRejectedArtisan, isTrue);
      expect(updatedUser.isApprovedArtisan, isFalse);
    });
  });

  group('Artisan Profile & Experience Persistence Tests', () {
    test('updateUserProfile creates artisan_profiles and preserves bio, tags, and documents when row initially missing', () async {
      final service = SupabaseService();
      SharedPreferences.setMockInitialValues({});

      // Update profile for an artisan account whose artisan_profiles row was never created
      final updated = await service.updateUserProfile(
        email: 'newartisan@warisankita.my',
        username: 'master_kamal',
        displayName: 'Kamal Woodcraft',
        studioName: 'Kamal Ukiran Kayu',
        craftCategory: 'Traditional Woodcarving',
        bio: 'Specialist in Kelantan floral woodcarving with 25 years experience.',
        state: 'Kelantan',
        address: 'Lot 102, Kampung Laut, Tumpat',
        latitude: 6.1955,
        longitude: 102.2355,
        phone: '+60123456789',
        toolsAndMaterials: ['Chedung', 'Ketam Kayu', 'Kayu Cengal'],
      );

      expect(updated.username, equals('master_kamal'));
      expect(updated.studioName, equals('Kamal Ukiran Kayu'));
      expect(updated.craftCategory, equals('Traditional Woodcarving'));
      expect(updated.bio, equals('Specialist in Kelantan floral woodcarving with 25 years experience.'));
      expect(updated.state, equals('Kelantan'));
      expect(updated.address, equals('Lot 102, Kampung Laut, Tumpat'));
      expect(updated.latitude, equals(6.1955));
      expect(updated.longitude, equals(102.2355));
      expect(updated.phone, equals('+60123456789'));
      expect(updated.tags, containsAll(['Chedung', 'Ketam Kayu', 'Kayu Cengal']));
      expect(updated.role, equals('Artisan'));

      // Verify that getCurrentUser recovers the updated profile and does not drop any field
      final retrieved = await service.getCurrentUser();
      expect(retrieved, isNotNull);
      expect(retrieved!.bio, equals('Specialist in Kelantan floral woodcarving with 25 years experience.'));
      expect(retrieved.studioName, equals('Kamal Ukiran Kayu'));
      expect(retrieved.craftCategory, equals('Traditional Woodcarving'));
      expect(retrieved.tags, containsAll(['Chedung', 'Ketam Kayu', 'Kayu Cengal']));
      expect(retrieved.latitude, equals(6.1955));
      expect(retrieved.longitude, equals(102.2355));
    });

    test('updateUserProfile and UserModel persist and retrieve experience without rank title', () async {
      final service = SupabaseService();
      SharedPreferences.setMockInitialValues({});

      final updated = await service.updateUserProfile(
        email: 'experience_test@warisankita.my',
        username: 'master_azman',
        studioName: 'Azman Pottery Studio',
        craftCategory: 'Pottery & Ceramics',
        experience: '20+ Years Experience',
        bio: 'Practicing traditional Labu Sayong pottery craftsmanship for over two decades.',
        state: 'Perak',
      );

      expect(updated.experience, equals('20+ Years Experience'));

      // Verify serialization / deserialization
      final map = updated.toMap();
      expect(map['experience'], equals('20+ Years Experience'));
      final restored = UserModel.fromMap(map);
      expect(restored.experience, equals('20+ Years Experience'));

      // Test ProfileValidator for experience
      expect(ProfileValidator.validateExperience(null, isRequired: true), isNotNull);
      expect(ProfileValidator.validateExperience('', isRequired: true), isNotNull);
      expect(ProfileValidator.validateExperience('20+ Years Experience', isRequired: true), isNull);
      // Optional mode for profile builder
      expect(ProfileValidator.validateExperience(null, isRequired: false), isNull);
      expect(ProfileValidator.validateExperience('', isRequired: false), isNull);

      // Verify that default 1 year from database does NOT force '1 Years' onto user
      final defaultMap = {
        'id': 'u_default_1',
        'email': 'default@artisan.my',
        'role': 'Artisan',
        'artisan_profiles': {
          'years_experience': 1,
          'experience': null,
        }
      };
      final defaultUser = UserModel.fromMap(defaultMap);
      expect(defaultUser.experience, isNull);
    });

    test('Artisan experience persists on getCurrentUser (reload) and displays in admin getActiveArtisans and getAllUsers', () async {
      final service = SupabaseService();
      SharedPreferences.setMockInitialValues({});

      // 1. Artisan saves custom experience
      final updated = await service.updateUserProfile(
        email: 'reload_test_artisan@warisankita.my',
        username: 'batik_master_amin',
        studioName: 'Amin Batik House',
        craftCategory: 'Batik & Textiles',
        experience: '15 Years Craft Experience',
        bio: 'Preserving Terengganu silk batik heritage.',
        state: 'Terengganu',
      );

      expect(updated.experience, equals('15 Years Craft Experience'));

      // 2. Simulate app reload via getCurrentUser
      final reloaded = await service.getCurrentUser();
      expect(reloaded, isNotNull);
      expect(reloaded!.email, equals('reload_test_artisan@warisankita.my'));
      expect(reloaded.experience, equals('15 Years Craft Experience'));

      // 3. Verify Admin gets this artisan in getActiveArtisans with experience
      final activeArtisans = await service.getActiveArtisans();
      final foundActive = activeArtisans.firstWhere(
        (a) => a.email.toLowerCase() == 'reload_test_artisan@warisankita.my',
      );
      expect(foundActive.experience, equals('15 Years Craft Experience'));

      // 4. Verify Admin gets this artisan in getAllUsers with experience
      final allUsers = await service.getAllUsers();
      final foundUser = allUsers.firstWhere(
        (u) => u.email.toLowerCase() == 'reload_test_artisan@warisankita.my',
      );
      expect(foundUser.experience, equals('15 Years Craft Experience'));
    });
  });

  group('Artisan Document Preservation & Rollback Security', () {
    test('UC100: linkArtisanToExistingTourist returns clean failure and does not crash when session dropped and email missing', () async {
      final service = SupabaseService();
      final repo = UserRepository(service: service);
      final authVM = AuthViewModel(repository: repo);
      SharedPreferences.setMockInitialValues({});

      // Calling linkArtisanToExistingTourist with empty email and no active user session
      final result = await authVM.linkArtisanToExistingTourist(
        email: '',
        studioName: 'Mystery Studio',
        craftCategory: 'Woodwork',
        ssmNumber: '202601009988',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Authentication required'));
    });

    test('UC100: linkArtisanRoleToTourist restores email from SharedPreferences if session dropped', () async {
      final service = SupabaseService();
      // Setup existing tourist session in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'wk_last_auth_user': jsonEncode({
          'id': 'u_cached_tourist',
          'email': 'cached_tourist@warisankita.my',
          'role': 'Tourist',
          'status': 'ACTIVE',
        }),
      });

      // Calling with empty email - service recovers email from SharedPreferences session
      final linked = await service.linkArtisanRoleToTourist(
        email: '',
        studioName: 'Cached Artisan Workshop',
        craftCategory: 'Textiles',
        ssmNumber: '202601007744',
        experience: '8 Years',
      );

      expect(linked.email, equals('cached_tourist@warisankita.my'));
      expect(linked.status, equals('PENDING_APPROVAL'));
      expect(linked.experience, equals('8 Years'));
    });

    test('UC100: ProfileValidator.validateEmail validates applicant email correctly', () {
      expect(ProfileValidator.validateEmail(null), equals('Email address cannot be empty'));
      expect(ProfileValidator.validateEmail(''), equals('Email address cannot be empty'));
      expect(ProfileValidator.validateEmail('invalid_email'), equals('Please enter a valid email address'));
      expect(ProfileValidator.validateEmail('valid.artisan@student.tarc.edu.my'), isNull);
    });

    test('UC100: re-application preserves existing document types when updating a single document', () async {
      final service = SupabaseService();
      SharedPreferences.setMockInitialValues({});

      // 1. Initial application with SSM and Kraftangan cert
      final user1 = await service.linkArtisanRoleToTourist(
        email: 'reapply_artisan@warisankita.my',
        studioName: 'Reapply Studio',
        craftCategory: 'Woodwork',
        ssmNumber: '202601005511',
        ssmFile: _TestPlatformFile(
          name: 'ssm_initial.pdf',
          data: Uint8List.fromList([1, 2, 3]),
        ),
        certFile: _TestPlatformFile(
          name: 'cert_initial.pdf',
          data: Uint8List.fromList([4, 5, 6]),
        ),
      );

      expect(user1.artisanDocuments.length, equals(2));
      final docTypes1 = user1.artisanDocuments.map((d) => d['doc_type']).toSet();
      expect(docTypes1, contains('SSM_BUSINESS_CERT'));
      expect(docTypes1, contains('KRAFTANGAN_MASTER_CERT'));

      // 2. Re-application with ONLY a new SSM file (e.g. after rejected SSM was corrected)
      final user2 = await service.linkArtisanRoleToTourist(
        email: 'reapply_artisan@warisankita.my',
        studioName: 'Reapply Studio',
        craftCategory: 'Woodwork',
        ssmNumber: '202601005511',
        ssmFile: _TestPlatformFile(
          name: 'ssm_updated_v2.pdf',
          data: Uint8List.fromList([7, 8, 9]),
        ),
        // certFile is omitted/null
      );

      // Verify: SSM_BUSINESS_CERT was updated, but KRAFTANGAN_MASTER_CERT was NOT deleted!
      expect(user2.artisanDocuments.length, equals(2));
      final ssmDoc = user2.artisanDocuments.firstWhere((d) => d['doc_type'] == 'SSM_BUSINESS_CERT');
      expect(ssmDoc['file_name'], equals('ssm_updated_v2.pdf'));
      final certDoc = user2.artisanDocuments.firstWhere((d) => d['doc_type'] == 'KRAFTANGAN_MASTER_CERT');
      expect(certDoc['file_name'], equals('cert_initial.pdf'));
    });

    test('UC100: re-application preserves all previous documents when no new files are provided', () async {
      final service = SupabaseService();
      SharedPreferences.setMockInitialValues({});

      await service.linkArtisanRoleToTourist(
        email: 'preserve_docs@warisankita.my',
        studioName: 'Preserve Studio',
        craftCategory: 'Pottery',
        ssmNumber: '202601005522',
        ssmFile: _TestPlatformFile(
          name: 'my_ssm.pdf',
          data: Uint8List.fromList([1, 2]),
        ),
        certFile: _TestPlatformFile(
          name: 'my_cert.pdf',
          data: Uint8List.fromList([3, 4]),
        ),
      );

      // Re-apply or update metadata without files
      final updated = await service.linkArtisanRoleToTourist(
        email: 'preserve_docs@warisankita.my',
        studioName: 'Preserve Studio Renamed',
        craftCategory: 'Pottery',
        ssmNumber: '202601005522',
      );

      expect(updated.artisanDocuments.length, equals(2));
      final names = updated.artisanDocuments.map((d) => d['file_name']).toSet();
      expect(names, contains('my_ssm.pdf'));
      expect(names, contains('my_cert.pdf'));
    });

    test('isLiveOpen toggle defaults to true and correctly updates, serializes, and toggles', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SupabaseService();

      // Sign in or link artisan
      final user = await service.linkArtisanRoleToTourist(
        email: 'artisan_demo@warisankita.my',
        studioName: 'Demo Studio',
        craftCategory: 'Wood carving',
        ssmNumber: '202601007788',
      );

      // Default should be true
      expect(user.isLiveOpen, isTrue);

      // Update to false (artisan turns off demo availability)
      final closedUser = await service.updateUserProfile(
        email: 'artisan_demo@warisankita.my',
        isLiveOpen: false,
      );
      expect(closedUser.isLiveOpen, isFalse);

      // Verify toMap & fromMap roundtrip
      final map = closedUser.toMap();
      expect(map['is_live_open'], isFalse);
      expect(map['isLiveOpen'], isFalse);

      final reloadedUser = UserModel.fromMap(map);
      expect(reloadedUser.isLiveOpen, isFalse);

      // Reopen demo availability
      final reopenedUser = await service.updateUserProfile(
        email: 'artisan_demo@warisankita.my',
        isLiveOpen: true,
      );
      expect(reopenedUser.isLiveOpen, isTrue);

      // Verify ArtisanModel.fromMap extracts is_live_open
      final artisanModelFromRoot = ArtisanModel.fromMap({
        'id': 'artisan-1',
        'studio_name': 'Demo Studio',
        'craft_category': 'Wood carving',
        'is_live_open': false,
      });
      expect(artisanModelFromRoot.isLiveOpen, isFalse);

      final artisanModelFromUserJoin = ArtisanModel.fromMap({
        'id': 'artisan-2',
        'studio_name': 'Demo Studio',
        'craft_category': 'Wood carving',
        'users': {'is_live_open': true},
      });
      expect(artisanModelFromUserJoin.isLiveOpen, isTrue);
    });

    test('AuthViewModel.updateProfile synchronizes isLiveOpen state cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SupabaseService();
      final userRepo = UserRepository(service: service);
      final authVM = AuthViewModel(repository: userRepo);

      final user = await service.linkArtisanRoleToTourist(
        email: 'sync_artisan@warisankita.my',
        studioName: 'Sync Studio',
        craftCategory: 'Batik',
        ssmNumber: '202601009911',
      );
      authVM.setCurrentUserForTesting(user);

      expect(authVM.currentUser?.isLiveOpen, isTrue);

      // Toggled from dashboard
      await authVM.updateProfile(isLiveOpen: false);
      expect(authVM.currentUser?.isLiveOpen, isFalse);

      // Toggled back from profile builder
      await authVM.updateProfile(isLiveOpen: true);
      expect(authVM.currentUser?.isLiveOpen, isTrue);
    });
  });

  group('Artisan Profile Data Persistence & UI Reactivity Tests', () {
    test('UserModel serialization preserves artisanDocuments, tags, and bio across toMap and fromMap', () {
      const user = UserModel(
        id: 'artisan_test_uid',
        email: 'artisan@warisankita.my',
        role: 'Artisan',
        roles: ['Artisan'],
        status: 'ACTIVE',
        bio: 'Master woodcarver with 25 years of experience in Terengganu motifs.',
        studioName: 'Ukir Warisan Studio',
        craftCategory: 'Woodcarving',
        address: '123 Jalan Ukir, Kuala Terengganu',
        state: 'Terengganu',
        tags: ['Woodcarving', 'Teak Wood', 'Traditional Chisels'],
        artisanDocuments: [
          {
            'id': 'doc_img_1',
            'doc_type': 'PORTFOLIO_IMAGE',
            'file_name': 'portfolio_carving_1.webp',
            'file_url': 'https://supabase.co/storage/v1/object/public/artisan_public_media/portfolio_carving_1.webp',
          },
          {
            'id': 'doc_cert_1',
            'doc_type': 'BUSINESS_REGISTRATION',
            'file_name': 'ssm_cert.pdf',
            'file_url': 'https://supabase.co/storage/v1/object/public/artisan_private_docs/ssm_cert.pdf',
          },
        ],
      );

      final map = user.toMap();
      expect(map['bio'], 'Master woodcarver with 25 years of experience in Terengganu motifs.');
      expect(map['tags'], ['Woodcarving', 'Teak Wood', 'Traditional Chisels']);
      expect(map['artisan_documents'], isNotEmpty);
      expect((map['artisan_documents'] as List).length, 2);

      final restored = UserModel.fromMap(map);
      expect(restored.bio, 'Master woodcarver with 25 years of experience in Terengganu motifs.');
      expect(restored.tags, ['Woodcarving', 'Teak Wood', 'Traditional Chisels']);
      expect(restored.artisanDocuments.length, 2);
      expect(restored.artisanDocuments.first['doc_type'], 'PORTFOLIO_IMAGE');
      expect(restored.artisanDocuments.first['file_url'], contains('portfolio_carving_1.webp'));
    });

    test('UserModel.fromMap recovers artisan_profiles join with documents and bio', () {
      final joinedMap = {
        'id': 'artisan_join_uid',
        'email': 'join_artisan@warisankita.my',
        'role': 'Tourist', // initially Tourist in users table
        'status': 'ACTIVE',
        'full_name': 'Pak Awang',
        'artisan_profiles': {
          'id': 'prof_1',
          'studio_name': 'Bengkel Songket Awang',
          'craft_category': 'Songket Weaving',
          'bio': 'Specializing in fine gold thread Songket weaving since 1988.',
          'status': 'APPROVED',
          'tags': ['Gold Thread', 'Handloom'],
          'artisan_documents': [
            {
              'id': 'doc_1',
              'doc_type': 'STUDIO_PHOTO',
              'file_name': 'loom_workshop.webp',
              'file_url': 'https://supabase.co/storage/v1/object/public/artisan_public_media/loom_workshop.webp',
            }
          ],
        },
      };

      final parsed = UserModel.fromMap(joinedMap);
      expect(parsed.studioName, 'Bengkel Songket Awang');
      expect(parsed.craftCategory, 'Songket Weaving');
      expect(parsed.bio, 'Specializing in fine gold thread Songket weaving since 1988.');
      expect(parsed.tags, ['Gold Thread', 'Handloom']);
      expect(parsed.artisanDocuments.length, 1);
      expect(parsed.artisanDocuments.first['file_url'], contains('loom_workshop.webp'));
    });

    testWidgets('ProfileBuilderTab synchronizes bio and portfolio images when user updates via AuthViewModel', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final moderationVM = ModerationViewModel(repository: userRepo);

        // Initial user has empty bio and no documents
        authVM.setCurrentUserForTesting(
          const UserModel(
            id: 'reactive_artisan_uid',
            email: 'reactive@artisan.my',
            role: 'Artisan',
            roles: ['Artisan'],
            status: 'ACTIVE',
            bio: '',
            studioName: 'Reactive Batik Studio',
            craftCategory: 'Batik Painting',
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
              ChangeNotifierProvider<ModerationViewModel>.value(value: moderationVM),
              Provider<SupabaseService>.value(value: service),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ProfileBuilderTab(),
              ),
            ),
          ),
        );
        await tester.pump();
        while (tester.takeException() != null) {}

        // Initially bio field is empty
        final initialBioField = find.widgetWithText(TextFormField, 'Biography & Heritage Craft Story');
        expect(initialBioField, findsOneWidget);

        // Simulate profile loading with bio and portfolio photos
        authVM.setCurrentUserForTesting(
          const UserModel(
            id: 'reactive_artisan_uid',
            email: 'reactive@artisan.my',
            role: 'Artisan',
            roles: ['Artisan'],
            status: 'ACTIVE',
            bio: 'Preserving authentic Kelantan canting batik techniques for future generations.',
            studioName: 'Reactive Batik Studio',
            craftCategory: 'Batik Painting',
            tags: ['Canting', 'Natural Wax', 'Silk'],
            artisanDocuments: [
              {
                'doc_type': 'PORTFOLIO_IMAGE',
                'file_url': 'https://example.com/batik_1.webp',
                'file_name': 'batik_1.webp',
              }
            ],
          ),
        );

        await tester.pump();
        while (tester.takeException() != null) {}

        // The bio field and portfolio count should now reflect the refreshed data
        expect(find.text('Preserving authentic Kelantan canting batik techniques for future generations.'), findsOneWidget);
        expect(find.text('1 Uploaded (Unlimited)'), findsOneWidget);
        expect(find.text('Canting'), findsOneWidget);
      }, createHttpClient: (context) => _MockHttpClient());
    });

    test('updateUserProfile creates artisan_profiles and preserves bio, tags, and documents when row initially missing', () async {
        final service = SupabaseService();
        SharedPreferences.setMockInitialValues({});

        // Update profile for an artisan account whose artisan_profiles row was never created
        final updated = await service.updateUserProfile(
          email: 'newartisan@warisankita.my',
          username: 'master_kamal',
          displayName: 'Kamal Woodcraft',
          studioName: 'Kamal Ukiran Kayu',
          craftCategory: 'Traditional Woodcarving',
          bio: 'Specialist in Kelantan floral woodcarving with 25 years experience.',
          state: 'Kelantan',
          address: 'Lot 102, Kampung Laut, Tumpat',
          latitude: 6.1955,
          longitude: 102.2355,
          phone: '+60123456789',
          toolsAndMaterials: ['Chedung', 'Ketam Kayu', 'Kayu Cengal'],
        );

        expect(updated.username, equals('master_kamal'));
        expect(updated.studioName, equals('Kamal Ukiran Kayu'));
        expect(updated.craftCategory, equals('Traditional Woodcarving'));
        expect(updated.bio, equals('Specialist in Kelantan floral woodcarving with 25 years experience.'));
        expect(updated.state, equals('Kelantan'));
        expect(updated.address, equals('Lot 102, Kampung Laut, Tumpat'));
        expect(updated.latitude, equals(6.1955));
        expect(updated.longitude, equals(102.2355));
        expect(updated.phone, equals('+60123456789'));
        expect(updated.tags, containsAll(['Chedung', 'Ketam Kayu', 'Kayu Cengal']));
        expect(updated.role, equals('Artisan'));

        // Verify that getCurrentUser recovers the updated profile and does not drop any field
        final retrieved = await service.getCurrentUser();
        expect(retrieved, isNotNull);
        expect(retrieved!.bio, equals('Specialist in Kelantan floral woodcarving with 25 years experience.'));
        expect(retrieved.studioName, equals('Kamal Ukiran Kayu'));
        expect(retrieved.craftCategory, equals('Traditional Woodcarving'));
        expect(retrieved.tags, containsAll(['Chedung', 'Ketam Kayu', 'Kayu Cengal']));
        expect(retrieved.latitude, equals(6.1955));
        expect(retrieved.longitude, equals(102.2355));
      });

      test('updateUserProfile and UserModel persist and retrieve experience without rank title', () async {
        final service = SupabaseService();
        SharedPreferences.setMockInitialValues({});

        final updated = await service.updateUserProfile(
          email: 'experience_test@warisankita.my',
          username: 'master_azman',
          studioName: 'Azman Pottery Studio',
          craftCategory: 'Pottery & Ceramics',
          experience: '20+ Years Experience',
          bio: 'Practicing traditional Labu Sayong pottery craftsmanship for over two decades.',
          state: 'Perak',
        );

        expect(updated.experience, equals('20+ Years Experience'));

        // Verify serialization / deserialization
        final map = updated.toMap();
        expect(map['experience'], equals('20+ Years Experience'));
        final restored = UserModel.fromMap(map);
        expect(restored.experience, equals('20+ Years Experience'));

        // Test ProfileValidator for experience
        expect(ProfileValidator.validateExperience(null, isRequired: true), isNotNull);
        expect(ProfileValidator.validateExperience('', isRequired: true), isNotNull);
        expect(ProfileValidator.validateExperience('20+ Years Experience', isRequired: true), isNull);
        // Optional mode for profile builder
        expect(ProfileValidator.validateExperience(null, isRequired: false), isNull);
        expect(ProfileValidator.validateExperience('', isRequired: false), isNull);

        // Verify that default 1 year from database does NOT force '1 Years' onto user
        final defaultMap = {
          'id': 'u_default_1',
          'email': 'default@artisan.my',
          'role': 'Artisan',
          'artisan_profiles': {
            'years_experience': 1,
            'experience': null,
          }
        };
        final defaultUser = UserModel.fromMap(defaultMap);
        expect(defaultUser.experience, isNull);
      });

      test('Artisan experience persists on getCurrentUser (reload) and displays in admin getActiveArtisans and getAllUsers', () async {
        final service = SupabaseService();
        SharedPreferences.setMockInitialValues({});

        // 1. Artisan saves custom experience
        final updated = await service.updateUserProfile(
          email: 'reload_test_artisan@warisankita.my',
          username: 'batik_master_amin',
          studioName: 'Amin Batik House',
          craftCategory: 'Batik & Textiles',
          experience: '15 Years Craft Experience',
          bio: 'Preserving Terengganu silk batik heritage.',
          state: 'Terengganu',
        );

        expect(updated.experience, equals('15 Years Craft Experience'));

        // 2. Simulate app reload via getCurrentUser
        final reloaded = await service.getCurrentUser();
        expect(reloaded, isNotNull);
        expect(reloaded!.email, equals('reload_test_artisan@warisankita.my'));
        expect(reloaded.experience, equals('15 Years Craft Experience'));

        // 3. Verify Admin gets this artisan in getActiveArtisans with experience
        final activeArtisans = await service.getActiveArtisans();
        final foundActive = activeArtisans.firstWhere(
          (a) => a.email.toLowerCase() == 'reload_test_artisan@warisankita.my',
        );
        expect(foundActive.experience, equals('15 Years Craft Experience'));

        // 4. Verify Admin gets this artisan in getAllUsers with experience
        final allUsers = await service.getAllUsers();
        final foundUser = allUsers.firstWhere(
          (u) => u.email.toLowerCase() == 'reload_test_artisan@warisankita.my',
        );
        expect(foundUser.experience, equals('15 Years Craft Experience'));
      });

      testWidgets('EditProfileScreen renders and preserves custom craft category and all Malaysian states without overwrite', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final moderationVM = ModerationViewModel(repository: userRepo);

        // Seed an artisan user with custom state and craft category
        final customUser = UserModel(
          id: 'u_custom_craft_1',
          email: 'custom_craft@warisankita.my',
          username: 'custom_craft_artisan',
          displayName: 'Che Wan Craft',
          role: 'Artisan',
          status: 'ACTIVE',
          craftCategory: 'Wayang Kulit & Puppetry',
          state: 'Perlis',
          studioName: 'Che Wan Puppetry Studio',
          phone: '+60 19-876 5432',
        );
        authVM.setCurrentUserForTesting(customUser);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
              ChangeNotifierProvider<ModerationViewModel>.value(value: moderationVM),
            ],
            child: const MaterialApp(
              home: EditProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial values reflect custom user data rather than hardcoded defaults
        expect(find.text('Che Wan Craft'), findsOneWidget);
        expect(find.text('custom_craft_artisan'), findsOneWidget);
        expect(find.text('Wayang Kulit & Puppetry'), findsOneWidget);
        expect(find.text('Perlis'), findsOneWidget);

        // Ensure dummy strings are not present
        expect(find.text('Aiman Haziq'), findsNothing);
        expect(find.text('aiman_haziq'), findsNothing);
        expect(find.text('+60 12-345 6789'), findsNothing);
      });
    });
}
