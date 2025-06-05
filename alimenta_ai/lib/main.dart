import 'package:alimenta_ai/pages/login.dart';
import 'package:alimenta_ai/pages/dashboard.dart';
import 'package:alimenta_ai/pages/welcome.dart';
import 'package:alimenta_ai/pages/registro_unificado.dart';
import 'package:alimenta_ai/pages/weight_history.dart';
import 'package:alimenta_ai/pages/audio_transcription_page.dart';
import 'package:alimenta_ai/pages/profile.dart';
import 'package:alimenta_ai/theme/app_theme.dart';
import 'package:alimenta_ai/theme/theme_provider.dart';
import 'package:alimenta_ai/services/nutricao_service.dart';
import 'package:alimenta_ai/services/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  while (!themeProvider.isInitialized) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => NutricaoService()),
        ChangeNotifierProvider(create: (_) => AudioService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginPage(),
            '/dashboard': (context) => const DashboardPage(),
            '/home': (context) => const DashboardPage(), // Alias
            '/registro': (context) => const RegistroUnificadoPage(),
            '/registra-alimento': (context) =>
                const RegistroUnificadoPage(), // Usando a nova tela unificada
            '/profile': (context) => const ProfilePage(),
            '/weight-history': (context) => const WeightHistoryPage(),            '/notifications': (context) => const WeightHistoryPage(),
            '/audio-transcription': (context) => const AudioTranscriptionPage(),
            // '/debug': (context) => const DebugTestPage(),
          },
        );
      },
    );
  }
}
