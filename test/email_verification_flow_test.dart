import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/ui/auth/email_verification_screen.dart';
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

  group('Unconfirmed Registration & Change Email Flow Tests', () {
    test('cancelPendingRegistration frees username and email for reuse', () async {
      // 1. Sign up tourist with initial email and username
      final regResult = await authVM.registerTourist(
        email: 'typo@warisankita.my',
        username: 'heritagefan',
        fullName: 'Heritage Fan',
        password: 'Password123!',
        confirmPassword: 'Password123!',
      );
      expect(regResult.success, isTrue);
      expect(regResult.requiresEmailVerification, isTrue);

      // 2. Check username availability: since it is registered, it is NOT available
      final availableBefore = await authVM.isUsernameAvailable('heritagefan');
      expect(availableBefore, isFalse);

      // 3. User cancels pending registration to change email
      final cancelled = await authVM.cancelPendingRegistration('typo@warisankita.my');
      expect(cancelled, isTrue);

      // 4. Username is now available again!
      final availableAfter = await authVM.isUsernameAvailable('heritagefan');
      expect(availableAfter, isTrue);

      // 5. User can now register with the corrected email and the SAME username!
      final newRegResult = await authVM.registerTourist(
        email: 'correct@warisankita.my',
        username: 'heritagefan',
        fullName: 'Heritage Fan',
        password: 'Password123!',
        confirmPassword: 'Password123!',
      );
      expect(newRegResult.success, isTrue);
      expect(newRegResult.requiresEmailVerification, isTrue);
    });

    testWidgets('EmailVerificationScreen displays confirmation dialog when tapping Change email address', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authVM,
          child: const MaterialApp(
            home: EmailVerificationScreen(
              email: 'typo@warisankita.my',
              autoStartTimer: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen renders email
      expect(find.text('typo@warisankita.my'), findsOneWidget);
      expect(find.text('Change email address'), findsOneWidget);

      // Tap "Change email address"
      await tester.ensureVisible(find.text('Change email address'));
      await tester.tap(find.text('Change email address'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Change Email Address?'), findsOneWidget);
      expect(find.text('Keep Waiting'), findsOneWidget);
      expect(find.text('Change Email'), findsOneWidget);

      // Tap "Keep Waiting" to dismiss
      await tester.tap(find.text('Keep Waiting'));
      await tester.pumpAndSettle();

      // Verify dialog is gone and still on verification screen
      expect(find.text('Change Email Address?'), findsNothing);
      expect(find.text('typo@warisankita.my'), findsOneWidget);
    });

    testWidgets('Confirming Change Email calls cancelPendingRegistration and pops', (tester) async {
      // First create pending account in backend
      backend.add(
        'typo@warisankita.my',
        username: 'traveler99',
        role: 'Tourist',
        confirmed: false,
        password: 'Password123!',
      );

      bool popped = false;
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authVM,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final res = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const EmailVerificationScreen(
                        email: 'typo@warisankita.my',
                        autoStartTimer: false,
                      ),
                    ),
                  );
                  if (res == true) popped = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap "Change email address"
      await tester.ensureVisible(find.text('Change email address'));
      await tester.tap(find.text('Change email address'));
      await tester.pumpAndSettle();

      // Confirm "Change Email"
      await tester.tap(find.text('Change Email'));
      await tester.pumpAndSettle();

      // Verify popped back with true
      expect(popped, isTrue);
      // Verify account was removed from backend
      expect(backend.accounts.containsKey('typo@warisankita.my'), isFalse);
    });

    testWidgets('AppBar back button pops without cancelling pending registration (Option A)', (tester) async {
      backend.add(
        'pending@warisankita.my',
        username: 'pendinguser',
        role: 'Tourist',
        confirmed: false,
        password: 'Password123!',
      );

      bool popped = false;
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authVM,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmailVerificationScreen(
                        email: 'pending@warisankita.my',
                        autoStartTimer: false,
                      ),
                    ),
                  );
                  popped = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap AppBar back arrow
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Verify popped back
      expect(popped, isTrue);
      // Account is STILL in backend (not deleted!)
      expect(backend.accounts.containsKey('pending@warisankita.my'), isTrue);
    });
  });
}
