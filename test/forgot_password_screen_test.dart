import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';
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

  Widget buildTestWidget({int initialStep = 3, String? initialEmail}) {
    return ChangeNotifierProvider<AuthViewModel>.value(
      value: authVM,
      child: MaterialApp(
        home: ForgotPasswordScreen(
          initialStep: initialStep,
          initialEmail: initialEmail,
        ),
      ),
    );
  }

  group('ForgotPasswordScreen Validation Tests (matching ChangePasswordDialog)', () {
    testWidgets('shows correct error when new password is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final resetBtn = find.text('RESET PASSWORD');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a new password'), findsOneWidget);
      expect(find.text('New password must be at least 8 characters'), findsNothing);
    });

    testWidgets('shows 8-character minimum error specifically on new password field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'short');
      final resetBtn = find.text('RESET PASSWORD');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('New password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows empty error on confirm password field when confirm is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'ValidPass123!');
      final resetBtn = find.text('RESET PASSWORD');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please confirm your new password'), findsOneWidget);
    });

    testWidgets('shows mismatch error on confirm password field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'ValidNewPass123!');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm New Password'), 'DifferentPass123!');
      final resetBtn = find.text('RESET PASSWORD');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('New passwords do not match'), findsOneWidget);
    });

    testWidgets('clears error messages when user types in password fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final resetBtn = find.text('RESET PASSWORD');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a new password'), findsOneWidget);

      // Typing in new password clears error
      await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'a');
      await tester.pumpAndSettle();

      expect(find.text('Please enter a new password'), findsNothing);
    });

    testWidgets('allows independent password visibility toggling', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final visibilityOffIcons = find.byIcon(Icons.visibility_off);
      expect(visibilityOffIcons, findsNWidgets(2));

      // Toggle first (new password)
      await tester.tap(visibilityOffIcons.first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('validates email on step 1', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialStep: 1));
      await tester.pumpAndSettle();

      final sendBtn = find.text('SEND RESET LINK');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your registered email'), findsOneWidget);

      // Enter invalid email format
      await tester.enterText(find.widgetWithText(TextField, 'Registered Email Address'), 'invalid-email');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('renders properly with high-contrast elements in dark mode', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authVM,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const ForgotPasswordScreen(initialStep: 3),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('RESET PASSWORD'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'New Password'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirm New Password'), findsOneWidget);
    });
  });
}
