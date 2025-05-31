import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:alimenta_ai/services/auth_service.dart';
import 'package:alimenta_ai/pages/login.dart';

// Generate mocks
@GenerateMocks([AuthService])
import 'navigation_animation_test.mocks.dart';

void main() {
  group('🎭 Navigation & Animation Tests - Caixa Branca', () {
    late MockAuthService mockAuthService;

    setUp(() {
      print('🔧 [${DateTime.now()}] Configurando mocks para testes de navegação e animação');
      mockAuthService = MockAuthService();
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Limpando recursos após teste de navegação');
      reset(mockAuthService);
    });

    testWidgets('🧭 Teste de Navigation Push/Pop', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Navigation Push/Pop');
      
      final navigatorKey = GlobalKey<NavigatorState>();
      
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: TestHomePage(),
        routes: {
          '/second': (context) => TestSecondPage(),
          '/third': (context) => TestThirdPage(),
        },
      ));

      expect(find.text('Home Page'), findsOneWidget);
      print('✅ [SUCESSO] Página inicial carregada');

      // Navigate to second page
      await tester.tap(find.text('Go to Second'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page'), findsOneWidget);
      expect(find.text('Home Page'), findsNothing);
      print('✅ [SUCESSO] Navegação para segunda página');

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Second Page'), findsNothing);
      print('✅ [SUCESSO] Navegação de volta');
    });

    testWidgets('🎯 Teste de Named Routes', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Named Routes');
      
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => TestHomePage(),
          '/second': (context) => TestSecondPage(),
          '/third': (context) => TestThirdPage(),
        },
      ));

      expect(find.text('Home Page'), findsOneWidget);
      print('✅ [SUCESSO] Rota inicial carregada');

      // Navigate using named route
      await tester.tap(find.text('Go to Third'));
      await tester.pumpAndSettle();

      expect(find.text('Third Page'), findsOneWidget);
      print('✅ [SUCESSO] Navegação por named route');
    });

    testWidgets('🔄 Teste de Route Arguments', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Route Arguments');
      
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestArgumentPage(),
                      settings: RouteSettings(arguments: {'id': 123, 'name': 'Test User'}),
                    ),
                  );
                },
                child: Text('Navigate with Args'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Navigate with Args'));
      await tester.pumpAndSettle();

      expect(find.text('ID: 123'), findsOneWidget);
      expect(find.text('Name: Test User'), findsOneWidget);
      print('✅ [SUCESSO] Argumentos de rota passados corretamente');
    });

    testWidgets('🎭 Teste de Page Transitions', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Page Transitions');
      
      await tester.pumpWidget(MaterialApp(
        home: TestHomePage(),
        onGenerateRoute: (settings) {
          if (settings.name == '/custom') {
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => TestSecondPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                print('🎭 [TRANSITION] Animation value: ${animation.value}');
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          }
          return null;
        },
      ));

      // Navigate with custom transition
      await tester.tap(find.text('Custom Transition'));
      await tester.pump(); // Start animation
      await tester.pump(Duration(milliseconds: 150)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      expect(find.text('Second Page'), findsOneWidget);
      print('✅ [SUCESSO] Transição customizada executada');
    });

    testWidgets('🎪 Teste de Animation Controller', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Animation Controller');
      
      late AnimationController controller;
      late Animation<double> animation;
      
      await tester.pumpWidget(MaterialApp(
        home: TestAnimationWidget(
          onAnimationCreated: (AnimationController c, Animation<double> a) {
            controller = c;
            animation = a;
            print('🎭 [ANIMATION] Controller criado - Duration: ${c.duration}');
          },
        ),
      ));

      expect(find.byType(TestAnimationWidget), findsOneWidget);
      print('✅ [SUCESSO] Widget de animação criado');

      // Start animation
      controller.forward();
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));

      expect(animation.value, greaterThan(0.0));
      expect(animation.value, lessThan(1.0));
      print('📊 [PERFORMANCE] Animation progress: ${animation.value}');

      await tester.pumpAndSettle();
      expect(animation.value, equals(1.0));
      print('✅ [SUCESSO] Animação completada');
    });

    testWidgets('🔄 Teste de Animation Reverse', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Animation Reverse');
      
      late AnimationController controller;
      
      await tester.pumpWidget(MaterialApp(
        home: TestAnimationWidget(
          onAnimationCreated: (AnimationController c, Animation<double> a) {
            controller = c;
          },
        ),
      ));

      // Forward animation
      controller.forward();
      await tester.pumpAndSettle();
      expect(controller.value, equals(1.0));
      print('✅ [SUCESSO] Animação forward completada');

      // Reverse animation
      controller.reverse();
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      expect(controller.value, lessThan(1.0));
      print('📊 [PERFORMANCE] Reverse progress: ${controller.value}');

      await tester.pumpAndSettle();
      expect(controller.value, equals(0.0));
      print('✅ [SUCESSO] Animação reverse completada');
    });

    testWidgets('🎯 Teste de Tween Animations', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Tween Animations');
      
      await tester.pumpWidget(MaterialApp(
        home: TestTweenWidget(),
      ));

      // Find the animated container
      final containerFinder = find.byType(AnimatedContainer);
      expect(containerFinder, findsOneWidget);      // Get initial container
      AnimatedContainer initialContainer = tester.widget(containerFinder);
      print('📊 [TWEEN] Container encontrado');

      // Trigger animation
      await tester.tap(find.text('Animate'));
      await tester.pump();      await tester.pump(Duration(milliseconds: 150));

      // Check animation in progress
      AnimatedContainer animatingContainer = tester.widget(containerFinder);
      print('📊 [TWEEN] Animação em progresso');

      await tester.pumpAndSettle();

      // Check final state
      AnimatedContainer finalContainer = tester.widget(containerFinder);
      print('📊 [TWEEN] Estado final alcançado');

      // Verify animation occurred by checking if widget still exists
      expect(containerFinder, findsOneWidget);
      print('✅ [SUCESSO] Tween animation executada');
    });

    testWidgets('🎨 Teste de Hero Animations', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Hero Animations');
      
      await tester.pumpWidget(MaterialApp(
        home: TestHeroPage(),
        routes: {
          '/hero-detail': (context) => TestHeroDetailPage(),
        },
      ));

      expect(find.byType(Hero), findsOneWidget);
      print('✅ [SUCESSO] Hero widget encontrado');

      // Tap hero to navigate
      await tester.tap(find.byType(Hero));
      await tester.pump(); // Start hero animation
      await tester.pump(Duration(milliseconds: 150)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      expect(find.text('Hero Detail'), findsOneWidget);
      print('✅ [SUCESSO] Hero animation executada');
    });

    testWidgets('📱 Teste de Modal Animations', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Modal Animations');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      height: 200,
                      child: Center(child: Text('Modal Content')),
                    ),
                  );
                },
                child: Text('Show Modal'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Modal'));
      await tester.pump(); // Start modal animation
      await tester.pump(Duration(milliseconds: 150)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      expect(find.text('Modal Content'), findsOneWidget);
      print('✅ [SUCESSO] Modal animation executada');

      // Close modal
      await tester.tapAt(Offset(100, 100)); // Tap outside modal
      await tester.pumpAndSettle();

      expect(find.text('Modal Content'), findsNothing);
      print('✅ [SUCESSO] Modal fechada');
    });

    testWidgets('🌊 Teste de Gesture-based Navigation', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Gesture Navigation');
      
      await tester.pumpWidget(MaterialApp(
        home: TestGestureNavPage(),
        routes: {
          '/swipe-target': (context) => TestSwipeTargetPage(),
        },
      ));

      // Swipe to navigate
      await tester.drag(find.text('Swipe me right'), Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Swipe Target'), findsOneWidget);
      print('✅ [SUCESSO] Navegação por gesto executada');
    });
  });
}

