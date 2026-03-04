import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/income_setup_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

  if (!hasSeenWelcome) {
    await prefs.setBool('has_seen_welcome', true);
  }

  runApp(
    MizanApp(
      showWelcome: !hasSeenWelcome,
      onboardingCompleted: onboardingCompleted,
    ),
  );
}

class MizanApp extends StatelessWidget {
  const MizanApp({
    super.key,
    required this.showWelcome,
    required this.onboardingCompleted,
  });

  final bool showWelcome;
  final bool onboardingCompleted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mizan',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF30e8c9),
        scaffoldBackgroundColor: const Color(0xFF11211e),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF30e8c9),
          secondary: Color(0xFF30e8c9),
          surface: Color(0xFF1e293b),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: onboardingCompleted
          ? const HomeScreen()
          : (showWelcome ? const WelcomeScreen() : const IncomeSetupScreen()),
    );
  }
}
