import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health_app/home_page.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ==========================================
  // 🛠️ DEVELOPMENT TOGGLE
  // Set to true to bypass backend for UI testing
  // ==========================================
  final bool _isTestingMode = true;

  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _backendUsernameError;
  String? _backendEmailError;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Aura Fit",
                        style: TextStyle(
                          fontSize: 80,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: Image.asset(
                          'assets/aurafit_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Optional Visual Indicator for Devs
                      if (_isTestingMode)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "TESTING MODE ACTIVE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      _buildGlassCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
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
              border: Border.all(color: const Color(0xFF4DD0E1).withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 32,
                    color: Color(0xFF4DD0E1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  "Full Name",
                  Icons.person,
                  _usernameController,
                  onChanged: (val) {
                    if (_backendUsernameError != null)
                      setState(() => _backendUsernameError = null);
                  },
                  validator: (value) {
                    if (_backendUsernameError != null)
                      return _backendUsernameError;
                    return (value == null || value.length < 3)
                        ? "Enter at least 3 characters"
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "E-mail",
                  Icons.email,
                  _emailController,
                  onChanged: (val) {
                    if (_backendEmailError != null)
                      setState(() => _backendEmailError = null);
                  },
                  validator: (value) {
                    if (_backendEmailError != null) return _backendEmailError;
                    if (value == null || value.isEmpty)
                      return "Email is required";
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
                      return "Enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "Password",
                  Icons.lock,
                  _passwordController,
                  isPassword: true,
                  validator: (value) => (value == null || value.length < 6)
                      ? "Password must be 6+ characters"
                      : null,
                ),
                const SizedBox(height: 40),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4DD0E1),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _isLoading ? null : _handleRegister,
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
              "Continue",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() {
      _backendEmailError = null;
      _backendUsernameError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // ==========================================
        // MOCK LOGIN LOGIC
        // ==========================================
        if (_isTestingMode) {
          // Simulate network delay to test loading spinner
          await Future.delayed(const Duration(seconds: 1));

          final String testUsername = _usernameController.text.trim();
          const String testToken = "mock_jwt_session_token_12345";

          await _storage.write(key: 'user_session_token', value: testToken);
          await _storage.write(key: 'username', value: testUsername);

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomePage(userSessionToken: testToken, username: testUsername),
            ),
            (route) => false,
          );

          return; // Exit function so real HTTP code doesn't run
        }

        // ==========================================
        // REAL BACKEND LOGIC
        // ==========================================
        var url = Uri.http('10.0.2.2:3000', 'auth/register');
        var response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          await _storage.write(key: 'user_session_token', value: response.body);
          await _storage.write(
            key: 'username',
            value: _usernameController.text.trim(),
          );

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                userSessionToken: response.body,
                username: _usernameController.text,
              ),
            ),
            (route) => false,
          );
        } else if (response.statusCode == 409) {
          final errorData = jsonDecode(response.body);
          final String msg = errorData['message'] ?? "";
          setState(() {
            if (msg.toLowerCase().contains("username"))
              _backendUsernameError = msg;
            else if (msg.toLowerCase().contains("email"))
              _backendEmailError = msg;
          });
          _formKey.currentState!.validate();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Connection error: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF4DD0E1).withOpacity(0.5)),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4DD0E1)),
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
