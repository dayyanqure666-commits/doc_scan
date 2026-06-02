import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.document_scanner_outlined,
      color: Color(0xFF2563EB),
      title: 'Scan Anything',
      subtitle:
          'Point your camera at any document. Our AI detects edges automatically and captures a perfect scan every time.',
    ),
    _OnboardingPage(
      icon: Icons.auto_fix_high_outlined,
      color: Color(0xFF7C3AED),
      title: 'Auto-Enhance',
      subtitle:
          'Remove shadows, boost contrast, and sharpen text. Your scans look professional — ready for any OCR system.',
    ),
    _OnboardingPage(
      icon: Icons.picture_as_pdf_outlined,
      color: Color(0xFF059669),
      title: 'Export Clean PDFs',
      subtitle:
          'Generate multi-page, compressed PDFs optimized for text recognition. Share instantly or store locally.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            // Indicator + Navigation
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: WormEffect(
                      activeDotColor: Theme.of(context).colorScheme.primary,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
