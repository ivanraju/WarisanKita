import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';
import 'package:warisan_kita/ui/auth/register_screen.dart';
import 'package:warisan_kita/ui/core/widgets/change_password_dialog.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'support/auth_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthBackend backend;
  late SupabaseService service;
  late UserRepository repo;
  late AuthViewModel authVM;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = AuthBackend();
    service = SupabaseService(client: backend.client);
    repo = UserRepository(service: service);
    authVM = AuthViewModel(repository: repo);
  });

  tearDown(() async {
    await backend.client.dispose();
  });

  group('ProfileValidator.validatePasswordPersonalDetails Unit Tests', () {
    test('rejects exact email match', () {
      final err = ProfileValidator.validatePasswordPersonalDetails(
        'ali@warisankita.my',
        email: 'ali@warisankita.my',
      );
      expect(err, 'Password cannot be your email address');
    });

    test('rejects email prefix match and derivative', () {
      final errExact = ProfileValidator.validatePasswordPersonalDetails(
        'alikamal',
        email: 'alikamal@gmail.com',
      );
      expect(errExact, 'Password cannot contain your email address');

      final errDerivative = ProfileValidator.validatePasswordPersonalDetails(
        'alikamal123!',
        email: 'alikamal@gmail.com',
      );
      expect(errDerivative, 'Password cannot contain your email address');
    });

    test('rejects exact username and derivative', () {
      final errExact = ProfileValidator.validatePasswordPersonalDetails(
        'kancil99',
        username: 'kancil99',
      );
      expect(errExact, 'Password is too similar to your username');

      final errDerivative = ProfileValidator.validatePasswordPersonalDetails(
        'kancil99!2026',
        username: 'kancil99',
      );
      expect(errDerivative, 'Password is too similar to your username');
    });

    test('rejects full name and name components', () {
      final errFull = ProfileValidator.validatePasswordPersonalDetails(
        'ahmadzaki',
        fullName: 'Ahmad Zaki',
      );
      expect(errFull, 'Password cannot be your name');

      final errFirst = ProfileValidator.validatePasswordPersonalDetails(
        'Ahmad2026!',
        fullName: 'Ahmad Zaki',
      );
      expect(errFirst, 'Password cannot contain your name');

      final errSecond = ProfileValidator.validatePasswordPersonalDetails(
        'PassZaki123',
        fullName: 'Ahmad Zaki',
      );
      expect(errSecond, 'Password cannot contain your name');
    });

    test('allows complex passwords containing short names incidentally', () {
      // Short 2-letter name "Li" shouldn't block "ReliableHeritage2026!"
      final errName = ProfileValidator.validatePasswordPersonalDetails(
        'ReliableHeritage2026!',
        fullName: 'Li',
      );
      expect(errName, isNull);

      // Short 3-letter username "dan" shouldn't block "SpontaneousPass2026!"
      final errUser = ProfileValidator.validatePasswordPersonalDetails(
        'SpontaneousPass2026!',
        username: 'dan',
      );
      expect(errUser, isNull);

      // Short email prefix "ed" shouldn't block "Credibility2026!"
      final errEmail = ProfileValidator.validatePasswordPersonalDetails(
        'Credibility2026!',
        email: 'ed@gmail.com',
      );
      expect(errEmail, isNull);
    });
  });

  group('AuthViewModel Personal Details Password Enforcement', () {
    test('registerTourist rejects password containing username, email, or full name', () async {
      final resUser = await authVM.registerTourist(
        email: 'test@warisankita.my',
        username: 'explorer99',
        fullName: 'Ahmad Zaki',
        password: 'explorer99!pass',
        confirmPassword: 'explorer99!pass',
      );
      expect(resUser.success, isFalse);
      expect(resUser.message, contains('USERNAME'));

      final resName = await authVM.registerTourist(
        email: 'test@warisankita.my',
        username: 'explorer99',
        fullName: 'Ahmad Zaki',
        password: 'Ahmad2026!Pass',
        confirmPassword: 'Ahmad2026!Pass',
      );
      expect(resName.success, isFalse);
      expect(resName.message, contains('NAME'));
    });
  });

  group('Widget Tests for Personal Information Password Rejection', () {
    testWidgets('RegisterScreen shows error when password contains username or name', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authVM,
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. siticrafts'), 'sarah99');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'sarah99!Pass');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'sarah99!Pass');

      final btn = find.text('Create Explorer Account');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Password is too similar to your username'), findsOneWidget);
    });

    testWidgets('ChangePasswordDialog shows error when new password contains user attributes', (tester) async {
      // Set current logged in user
      authVM.setCurrentUserForTesting(
        UserModel(
          id: 'u1',
          email: 'explorer@warisankita.my',
          username: 'kancil99',
          displayName: 'Kancil Explorer',
          role: 'Tourist',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authVM,
          child: const MaterialApp(
            home: Scaffold(body: ChangePasswordDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter fields
      await tester.enterText(find.widgetWithText(TextField, 'Current Password'), 'OldPassword123');
      await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'kancil99!2026');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm New Password'), 'kancil99!2026');

      final updateBtn = find.text('Update Password');
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(find.text('Password is too similar to your username'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen shows error when new password contains email prefix', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authVM,
          child: const MaterialApp(
            home: ForgotPasswordScreen(
              initialStep: 3,
              initialEmail: 'sarahnor@gmail.com',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'sarahnor!2026');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm New Password'), 'sarahnor!2026');

      final resetBtn = find.text('RESET PASSWORD');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Password cannot contain your email address'), findsOneWidget);
    });
  });
}
