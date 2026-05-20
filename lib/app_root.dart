import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return StreamBuilder<String?>(
      stream: authController.authUserIdStream,
      builder: (context, snapshot) {
        // Keep splash until Firebase is ready
        if (_showSplash ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final userId = snapshot.data;

        if (userId != null) {
          return HomeScreen(userId: userId);
        }

        return const LoginScreen();
      },
    );
  }
}
