import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/pages/login.dart';

void main() {
  group('Login Page Tests', () {
    testWidgets('Login page shows all required UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      // Verificar elementos visuais principais
      expect(find.byType(TextField), findsNWidgets(2)); // Email e senha
      expect(find.text('ENTRAR'), findsOneWidget);
      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(find.text('Não tem uma conta?'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsOneWidget);
    });

    testWidgets('Shows error on empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      // Tentar login com campos vazios
      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor, preencha todos os campos'), findsOneWidget);
    });

    testWidgets('Login button triggers animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      // Preencher campos
      await tester.enterText(find.byType(TextField).first, 'test@email.com');
      await tester.enterText(find.byType(TextField).last, 'password123');

      // Verificar animação do botão
      final buttonFinder = find.text('ENTRAR');
      await tester.tap(buttonFinder);
      await tester.pump();

      // Verificar se o loading é mostrado
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
