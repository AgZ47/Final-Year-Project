import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter (Frosted Glass)
import 'package:flutter/material.dart';
import 'package:health_app/home_page.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background from image
      body: Stack(
        children: [
          // 1. Background decorative circles
          Positioned(
            top: 300,
            right: -50,
            child: _buildCircle(200, const Color(0xFF1D8B8E)),
          ),
          Positioned(
            top: 280,
            right: 100,
            child: _buildCircle(60, const Color(0xFF1D8B8E)),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: _buildCircle(180, const Color(0xFF1D8B8E)),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo placeholder (Use Image.asset when ready)
                const Text(
                  "Aura Fit",
                  style: TextStyle(
                    fontSize: 80,
                    color: Color(0xFF4CB6BD),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // 3. The Glassmorphism Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildTextField(
                              "Full Name",
                              Icons.person,
                              _usernameController,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              "E-mail or Mobile Number",
                              Icons.email,
                              _emailController,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              "Password",
                              Icons.lock,
                              _passwordController,
                              isPassword: true,
                            ),
                            const SizedBox(height: 40),

                            // 4. Continue Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CB6BD),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                var url = Uri.http(
                                  '10.0.2.2:3000',
                                  'auth/register',
                                );
                                var response = await http.post(
                                  url,
                                  headers: {"Content-Type": "application/json"},
                                  body: jsonEncode({
                                    'username': _usernameController.text,
                                    'email': _emailController.text,
                                    'password': _passwordController.text,
                                  }),
                                );
                                if (response.statusCode == 200) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomePage(
                                        userSessionToken: response.body,
                                        username: _usernameController.text,
                                      ),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                } else {
                                  print("FAILED TO SEND DATA TO BACKEND");
                                  print(response.statusCode);
                                }
                              },
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Center(
                              child: Text(
                                "Joined us before? Sign In",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the circles
  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.6),
      ),
    );
  }

  // Helper for the underline textfields
  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController? controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4CB6BD)),
        ),
      ),
    );
  }
}
