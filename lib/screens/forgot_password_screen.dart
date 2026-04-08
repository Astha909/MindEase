import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _error = "Email is required";
      return false;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _error = "Invalid email format";
      return false;
    }

    _error = null;
    return true;
  }

  String _friendlyError(String error) {
    final e = error.toLowerCase();

    if (e.contains("user-not-found")) {
      return "Email not registered";
    }

    if (e.contains("invalid-email")) {
      return "Invalid email format";
    }

    if (e.contains("network")) {
      return "Check your internet connection";
    }

    return "Something went wrong";
  }

  Future<void> _handleReset(AuthController authController) async {
    if (authController.isLoading) return;

    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
      return;
    }

    final success = await authController.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );

      Navigator.pop(context);
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
    final isLoading = authController.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Enter your email and we will send you a password reset link.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!isLoading) {
                  _handleReset(authController);
                }
              },
              decoration: const InputDecoration(
                hintText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : () => _handleReset(authController),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Send Reset Link"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