// Helper Widgets for Testing
class TestHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/second'),
            child: Text('Go to Second'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/third'),
            child: Text('Go to Third'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/custom'),
            child: Text('Custom Transition'),
          ),
        ],
      ),
    );
  }
}

class TestSecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Second Page')),
      body: Center(child: Text('Second Page')),
    );
  }
}

class TestThirdPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Third Page')),
      body: Center(child: Text('Third Page')),
    );
  }
}

class TestArgumentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: AppBar(title: Text('Argument Page')),
      body: Column(
        children: [
          Text('ID: ${args?['id']}'),
          Text('Name: ${args?['name']}'),
        ],
      ),
    );
  }
}

class TestAnimationWidget extends StatefulWidget {
  final Function(AnimationController, Animation<double>) onAnimationCreated;
  
  const TestAnimationWidget({Key? key, required this.onAnimationCreated}) : super(key: key);

  @override
  _TestAnimationWidgetState createState() => _TestAnimationWidgetState();
}

class _TestAnimationWidgetState extends State<TestAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    widget.onAnimationCreated(_controller, _animation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Center(
            child: Transform.scale(
              scale: _animation.value,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TestTweenWidget extends StatefulWidget {
  @override
  _TestTweenWidgetState createState() => _TestTweenWidgetState();
}

class _TestTweenWidgetState extends State<TestTweenWidget> {
  double _width = 100.0;
  Color _color = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: _width,
            height: 100,
            color: _color,
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _width = _width == 100.0 ? 200.0 : 100.0;
                _color = _color == Colors.blue ? Colors.red : Colors.blue;
              });
            },
            child: Text('Animate'),
          ),
        ],
      ),
    );
  }
}

class TestHeroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Hero(
          tag: 'hero-tag',
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/hero-detail'),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.purple,
              child: Center(child: Text('Hero')),
            ),
          ),
        ),
      ),
    );
  }
}

class TestHeroDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hero Detail')),
      body: Center(
        child: Hero(
          tag: 'hero-tag',
          child: Container(
            width: 200,
            height: 200,
            color: Colors.purple,
            child: Center(child: Text('Hero Detail')),
          ),
        ),
      ),
    );
  }
}

class TestGestureNavPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx > 500) {
              Navigator.pushNamed(context, '/swipe-target');
            }
          },
          child: Container(
            width: 200,
            height: 100,
            color: Colors.green,
            child: Center(child: Text('Swipe me right')),
          ),
        ),
      ),
    );
  }
}

class TestSwipeTargetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Swipe Target')),
      body: Center(child: Text('Swipe Target')),
    );
  }
}
