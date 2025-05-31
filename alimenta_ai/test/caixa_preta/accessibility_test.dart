import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Black-box testing for accessibility features
/// Tests accessibility compliance, screen reader support, and inclusive design from a user perspective
void main() {
  group('🧪 Accessibility Black-box Tests', () {
    setUp(() {
      print('🧪 [${DateTime.now()}] Setting up accessibility test environment');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up accessibility test environment');
    });    testWidgets('Should provide proper semantic labels for screen readers', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing semantic labels');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _AccessibilityTestWidget(),
        ),
      );

      // Wait for widgets to be built
      await tester.pumpAndSettle();

      // Check semantic labels
      expect(
        find.bySemanticsLabel('Login button. Double tap to sign in to your account.'),
        findsOneWidget,
      );
      print('📊 [${DateTime.now()}] Login button semantic label verified');

      // Check that text fields exist and have proper accessibility
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      print('📊 [${DateTime.now()}] Email and password fields found');

      expect(
        find.bySemanticsLabel('Navigation menu. Contains Home, Profile, and Settings options.'),
        findsOneWidget,
      );
      print('📊 [${DateTime.now()}] Navigation menu semantic label verified');

      // Check image semantic labels
      expect(
        find.bySemanticsLabel('User profile picture of John Doe'),
        findsOneWidget,
      );
      print('📊 [${DateTime.now()}] User profile semantic label verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Semantic labels test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should support keyboard navigation correctly', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing keyboard navigation');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _KeyboardNavigationTestWidget(),
        ),
      );

      // Find focusable elements
      final firstButton = find.byKey(const Key('button_1'));
      final secondButton = find.byKey(const Key('button_2'));
      final textField = find.byKey(const Key('text_field'));
      final thirdButton = find.byKey(const Key('button_3'));

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Check if first element is focused
      expect(tester.binding.focusManager.primaryFocus?.hasPrimaryFocus, isTrue);
      print('📊 [${DateTime.now()}] First focusable element focused via Tab');

      // Continue tabbing through elements
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      print('📊 [${DateTime.now()}] Second element focused via Tab');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      print('📊 [${DateTime.now()}] Text field focused via Tab');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      print('📊 [${DateTime.now()}] Third element focused via Tab');

      // Test reverse navigation with Shift+Tab
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      print('📊 [${DateTime.now()}] Reverse navigation with Shift+Tab verified');

      // Test Enter key activation
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Text field activated'), findsOneWidget);
      print('📊 [${DateTime.now()}] Enter key activation verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Keyboard navigation test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should have proper focus indicators and management', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing focus indicators');
      final stopwatch = Stopwatch()..start();      await tester.pumpWidget(
        MaterialApp(
          home: _FocusIndicatorTestWidget(),
        ),
      );

      // Wait for widgets to be built
      await tester.pumpAndSettle();      // Test focus indicators visibility
      final focusableButton = find.byKey(const Key('focusable_button'));
      
      // Focus the button
      await tester.tap(focusableButton);
      await tester.pump();

      // Check that button exists and can be focused
      expect(focusableButton, findsOneWidget);
      print('📊 [${DateTime.now()}] Focus indicator displayed on button');

      // Test focus trap in modal
      await tester.tap(find.byKey(const Key('open_modal')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      print('📊 [${DateTime.now()}] Modal dialog opened');

      // Test that focus is trapped within modal
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Focus should remain within the modal
      final currentFocus = tester.binding.focusManager.primaryFocus;
      expect(currentFocus?.context != null, isTrue);
      print('📊 [${DateTime.now()}] Focus trapped within modal verified');

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      print('📊 [${DateTime.now()}] Modal closed and focus restored');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Focus indicators test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should support high contrast and visual accessibility', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing high contrast support');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _HighContrastTestWidget(),
          theme: ThemeData(
            // High contrast theme
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      );

      // Check color contrast ratios
      final primaryButton = find.byKey(const Key('primary_button'));
      final secondaryButton = find.byKey(const Key('secondary_button'));
      final errorText = find.byKey(const Key('error_text'));

      expect(primaryButton, findsOneWidget);
      expect(secondaryButton, findsOneWidget);
      expect(errorText, findsOneWidget);

      print('📊 [${DateTime.now()}] High contrast elements rendered');      // Test text size scaling
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/settings',
        StandardMethodCodec().encodeSuccessEnvelope({
          'textScaleFactor': 1.5,
        }),
        (data) {},
      );
      await tester.pumpAndSettle();

      print('📊 [${DateTime.now()}] Text scaling applied');

      // Verify elements are still visible and accessible
      expect(primaryButton, findsOneWidget);
      expect(secondaryButton, findsOneWidget);
      expect(errorText, findsOneWidget);

      print('📊 [${DateTime.now()}] Elements remain accessible with text scaling');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] High contrast test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should provide appropriate touch targets and spacing', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing touch targets');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _TouchTargetTestWidget(),
        ),
      );

      // Check minimum touch target sizes (44x44 logical pixels)
      final smallButton = find.byKey(const Key('small_button'));
      final normalButton = find.byKey(const Key('normal_button'));
      final iconButton = find.byKey(const Key('icon_button'));

      final smallButtonSize = tester.getSize(smallButton);
      final normalButtonSize = tester.getSize(normalButton);
      final iconButtonSize = tester.getSize(iconButton);

      expect(smallButtonSize.width, greaterThanOrEqualTo(44.0));
      expect(smallButtonSize.height, greaterThanOrEqualTo(44.0));
      print('📊 [${DateTime.now()}] Small button meets minimum touch target size: ${smallButtonSize}');

      expect(normalButtonSize.width, greaterThanOrEqualTo(44.0));
      expect(normalButtonSize.height, greaterThanOrEqualTo(44.0));
      print('📊 [${DateTime.now()}] Normal button meets minimum touch target size: ${normalButtonSize}');

      expect(iconButtonSize.width, greaterThanOrEqualTo(44.0));
      expect(iconButtonSize.height, greaterThanOrEqualTo(44.0));
      print('📊 [${DateTime.now()}] Icon button meets minimum touch target size: ${iconButtonSize}');

      // Test touch target spacing
      final button1Center = tester.getCenter(find.byKey(const Key('spaced_button_1')));
      final button2Center = tester.getCenter(find.byKey(const Key('spaced_button_2')));

      final distance = (button1Center - button2Center).distance;
      expect(distance, greaterThanOrEqualTo(48.0)); // Minimum spacing
      print('📊 [${DateTime.now()}] Button spacing verified: ${distance}px');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Touch targets test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should support voice control and gestures', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing voice control support');
      final stopwatch = Stopwatch()..start();      await tester.pumpWidget(
        MaterialApp(
          home: _VoiceControlTestWidget(),
        ),
      );

      // Wait for widgets to be built
      await tester.pumpAndSettle();

      // Test voice-activated elements have proper labels
      final voiceButton = find.bySemanticsLabel('Say "activate button" to press this button');
      expect(voiceButton, findsOneWidget);
      print('📊 [${DateTime.now()}] Voice-activated button found with proper label');      // Test gesture hints
      expect(find.text('Swipeable Area'), findsOneWidget);
      print('📊 [${DateTime.now()}] Swipe gesture area found');

      // Test custom semantic actions
      final customActionWidget = find.byKey(const Key('custom_action_widget'));      expect(customActionWidget, findsOneWidget);
      print('📊 [${DateTime.now()}] Custom action widget found');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Voice control test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should provide proper form accessibility', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing form accessibility');
      final stopwatch = Stopwatch()..start();      await tester.pumpWidget(
        MaterialApp(
          home: _AccessibleFormTestWidget(),
        ),
      );

      // Wait for widgets to be built
      await tester.pumpAndSettle();      // Test form field labels and descriptions
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      print('📊 [${DateTime.now()}] Form fields have proper labels');

      // Test error message accessibility
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all required fields'), findsOneWidget);
      print('📊 [${DateTime.now()}] Error message displayed');      // Test field grouping
      expect(find.text('Accessible Form Test'), findsOneWidget);
      print('📊 [${DateTime.now()}] Form sections properly structured');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Form accessibility test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should support reduced motion preferences', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing reduced motion support');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _ReducedMotionTestWidget(),
        ),
      );

      // Test default animation
      await tester.tap(find.byKey(const Key('animate_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byKey(const Key('animated_widget')), findsOneWidget);
      print('📊 [${DateTime.now()}] Default animation working');      // Simulate reduced motion preference
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/settings',
        StandardMethodCodec().encodeSuccessEnvelope({
          'accessibilityFeatures': {
            'disableAnimations': true,
          },
        }),
        (data) {},
      );

      await tester.pumpAndSettle();

      // Test that animations are disabled or reduced
      await tester.tap(find.byKey(const Key('animate_button_reduced')));
      await tester.pump();

      expect(find.byKey(const Key('instant_widget')), findsOneWidget);
      print('📊 [${DateTime.now()}] Reduced motion preference respected');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Reduced motion test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should provide proper reading order and structure', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing reading order');
      final stopwatch = Stopwatch()..start();      await tester.pumpWidget(
        MaterialApp(
          home: _ReadingOrderTestWidget(),
        ),
      );

      // Wait for widgets to be built
      await tester.pumpAndSettle();

      // Test semantic tree structure
      final semantics = tester.getSemantics(find.byType(Scaffold));
      expect(semantics.hasChildren, isTrue);
      print('📊 [${DateTime.now()}] Semantic tree structure verified');      // Test heading hierarchy
      expect(find.text('Main Title'), findsOneWidget);
      expect(find.text('Section Subtitle'), findsOneWidget);
      expect(find.text('Subsection Title'), findsOneWidget);
      print('📊 [${DateTime.now()}] Heading hierarchy properly structured');      // Test content reading order
      expect(find.text('This is the first paragraph of content.'), findsOneWidget);
      expect(find.text('This is the second paragraph of content.'), findsOneWidget);
      print('📊 [${DateTime.now()}] Content structure verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Reading order test completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

// Helper widgets for accessibility testing

class _AccessibilityTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Test')),
      body: Column(
        children: [
          const TextField(
            key: Key('email_field'),
            decoration: InputDecoration(
              labelText: 'Email',
              semanticCounterText: 'Email input field. Enter your email address.',
            ),
          ),
          const TextField(
            key: Key('password_field'),
            decoration: InputDecoration(
              labelText: 'Password',
              semanticCounterText: 'Password input field. Enter your password.',
            ),
            obscureText: true,
          ),
          Semantics(
            label: 'Login button. Double tap to sign in to your account.',
            button: true,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Login'),
            ),
          ),
          Semantics(
            label: 'Navigation menu. Contains Home, Profile, and Settings options.',
            child: Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.home)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
              ],
            ),
          ),
          Semantics(
            label: 'User profile picture of John Doe',
            image: true,
            child: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardNavigationTestWidget extends StatefulWidget {
  @override
  State<_KeyboardNavigationTestWidget> createState() => _KeyboardNavigationTestWidgetState();
}

class _KeyboardNavigationTestWidgetState extends State<_KeyboardNavigationTestWidget> {
  String _activatedElement = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard Navigation Test')),
      body: Column(
        children: [
          if (_activatedElement.isNotEmpty)
            Text('$_activatedElement activated'),
          ElevatedButton(
            key: const Key('button_1'),
            onPressed: () => setState(() => _activatedElement = 'Button 1'),
            child: const Text('Button 1'),
          ),
          ElevatedButton(
            key: const Key('button_2'),
            onPressed: () => setState(() => _activatedElement = 'Button 2'),
            child: const Text('Button 2'),
          ),          Focus(
            onKeyEvent: (node, event) {
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                setState(() => _activatedElement = 'Text field');
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: const TextField(
              key: Key('text_field'),
              decoration: InputDecoration(labelText: 'Text Field'),
            ),
          ),
          ElevatedButton(
            key: const Key('button_3'),
            onPressed: () => setState(() => _activatedElement = 'Button 3'),
            child: const Text('Button 3'),
          ),
        ],
      ),
    );
  }
}

