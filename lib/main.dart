import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/data/repositories/forum_repository.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';

import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/navigation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/itinerary_viewmodel.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

import 'package:warisan_kita/ui/auth/splash_screen.dart';
import 'package:warisan_kita/ui/auth/login_screen.dart';
import 'package:warisan_kita/ui/auth/register_screen.dart';
import 'package:warisan_kita/ui/auth/role_selection_screen.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';
import 'package:warisan_kita/ui/tourist/tourist_main_scaffold.dart';
import 'package:warisan_kita/ui/tourist/apply_artisan_screen.dart';
import 'package:warisan_kita/ui/artisan/artisan_main_scaffold.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/ui/admin_web/admin_moderation_dashboard_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://zmvykemnpuremkebjvyo.supabase.co',
    publishableKey: 'sb_publishable_8XUf77oFBVRsQ5fq1N8aOw_UljZ5waS',
  );

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => SupabaseService()),
        Provider(create: (context) => UserRepository(service: context.read<SupabaseService>())),
        Provider(create: (context) => ArtisanRepository(service: context.read<SupabaseService>())),
        Provider(create: (context) => ForumRepository(service: context.read<SupabaseService>())),
        Provider(create: (_) => const MatchmakerRepository()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(repository: context.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => DirectoryViewModel(repository: context.read<ArtisanRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ForumViewModel(repository: context.read<ForumRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => GamificationViewModel()),
        ChangeNotifierProvider(
          create: (context) => MatchmakerViewModel(repository: context.read<MatchmakerRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ModerationViewModel(repository: context.read<UserRepository>()),
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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        final email = data.session?.user.email;
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordScreen(
              initialStep: 3,
              initialEmail: email,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: kIsWeb ? 'Warisan Kita • Admin Portal' : 'Warisan Kita',
      debugShowCheckedModeBanner: false,
      themeMode: themeVM.themeMode,
      theme: ThemeViewModel.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/tourist': (context) => const TouristMainScaffold(),
        '/apply-artisan': (context) => const ApplyArtisanScreen(),
        '/artisan': (context) => const ArtisanMainScaffold(),
        '/pending-artisan': (context) => const ArtisanApplicationPendingScreen(),
        'pending_artisan': (context) => const ArtisanApplicationPendingScreen(),
        '/admin': (context) => const AdminModerationDashboardView(),
      },
    );
  }
}
