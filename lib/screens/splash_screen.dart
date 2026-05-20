import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 🔥 Slower smooth animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 🔥 Movement animation
    _moveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // 🔥 Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // 🔥 Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // 🔥 Start animation then navigate automatically
    _controller.forward().then((_) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double logoSize = 145;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🔥 Background matching logo colors
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF061A3A),
              Color(0xFF152C6B),
              Color(0xFF5D4FA3),
              Color(0xFFFFB199),
            ],
          ),
        ),

        child: LayoutBuilder(
          builder: (context, constraints) {
            // 🔥 Start from bottom-left outside screen
            final double startLeft = -logoSize;

            final double startTop = constraints.maxHeight - logoSize - 60;

            // 🔥 End at center
            final double endLeft = (constraints.maxWidth - logoSize) / 2;

            final double endTop = (constraints.maxHeight - logoSize) / 2;

            return Stack(
              children: [
                // ✨ Small stars effect
                Positioned(
                  top: 120,
                  left: 50,
                  child: _buildStar(4),
                ),

                Positioned(
                  top: 200,
                  right: 70,
                  child: _buildStar(3),
                ),

                Positioned(
                  bottom: 180,
                  left: 80,
                  child: _buildStar(5),
                ),

                Positioned(
                  bottom: 250,
                  right: 40,
                  child: _buildStar(3),
                ),

                // 🔥 Main animated logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double left = startLeft +
                        (endLeft - startLeft) * _moveAnimation.value;

                    final double top =
                        startTop + (endTop - startTop) * _moveAnimation.value;

                    return Positioned(
                      left: left,
                      top: top,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.35),
                          blurRadius: 35,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✨ Tiny glowing stars
  Widget _buildStar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}
