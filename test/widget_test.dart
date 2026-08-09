import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/ui/auth/auth_view.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

void main() {
  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('WarisanKita'), findsOneWidget);
    expect(find.text('EXPLORE NOW'), findsOneWidget);
  });
}
