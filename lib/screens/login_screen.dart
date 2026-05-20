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

enum LoginAction {
  email,
  google,
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();

  final RegExp _emailRegex = RegExp(
    r'^[^@]+@[^@]+\.[^@]+$',
  );

  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  double _shakeOffset = 0;

  LoginAction? _activeAction;

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
        e.contains("invalid password") ||
        e.contains("invalid-credential")) {
      return "Incorrect email or password";
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

    if (e.contains("profile missing")) {
      return "Profile missing. Please register again.";
    }

    if (e.contains("cancelled")) {
      return "Google sign-in cancelled";
    }

    return "Login failed. Please try again.";
  }

  void _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = email.isEmpty
          ? "Email is required"
          : (!_emailRegex.hasMatch(email) ? "Invalid email format" : null);

      _passwordError = password.isEmpty ? "Password is required" : null;
    });
  }

  bool _isFormValid() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    return email.isNotEmpty &&
        password.isNotEmpty &&
        _emailRegex.hasMatch(email);
  }

  Future<void> _triggerShake() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() => _shakeOffset = 8);

      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;
      setState(() => _shakeOffset = -8);

      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;
    setState(() => _shakeOffset = 0);
  }

  Future<void> _login(AuthController authController) async {
    _validateFields();

    if (!_isFormValid()) {
      await _triggerShake();
      return;
    }

    if (authController.isLoading) return;

    setState(() {
      _activeAction = LoginAction.email;
    });

    final success = await authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _activeAction = null;
    });

    if (success) {
      final uid = authController.getCurrentUserId();

      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unexpected error. Try again."),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: uid),
        ),
      );
    } else {
      final error = authController.errorMessage;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(error)),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin(AuthController authController) async {
    if (authController.isLoading) return;

    setState(() {
      _activeAction = LoginAction.google;
    });

    final success = await authController.loginWithGoogle();

    if (!mounted) return;

    setState(() {
      _activeAction = null;
    });

    if (success) {
      final uid = authController.getCurrentUserId();

      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unexpected error. Try again."),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: uid),
        ),
      );
    } else {
      final error = authController.errorMessage;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(error)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final isLoading = authController.isLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFE6FAFA),
          body: SafeArea(
            child: AutofillGroup(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          transform: Matrix4.translationValues(
                            _shakeOffset,
                            0,
                            0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Login to continue your wellness journey",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 34),
                              TextField(
                                controller: _emailController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.email,
                                ],
                                onChanged: (_) => _validateFields(),
                                onSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(
                                    _passwordFocusNode,
                                  );
                                },
                                decoration: _inputDecoration(
                                  "Email",
                                  prefixIcon: const Icon(Icons.email_rounded),
                                ).copyWith(
                                  errorText: _emailError,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                enabled: !isLoading,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.password,
                                ],
                                onChanged: (_) => _validateFields(),
                                onSubmitted: (_) {
                                  if (!isLoading) {
                                    _login(authController);
                                  }
                                },
                                decoration: _inputDecoration(
                                  "Password",
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                    ),
                                  ),
                                ).copyWith(
                                  errorText: _passwordError,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ForgotPasswordScreen(
                                                authController: authController,
                                              ),
                                            ),
                                          );
                                        },
                                  child: const Text("Forgot Password?"),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _emailController,
                                builder: (context, _, __) {
                                  return ValueListenableBuilder<
                                      TextEditingValue>(
                                    valueListenable: _passwordController,
                                    builder: (context, __, ___) {
                                      final canLogin =
                                          _isFormValid() && !isLoading;

                                      return SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: canLogin
                                              ? () => _login(authController)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor:
                                                const Color(0xFF5D9CEC),
                                            disabledBackgroundColor:
                                                const Color(0xFF5D9CEC)
                                                    .withOpacity(0.35),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: isLoading &&
                                                  _activeAction ==
                                                      LoginAction.email
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  "Login",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 22),
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Text("OR"),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  icon: isLoading &&
                                          _activeAction == LoginAction.google
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Image.asset(
                                          "assets/images/google_logo.png",
                                          height: 20,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Text(
                                              "G",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            );
                                          },
                                        ),
                                  label: const Text(
                                    "Continue with Google",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => _handleGoogleLogin(
                                            authController,
                                          ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: isLoading
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
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
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
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(
        color: Color(0xFF5D9CEC),
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(
        color: Colors.redAccent,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.4,
      ),
    ),
  );
}
