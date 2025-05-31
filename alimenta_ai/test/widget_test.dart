import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/pages/welcome.dart';
import 'package:alimenta_ai/theme/app_theme.dart';

void main() {
  group('Basic App Tests', () {
    testWidgets('App should render MaterialApp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WelcomeScreen(),
        ),
      );
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Welcome screen should render basic elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WelcomeScreen(),
        ),
      );
      
      await tester.pump();
      
      // Verifica se a tela de boas-vindas carregou
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}