import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Debug semantic labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Semantics(
                label: 'Email input field. Enter your email address.',
                child: const TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(labelText: 'Email'),
                ),
              ),
              Semantics(
                label: 'Login button. Double tap to sign in to your account.',
                button: true,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Print all semantics to debug
    final semanticsData = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode?.debugDescribeChildren();
    print('Semantics tree: $semanticsData');

    // Try to find by key first
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    print('Email field found by key');

    // Try to find by text
    expect(find.text('Login'), findsOneWidget);
    print('Login button found by text');

    // Try to find by semantics label
    try {
      expect(find.bySemanticsLabel('Email input field. Enter your email address.'), findsOneWidget);
      print('Email field found by semantics label');
    } catch (e) {
      print('Email field NOT found by semantics label: $e');
    }

    try {
      expect(find.bySemanticsLabel('Login button. Double tap to sign in to your account.'), findsOneWidget);
      print('Login button found by semantics label');
    } catch (e) {
      print('Login button NOT found by semantics label: $e');
    }
  });
}
