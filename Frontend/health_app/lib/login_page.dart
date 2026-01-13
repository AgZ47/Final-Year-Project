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
                        child: Form(
                          key: _formKey,
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
                                validator: (value) {
                                  if (_backendUsernameError != null)
                                    return _backendUsernameError;
                                  if (value == null || value.length < 3)
                                    return "Enter atleast 3 characters";
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                "E-mail or Mobile Number",
                                Icons.email,
                                _emailController,
                                validator: (value) {
                                  if (_backendEmailError != null)
                                    return _backendEmailError;
                                  if (value == null || value.isEmpty)
                                    return "Email is required";
                                  if (!RegExp(
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                  ).hasMatch(value)) {
                                    return "Please enter a valid email address";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                "Password",
                                Icons.lock,
                                _passwordController,
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return "Password is required";
                                  if (value.length < 6)
                                    return "Password must be at least 6 characters";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 40),

                              // 4. Continue Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CB6BD),
                                  minimumSize: const Size(double.infinity, 50),
                                  //minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        // 1. Reset errors before the new attempt
                                        setState(() {
                                          _backendEmailError = null;
                                          _backendUsernameError = null;
                                        });

                                        if (_formKey.currentState!.validate()) {
                                          setState(() => _isLoading = true);

                                          try {
                                            // 2. Use Uri.http for local development on port 3000
                                            var url = Uri.http(
                                              '10.0.2.2:3000',
                                              'auth/register',
                                            );

                                            var response = await http.post(
                                              url,
                                              headers: {
                                                "Content-Type":
                                                    "application/json",
                                              },
                                              body: jsonEncode({
                                                'username':
                                                    _usernameController.text,
                                                'email': _emailController.text,
                                                'password':
                                                    _passwordController.text,
                                              }),
                                            );

                                            if (response.statusCode == 200) {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      HomePage(
                                                        userSessionToken:
                                                            response.body,
                                                        username:
                                                            _usernameController
                                                                .text,
                                                      ),
                                                ),
                                                (Route<dynamic> route) => false,
                                              );
                                            }
                                            // 3. Handle Duplicate Errors (Conflict)
                                            else if (response.statusCode ==
                                                409) {
                                              final errorData = jsonDecode(
                                                response.body,
                                              );
                                              final String message =
                                                  errorData['message'] ?? "";

                                              setState(() {
                                                if (message.contains(
                                                      "Username",
                                                    ) ||
                                                    message.contains(
                                                      "username",
                                                    )) {
                                                  _backendUsernameError =
                                                      message;
                                                } else if (message.contains(
                                                      "Email",
                                                    ) ||
                                                    message.contains("email")) {
                                                  _backendEmailError = message;
                                                }
                                              });

                                              // 4. CRITICAL: Re-trigger validation to display the backend messages
                                              _formKey.currentState!.validate();
                                            } else {
                                              print(
                                                "SERVER ERROR: ${response.statusCode}",
                                              );
                                            }
                                          } catch (e) {
                                            print("NETWORK ERROR: $e");
                                          } finally {
                                            if (mounted)
                                              setState(
                                                () => _isLoading = false,
                                              );
                                          }
                                        }
                                      },
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        errorStyle: const TextStyle(color: Color(0xFF4CB6BD)),
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
