import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/data/services/connectivity_service.dart';
import 'package:warisan_kita/ui/widgets/offline_banner_wrapper.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/ui/auth/login_screen.dart';

void main() {
  group('ConnectivityService Tests', () {
    test('initial state defaults to online and not wasOffline', () {
      final service = ConnectivityService(initialOnline: true);
      expect(service.isOnline, isTrue);
      expect(service.isOffline, isFalse);
      expect(service.wasOffline, isFalse);
    });

    test('transitions to offline correctly', () {
      final service = ConnectivityService(initialOnline: true);
      var notified = false;
      service.addListener(() => notified = true);

      service.setOnlineForTesting(false);

      expect(notified, isTrue);
      expect(service.isOnline, isFalse);
      expect(service.isOffline, isTrue);
      expect(service.wasOffline, isTrue);
    });

    test('recovers from offline to online retaining wasOffline flag', () {
      final service = ConnectivityService(initialOnline: true);
      service.setOnlineForTesting(false);
      expect(service.wasOffline, isTrue);

      service.setOnlineForTesting(true);
      expect(service.isOnline, isTrue);
      expect(service.isOffline, isFalse);
      expect(service.wasOffline, isTrue);

      service.clearWasOffline();
      expect(service.wasOffline, isFalse);
    });
  });

  group('OfflineBannerWrapper Widget Tests', () {
    testWidgets('renders child normally without connectivity service', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineBannerWrapper(
            child: Scaffold(
              body: Text('Main Content Area'),
            ),
          ),
        ),
      );

      expect(find.text('Main Content Area'), findsOneWidget);
    });

    testWidgets('displays offline banner when network is lost', (tester) async {
      final service = ConnectivityService(initialOnline: true);

      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectivityService>.value(
          value: service,
          child: const MaterialApp(
            home: OfflineBannerWrapper(
              child: Scaffold(
                body: Text('Home Screen Content'),
              ),
            ),
          ),
        ),
      );

      // Initially online: banner is hidden
      final animatedSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(animatedSlide.offset, const Offset(0, -1.2));

      // Simulate going offline
      service.setOnlineForTesting(false);
      await tester.pumpAndSettle();

      // Banner should now be visible with offline message
      expect(find.text("You're offline. Some features may be unavailable."), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      final visibleSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(visibleSlide.offset, const Offset(0, 0));
    });

    testWidgets('dismisses offline banner when user taps close icon', (tester) async {
      final service = ConnectivityService(initialOnline: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectivityService>.value(
          value: service,
          child: const MaterialApp(
            home: OfflineBannerWrapper(
              child: Scaffold(
                body: Text('Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap close icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Slide should now be hidden
      final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(slide.offset, const Offset(0, -1.2));
    });

    testWidgets('displays back online banner and auto-dismisses after 3 seconds', (tester) async {
      final service = ConnectivityService(initialOnline: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectivityService>.value(
          value: service,
          child: const MaterialApp(
            home: OfflineBannerWrapper(
              child: Scaffold(
                body: Text('Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("You're offline. Some features may be unavailable."), findsOneWidget);

      // Connection restored
      service.setOnlineForTesting(true);
      await tester.pump(); // Trigger build
      await tester.pump(const Duration(milliseconds: 350)); // Animation settle

      expect(find.text("Back online. Connection restored."), findsOneWidget);
      expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);

      // Advance clock by 3.5 seconds
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Banner should be dismissed
      final dismissedSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(dismissedSlide.offset, const Offset(0, -1.2));
    });

    testWidgets('LoginScreen blocks login and shows snackbar when offline', (tester) async {
      final connectivity = ConnectivityService(initialOnline: false);
      final authVM = AuthViewModel();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectivityService>.value(value: connectivity),
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Sign In button
      final signInButton = find.widgetWithText(FilledButton, 'SIGN IN');
      expect(signInButton, findsOneWidget);

      // Tap Sign In while offline
      await tester.tap(signInButton);
      await tester.pump();

      // SnackBar should appear immediately informing user cannot sign in while offline
      expect(find.text('Cannot sign in while offline. Please connect to the internet.'), findsOneWidget);
    });
  });
}

