import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/ui/core/account_suspended_screen.dart';
import 'package:warisan_kita/ui/tourist/tourist_main_scaffold.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late SupabaseService service;
  late UserRepository repository;
  late AuthViewModel authVM;
  late LanguageViewModel langVM;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SupabaseService();
    repository = UserRepository(service: service);
    authVM = AuthViewModel(repository: repository);
    langVM = LanguageViewModel();
  });

  group('Tourist Account Suspension Guard Tests', () {
    testWidgets('AccountSuspendedScreen displays suspension info and sign out button with fallback reason', (tester) async {
      const suspendedUser = UserModel(
        id: 'tourist-101',
        email: 'suspended.tourist@warisankita.my',
        username: 'suspended_tourist',
        displayName: 'Ahmad Suspended',
        role: 'Tourist',
        status: 'SUSPENDED',
        isSuspended: true,
      );
      authVM.setCurrentUserForTesting(suspendedUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
            ChangeNotifierProvider<LanguageViewModel>.value(value: langVM),
          ],
          child: const MaterialApp(
            home: AccountSuspendedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT SUSPENDED'), findsOneWidget);
      expect(find.text('Access Suspended'), findsOneWidget);
      expect(find.text('Ahmad Suspended'), findsOneWidget);
      expect(find.text('REASON FOR SUSPENSION'), findsOneWidget);
      expect(find.text('Violation of community guidelines and platform terms of service.'), findsOneWidget);
      expect(find.byKey(const Key('account_suspended_sign_out_button')), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('AccountSuspendedScreen displays specific admin suspension reason when provided', (tester) async {
      const suspendedUser = UserModel(
        id: 'tourist-102',
        email: 'reason.test@warisankita.my',
        username: 'abusive_user',
        displayName: 'Siti Flagged',
        role: 'Tourist',
        status: 'SUSPENDED',
        isSuspended: true,
        suspensionReason: 'Repeated offensive comments in Live Forum discussion',
      );
      authVM.setCurrentUserForTesting(suspendedUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
            ChangeNotifierProvider<LanguageViewModel>.value(value: langVM),
          ],
          child: const MaterialApp(
            home: AccountSuspendedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('REASON FOR SUSPENSION'), findsOneWidget);
      expect(find.text('Repeated offensive comments in Live Forum discussion'), findsOneWidget);
    });

    testWidgets('TouristMainScaffold shows AccountSuspendedScreen when user is suspended', (tester) async {
      const suspendedUser = UserModel(
        id: 'tourist-103',
        email: 'blocked@warisankita.my',
        username: 'blocked_user',
        role: 'Tourist',
        status: 'SUSPENDED',
        isSuspended: true,
        suspensionReason: 'Fraudulent activity report',
      );
      authVM.setCurrentUserForTesting(suspendedUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
            ChangeNotifierProvider<LanguageViewModel>.value(value: langVM),
          ],
          child: const MaterialApp(
            home: TouristMainScaffold(enableLivePolling: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render AccountSuspendedScreen instead of tourist tabs
      expect(find.byType(AccountSuspendedScreen), findsOneWidget);
      expect(find.text('ACCOUNT SUSPENDED'), findsOneWidget);
      expect(find.text('Access Suspended'), findsOneWidget);
      expect(find.text('Fraudulent activity report'), findsOneWidget);
    });

    testWidgets('AccountSuspendedScreen Sign Out logs out the user', (tester) async {
      const suspendedUser = UserModel(
        id: 'tourist-104',
        email: 'logout.test@warisankita.my',
        username: 'logout_user',
        role: 'Tourist',
        status: 'SUSPENDED',
        isSuspended: true,
      );
      authVM.setCurrentUserForTesting(suspendedUser);
      expect(authVM.currentUser, isNotNull);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
            ChangeNotifierProvider<LanguageViewModel>.value(value: langVM),
          ],
          child: MaterialApp(
            routes: {
              '/login': (context) => const Scaffold(body: Text('Login Screen')),
            },
            home: const AccountSuspendedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final signOutBtn = find.byKey(const Key('account_suspended_sign_out_button'));
      expect(signOutBtn, findsOneWidget);
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(authVM.currentUser, isNull);
      expect(find.text('Login Screen'), findsOneWidget);
    });

    test('ModerationViewModel.suspendUser records reason and reactivateUser clears it', () async {
      final moderationVM = ModerationViewModel(repository: repository);
      final users = await repository.getAllUsers();
      final targetUser = users.firstWhere((u) => !u.isAdmin);

      await moderationVM.suspendUser(targetUser.id, reason: 'Disrespectful forum behavior');
      final suspended = moderationVM.registeredUsers.firstWhere((u) => u.id == targetUser.id);
      expect(suspended.isSuspended, isTrue);
      expect(suspended.status, 'SUSPENDED');
      expect(suspended.suspensionReason, 'Disrespectful forum behavior');

      await moderationVM.reactivateUser(targetUser.id);
      final reactivated = moderationVM.registeredUsers.firstWhere((u) => u.id == targetUser.id);
      expect(reactivated.isSuspended, isFalse);
      expect(reactivated.status, 'ACTIVE');
      expect(reactivated.suspensionReason, isNull);
    });
  });
}
