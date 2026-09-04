import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/ui/core/edit_profile_screen.dart';
import 'package:warisan_kita/ui/core/settings_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';

base class MockPlatformFile extends PlatformFile {
  @override
  final String name;
  final Uint8List _fakeBytes;
  @override
  final String? path;

  MockPlatformFile({
    required this.name,
    required Uint8List bytes,
    this.path,
  }) : _fakeBytes = bytes;

  @override
  Future<Uint8List> readAsBytes() async => _fakeBytes;

  @override
  Future<int> length() async => _fakeBytes.length;

  @override
  Stream<Uint8List> readAsByteStream() async* {
    yield _fakeBytes;
  }

  @override
  Uri get uri => Uri.file(path ?? name);

  @override
  XFile get xFile => XFile.fromData(_fakeBytes, name: name, path: path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late SupabaseService service;
  late UserRepository repository;
  late AuthViewModel authVM;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SupabaseService();
    repository = UserRepository(service: service);
    authVM = AuthViewModel(repository: repository);
  });

  final validPngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82
  ]);

  group('Profile Avatar Upload & Persistence Tests', () {
    test('UserRepository.uploadUserAvatar processes platform file and returns URL', () async {
      final platformFile = MockPlatformFile(
        name: 'my_avatar.png',
        bytes: validPngBytes,
      );

      final url = await repository.uploadUserAvatar('tourist@warisankita.my', platformFile);
      expect(url, isNotNull);
      expect(url, isNotEmpty);
    });

    test('updateUserProfile with avatarUrl persists and updates user model', () async {
      await authVM.login('tourist@warisankita.my', 'password123');
      expect(authVM.currentUser, isNotNull);

      await authVM.updateProfile(
        username: 'aiman_explorer',
        displayName: 'Aiman Explorer',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      );

      expect(authVM.currentUser?.avatarUrl, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400');
      expect(authVM.currentUser?.username, 'aiman_explorer');
    });

    test('AuthViewModel.uploadAvatar updates currentUser avatarUrl and notifies listeners', () async {
      await authVM.login('tourist@warisankita.my', 'password123');

      final platformFile = MockPlatformFile(
        name: 'new_photo.png',
        bytes: validPngBytes,
      );

      final url = await authVM.uploadAvatar(platformFile);
      expect(url, isNotNull);
      expect(authVM.currentUser?.avatarUrl, url);
      expect(authVM.currentUser?.avatarImageProvider, isNotNull);
    });
  });

  group('EditProfileScreen & SettingsScreen Avatar UI Tests', () {
    testWidgets('EditProfileScreen renders user initials when avatarUrl is null', (tester) async {
      final loginFuture = authVM.login('tourist@warisankita.my', 'password123');
      await tester.pump(const Duration(milliseconds: 500));
      await loginFuture;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider(create: (_) => ModerationViewModel(repository: repository)),
          ],
          child: const MaterialApp(
            home: EditProfileScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.text('SAVE & SYNC PROFILE'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders avatar header card with user profile info', (tester) async {
      final loginFuture = authVM.login('tourist@warisankita.my', 'password123');
      await tester.pump(const Duration(milliseconds: 500));
      await loginFuture;

      const matchmakerRepo = MatchmakerRepository();
      final matchmakerVM = MatchmakerViewModel(repository: matchmakerRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageViewModel()),
            ChangeNotifierProvider(create: (_) => ThemeViewModel()),
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: matchmakerVM),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(authVM.currentUser!.effectiveUsername), findsOneWidget);
      expect(find.text(authVM.currentUser!.email), findsOneWidget);
    });
  });
}
