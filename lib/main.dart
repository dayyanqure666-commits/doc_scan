import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/session_manager.dart';
import 'core/services/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'screens/login_screen.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for consistent scanning UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  bool isLoggedIn = false;
  try {
    isLoggedIn = await SessionManager().isLoggedIn();
  } catch (e) {
    debugPrint('Session verification failed, falling back to guest mode: $e');
  }

  runApp(DocScanApp(
    showOnboarding: !onboardingComplete,
    isLoggedIn: isLoggedIn,
  ));
}

class DocScanApp extends StatelessWidget {
  final bool showOnboarding;
  final bool isLoggedIn;
  
  const DocScanApp({
    super.key,
    required this.showOnboarding,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider()..init(),
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'DocScan',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appState.settings.darkMode ? ThemeMode.dark : ThemeMode.system,
            home: isLoggedIn
                ? (showOnboarding ? const OnboardingScreen() : const HomeScreen())
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
