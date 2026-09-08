import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/ui/auth/register_screen.dart';
import 'package:warisan_kita/ui/core/edit_profile_screen.dart';
import 'package:warisan_kita/ui/tourist/apply_artisan_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

const List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

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
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();
  group('ProfileValidator Unit Tests', () {
    test('validateUsername validates valid handles', () {
      expect(ProfileValidator.validateUsername('pakmat'), isNull);
      expect(ProfileValidator.validateUsername('siti_crafts'), isNull);
      expect(ProfileValidator.validateUsername('@aiman99'), isNull);
      expect(ProfileValidator.validateUsername('labu_sayong_01'), isNull);
    });

    test('validateUsername rejects invalid or reserved handles', () {
      expect(ProfileValidator.validateUsername(''), isNotNull);
      expect(ProfileValidator.validateUsername('   '), isNotNull);
      expect(ProfileValidator.validateUsername('ab'), isNotNull); // too short
      expect(ProfileValidator.validateUsername('a_very_long_handle_that_exceeds_twenty_characters'), isNotNull); // too long
      expect(ProfileValidator.validateUsername('pak-mat'), isNotNull); // hyphens not allowed in handle
      expect(ProfileValidator.validateUsername('pak mat'), isNotNull); // spaces not allowed
      expect(ProfileValidator.validateUsername('12345'), isNotNull); // numbers only without letters
      expect(ProfileValidator.validateUsername('admin'), isNotNull); // reserved
      expect(ProfileValidator.validateUsername('warisankita'), isNotNull); // reserved
      expect(ProfileValidator.validateUsername('system'), isNotNull); // reserved
    });

    test('validateFullName validates full names', () {
      expect(ProfileValidator.validateFullName('Pak Mat'), isNull);
      expect(ProfileValidator.validateFullName('Dr. Siti Nurhaliza'), isNull);
      expect(ProfileValidator.validateFullName("Aiman O'Connor"), isNull);
      expect(ProfileValidator.validateFullName('Che-Wan Nor'), isNull);

      expect(ProfileValidator.validateFullName(''), isNotNull);
      expect(ProfileValidator.validateFullName('A'), isNotNull); // too short
      expect(ProfileValidator.validateFullName('User1234!'), isNotNull); // numbers/special
    });

    test('validateStudioName validates genuine studio names', () {
      expect(ProfileValidator.validateStudioName('Pak Mat Pottery Studio'), isNull);
      expect(ProfileValidator.validateStudioName('Kuala Kangsar Ceramic Arts'), isNull);

      expect(ProfileValidator.validateStudioName(''), isNotNull);
      expect(ProfileValidator.validateStudioName('ab'), isNotNull); // too short
      expect(ProfileValidator.validateStudioName('test'), isNotNull); // placeholder
      expect(ProfileValidator.validateStudioName('dummy'), isNotNull); // placeholder
      expect(ProfileValidator.validateStudioName('studio'), isNotNull); // placeholder
      expect(ProfileValidator.validateStudioName('n/a'), isNotNull); // placeholder
    });

    test('validatePhone validates Malaysian and international formats', () {
      expect(ProfileValidator.validatePhone('+60 12-345 6789'), isNull);
      expect(ProfileValidator.validatePhone('0123456789'), isNull);
      expect(ProfileValidator.validatePhone('+60198765432'), isNull);
      expect(ProfileValidator.validatePhone('03-79551234'), isNull);
      expect(ProfileValidator.validatePhone('+442071838750'), isNull);

      // Optional when isRequired: false
      expect(ProfileValidator.validatePhone('', isRequired: false), isNull);
      expect(ProfileValidator.validatePhone(null, isRequired: false), isNull);

      // Required when isRequired: true
      expect(ProfileValidator.validatePhone('', isRequired: true), isNotNull);

      // Rejects dummy patterns and letters
      expect(ProfileValidator.validatePhone('12345678'), isNotNull);
      expect(ProfileValidator.validatePhone('00000000'), isNotNull);
      expect(ProfileValidator.validatePhone('not-a-phone'), isNotNull);
      expect(ProfileValidator.validatePhone('123'), isNotNull);
    });

    test('validateBio validates biography lengths', () {
      expect(
        ProfileValidator.validateBio(
          'Master Pak Mat has been hand-crafting traditional clay labu sayong for over 25 years.',
          isRequired: true,
        ),
        isNull,
      );

      expect(ProfileValidator.validateBio('', isRequired: true), isNotNull);
      expect(ProfileValidator.validateBio('Too short', isRequired: true, minLength: 15), isNotNull);
      expect(ProfileValidator.validateBio('', isRequired: false), isNull);
    });

    test('validateEmail validates format', () {
      expect(ProfileValidator.validateEmail('tourist@warisankita.my'), isNull);
      expect(ProfileValidator.validateEmail('artisan@gmail.com'), isNull);

      expect(ProfileValidator.validateEmail(''), isNotNull);
      expect(ProfileValidator.validateEmail('notanemail'), isNotNull);
      expect(ProfileValidator.validateEmail('user@'), isNotNull);
      expect(ProfileValidator.validateEmail('@domain.com'), isNotNull);
    });

    test('validatePassword & confirmPassword validate security constraints', () {
      expect(ProfileValidator.validatePassword('Heritage2026!'), isNull);
      expect(ProfileValidator.validatePassword('short'), isNotNull); // < 8 chars
      expect(ProfileValidator.validatePassword('allletterspassword'), isNotNull); // no numbers
      expect(ProfileValidator.validatePassword('1234567890'), isNotNull); // no letters

      expect(ProfileValidator.validateConfirmPassword('Heritage2026!', 'Heritage2026!'), isNull);
      expect(ProfileValidator.validateConfirmPassword('Heritage2026!', 'DifferentPass'), isNotNull);
      expect(ProfileValidator.validateConfirmPassword('', 'Heritage2026!'), isNotNull);
    });

    test('validateTag validates tools, materials, and duplicates', () {
      final existingTags = ['River Clay', 'Natural Dyes'];
      expect(ProfileValidator.validateTag('Paddy Husk Kiln Ash', existingTags), isNull);
      expect(ProfileValidator.validateTag('', existingTags), isNotNull);
      expect(ProfileValidator.validateTag('A', existingTags), isNotNull); // too short
      expect(ProfileValidator.validateTag('River Clay', existingTags), isNotNull); // duplicate
      expect(ProfileValidator.validateTag('river clay', existingTags), isNotNull); // case-insensitive duplicate
    });

    test('validateState validates Malaysian states', () {
      expect(ProfileValidator.validateState('Melaka'), isNull);
      expect(ProfileValidator.validateState('Terengganu'), isNull);
      expect(ProfileValidator.validateState('Sabah'), isNull);

      expect(ProfileValidator.validateState(''), isNotNull);
      expect(ProfileValidator.validateState('California'), isNotNull);
      expect(ProfileValidator.validateState('Singapore'), isNotNull);
    });
  });

  group('Profile Builder & Edit Profile Widget Validation Tests', () {
    late SupabaseService mockService;
    late UserRepository userRepo;
    late ArtisanRepository artisanRepo;
    late AuthViewModel authVM;
    late DirectoryViewModel directoryVM;
    late ModerationViewModel moderationVM;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockService = SupabaseService();
      userRepo = UserRepository(service: mockService);
      artisanRepo = ArtisanRepository(service: mockService);
      authVM = AuthViewModel(repository: userRepo);
      directoryVM = DirectoryViewModel(repository: artisanRepo);
      moderationVM = ModerationViewModel(repository: userRepo);
      await authVM.login('artisan@warisankita.my', 'password123');
    });

    testWidgets('ProfileBuilderTab shows validation errors when fields are cleared and saved', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: directoryVM),
            ChangeNotifierProvider.value(value: moderationVM),
            Provider.value(value: mockService),
          ],
          child: const MaterialApp(
            home: ProfileBuilderTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find username TextFormField and clear it
      final usernameField = find.widgetWithText(TextFormField, 'Account Username / Handle (@username)');
      expect(usernameField, findsOneWidget);
      await tester.enterText(usernameField, '');
      await tester.pumpAndSettle();

      // Find studio name TextFormField and enter invalid placeholder
      final studioField = find.widgetWithText(TextFormField, 'Artisan Studio Name');
      expect(studioField, findsOneWidget);
      await tester.enterText(studioField, 'test');
      await tester.pumpAndSettle();

      // Scroll down to SAVE PROFILE button
      final saveBtn = find.text('SAVE PROFILE');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Username handle cannot be empty'), findsOneWidget);
      expect(find.text('Please enter a genuine, recognizable studio or workshop name'), findsOneWidget);
      expect(find.text('Please correct the highlighted form errors before saving.'), findsOneWidget);
    });

    testWidgets('EditProfileScreen shows validation errors when handle is invalid', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: moderationVM),
          ],
          child: const MaterialApp(
            home: EditProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final usernameField = find.widgetWithText(TextFormField, 'Unique Username Handle');
      expect(usernameField, findsOneWidget);
      await tester.enterText(usernameField, 'ab'); // too short
      await tester.pumpAndSettle();

      final saveBtn = find.text('SAVE & SYNC PROFILE');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
      expect(find.text('Please correct the highlighted form errors before saving.'), findsOneWidget);
    });

    testWidgets('RegisterScreen validates full name and username handles using ProfileValidator', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid full name with numbers/special symbols
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'User123!');
      await tester.pumpAndSettle();

      // Enter handle that is too short
      final handleField = find.widgetWithText(TextFormField, 'Unique Username / Handle');
      expect(handleField, findsOneWidget);
      await tester.enterText(handleField, 'ab');
      await tester.pumpAndSettle();

      // Tap Register button
      final regBtn = find.widgetWithText(FilledButton, 'Create Explorer Account');
      expect(regBtn, findsOneWidget);
      await tester.ensureVisible(regBtn);
      await tester.tap(regBtn);
      await tester.pumpAndSettle();

      expect(find.text('Full name can only contain letters, spaces, hyphens, and apostrophes'), findsOneWidget);
      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('ApplyArtisanScreen enforces Studio Name and Bio validation on submit', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: moderationVM),
          ],
          child: const MaterialApp(
            home: ApplyArtisanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid placeholder studio name
      final studioField = find.widgetWithText(TextFormField, 'Studio Name *');
      expect(studioField, findsOneWidget);
      await tester.enterText(studioField, 'test');
      await tester.pumpAndSettle();

      // Enter short bio
      final bioField = find.widgetWithText(TextFormField, 'Studio Heritage Bio *');
      expect(bioField, findsOneWidget);
      await tester.enterText(bioField, 'short');
      await tester.pumpAndSettle();

      // Tap submit
      final submitBtn = find.widgetWithText(FilledButton, 'Submit Artisan Application');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a genuine, recognizable studio or workshop name'), findsOneWidget);
      expect(find.text('Bio must be at least 15 characters'), findsOneWidget);
    });
  });
}
