import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/pages/login.dart';

void main() {
  group('Login Page Tests', () {
    testWidgets('Login page renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      
      await tester.pump();

      // Verificar se a página carregou
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Login page shows basic elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      
      await tester.pumpAndSettle();

      // Verificar elementos básicos
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
      expect(find.text('ENTRAR'), findsOneWidget);
    });
    
    testWidgets('Login button is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      
      await tester.pumpAndSettle();

      // Verificar se o botão é clicável
      final loginButton = find.text('ENTRAR');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pump(); // Apenas um pump para evitar timeout
    });
  });
}
