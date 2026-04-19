// ============================================================
// main.dart
// Rajpatra AI — Officer Assistant
// Direct access — no login required
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_provider.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/editor_screen.dart';
import 'services/groq_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Groq Service ───────────────────────────────────────────
  GroqService.instance.init();

  runApp(const RajpatraApp());
}

class RajpatraApp extends StatelessWidget {
  const RajpatraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LetterProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routes: {'/editor': (_) => const EditorScreen()},
        // Go straight to dashboard — no login gate
        home: const DashboardScreen(),
      ),
    );
  }
}
