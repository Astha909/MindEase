import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  final AuthController authController;

  const RegisterScreen({
    super.key,
    required this.authController,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _selectedGender;
  String? _selectedSexuality;

  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _ageFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final age = int.tryParse(_ageController.text);
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      _error = "Name is required";
      return false;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _error = "Invalid email";
      return false;
    }

    if (age == null || age <= 0) {
      _error = "Enter valid age";
      return false;
    }

    if (password.length < 6) {
      _error = "Password must be at least 6 characters";
      return false;
    }

    _error = null;
    return true;
  }

  Future<void> _handleRegister() async {
    if (widget.authController.isLoading) return;

    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
      return;
    }

    final success = await widget.authController.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender ?? "Prefer not to say",
      sexuality: _selectedSexuality,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.authController.errorMessage ?? "Registration Failed",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authController.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFE6FAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
                decoration: _inputDecoration('Full Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_ageFocus),
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ageController,
                focusNode: _ageFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                decoration: _inputDecoration('Age'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Gender'),
                items: const [
                  'Male',
                  'Female',
                  'Other',
                  'Prefer not to say',
                ]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Sexuality'),
                items: const [
                  'Straight',
                  'Gay',
                  'Lesbian',
                  'Bisexual',
                  'Asexual',
                  'Prefer not to say',
                ]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedSexuality = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!isLoading) _handleRegister();
                },
                decoration: _inputDecoration('Password'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Register'),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Already have an account? Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );
}
