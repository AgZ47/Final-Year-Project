import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health_app/animations/introduction_animation_screen.dart';
import 'package:health_app/home_page.dart';
import 'services/health_database_service.dart';

void main() {
  // Required for background initialization
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, String?>> _initializeApp() async {
    const storage = FlutterSecureStorage();

    try {
      //Initializing the encrypted database
      // This retrieves/generates the key and opens the DB
      await HealthDatabaseService.instance.database;

      //Checking login status
      String? token = await storage.read(key: 'user_session_token');
      String? username = await storage.read(key: 'username');

      return {'token': token, 'username': username};
    } catch (e) {
      //DB exception handling
      debugPrint("App Init Error: $e");
      return {'token': null, 'username': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // ── Core palette (matching sleep screen) ──
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        primaryColor: const Color(0xFF4DD0E1),          // Teal accent
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4DD0E1),                    // Teal accent
          secondary: Color(0xFF7E57C2),                  // Purple
          tertiary: Color(0xFF5C6BC0),                   // Indigo
          surface: Color(0xFF152238),                    // Navy card surface
          onPrimary: Color(0xFF0D1B2A),
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        // ── Navigation bar ──
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0D1B2A),
          indicatorColor: const Color(0xFF4DD0E1).withOpacity(0.15),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF4DD0E1));
            }
            return const IconThemeData(color: Colors.white38);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF4DD0E1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(color: Colors.white38, fontSize: 12);
          }),
        ),
        // ── Text ──
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
        // ── Cards ──
        cardTheme: CardThemeData(
          color: const Color(0xFF152238),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        // ── AppBar ──
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        // ── Inputs ──
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white54),
          prefixIconColor: Colors.white38,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white12),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4DD0E1)),
          ),
        ),
      ),
      home: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data!['token'] != null) {
            return HomePage(
              userSessionToken: snapshot.data!['token']!,
              username: snapshot.data!['username'] ?? "User",
            );
          }

          return const IntroductionAnimationScreen();
        },
      ),
    );
  }
}
