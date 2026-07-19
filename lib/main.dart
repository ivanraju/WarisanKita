import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:warisan_kita/features/auth/login_screen.dart';
import 'package:warisan_kita/state/auth_state.dart';
import 'package:warisan_kita/state/directory_state.dart';
import 'package:warisan_kita/state/forum_state.dart';
import 'package:warisan_kita/state/gamification_state.dart';
import 'package:warisan_kita/state/matchmaker_state.dart';
import 'package:warisan_kita/state/navigation_state.dart';
import 'package:warisan_kita/state/itinerary_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://placeholder.supabase.co',
    anonKey: 'placeholder-key',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => DirectoryState()),
        ChangeNotifierProvider(create: (_) => ForumState()),
        ChangeNotifierProvider(create: (_) => GamificationState()),
        ChangeNotifierProvider(create: (_) => MatchmakerState()),
        ChangeNotifierProvider(create: (_) => NavigationState()),
        ChangeNotifierProvider(create: (_) => ItineraryState()),
      ],
      child: const WarisanKitaApp(),
    ),
  );
}

class WarisanKitaApp extends StatelessWidget {
  const WarisanKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WarisanKita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF004D40),
          primary: const Color(0xFF004D40),
          secondary: const Color(0xFFFF7043),
          tertiary: const Color(0xFFFFD54F),
          surface: const Color(0xFFFFFFFF),
          background: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF004D40),
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF004D40),
            fontSize: 26,
          ),
        ),
        // FIXED: Using CardThemeData instead of CardTheme
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
