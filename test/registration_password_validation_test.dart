import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/ui/auth/register_screen.dart';
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

  Widget buildTestWidget() {
    return ChangeNotifierProvider<AuthViewModel>.value(
      value: authVM,
      child: const MaterialApp(
        home: RegisterScreen(),
      ),
    );
  }

  group('Registration Password Validation Tests (aligned with Settings & Reset Password)', () {
    testWidgets('shows correct error when password is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final registerBtn = find.text('Create Explorer Account');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('shows 8-character minimum error on password field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'short');
      final registerBtn = find.text('Create Explorer Account');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('detects password too similar to chosen username', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. siticrafts'), 'craftmaster');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'craftmaster');
      final registerBtn = find.text('Create Explorer Account');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Password is too similar to your username'), findsOneWidget);
    });

    testWidgets('shows mismatch error on confirm password field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'ValidPass123!');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'DifferentPass123!');
      final registerBtn = find.text('Create Explorer Account');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('allows independent password visibility toggling', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final visibilityOffIcons = find.byIcon(Icons.visibility_off);
      expect(visibilityOffIcons, findsNWidgets(2));

      // Toggle first (password)
      await tester.tap(visibilityOffIcons.first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
