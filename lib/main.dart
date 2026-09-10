import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/forum_repository.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/data/services/location_service.dart';
import 'package:warisan_kita/data/repositories/location_repository.dart';

import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/navigation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/itinerary_viewmodel.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_moderation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/map_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

import 'package:warisan_kita/ui/auth/splash_screen.dart';
import 'package:warisan_kita/ui/auth/login_screen.dart';
import 'package:warisan_kita/ui/auth/register_screen.dart';
import 'package:warisan_kita/ui/auth/role_selection_screen.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';
import 'package:warisan_kita/ui/auth/email_verification_screen.dart';
import 'package:warisan_kita/ui/tourist/tourist_main_scaffold.dart';
import 'package:warisan_kita/ui/tourist/apply_artisan_screen.dart';
import 'package:warisan_kita/ui/artisan/artisan_main_scaffold.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/ui/admin_web/admin_moderation_dashboard_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Gracefully handle upstream Flutter HardwareKeyboard KeyDownEvent assertions on Desktop/Web
  FlutterError.onError = (FlutterErrorDetails details) {
    final errorMsg = details.exceptionAsString();
    if (errorMsg.contains('hardware_keyboard.dart') ||
        errorMsg.contains('KeyDownEvent') ||
        errorMsg.contains('_pressedKeys.containsKey')) {
      debugPrint(
        'Suppressed upstream HardwareKeyboard repeat event assertion: $errorMsg',
      );
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    if (errorStr.contains('hardware_keyboard.dart') ||
        errorStr.contains('KeyDownEvent') ||
        errorStr.contains('_pressedKeys.containsKey')) {
      debugPrint(
        'Suppressed unhandled HardwareKeyboard repeat event exception: $errorStr',
      );
      return true;
    }
    return false;
  };

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://zmvykemnpuremkebjvyo.supabase.co',
    publishableKey: 'sb_publishable_8XUf77oFBVRsQ5fq1N8aOw_UljZ5waS',
  );

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => SupabaseService()),
        Provider<LocationService>(create: (_) => const LocationService()),
        Provider<LocationRepository>(
          create: (context) =>
              LocationRepository(service: context.read<LocationService>()),
        ),
        Provider(
          create: (context) =>
              UserRepository(service: context.read<SupabaseService>()),
        ),
        Provider(
          create: (context) =>
              ArtisanRepository(service: context.read<SupabaseService>()),
        ),
        Provider(
          create: (context) =>
              ForumRepository(service: context.read<SupabaseService>()),
        ),
        Provider(
          create: (context) =>
              GamificationRepository(service: context.read<SupabaseService>()),
        ),
        Provider(create: (_) => const MatchmakerRepository()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              AuthViewModel(repository: context.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              DirectoryViewModel(repository: context.read<ArtisanRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ForumViewModel(repository: context.read<ForumRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => GamificationViewModel(
            repository: context.read<GamificationRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => GamificationModerationViewModel(
            repository: context.read<GamificationRepository>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, MatchmakerViewModel>(
          create: (context) => MatchmakerViewModel(
            repository: context.read<MatchmakerRepository>(),
            initialUserEmail: context.read<AuthViewModel>().currentUser?.email,
          ),
          update: (context, authVM, matchmakerVM) {
            matchmakerVM?.updateUserContext(authVM.currentUser?.email);
            return matchmakerVM ??
                MatchmakerViewModel(
                  repository: context.read<MatchmakerRepository>(),
                  initialUserEmail: authVM.currentUser?.email,
                );
          },
        ),
        ChangeNotifierProvider<MapViewModel>(
          create: (context) => MapViewModel(
            artisanRepository: context.read<ArtisanRepository>(),
            gamificationRepository: context.read<GamificationRepository>(),
            locationRepository: context.read<LocationRepository>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) =>
              ModerationViewModel(repository: context.read<UserRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => ItineraryViewModel()),
      ],
      child: const WarisanKitaApp(),
    ),
  );
}

class WarisanKitaApp extends StatefulWidget {
  const WarisanKitaApp({super.key});

  @override
  State<WarisanKitaApp> createState() => _WarisanKitaAppState();
}

class _WarisanKitaAppState extends State<WarisanKitaApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // 🔗 Listen to Deep Link / Auth Recovery Event to link back directly to the app
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        if (!mounted) return;
        if (data.session != null) {
          context.read<SupabaseService>().acceptPasswordRecovery(data.session!);
        }
        final email = data.session?.user.email;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  ForgotPasswordScreen(initialStep: 3, initialEmail: email),
            ),
          );
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  static final Map<String, WidgetBuilder> _appRoutes = {
    '/': (context) => kIsWeb ? const LoginScreen() : const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) =>
        kIsWeb ? const LoginScreen() : const RegisterScreen(),
    '/role-selection': (context) =>
        kIsWeb ? const LoginScreen() : const RoleSelectionScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),
    '/verify-email': (context) =>
        const EmailVerificationScreen(email: 'user@warisankita.my'),
    '/tourist': (context) =>
        kIsWeb ? const LoginScreen() : const TouristMainScaffold(),
    '/apply-artisan': (context) =>
        kIsWeb ? const LoginScreen() : const ApplyArtisanScreen(),
    '/artisan': (context) =>
        kIsWeb ? const LoginScreen() : const ArtisanMainScaffold(),
    '/pending-artisan': (context) =>
        kIsWeb ? const LoginScreen() : const ArtisanApplicationPendingScreen(),
    'pending_artisan': (context) =>
        kIsWeb ? const LoginScreen() : const ArtisanApplicationPendingScreen(),
    '/admin': (context) => const AdminModerationDashboardView(),
  };

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: kIsWeb ? 'Warisan Kita • Admin Portal' : 'Warisan Kita',
      debugShowCheckedModeBanner: false,
      themeMode: themeVM.themeMode,
      theme: ThemeViewModel.lightTheme,
      darkTheme: ThemeViewModel.darkTheme,
      initialRoute: kIsWeb ? '/admin' : '/',
      onGenerateInitialRoutes: (initialRoute) {
        if (kIsWeb) {
          // On Web, strictly restrict access: /admin or /login only.
          if (initialRoute == '/admin' ||
              initialRoute == '/' ||
              initialRoute.isEmpty) {
            return [
              MaterialPageRoute(
                settings: const RouteSettings(name: '/admin'),
                builder: (_) => const AdminModerationDashboardView(),
              ),
            ];
          }
          return [
            MaterialPageRoute(
              settings: const RouteSettings(name: '/login'),
              builder: (_) => const LoginScreen(),
            ),
          ];
        }

        // On Native Mobile / Desktop:
        if (initialRoute == '/' || initialRoute.isEmpty) {
          return [
            MaterialPageRoute(
              settings: const RouteSettings(name: '/'),
              builder: (context) => const SplashScreen(),
            ),
          ];
        }
        final builder = _appRoutes[initialRoute] ?? _appRoutes['/']!;
        return [
          MaterialPageRoute(
            settings: RouteSettings(name: initialRoute),
            builder: builder,
          ),
        ];
      },
      routes: _appRoutes,
    );
  }
}
