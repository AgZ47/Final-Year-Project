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
      theme: ThemeData.dark(),
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
