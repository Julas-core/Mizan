import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_service.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

  if (!hasSeenWelcome) {
    await prefs.setBool('has_seen_welcome', true);
  }

  final initialLoc = onboardingCompleted
      ? '/'
      : (showWelcomeRoute(!hasSeenWelcome) ? '/welcome' : '/income_setup');

  runApp(ProviderScope(child: MizanApp(initialLocation: initialLoc)));
}

bool showWelcomeRoute(bool showWelcome) => showWelcome;

class MizanApp extends ConsumerStatefulWidget {
  final String initialLocation;

  const MizanApp({super.key, required this.initialLocation});

  @override
  ConsumerState<MizanApp> createState() => _MizanAppState();
}

class _MizanAppState extends ConsumerState<MizanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.initialLocation);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mizan',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
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
    );
  }
}
