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
    testWidgets('AccountSuspendedScreen displays suspension info and sign out button', (tester) async {
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
      expect(find.byKey(const Key('account_suspended_sign_out_button')), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('TouristMainScaffold shows AccountSuspendedScreen when user is suspended', (tester) async {
      const suspendedUser = UserModel(
        id: 'tourist-102',
        email: 'blocked@warisankita.my',
        username: 'blocked_user',
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
            home: TouristMainScaffold(enableLivePolling: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render AccountSuspendedScreen instead of tourist tabs
      expect(find.byType(AccountSuspendedScreen), findsOneWidget);
      expect(find.text('ACCOUNT SUSPENDED'), findsOneWidget);
      expect(find.text('Access Suspended'), findsOneWidget);
    });

    testWidgets('AccountSuspendedScreen Sign Out logs out the user', (tester) async {
      const suspendedUser = UserModel(
        id: 'tourist-103',
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
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(authVM.currentUser, isNull);
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
