import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
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

  runApp(DocScanApp(showOnboarding: !onboardingComplete));
}

class DocScanApp extends StatelessWidget {
  final bool showOnboarding;
  const DocScanApp({super.key, required this.showOnboarding});

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
            home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
          );
        },
      ),
    );
  }
}
