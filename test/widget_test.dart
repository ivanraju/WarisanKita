import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/features/auth/login_screen.dart';
import 'package:warisan_kita/state/auth_state.dart';

void main() {
  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthState(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('WarisanKita'), findsOneWidget);
    expect(find.text('EXPLORE NOW'), findsOneWidget);
  });
}
