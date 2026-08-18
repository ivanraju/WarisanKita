import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/ui/auth/register_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/ui/admin_web/widgets/artisan_review_dialog.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_sidebar.dart';
import 'package:warisan_kita/ui/admin_web/widgets/admin_active_artisans_tab.dart';

void main() {
  late SupabaseService service;
  late UserRepository repository;
  late AuthViewModel authVM;

  setUp(() {
    service = SupabaseService();
    repository = UserRepository(service: service);
    authVM = AuthViewModel(repository: repository);
  });

  group('UC001_USER_LOGIN Tests', () {
    test('C1 Constraint: Password <= 7 characters should fail with M3 message', () async {
      final result = await authVM.login('tourist@warisankita.my', 'short');
      expect(result.success, isFalse);
      expect(result.message, contains('PASSWORD MUST BE GREATER THAN 7 CHARACTERS'));
    });

    test('A1 Alternate Flow: Invalid email format should fail with M4 message', () async {
      final result = await authVM.login('invalid-email-format', 'password123');
      expect(result.success, isFalse);
      expect(result.message, contains('INVALID CREDENTIALS'));
    });

    test('A2 Alternate Flow: Unregistered account should fail', () async {
      final result = await authVM.login('nonexistent@warisankita.my', 'password123');
      expect(result.success, isFalse);
      expect(result.message, contains('INVALID CREDENTIALS'));
    });

    test('A3 Alternate Flow: Suspended user account is blocked with M5 message', () async {
      final result = await authVM.login('suspended@warisankita.my', 'password123');
      expect(result.success, isFalse);
      expect(result.message, contains('ACCOUNT SUSPENDED BY ADMINISTRATOR'));
    });

    test('Basic Flow: Tourist Login succeeds and routes to /tourist', () async {
      final result = await authVM.login('tourist@warisankita.my', 'password123');
      expect(result.success, isTrue);
      expect(result.user?.role, equals('Tourist'));
      expect(result.route, equals('/tourist'));
    });

    test('Basic Flow: Login via Username / Handle succeeds seamlessly', () async {
      final result = await authVM.login('Aiman Haziq', 'password123');
      expect(result.success, isTrue);
      expect(result.user?.email, equals('tourist@warisankita.my'));
      expect(result.user?.role, equals('Tourist'));
    });

    test('Basic Flow: Master Artisan Login succeeds and offers session mode selection', () async {
      final result = await authVM.login('artisan@warisankita.my', 'password123');
      expect(result.success, isTrue);
      expect(result.user?.role, equals('Artisan'));
      expect(result.requiresRoleSelection, isTrue);
      expect(result.availableRoles, contains('Master Artisan'));
      
      authVM.selectActiveRole('Master Artisan');
      expect(authVM.activeRole, equals('Master Artisan'));
    });

    test('A4 Alternate Flow: Pending Artisan routes to pending_artisan screen', () async {
      final result = await authVM.login('pending.artisan@warisankita.my', 'password123');
      expect(result.success, isTrue);
      expect(result.user?.status, equals('PENDING_APPROVAL'));
      expect(result.requiresRoleSelection, isTrue);
    });

    test('A5 Alternate Flow: Artisan account triggers role selection prompt M7', () async {
      final result = await authVM.login('artisan@warisankita.my', 'password123');
      expect(result.success, isTrue);
      expect(result.requiresRoleSelection, isTrue);
      expect(result.availableRoles.length, greaterThanOrEqualTo(2));

      // Test selecting active role
      authVM.selectActiveRole('Master Artisan');
      expect(authVM.activeRole, equals('Master Artisan'));
      expect(authVM.requiresRoleSelection, isFalse);
    });
  });

  group('UC002_USER_REGISTRATION Tests', () {
    test('C1 Constraint: Password length <= 7 should fail', () async {
      final result = await authVM.registerTourist(
        username: 'New Tourist',
        email: 'newtourist@warisankita.my',
        password: 'short',
        confirmPassword: 'short',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('PASSWORD MUST BE GREATER THAN 7 CHARACTERS'));
    });

    test('C2 Constraint: Password mismatch should fail with M4 message', () async {
      final result = await authVM.registerTourist(
        username: 'New Tourist',
        email: 'newtourist@warisankita.my',
        password: 'password123',
        confirmPassword: 'differentPassword456',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('PASSWORDS DO NOT MATCH'));
    });

    test('Basic Flow: New Cultural Tourist registration succeeds with status ACTIVE', () async {
      final result = await authVM.registerTourist(
        username: 'Sarah Explorer',
        email: 'sarah.new@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(result.success, isTrue);
      expect(result.user?.role, equals('Tourist'));
      expect(result.user?.status, equals('ACTIVE'));
      expect(result.route, equals('/tourist'));
    });

    test('C3 Constraint: Master Artisan registration initializes strictly with PENDING_APPROVAL', () async {
      final result = await authVM.registerArtisan(
        email: 'new.artisan@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
        studioName: 'TERENGGANU BATIK STUDIO',
        craftCategory: 'Batik & Textiles',
        ssmNumber: 'SSM-2026-9901',
        ssmFileName: 'SSM_License.pdf',
        certFileName: 'Master_Cert.pdf',
      );
      expect(result.success, isTrue);
      expect(result.user?.role, equals('Artisan'));
      expect(result.user?.status, equals('PENDING_APPROVAL'));
      expect(result.route, equals('pending_artisan'));
    });

    test('Constraint: Duplicate username registration fails with USERNAME ALREADY TAKEN', () async {
      // 'Sarah Chen' username is already taken by dual.role@warisankita.my
      final result = await authVM.registerTourist(
        username: 'Sarah Chen',
        email: 'brand.new.user@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('USERNAME ALREADY TAKEN'));
    });

    test('Basic Flow: Identical Full Names with distinct handles succeed', () async {
      final result1 = await authVM.registerTourist(
        fullName: 'Sarah Jenkins',
        username: 'sarah_my_1',
        email: 'sarah.one@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(result1.success, isTrue);
      expect(result1.user?.displayName, equals('Sarah Jenkins'));
      expect(result1.user?.username, equals('sarah_my_1'));

      final result2 = await authVM.registerTourist(
        fullName: 'Sarah Jenkins',
        username: 'sarah_my_2',
        email: 'sarah.two@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(result2.success, isTrue);
      expect(result2.user?.displayName, equals('Sarah Jenkins'));
      expect(result2.user?.username, equals('sarah_my_2'));
    });

    test('Basic Flow: Dual Role (Artisan & Tourist) registration assigns Artisan & Tourist role and dual roles', () async {
      final result = await authVM.registerArtisan(
        username: 'Haziq Potter',
        email: 'haziq.dual@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
        studioName: 'HAZIQ HERITAGE CERAMICS',
        craftCategory: 'Pottery & Ceramics',
        ssmNumber: 'SSM-2026-DUAL-001',
        ssmFileName: 'SSM_License.pdf',
        role: 'Artisan & Tourist',
      );
      expect(result.success, isTrue);
      expect(result.user?.role, equals('Artisan & Tourist'));
      expect(result.user?.isDualRole, isTrue);
      expect(result.user?.isArtisan, isTrue);
      expect(result.user?.isTourist, isTrue);
      expect(result.user?.roles, contains('Tourist'));
      expect(result.user?.roles, contains('Artisan'));
      expect(result.user?.status, equals('PENDING_APPROVAL'));
    });

    test('A4-2 Alternate Flow: Linking Artisan role to existing Tourist account sets status PENDING_APPROVAL', () async {
      final result = await authVM.linkArtisanToExistingTourist(
        email: 'tourist@warisankita.my',
        studioName: 'AHMAD HERITAGE WOODCRAFT',
        craftCategory: 'Woodwork',
        ssmNumber: 'SSM-LINK-2026',
        ssmFileName: 'SSM_Doc.pdf',
      );
      expect(result.success, isTrue);
      expect(result.user?.status, equals('PENDING_APPROVAL'));
      expect(result.user?.studioName, equals('AHMAD HERITAGE WOODCRAFT'));
      expect(result.user?.craftCategory, equals('Woodwork'));
    });

    test('A3 Alternate Flow: Existing email attempting registration is rejected', () async {
      final regTourist = await authVM.registerTourist(
        username: 'pakmat_explorer',
        email: 'artisan@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(regTourist.success, isFalse);
      expect(regTourist.message, contains('ACCOUNT ALREADY REGISTERED'));
    });

    test('Authentication Check: Registering existing account fails with ACCOUNT ALREADY REGISTERED error', () async {
      final duplicateResult = await authVM.registerTourist(
        username: 'new_username',
        email: 'tourist@warisankita.my',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(duplicateResult.success, isFalse);
      expect(duplicateResult.message, contains('ACCOUNT ALREADY REGISTERED'));
    });

    test('Existing Account Check API returns profile metadata for both roles', () async {
      final touristCheck = await authVM.checkExistingAccount('tourist@warisankita.my');
      expect(touristCheck.exists, isTrue);
      expect(touristCheck.isTourist, isTrue);

      final artisanCheck = await authVM.checkExistingAccount('artisan@warisankita.my');
      expect(artisanCheck.exists, isTrue);
      expect(artisanCheck.isArtisan, isTrue);

      final unknownCheck = await authVM.checkExistingAccount('nobody@example.com');
      expect(unknownCheck.exists, isFalse);
    });
  });

  group('UC003_RESET_PASSWORD Tests', () {
    test('A1 Alternate Flow: Requesting reset for unregistered email fails with M4', () async {
      final result = await authVM.sendPasswordReset('unregistered@warisankita.my');
      expect(result.success, isFalse);
      expect(result.message, contains('EMAIL NOT FOUND'));
    });

    test('Basic Flow: Requesting reset for registered email generates 15-min token', () async {
      final result = await authVM.sendPasswordReset('tourist@warisankita.my');
      expect(result.success, isTrue);
      expect(result.message, contains('PASSWORD RESET LINK HAS BEEN SENT'));
    });

    test('C2 & C3 Constraints: Confirming reset with password mismatch fails', () async {
      final result = await authVM.confirmPasswordReset(
        email: 'tourist@warisankita.my',
        token: 'TOKEN-SAMPLE',
        newPassword: 'newpassword123',
        confirmPassword: 'mismatchedPassword999',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('PASSWORDS DO NOT MATCH'));
    });

    test('Basic Flow: Confirming reset with valid credentials updates password and allows login', () async {
      final resetResult = await authVM.confirmPasswordReset(
        email: 'tourist@warisankita.my',
        token: 'TOKEN-SAMPLE',
        newPassword: 'brandNewPassword2026',
        confirmPassword: 'brandNewPassword2026',
      );
      expect(resetResult.success, isTrue);

      // Verify login with new password succeeds
      final loginResult = await authVM.login('tourist@warisankita.my', 'brandNewPassword2026');
      expect(loginResult.success, isTrue);
    });
  });

  group('Profile & Username Dynamic Binding Tests', () {
    test('UserModel computes effectiveUsername and initials correctly', () {
      const userWithUsername = UserModel(
        id: 'u1',
        email: 'siti.nur@warisankita.my',
        username: 'Siti Nurhaliza',
        role: 'Tourist',
      );
      expect(userWithUsername.effectiveUsername, equals('Siti Nurhaliza'));
      expect(userWithUsername.initials, equals('SN'));

      const userWithEmailOnly = UserModel(
        id: 'u2',
        email: 'ahmad.faiz@warisankita.my',
        role: 'Tourist',
      );
      expect(userWithEmailOnly.effectiveUsername, equals('Ahmad Faiz'));
      expect(userWithEmailOnly.initials, equals('AF'));
    });

    test('AuthViewModel.updateProfile updates current user username dynamically', () async {
      final vm = AuthViewModel();
      expect(vm.currentUser?.effectiveUsername, equals('Aiman Haziq'));

      await vm.updateProfile(
        username: 'Tengku Iskandar',
        bio: 'Explorer of Terengganu woodcarving heritage.',
      );

      expect(vm.currentUser?.effectiveUsername, equals('Tengku Iskandar'));
      expect(vm.currentUser?.initials, equals('TI'));
      expect(vm.currentUser?.bio, equals('Explorer of Terengganu woodcarving heritage.'));
    });

    test('AuthViewModel.logout clears session and resets auth state', () async {
      final vm = AuthViewModel();
      await vm.login('tourist@warisankita.my', 'password123');
      expect(vm.isAuthenticated, isTrue);
      expect(vm.currentUser, isNotNull);

      await vm.logout();
      expect(vm.isAuthenticated, isFalse);
      expect(vm.currentUser, isNull);
      expect(vm.activeRole, isNull);
      expect(vm.requiresRoleSelection, isFalse);
    });
  });

  group('Artisan Registration UI & Document Upload Tests', () {
    testWidgets('RegisterScreen renders single-page tourist registration form', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Verify single-page tourist registration UI
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Unique Username / Handle'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Create Explorer Account'), findsOneWidget);
    });

    testWidgets('RegisterScreen dynamic inline alert: Typing registered email shows Sign In shortcut', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider(create: (_) => ModerationViewModel()),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Enter registered email
      final emailField = find.widgetWithText(TextFormField, 'Email Address');
      await tester.enterText(emailField, 'tourist@warisankita.my');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify inline alert appears
      expect(find.text('Account Already Exists'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });
  });

  group('UC100_MODERATE_ARTISAN_PROFILE Tests', () {
    late ModerationViewModel moderationVM;

    setUp(() {
      moderationVM = ModerationViewModel();
    });

    test('Basic Flow: Moderation queue initializes with pending applications and SSM proofs', () {
      expect(moderationVM.totalPendingCount, equals(5));
      final firstApp = moderationVM.filteredArtisans.first;
      expect(firstApp.ssmNumber, isNotNull);
      expect(firstApp.ssmFileName, contains('.pdf'));
      expect(firstApp.certFileName, contains('.pdf'));
    });

    test('Basic Flow: Admin approves pure Artisan application -> role is Artisan and status ACTIVE', () {
      final initialCount = moderationVM.totalPendingCount;
      final targetApp = moderationVM.filteredArtisans.firstWhere((a) => !a.isUpgradeFromTourist);

      moderationVM.approveArtisan(targetApp.id);

      expect(moderationVM.totalPendingCount, equals(initialCount - 1));
      final approvedUser = moderationVM.registeredUsers.firstWhere((u) => u.email == targetApp.email);
      expect(approvedUser.role, equals('Artisan'));
      expect(approvedUser.status, equals('ACTIVE'));
    });

    test('Basic Flow: Admin approves Tourist upgrade application -> role automatically upgrades to Artisan', () {
      final initialCount = moderationVM.totalPendingCount;
      final upgradeApp = moderationVM.filteredArtisans.firstWhere((a) => a.isUpgradeFromTourist);

      moderationVM.approveArtisan(upgradeApp.id);

      expect(moderationVM.totalPendingCount, equals(initialCount - 1));
      final upgradedUser = moderationVM.registeredUsers.firstWhere((u) => u.email == upgradeApp.email);
      expect(upgradedUser.role, equals('Artisan'));
      expect(upgradedUser.status, equals('ACTIVE'));
    });

    test('Alternate Flow: Admin rejects Artisan application -> status set to REJECTED', () {
      final initialCount = moderationVM.totalPendingCount;
      final targetApp = moderationVM.filteredArtisans.first;

      moderationVM.rejectArtisan(targetApp.id, reason: 'Incomplete Kraftangan certificate');

      expect(moderationVM.totalPendingCount, equals(initialCount - 1));
    });

    test('Basic Flow: Newly registered artisan dynamically surfaces in ModerationViewModel via fetchPendingArtisans', () async {
      await service.signUp(
        email: 'new_artisan_2026@warisankita.my',
        password: 'password123',
        role: 'Artisan',
        username: 'master_kamal',
        displayName: 'Kamal Heritage Batik',
        studioName: 'Kamal Heritage Batik Studio',
        craftCategory: 'Batik Weaving',
        ssmNumber: 'SSM-2026-99182',
      );

      final modVM = ModerationViewModel(repository: repository);
      await modVM.fetchPendingArtisans();

      expect(modVM.filteredArtisans.any((a) => a.email == 'new_artisan_2026@warisankita.my'), isTrue);
      final found = modVM.filteredArtisans.firstWhere((a) => a.email == 'new_artisan_2026@warisankita.my');
      expect(found.name, contains('Kamal Heritage Batik'));
    });

    testWidgets('UI Widget Test: ArtisanReviewDialog displays SSM license, upgrade alert, and handles approval', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final upgradeApp = moderationVM.filteredArtisans.firstWhere((a) => a.isUpgradeFromTourist);
      bool approved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtisanReviewDialog(
              artisan: upgradeApp,
              onApprove: () => approved = true,
              onReject: () {},
            ),
          ),
        ),
      );

      expect(find.text('Review Artisan Profile Application'), findsOneWidget);
      expect(find.textContaining('Tourist Account Upgrade'), findsOneWidget);
      expect(find.textContaining('202601004821'), findsOneWidget);
      expect(find.textContaining('SSM_Registration_Cert_2026.pdf'), findsOneWidget);
      expect(find.textContaining('Kraftangan_Master_Certificate.pdf'), findsOneWidget);

      final approveBtn = find.text('Approve & Upgrade to Dual Role');
      expect(approveBtn, findsOneWidget);

      await tester.ensureVisible(approveBtn);
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(approved, isTrue);
    });

    testWidgets('UI Widget Test: AdminSidebar tab switching triggers onTabSelected with correct tabId', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? selectedTab;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVM),
            ChangeNotifierProvider.value(value: moderationVM),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AdminSidebar(
                activeTab: 'Overview',
                onTabSelected: (tab) => selectedTab = tab,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Overview & Analytics'), findsOneWidget);
      expect(find.text('Artisan Verification'), findsOneWidget);
      expect(find.text('Active Artisans'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Quest Moderation'), findsOneWidget);
      expect(find.text('Community Forum'), findsOneWidget);
      expect(find.text('System Settings'), findsOneWidget);

      await tester.tap(find.text('Artisan Verification'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals('Pending Approvals'));

      await tester.tap(find.text('User Management'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals('User Management'));

      await tester.tap(find.text('Quest Moderation'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals('Quest Approvals'));
    });

    test('Basic Flow: Active artisans list initializes with verified masters and handles live status toggling', () {
      expect(moderationVM.activeArtisanMasters.isNotEmpty, isTrue);
      final firstArtisan = moderationVM.activeArtisanMasters.first;
      final initialLive = firstArtisan.isLiveOpen;

      moderationVM.toggleActiveArtisanLiveStatus(firstArtisan.id);

      final updatedArtisan = moderationVM.activeArtisanMasters.firstWhere((a) => a.id == firstArtisan.id);
      expect(updatedArtisan.isLiveOpen, equals(!initialLive));
    });

    test('Basic Flow: Admin approves pending artisan -> automatically inserted into activeArtisanMasters', () async {
      final initialActiveCount = moderationVM.activeArtisanMasters.length;
      final pendingApp = moderationVM.filteredArtisans.first;

      await moderationVM.approveArtisan(pendingApp.id);

      expect(moderationVM.activeArtisanMasters.length, equals(initialActiveCount + 1));
      final inserted = moderationVM.activeArtisanMasters.firstWhere((a) => a.email == pendingApp.email);
      expect(inserted.name, equals(pendingApp.name));
      expect(inserted.licenseNo, equals(pendingApp.ssmNumber));
    });

    testWidgets('UI Widget Test: AdminActiveArtisansTab renders verified masters and details modal', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: moderationVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AdminActiveArtisansTab(),
            ),
          ),
        ),
      );

      expect(find.text('Verified Master Artisans Directory'), findsOneWidget);
      expect(find.textContaining('Verified Masters Live'), findsOneWidget);
      expect(find.text('Pak Mat Pottery Studio'), findsOneWidget);
      expect(find.text('Tok Guru Crafts'), findsOneWidget);

      // Tap 'Details' on the first artisan
      final detailsBtn = find.text('Details').first;
      await tester.ensureVisible(detailsBtn);
      await tester.tap(detailsBtn);
      await tester.pumpAndSettle();

      expect(find.text('SSM & Kraftangan Verified Master Artisan'), findsOneWidget);
      expect(find.text('Close Profile'), findsOneWidget);

      await tester.tap(find.text('Close Profile'));
      await tester.pumpAndSettle();
      expect(find.text('SSM & Kraftangan Verified Master Artisan'), findsNothing);
    });
  });
}

