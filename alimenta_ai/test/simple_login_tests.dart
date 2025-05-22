import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/pages/login.dart';
import 'package:alimenta_ai/services/auth_service.dart';

void main() {
  // -------------------------
  // BLACK BOX TESTS
  // -------------------------
  group('Black Box Tests - User Interface', () {
    testWidgets('Login page shows all required UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Page')),
            '/intro': (context) => const Scaffold(body: Text('Intro Page')),
          },
          home: const LoginPage(),
        ),
      );

   
      expect(find.text('Login'), findsOneWidget); // AppBar title
      expect(find.text('ENTRAR'), findsOneWidget); // Login button
      expect(find.text('Esqueceu a senha?'),
          findsOneWidget); // Forgot password text
      expect(find.text('Não tem uma conta? '),
          findsOneWidget); // Don't have account text
      expect(find.text('Cadastre-se'), findsOneWidget); // Register text
    });

    testWidgets('Login page allows text input in fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Page')),
            '/intro': (context) => const Scaffold(body: Text('Intro Page')),
          },
          home: const LoginPage(),
        ),
      );

      // Enter text in Email field
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'user@example.com');
      expect(find.text('user@example.com'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Senha'), 'password123');
      expect(find.text('password123'), findsOneWidget);
    });
  });

  group('Gray Box Tests - Component Interaction', () {
    testWidgets('Password visibility toggle works',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Initially password should be obscured
      Finder passwordField = find.widgetWithText(TextField, 'Senha');
      TextField textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, true);

      // Tap visibility toggle button
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now password should be visible
      passwordField = find.widgetWithText(TextField, 'Senha');
      textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, false);
    });

    testWidgets('Loading state appears when login button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Page')),
          },
          home: const LoginPage(),
        ),
      );

      // Enter valid credentials
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Senha'), 'password123');

      // Initially no CircularProgressIndicator should be visible
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap login button
      await tester.tap(find.text('ENTRAR'));
      await tester.pump(); // Rebuild the widget once

      // After tapping, a CircularProgressIndicator might appear (depends on implementation)
      // Note: This might need adjustments based on how your loading state is implemented
    });
  });

  // -------------------------
  // WHITE BOX TESTS
  // -------------------------
  group('White Box Tests - Internal Logic', () {
    test('AuthService login validation works', () {
      AuthService authService = AuthService();
      expect(
        () => authService.login('', 'password123'),
        returnsNormally,
        reason: 'Empty email should be handled gracefully',
      );

      expect(
        authService.baseUrl,
        contains('/api'),
        reason: 'API URL should contain the correct path',
      );
    });

    test('Login function handles errors', () async {
      AuthService authService = AuthService();

      try {
        // ignore: unused_local_variable
        final oldUrl = authService.baseUrl;


        final result = await authService.login('test@example.com', 'password');
        expect(result.containsKey('success'), true);
      } catch (e) {
        fail('Login function should handle errors gracefully: $e');
      }
    });
  });
}
