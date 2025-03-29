import 'package:alimenta_ai/pages/tela_introducao.dart';
import 'package:alimenta_ai/pages/login.dart';
import 'package:alimenta_ai/pages/home.dart';
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
        '/intro': (context) => const TelaIntroducao(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
