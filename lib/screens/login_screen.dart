// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  /// 🔥 FIXED: separate loading states (UI only)
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  String? _emailError;
  String? _passwordError;

  double _shakeOffset = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String _friendlyError(String error) {
    final e = error.toLowerCase();

    if (e.contains("wrong-password") ||
        e.contains("password is invalid") ||
        e.contains("invalid password")) {
      return "Incorrect password";
    }

    if (e.contains("user-not-found") ||
        e.contains("no user record") ||
        e.contains("user does not exist")) {
      return "Email not registered";
    }

    if (e.contains("invalid-email")) {
      return "Invalid email format";
    }

    if (e.contains("network")) {
      return "Network error. Check internet connection.";
    }

    if (e.contains("verify")) {
      return "Please verify your email before logging in.";
    }

    return "Login failed";
  }

  void _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    setState(() {
      _emailError = email.isEmpty
          ? "Email is required"
          : (!emailRegex.hasMatch(email) ? "Invalid email format" : null);

      _passwordError = password.isEmpty ? "Password is required" : null;
    });
  }

  bool _isFormValid() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    return email.isNotEmpty &&
        password.isNotEmpty &&
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  void _triggerShake() async {
    for (int i = 0; i < 3; i++) {
      setState(() => _shakeOffset = 8);
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() => _shakeOffset = -8);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() => _shakeOffset = 0);
  }

  Future<void> _login(AuthController authController) async {
    _validateFields();

    if (!_isFormValid()) {
      _triggerShake();
      return;
    }

    if (_isEmailLoading || _isGoogleLoading) return;

    setState(() => _isEmailLoading = true);

    final success = await authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isEmailLoading = false);

    if (success) {
      final uid = authController.getCurrentUserId();

      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected error. Try again")),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: uid),
        ),
      );
    } else if (authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(authController.errorMessage!),
          ),
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin(AuthController authController) async {
    if (_isEmailLoading || _isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    final success = await authController.loginWithGoogle();

    if (!mounted) return;

    setState(() => _isGoogleLoading = false);

    if (success) {
      final uid = authController.getCurrentUserId();

      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected error. Try again")),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: uid),
        ),
      );
    } else if (authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(authController.errorMessage!),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    final isAnyLoading =
        _isEmailLoading || _isGoogleLoading || authController.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFE6FAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Transform.translate(
            offset: Offset(_shakeOffset, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _validateFields(),
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  decoration: _inputDecoration(
                    'Email',
                    prefixIcon: const Icon(Icons.email),
                  ).copyWith(
                    errorText: _emailError,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _validateFields(),
                  onSubmitted: (_) {
                    if (!isAnyLoading) {
                      _login(authController);
                    }
                  },
                  decoration: _inputDecoration(
                    'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ).copyWith(
                    errorText: _passwordError,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isAnyLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                    child: const Text("Forgot Password?"),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAnyLoading || !_isFormValid()
                        ? null
                        : () => _login(authController),
                    child: _isEmailLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    icon: Image.network(
                      "https://developers.google.com/identity/images/g-logo.png",
                      height: 20,
                    ),
                    label: _isGoogleLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "Continue with Google",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                    onPressed: isAnyLoading
                        ? null
                        : () => _handleGoogleLogin(authController),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: isAnyLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                authController: authController,
                              ),
                            ),
                          );
                        },
                  child: const Text(
                    "Don't have an account? Register",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  String hint, {
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );
}
