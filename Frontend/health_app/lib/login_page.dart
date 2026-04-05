import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:health_app/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = true;
  bool _isRegistered = false;
  String _savedUsername = "";

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  // Check if the user has already set up the app locally
  Future<void> _checkRegistrationStatus() async {
    String? username = await _storage.read(key: 'username');
    if (username != null && username.isNotEmpty) {
      setState(() {
        _isRegistered = true;
        _savedUsername = username;
        _isLoading = false;
      });
      // Automatically prompt for biometrics if they are already registered
      _authenticateUser();
    } else {
      setState(() {
        _isRegistered = false;
        _isLoading = false;
      });
    }
  }

  // Trigger FaceID / TouchID / Device PIN
  Future<void> _authenticateUser() async {
    setState(() => _isLoading = true);
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        // Fallback if device has no security set up: just let them in
        _navigateToHome(_savedUsername);
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock Aura Fit to view your health data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allows PIN fallback
        ),
      );

      if (didAuthenticate) {
        _navigateToHome(_savedUsername);
      } else {
        setState(() => _isLoading = false);
      }
    } on PlatformException catch (e) {
      debugPrint("Auth Error: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Save the name for first-time setup
  Future<void> _handleFirstTimeSetup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final name = _usernameController.text.trim();

      // Save locally
      await _storage.write(key: 'username', value: name);
      // Give them a dummy token so main.dart knows they are logged in
      await _storage.write(
        key: 'user_session_token',
        value: 'local_auth_token',
      );

      _navigateToHome(name);
    }
  }

  void _navigateToHome(String username) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HomePage(userSessionToken: 'local_auth_token', username: username),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          // Background UI Orbs
          Positioned(
            top: 300,
            right: -50,
            child: _buildCircle(200, const Color(0xFF4DD0E1)),
          ),
          Positioned(
            top: 280,
            right: 100,
            child: _buildCircle(60, const Color(0xFF7E57C2)),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: _buildCircle(180, const Color(0xFF5C6BC0)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Aura Fit",
                      style: TextStyle(
                        fontSize: 60,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Icon(
                      Icons.health_and_safety_rounded,
                      size: 80,
                      color: Color(0xFF4DD0E1),
                    ),
                    const SizedBox(height: 40),

                    _isRegistered ? _buildUnlockCard() : _buildSetupCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UI: First Time Setup (No Account Found) ──
  Widget _buildSetupCard() {
    return _glassCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome",
              style: TextStyle(
                fontSize: 32,
                color: Color(0xFF4DD0E1),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Let's set up your secure local profile.",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person,
                  color: const Color(0xFF4DD0E1).withOpacity(0.5),
                ),
                labelText: "What should we call you?",
                labelStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white12),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4DD0E1)),
                ),
              ),
              validator: (value) => (value == null || value.length < 2)
                  ? "Please enter your name"
                  : null,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DD0E1),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _handleFirstTimeSetup,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Start Wellness Journey",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI: Returning User (Account Found) ──
  Widget _buildUnlockCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Welcome back,",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            _savedUsername,
            style: const TextStyle(
              fontSize: 32,
              color: Color(0xFF4DD0E1),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          const Icon(
            Icons.fingerprint_rounded,
            size: 70,
            color: Colors.white54,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7E57C2),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _authenticateUser,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Unlock Aura Fit",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── UI Helper: Glassmorphism Card ──
  Widget _glassCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF4DD0E1).withOpacity(0.15),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.4),
      ),
    );
  }
}