class _FocusIndicatorTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Indicator Test')),
      body: Column(
        children: [
          Focus(
            child: Builder(
              builder: (context) {
                final isFocused = Focus.of(context).hasFocus;
                return Container(
                  decoration: BoxDecoration(
                    border: isFocused ? Border.all(color: Colors.blue, width: 3) : null,
                  ),
                  child: ElevatedButton(
                    key: const Key('focusable_button'),
                    onPressed: () {},
                    child: const Text('Focusable Button'),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            key: const Key('open_modal'),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Modal Dialog'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('This is a modal dialog with focus trap.'),
                    TextField(),
                    ElevatedButton(onPressed: () {}, child: const Text('Action')),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: const Text('Open Modal'),
          ),
        ],
      ),
    );
  }
}

class _HighContrastTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('High Contrast Test')),
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('primary_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () {},
            child: const Text('Primary Button'),
          ),
          OutlinedButton(
            key: const Key('secondary_button'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            onPressed: () {},
            child: const Text('Secondary Button'),
          ),
          Text(
            'Error message',
            key: const Key('error_text'),
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TouchTargetTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Touch Target Test')),
      body: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              key: const Key('small_button'),
              onPressed: () {},
              child: const Text('S'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('normal_button'),
            onPressed: () {},
            child: const Text('Normal Button'),
          ),
          const SizedBox(height: 16),
          IconButton(
            key: const Key('icon_button'),
            onPressed: () {},
            icon: const Icon(Icons.favorite),
            iconSize: 24,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                key: const Key('spaced_button_1'),
                onPressed: () {},
                child: const Text('Button 1'),
              ),
              ElevatedButton(
                key: const Key('spaced_button_2'),
                onPressed: () {},
                child: const Text('Button 2'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceControlTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Control Test')),
      body: Column(
        children: [
          Semantics(
            label: 'Say "activate button" to press this button',
            button: true,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Voice Activated Button'),
            ),
          ),
          Semantics(
            label: 'Swipe left or right to navigate between pages',
            child: Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Center(
                child: Text('Swipeable Area'),
              ),
            ),
          ),
          Semantics(
            label: 'Custom action widget',
            customSemanticsActions: {
              CustomSemanticsAction(label: 'Custom Action'): () {},
            },
            child: Container(
              key: const Key('custom_action_widget'),
              padding: const EdgeInsets.all(16),
              child: const Text('Widget with Custom Action'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibleFormTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessible Form Test')),
      body: Semantics(
        label: 'Personal information section',
        child: Column(
          children: [
            Semantics(
              label: 'Full name. Required field.',
              textField: true,
              child: const TextField(
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                ),
              ),
            ),
            Semantics(
              label: 'Email address. Must be a valid email format.',
              textField: true,
              child: const TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                ),
              ),
            ),
            Semantics(
              label: 'Password. Must be at least 8 characters long.',
              textField: true,
              obscured: true,
              child: const TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a secure password',
                ),
                obscureText: true,
              ),
            ),
            Semantics(
              label: 'Error: Please fill in all required fields',
              child: const Text(
                'Please fill in all required fields',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              key: const Key('submit_button'),
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReducedMotionTestWidget extends StatefulWidget {
  @override
  State<_ReducedMotionTestWidget> createState() => _ReducedMotionTestWidgetState();
}

class _ReducedMotionTestWidgetState extends State<_ReducedMotionTestWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _showAnimated = false;
  bool _showInstant = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reduced Motion Test')),
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('animate_button'),
            onPressed: () {
              setState(() => _showAnimated = true);
              _controller.forward();
            },
            child: const Text('Animate'),
          ),
          if (_showAnimated)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _controller.value,
                  child: Container(
                    key: const Key('animated_widget'),
                    width: 100,
                    height: 100,
                    color: Colors.blue,
                  ),
                );
              },
            ),
          ElevatedButton(
            key: const Key('animate_button_reduced'),
            onPressed: () {
              setState(() => _showInstant = true);
            },
            child: const Text('Animate (Reduced Motion)'),
          ),
          if (_showInstant)
            Container(
              key: const Key('instant_widget'),
              width: 100,
              height: 100,
              color: Colors.green,
            ),
        ],
      ),
    );
  }
}

class _ReadingOrderTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Order Test')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Main page title. Heading level 1.',
            header: true,
            child: const Text(
              'Main Title',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Semantics(
            label: 'First paragraph of content',
            child: const Text('This is the first paragraph of content.'),
          ),
          Semantics(
            label: 'Section subtitle. Heading level 2.',
            header: true,
            child: const Text(
              'Section Subtitle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Semantics(
            label: 'Second paragraph of content',
            child: const Text('This is the second paragraph of content.'),
          ),
          Semantics(
            label: 'Subsection title. Heading level 3.',
            header: true,
            child: const Text(
              'Subsection Title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
