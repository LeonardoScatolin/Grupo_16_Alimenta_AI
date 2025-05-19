import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/main.dart';

void main() {
  group('Basic App Tests', () {
    testWidgets('App should render initial UI', (tester) async {
      // Set a reasonable test screen size
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}