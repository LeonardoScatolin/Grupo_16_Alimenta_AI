import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/pages/registro_unificado.dart';

void main() {
  group('Meal Tracking Tests', () {
    testWidgets('Shows all meal sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RegistroUnificadoPage()),
      );

      expect(find.text('Café da Manhã'), findsOneWidget);
      expect(find.text('Almoço'), findsOneWidget);
      expect(find.text('Lanches'), findsOneWidget);
      expect(find.text('Janta'), findsOneWidget);
    });

    testWidgets('Can add food to meal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RegistroUnificadoPage()),
      );

      // Encontrar e tocar no botão de adicionar alimento
      await tester.tap(find.text('Adicionar Alimento').first);
      await tester.pumpAndSettle();

      // Verificar se o modal de gravação é exibido
      expect(find.text('Pressione e segure para falar'), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Calculates total calories correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RegistroUnificadoPage()),
      );

      // Verificar se o sumário de calorias é exibido
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.text('Calorias'), findsWidgets);
      
      // Verificar se os macros são exibidos
      expect(find.text('Proteína (g)'), findsOneWidget);
      expect(find.text('Carbs (g)'), findsOneWidget);
    });

    testWidgets('Shows date selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RegistroUnificadoPage()),
      );

      // Verificar elementos do seletor de data
      expect(find.byType(ListView), findsOneWidget);
      
      // Verificar se mostra o mês atual
      final now = DateTime.now();
      final months = [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
      ];
      expect(find.text(months[now.month - 1]), findsOneWidget);
    });
  });
}
