import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart'; // Import your login screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animation
              Image.asset(
                'assets/images/oouth_logo.png',
                height: 120,
                width: 120,
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(delay: 400.ms)
                  .then(delay: 400.ms)
                  .shimmer(duration: 1200.ms),

              const SizedBox(height: 24),

              // State logo
              Image.asset(
                'assets/images/ogun_logo.png',
                height: 60,
                width: 60,
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 800.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 48),

              // App name with fade and slide
              Text(
                'OOUTH MOBILE',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 800.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 24),

              // Loading indicator
              const CircularProgressIndicator()
                  .animate()
                  .fadeIn(delay: 1200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
