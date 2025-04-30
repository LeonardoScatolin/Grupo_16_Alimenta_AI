import 'package:alimenta_ai/pages/login.dart';
import 'package:alimenta_ai/pages/dashboard.dart';
import 'package:alimenta_ai/pages/tela_notificacao.dart';
import 'package:alimenta_ai/pages/welcome.dart';
import 'package:alimenta_ai/pages/registro_unificado.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/intro',
      routes: {
        '/intro': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const DashboardPage(),
        '/registra-alimento': (context) => const RegistroUnificadoPage(),
        '/notificacao': (context) => const NotificacoesPage(),
        '/refeicao': (context) =>
            const RegistroUnificadoPage(), // Agora usa a mesma página para ambos
      },
    );
  }
}
