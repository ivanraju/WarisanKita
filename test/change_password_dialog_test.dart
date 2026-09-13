import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/ui/core/widgets/change_password_dialog.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
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
        home: Scaffold(
          body: ChangePasswordDialog(),
        ),
      ),
    );
  }

  testWidgets('shows correct error when current password is empty', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    final updateBtn = find.text('Update Password');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your current password'), findsOneWidget);
    expect(find.text('New password must be at least 8 characters'), findsNothing);
  });

  testWidgets('does not show 8-character error on current password when current password is short', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    // Enter short current password (e.g. 4 characters)
    await tester.enterText(find.widgetWithText(TextField, 'Current Password'), '1234');
    final updateBtn = find.text('Update Password');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pumpAndSettle();

    // Current password must NOT show an 8-character requirement error
    expect(find.text('Please enter your current password'), findsNothing);
    expect(find.text('New password must be at least 8 characters'), findsNothing);
    // Instead, the new password field properly asks for a new password
    expect(find.text('Please enter a new password'), findsOneWidget);
  });

  testWidgets('shows 8-character minimum error specifically on new password field', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(find.widgetWithText(TextField, 'Current Password'), 'oldPass123!');
    await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'short');
    final updateBtn = find.text('Update Password');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pumpAndSettle();

    expect(find.text('New password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('shows mismatch error on confirm password field', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(find.widgetWithText(TextField, 'Current Password'), 'oldPass123!');
    await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'ValidNewPass123!');
    await tester.enterText(find.widgetWithText(TextField, 'Confirm New Password'), 'DifferentPass123!');
    final updateBtn = find.text('Update Password');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pumpAndSettle();

    expect(find.text('New passwords do not match'), findsOneWidget);
  });

  testWidgets('renders properly with high-contrast elements in dark mode', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: authVM,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ChangePasswordDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Change Password'), findsOneWidget);
    expect(find.byIcon(Icons.lock_reset_rounded), findsOneWidget);
    expect(find.text('Forgot current password? Reset via email'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Update Password'), findsOneWidget);
  });

  testWidgets('renders translated text in dialog and password strength meter when LanguageViewModel is provided', (tester) async {
    final fakeLangVM = _MockTestLanguageViewModel({
      'Change Password': 'Tukar Kata Laluan',
      'Current Password': 'Kata Laluan Semasa',
      'New Password': 'Kata Laluan Baharu',
      'Confirm New Password': 'Sahkan Kata Laluan Baharu',
      'Update Password': 'Kemas Kini Kata Laluan',
      'Password Strength': 'Kekuatan Kata Laluan',
      'Strong': 'Kuat',
      '8+ characters': '8+ aksara',
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<LanguageViewModel>.value(value: fakeLangVM),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChangePasswordDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog header and fields are translated
    expect(find.text('Tukar Kata Laluan'), findsOneWidget);
    expect(find.text('Kata Laluan Semasa'), findsOneWidget);
    expect(find.text('Kata Laluan Baharu'), findsOneWidget);
    expect(find.text('Sahkan Kata Laluan Baharu'), findsOneWidget);
    expect(find.text('Kemas Kini Kata Laluan'), findsOneWidget);

    // Enter a strong password into New Password field to trigger PasswordStrengthMeter
    await tester.enterText(find.widgetWithText(TextField, 'Kata Laluan Baharu'), 'MyStrongP@ssw0rd!');
    await tester.pumpAndSettle();

    // Verify PasswordStrengthMeter labels are translated
    expect(find.text('Kekuatan Kata Laluan'), findsOneWidget);
    expect(find.text('Kuat'), findsOneWidget);
    expect(find.text('8+ aksara'), findsOneWidget);
  });

  testWidgets('renders Confirm New Password with FloatingLabelBehavior.always to prevent truncation on small screens', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Confirm New Password should be present as a TextField with full label
    expect(find.widgetWithText(TextField, 'Confirm New Password'), findsOneWidget);

    final textField = tester.widget<TextField>(find.widgetWithText(TextField, 'Confirm New Password'));
    expect(textField.decoration?.floatingLabelBehavior, FloatingLabelBehavior.always);
    expect(textField.decoration?.labelText, 'Confirm New Password');
  });
}

class _MockTestLanguageViewModel extends LanguageViewModel {
  final Map<String, String> _translations;
  _MockTestLanguageViewModel(this._translations);

  @override
  String translate(String text) {
    return _translations[text] ?? text;
  }
}

