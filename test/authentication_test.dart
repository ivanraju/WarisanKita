import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/ui/auth/register_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'support/auth_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthBackend backend;
  late SupabaseService service;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = AuthBackend();
    service = SupabaseService(client: backend.client);
  });
  tearDown(() async => backend.client.dispose());

  test('login exposes a readable error while rejecting incorrect credentials', () async {
    backend.add('login@test.com');
    final vm = AuthViewModel(repository: UserRepository(service: service));
    final result = await vm.login('login@test.com', 'WrongPassword123!');
    expect(result.success, isFalse);
    expect(result.message,
        'Incorrect email, username, or password. Please try again.');
    expect(vm.errorMessage, result.message);
    expect(vm.isAuthenticated, isFalse);
    expect(backend.client.auth.currentSession, isNull);
  });

  test(
    'demo admin credentials cannot authenticate without backend approval',
    () async {
      await expectLater(
        service.signIn('admin', 'password123'),
        throwsA(anything),
      );
      expect(await service.getCurrentUser(), isNull);
    },
  );
  test('real admin uses backend authentication and role', () async {
    backend.add('realadmin@test.com', username: 'admin', role: 'Admin');
    expect((await service.signIn('admin', 'Password123!')).isAdmin, isTrue);
    expect(backend.requests.any((r) => r.url.path.endsWith('/token')), isTrue);
  });
  test('names and email addresses do not grant administrator privileges', () {
    expect(
      const UserModel(
        id: '1',
        email: 'admin@warisankita.my',
        username: 'admin',
        role: 'Tourist',
      ).isAdmin,
      isFalse,
    );
  });
  test('underscores and leading @ are preserved in username lookup', () async {
    backend.add('ali@test.com', username: 'ali_ahmad');
    expect(
      (await service.signIn('@ali_ahmad', 'Password123!')).email,
      'ali@test.com',
    );
    expect(backend.usernameFilter, r'ilike.ali\_ahmad');
  });
  test(
    'unverified registration cannot log in through a local fallback',
    () async {
      await service.signUp(
        email: 'new@test.com',
        password: 'Password123!',
        role: 'Tourist',
      );
      await expectLater(
        service.signIn('new@test.com', 'Password123!'),
        throwsA(anything),
      );
      expect(await service.getCurrentUser(), isNull);
    },
  );
  test(
    'master verification code cannot authenticate known or unknown email',
    () async {
      backend.add('known@test.com', confirmed: false);
      for (final email in ['known@test.com', 'unknown@test.com']) {
        await expectLater(
          service.verifyEmailOtp(email: email, token: '123456'),
          throwsA(anything),
        );
        expect(await service.getCurrentUser(), isNull);
      }
    },
  );
  test('backend verified code authenticates and restores profile', () async {
    backend.add('verified@test.com', confirmed: false);
    final user = await service.verifyEmailOtp(
      email: 'verified@test.com',
      token: '654321',
    );
    expect(user.email, 'verified@test.com');
    expect((await service.getCurrentUser())?.id, user.id);
    await service.signOut();
    expect(await service.getCurrentUser(), isNull);
  });
  test(
    'cached admin profile without backend session does not restore access',
    () async {
      SharedPreferences.setMockInitialValues({
        'wk_last_auth_user': jsonEncode({
          'id': '1',
          'email': 'cached@test.com',
          'role': 'Admin',
          'status': 'ACTIVE',
        }),
      });
      expect(await service.getCurrentUser(), isNull);
    },
  );
  test('missing or suspended database profile cannot authenticate', () async {
    backend.add('suspended@test.com')['status'] = 'SUSPENDED';
    await expectLater(
      service.signIn('suspended@test.com', 'Password123!'),
      throwsA(anything),
    );
    expect(backend.client.auth.currentSession, isNull);
    backend.add('missing@test.com');
    backend.failures['/rest/v1/users'] = 'Profile unavailable';
    await expectLater(
      service.signIn('missing@test.com', 'Password123!'),
      throwsA(anything),
    );
    expect(backend.client.auth.currentSession, isNull);
  });
  test(
    'signup failure does not create substitute profile or session',
    () async {
      backend.failures['/auth/v1/signup'] = 'Rate limited';
      await expectLater(
        service.signUp(
          email: 'failed@test.com',
          password: 'Password123!',
          role: 'Tourist',
        ),
        throwsA(anything),
      );
      expect(backend.accounts, isEmpty);
      expect(
        backend.requests.where(
          (r) => r.method == 'POST' && r.url.path == '/rest/v1/users',
        ),
        isEmpty,
      );
    },
  );
  test('reset and resend delivery errors propagate', () async {
    backend.add('user@test.com');
    backend.failures['/auth/v1/recover'] = 'Email delivery failed';
    backend.failures['/auth/v1/resend'] = 'Email delivery failed';
    await expectLater(
      service.sendPasswordResetEmail('user@test.com'),
      throwsA(anything),
    );
    await expectLater(
      service.resendVerificationOtp(email: 'user@test.com'),
      throwsA(anything),
    );
  });
  test('password reset requires a registered email address', () async {
    await expectLater(
      service.sendPasswordResetEmail('missing@test.com'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('EMAIL NOT FOUND'),
        ),
      ),
    );
    expect(
      backend.requests.where((request) => request.url.path.endsWith('/recover')),
      isEmpty,
    );

    backend.add('registered@test.com');
    await service.sendPasswordResetEmail('registered@test.com');
    expect(
      backend.requests.where((request) => request.url.path.endsWith('/recover')),
      hasLength(1),
    );
  });
  test('administrator accounts cannot request password reset via email', () async {
    backend.add('admin@warisankita.my', role: 'Tourist');
    backend.add('clqadmin@gmail.com', role: 'Admin', username: 'clqadmin');
    backend.add('staff@test.com', role: 'Admin', username: 'staffadmin');
    backend.add('user_named_admin@test.com', role: 'Tourist', username: 'admin');

    for (final email in [
      'admin@warisankita.my',
      'clqadmin@gmail.com',
      'admin@example.org',
      'staff@test.com',
      'user_named_admin@test.com',
    ]) {
      await expectLater(
        service.sendPasswordResetEmail(email),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            contains('ADMINISTRATOR ACCOUNT PROTECTED'),
          ),
        ),
      );
    }
    expect(
      backend.requests.where((request) => request.url.path.endsWith('/recover')),
      isEmpty,
    );
  });
  test('registration lookup identifies an existing live account', () async {
    backend.add('existing@test.com');

    final existing = await service.checkExistingAccount('EXISTING@test.com');
    final missing = await service.checkExistingAccount('missing@test.com');

    expect(existing.exists, isTrue);
    expect(existing.existingRole, 'Tourist');
    expect(missing.exists, isFalse);
  });
  test('live lookup overrides old local deletion markers', () async {
    SharedPreferences.setMockInitialValues({
      'wk_deleted_accounts': ['returned@test.com'],
      'wk_deleted_usernames': ['returneduser'],
    });
    backend.add('returned@test.com', username: 'returneduser');
    expect(await service.isUsernameAvailable('returneduser'), isFalse);
    expect((await service.checkExistingAccount('returned@test.com')).exists, isTrue);
  });
  test('failed lookup never reports available', () async {
    backend.failures['/rest/v1/users'] = 'Lookup unavailable';
    await expectLater(service.isUsernameAvailable('lookupuser'), throwsA(anything));
    await expectLater(service.checkExistingAccount('lookup@test.com'), throwsA(anything));
  });
  testWidgets('registration displays live username and email results', (
    tester,
  ) async {
    backend.add(
      'existing@test.com',
      username: 'existing_user',
    );
    final vm = AuthViewModel(repository: UserRepository(service: service));
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: vm,
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. siticrafts'),
      'existing_user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. siti@example.com'),
      'existing@test.com',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('@existing_user is already taken'), findsOneWidget);
    expect(
      find.text('This email is already registered. Please sign in instead.'),
      findsWidgets,
    );
  });
  test('forgot-password returns a clean message for an unknown email', () async {
    final vm = AuthViewModel(repository: UserRepository(service: service));

    final result = await vm.sendPasswordReset('missing@test.com');

    expect(result.success, isFalse);
    expect(
      result.message,
      'EMAIL NOT FOUND: No account is registered with this email address.',
    );
    expect(result.message, isNot(contains('AuthException')));
    expect(result.message, isNot(contains('statusCode')));
  });
  test('ordinary session and arbitrary token cannot change password', () async {
    backend.add('reset@test.com');
    await service.signIn('reset@test.com', 'Password123!');
    for (final token in ['', 'DUMMY-TOKEN']) {
      await expectLater(
        service.resetPasswordWithToken(
          email: 'reset@test.com',
          token: token,
          newPassword: 'NewPassword123!',
        ),
        throwsA(anything),
      );
    }
    expect(backend.passwordUpdates, 0);
  });
  test(
    'recovery is bound to account and consumed only after successful update',
    () async {
      backend.add('recover@test.com');
      await service.signIn('recover@test.com', 'Password123!');
      service.acceptPasswordRecovery(backend.client.auth.currentSession!);
      await expectLater(
        service.resetPasswordWithToken(
          email: 'other@test.com',
          token: '',
          newPassword: 'NewPassword123!',
        ),
        throwsA(anything),
      );
      backend.failures['PUT /auth/v1/user'] = 'Update unavailable';
      await expectLater(
        service.resetPasswordWithToken(
          email: 'recover@test.com',
          token: '',
          newPassword: 'NewPassword123!',
        ),
        throwsA(anything),
      );
      expect(backend.passwordUpdates, 0);
      backend.failures.clear();
      await service.resetPasswordWithToken(
        email: 'recover@test.com',
        token: '',
        newPassword: 'NewPassword123!',
      );
      expect(backend.passwordUpdates, 1);
      expect(backend.client.auth.currentSession, isNull);
      await expectLater(
        service.resetPasswordWithToken(
          email: 'recover@test.com',
          token: '',
          newPassword: 'AgainPassword123!',
        ),
        throwsA(anything),
      );
    },
  );
  test('administrator recovery session cannot reset password', () async {
    backend.add('admin@test.com', role: 'Admin');
    await service.signIn('admin@test.com', 'Password123!');
    service.acceptPasswordRecovery(backend.client.auth.currentSession!);
    await expectLater(
      service.resetPasswordWithToken(
        email: 'admin@test.com',
        token: '',
        newPassword: 'NewPassword123!',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('ADMINISTRATOR ACCOUNT PROTECTED'),
        ),
      ),
    );
    expect(backend.passwordUpdates, 0);
  });
  test('resetPasswordWithToken rejects reusing the same old password', () async {
    backend.add('sametest@test.com');
    await service.signIn('sametest@test.com', 'Password123!');
    service.acceptPasswordRecovery(backend.client.auth.currentSession!);
    await expectLater(
      service.resetPasswordWithToken(
        email: 'sametest@test.com',
        token: '',
        newPassword: 'Password123!',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('NEW PASSWORD CANNOT BE THE SAME AS YOUR CURRENT PASSWORD'),
        ),
      ),
    );
    expect(backend.passwordUpdates, 0);
  });
  test('changePassword rejects incorrect current password', () async {
    backend.add('changepass@test.com', password: 'CurrentPassword123!');
    final repo = UserRepository(service: service);
    final vm = AuthViewModel(repository: repo);
    await vm.login('changepass@test.com', 'CurrentPassword123!');

    final result = await vm.changePassword(
      currentPassword: 'WrongCurrentPassword!',
      newPassword: 'BrandNewPassword456!',
      confirmPassword: 'BrandNewPassword456!',
    );
    expect(result.success, isFalse);
    expect(result.message, contains('INCORRECT CURRENT PASSWORD'));
    expect(backend.passwordUpdates, 0);
  });
  test('changePassword rejects trivial casing variations (case-insensitive similarity)', () async {
    backend.add('casetest@test.com', password: 'CurrentPassword123!');
    final repo = UserRepository(service: service);
    final vm = AuthViewModel(repository: repo);
    await vm.login('casetest@test.com', 'CurrentPassword123!');

    final result = await vm.changePassword(
      currentPassword: 'CurrentPassword123!',
      newPassword: 'currentpassword123!',
      confirmPassword: 'currentpassword123!',
    );
    expect(result.success, isFalse);
    expect(result.message, contains('NEW PASSWORD IS TOO SIMILAR TO YOUR CURRENT PASSWORD'));
    expect(backend.passwordUpdates, 0);
  });
  test('changePassword successfully updates password with valid credentials', () async {
    backend.add('validsuccess@test.com', password: 'CurrentPassword123!');
    final repo = UserRepository(service: service);
    final vm = AuthViewModel(repository: repo);
    await vm.login('validsuccess@test.com', 'CurrentPassword123!');

    final result = await vm.changePassword(
      currentPassword: 'CurrentPassword123!',
      newPassword: 'BrandNewPassword456!',
      confirmPassword: 'BrandNewPassword456!',
    );
    expect(result.success, isTrue);
    expect(result.message, contains('PASSWORD CHANGED SUCCESSFULLY'));
    expect(backend.passwordUpdates, 1);
  });
  test('failed login clears previous view model user', () async {
    final vm = AuthViewModel(repository: UserRepository(service: service));
    backend.add('old@test.com');
    expect((await vm.login('old@test.com', 'Password123!')).success, isTrue);
    expect((await vm.login('old@test.com', 'WrongPassword')).success, isFalse);
    expect(vm.currentUser, isNull);
  });
  test(
    'username login verification response contains the resolved email',
    () async {
      backend.add(
        'unverified@test.com',
        username: 'unverified_name',
        confirmed: false,
      );
      final vm = AuthViewModel(repository: UserRepository(service: service));
      final result = await vm.login('@unverified_name', 'Password123!');
      expect(result.requiresEmailVerification, isTrue);
      expect(result.unverifiedEmail, 'unverified@test.com');
    },
  );
  test(
    'registration awaits verification without setting current user',
    () async {
      final vm = AuthViewModel(repository: UserRepository(service: service));
      final result = await vm.registerTourist(
        username: 'fresh_user',
        email: 'fresh@test.com',
        password: 'Password123!',
        confirmPassword: 'Password123!',
      );
      expect(result.success, isTrue);
      expect(result.requiresEmailVerification, isTrue);
      expect(vm.isAuthenticated, isFalse);
    },
  );
  test('registration supports backend automatic email confirmation', () async {
    backend.confirmOnSignup = true;
    final vm = AuthViewModel(repository: UserRepository(service: service));
    final result = await vm.registerTourist(
      username: 'auto_user',
      email: 'auto@test.com',
      password: 'Password123!',
      confirmPassword: 'Password123!',
    );
    expect(result.success, isTrue);
    expect(result.requiresEmailVerification, isFalse);
    expect(vm.currentUser?.email, 'auto@test.com');
  });
  test(
    'unknown reset token returns an authentication error, not a runtime failure',
    () async {
      await expectLater(
        service.resetPasswordWithToken(
          email: 'any@test.com',
          token: 'DUMMY',
          newPassword: 'NewPassword123!',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('recovery session'),
          ),
        ),
      );
      expect(backend.passwordUpdates, 0);
    },
  );
  test('suspended user session preserves identity and status on restore and refresh', () async {
    final record = backend.add('suspended_session@test.com', username: 'heritage_hero');
    final signedIn = await service.signIn('suspended_session@test.com', 'Password123!');
    expect(signedIn.email, 'suspended_session@test.com');
    expect(signedIn.isSuspended, isFalse);

    // Admin suspends user in database
    record['status'] = 'SUSPENDED';
    record['suspension_reason'] = 'Terms of Service violation';

    // getCurrentUser returns the suspended user model rather than throwing or nullifying
    final currentUser = await service.getCurrentUser();
    expect(currentUser, isNotNull);
    expect(currentUser!.isSuspended, isTrue);
    expect(currentUser.status, 'SUSPENDED');
    expect(currentUser.suspensionReason, 'Terms of Service violation');

    // AuthViewModel.refreshCurrentUser retains currentUser and sets error message
    final vm = AuthViewModel(repository: UserRepository(service: service));
    final refreshed = await vm.refreshCurrentUser();
    expect(refreshed, isNotNull);
    expect(refreshed!.isSuspended, isTrue);
    expect(vm.currentUser, isNotNull);
    expect(vm.currentUser!.isSuspended, isTrue);
    expect(vm.errorMessage, contains('ACCOUNT SUSPENDED'));

    // AuthViewModel.restoreSession preserves suspended user identity
    final restored = await vm.restoreSession();
    expect(restored, isNotNull);
    expect(restored!.isSuspended, isTrue);
    expect(vm.currentUser, isNotNull);
    expect(vm.currentUser!.isSuspended, isTrue);
    expect(vm.errorMessage, contains('ACCOUNT SUSPENDED'));
  });

  test('deactivateArtisanStudio demotes artisan to tourist while preserving user identity', () async {
    backend.add(
      'artisan_close@test.com',
      username: 'master_potter',
      role: 'Artisan',
      password: 'Password123!',
    );
    await service.signIn('artisan_close@test.com', 'Password123!');
    final vm = AuthViewModel(repository: UserRepository(service: service));
    await vm.restoreSession();
    expect(vm.currentUser, isNotNull);
    expect(vm.currentUser!.role, 'Artisan');

    final result = await vm.deactivateArtisanStudio();
    expect(result.success, isTrue);
    expect(vm.currentUser, isNotNull);
    expect(vm.currentUser!.role, 'Tourist');
    expect(vm.activeRole, 'Tourist');
    expect(vm.currentUser!.studioName, isNull);
  });

  test('deleteCurrentAccount rejects incorrect password and protects account', () async {
    backend.add(
      'delete_guard@test.com',
      username: 'delete_tester',
      role: 'Tourist',
      password: 'Password123!',
    );
    await service.signIn('delete_guard@test.com', 'Password123!');
    final vm = AuthViewModel(repository: UserRepository(service: service));
    await vm.restoreSession();
    expect(vm.currentUser, isNotNull);

    // Attempt deletion with wrong password
    final failResult = await vm.deleteCurrentAccount(password: 'WrongPassword!');
    expect(failResult.success, isFalse);
    expect(failResult.message?.toLowerCase(), contains('incorrect password'));
    expect(failResult.message, isNot(contains('AuthException')));
    expect(vm.currentUser, isNotNull); // Account still exists
  });

  test('deleteCurrentAccount deletes account cleanly when correct password is provided', () async {
    backend.add(
      'delete_success@test.com',
      username: 'delete_target',
      role: 'Tourist',
      password: 'Password123!',
    );
    await service.signIn('delete_success@test.com', 'Password123!');
    final vm = AuthViewModel(repository: UserRepository(service: service));
    await vm.restoreSession();
    expect(vm.currentUser, isNotNull);

    // Successful deletion with correct password
    final successResult = await vm.deleteCurrentAccount(password: 'Password123!');
    expect(successResult.success, isTrue);
    expect(vm.currentUser, isNull);
    expect(vm.activeRole, isNull);
  });

  test('after deactivating studio, user can successfully re-apply for artisan studio without email error', () async {
    backend.add(
      'reapply_artisan@test.com',
      username: 'reapply_artisan',
      role: 'Artisan',
      password: 'Password123!',
    );
    await service.signIn('reapply_artisan@test.com', 'Password123!');
    final vm = AuthViewModel(repository: UserRepository(service: service));
    await vm.restoreSession();
    expect(vm.currentUser, isNotNull);
    expect(vm.currentUser!.role, 'Artisan');

    // 1. Close studio
    final closeResult = await vm.deactivateArtisanStudio();
    expect(closeResult.success, isTrue);
    expect(vm.currentUser!.role, 'Tourist');

    // 2. Re-apply for artisan studio (passing empty string or relying on session)
    final applyResult = await vm.linkArtisanToExistingTourist(
      email: '',
      studioName: 'New Reborn Studio',
      craftCategory: 'Batik',
      ssmNumber: '202301099999',
    );
    expect(applyResult.success, isTrue);
    expect(vm.currentUser!.status, 'PENDING_APPROVAL');
    expect(vm.currentUser!.studioName, 'New Reborn Studio');
  });
}
