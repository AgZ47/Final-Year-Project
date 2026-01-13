import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health_app/animations/introduction_animation_screen.dart';
import 'package:health_app/home_page.dart';
import 'package:health_app/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, String?>> _checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'user_session_token');
    String? username = await storage.read(key: 'username');
    return {'token': token, 'username': username};
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _checkLoginStatus(),
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
      color: Colors.black54,
    );
  }
}
