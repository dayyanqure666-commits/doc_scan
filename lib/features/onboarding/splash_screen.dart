// lib/features/onboarding/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      onboardingDone ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.radiusXl,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                size: 56,
                color: AppTheme.primary,
              ),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            const Text(
              'DocScan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              'Scan · Enhance · Export',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            )
                .animate(delay: 350.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
