import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/ui/auth/email_verification_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseService service;
  late UserRepository repository;
  late AuthViewModel authVM;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SupabaseService();
    repository = UserRepository(service: service);
    authVM = AuthViewModel(repository: repository);
  });

  group('Email Validation & Supabase OTP Verification Unit Tests', () {
    test('Invalid email regex formats are rejected during tourist registration', () async {
      final invalidEmails = [
        'plainaddress',
        r'#@%^%#$@#$@#.com',
        '@example.com',
        'Joe Smith <email@example.com>',
        'email.example.com',
      ];

      for (final email in invalidEmails) {
        final result = await authVM.registerTourist(
          username: 'tester',
          email: email,
          password: 'validPassword123',
          confirmPassword: 'validPassword123',
        );
        expect(result.success, isFalse);
        expect(result.message, contains('VALID EMAIL'));
      }
    });

    test('Master test OTP 123456 verifies email successfully and creates active user session', () async {
      const email = 'verify.test@warisankita.my';
      
      // Register initial account
      await authVM.registerTourist(
        username: 'verifyuser',
        email: email,
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Verify with 123456
      final result = await authVM.verifyEmailOtp(
        email: email,
        token: '123456',
        targetRoute: '/tourist',
      );

      expect(result.success, isTrue);
      expect(result.user?.email, equals(email));
      expect(result.route, equals('/tourist'));
      expect(authVM.currentUser?.email, equals(email));
    });

    test('Incorrect 6-digit OTP code is rejected with INVALID_OTP error', () async {
      const email = 'verify.fail@warisankita.my';
      
      await authVM.registerTourist(
        username: 'failuser',
        email: email,
        password: 'password123',
        confirmPassword: 'password123',
      );

      final result = await authVM.verifyEmailOtp(
        email: email,
        token: '999999',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('invalid or has expired'));
    });

    test('Entering incomplete OTP token (< 6 digits) fails client-side validation', () async {
      final result = await authVM.verifyEmailOtp(
        email: 'test@warisankita.my',
        token: '123',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('6-DIGIT VERIFICATION CODE'));
    });

    test('Resend verification OTP updates pending OTP storage and returns success', () async {
      const email = 'resend.test@warisankita.my';
      
      final sent = await authVM.resendVerificationOtp(email);
      expect(sent, isTrue);
      expect(authVM.statusMessage, contains('6-digit verification code'));
    });
  });

  group('EmailVerificationScreen Widget Tests', () {
    testWidgets('Renders 6 input boxes, email label, and resend action', (tester) async {
      const email = 'explorer@warisankita.my';

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVM,
            child: const EmailVerificationScreen(
              email: email,
              targetRoute: '/tourist',
              autoStartTimer: false,
            ),
          ),
        ),
      );

      // Verify email text is displayed
      expect(find.text(email), findsOneWidget);
      expect(find.text('Verify Your Email'), findsOneWidget);

      // Verify 6 input fields are present
      expect(find.byType(TextFormField), findsNWidgets(6));

      // Verify action buttons
      expect(find.text('Verify & Proceed'), findsOneWidget);
      expect(find.textContaining('Resend in'), findsOneWidget);
      expect(find.text('Change email address'), findsOneWidget);
    });

    testWidgets('EmailVerificationScreen initializes with clean state and form fields', (tester) async {
      const email = 'widget.test@warisankita.my';

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVM,
            child: const EmailVerificationScreen(
              email: email,
              targetRoute: '/tourist',
              autoStartTimer: false,
            ),
          ),
        ),
      );

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6));
    });
  });
}
