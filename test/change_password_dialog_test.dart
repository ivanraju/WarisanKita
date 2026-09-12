import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
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
}
