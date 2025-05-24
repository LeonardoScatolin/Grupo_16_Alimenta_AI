import 'package:alimenta_ai/pages/login.dart';
import 'package:alimenta_ai/pages/dashboard.dart';
import 'package:alimenta_ai/pages/tela_notificacao.dart';
import 'package:alimenta_ai/pages/welcome.dart';
import 'package:alimenta_ai/pages/registro_unificado.dart';
import 'package:alimenta_ai/pages/profile.dart';
import 'package:alimenta_ai/pages/weight_history.dart';
import 'package:alimenta_ai/theme/app_theme.dart';
import 'package:alimenta_ai/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeProvider = ThemeProvider();
  while (!themeProvider.isInitialized) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
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
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/intro',
          routes: {
            '/intro': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const DashboardPage(),
            '/registra-alimento': (context) => const RegistroUnificadoPage(),
            '/notificacao': (context) => const NotificacoesPage(),
            '/refeicao': (context) => const RegistroUnificadoPage(),
            '/profile': (context) => const ProfilePage(),
            '/weight-history': (context) => const WeightHistoryPage(),
          },
        );
      },
    );
  }
}
