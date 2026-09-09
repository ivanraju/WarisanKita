import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/admin_web/widgets/artisan_review_dialog.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

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
      final user = UserModel(
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
      final email = 'reloc.artisan@warisankita.my';

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
      final service = SupabaseService();
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
}
