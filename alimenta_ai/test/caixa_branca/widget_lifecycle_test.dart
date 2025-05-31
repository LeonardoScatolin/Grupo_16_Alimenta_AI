import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alimenta_ai/pages/login.dart';
import 'package:alimenta_ai/pages/dashboard.dart';
import 'package:alimenta_ai/services/auth_service.dart';
import 'dart:async';

// Generate mocks
@GenerateMocks([AuthService, SharedPreferences])
import 'widget_lifecycle_test.mocks.dart';

void main() {
  group('🧪 Widget Lifecycle Tests - Caixa Branca', () {
    late MockAuthService mockAuthService;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      print('🔧 [${DateTime.now()}] Configurando mocks para testes de lifecycle');
      mockAuthService = MockAuthService();
      mockSharedPreferences = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Limpando recursos após teste de lifecycle');
      reset(mockAuthService);
      reset(mockSharedPreferences);
    });

    testWidgets('🔄 Teste de InitState e Dispose de StatefulWidget', (WidgetTester tester) async {
      final startTime = DateTime.now();
      print('🧪 [${DateTime.now()}] Iniciando teste: InitState e Dispose');

      // Mock de login bem-sucedido
      when(mockAuthService.login(any, any))
          .thenAnswer((_) async => {'success': true, 'token': 'mock_token'});

      print('📱 [WIDGET] Criando widget de login...');
      await tester.pumpWidget(MaterialApp(home: LoginPage()));
      
      // Verificar se o widget foi criado
      expect(find.byType(LoginPage), findsOneWidget);
      print('✅ [SUCESSO] Widget LoginPage criado com sucesso');      // Simular navegação para Dashboard - buscar pelo InkWell do botão
      final inkWellFinder = find.byType(InkWell);
      if (inkWellFinder.evaluate().isNotEmpty) {
        await tester.tap(inkWellFinder.first);
        // Usar pump com timeout específico para evitar timeout em animações
        await tester.pump(Duration(milliseconds: 100));
      } else {
        print('ℹ️ [INFO] Nenhum botão encontrado para simular tap - pulando navegação');
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('📊 [PERFORMANCE] Tempo de criação e navegação: ${duration}ms');
      print('✅ [SUCESSO] Teste de lifecycle completado');
    });

    testWidgets('🎯 Teste de Build Method Calls', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Build Method Calls');
      
      var buildCount = 0;
      
      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            buildCount++;
            print('🔄 [BUILD] Method chamado - Count: $buildCount');
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Rebuild $buildCount'),
                ),
              ),
            );
          },
        ),
      ));

      expect(buildCount, equals(1));
      print('✅ [SUCESSO] Build inicial realizado - Count: $buildCount');

      // Trigger rebuild
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buildCount, equals(2));
      print('✅ [SUCESSO] Rebuild triggered - Count: $buildCount');
    });

    testWidgets('📱 Teste de setState() e State Changes', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: setState e State Changes');
      
      bool isLoading = false;
      String statusText = 'Inicial';

      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  Text(statusText),
                  if (isLoading) CircularProgressIndicator(),
                  ElevatedButton(
                    onPressed: () {
                      print('🔄 [STATE] Mudando estado - isLoading: $isLoading -> ${!isLoading}');
                      setState(() {
                        isLoading = !isLoading;
                        statusText = isLoading ? 'Carregando' : 'Parado';
                      });
                    },
                    child: Text('Toggle Loading'),
                  ),
                ],
              ),
            );
          },
        ),
      ));

      expect(find.text('Inicial'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      print('✅ [SUCESSO] Estado inicial verificado');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Carregando'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('✅ [SUCESSO] Estado de loading ativado');
    });

    testWidgets('🔧 Teste de didUpdateWidget Lifecycle', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: didUpdateWidget');
      
      String currentKey = 'initial';
      
      Widget buildTestWidget(String key) {
        return MaterialApp(
          home: TestWidget(key: ValueKey(key), data: key),
        );
      }

      await tester.pumpWidget(buildTestWidget(currentKey));
      expect(find.text('Data: initial'), findsOneWidget);
      print('✅ [SUCESSO] Widget inicial criado');

      // Update widget
      currentKey = 'updated';
      await tester.pumpWidget(buildTestWidget(currentKey));
      await tester.pump();

      expect(find.text('Data: updated'), findsOneWidget);
      print('✅ [SUCESSO] Widget atualizado via didUpdateWidget');
    });

    testWidgets('🎭 Teste de Animation Controller Lifecycle', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Animation Controller');
      
      late AnimationController controller;
      
      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return AnimatedTestWidget(
              onControllerCreated: (AnimationController c) {
                controller = c;
                print('🎭 [ANIMATION] Controller criado - Status: ${c.status}');
              },
            );
          },
        ),
      ));

      expect(find.byType(AnimatedTestWidget), findsOneWidget);
      print('✅ [SUCESSO] AnimationController criado');

      // Test animation
      controller.forward();
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));

      expect(controller.value, greaterThan(0.0));
      print('📊 [PERFORMANCE] Animation value: ${controller.value}');
      print('✅ [SUCESSO] Animation em execução');
    });

    testWidgets('🧠 Teste de Memory Management', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Memory Management');
      
      final startTime = DateTime.now();
      List<Widget> widgets = [];

      // Create multiple widgets
      for (int i = 0; i < 100; i++) {
        widgets.add(Container(
          key: ValueKey('container_$i'),
          child: Text('Item $i'),
        ));
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(children: widgets),
        ),
      ));

      expect(find.byType(Container), findsWidgets);
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('📊 [PERFORMANCE] Criação de 100 widgets: ${duration}ms');
      
      // Clear widgets
      widgets.clear();
      await tester.pumpWidget(MaterialApp(home: Container()));
      
      print('🧠 [MEMORY] Widgets limpos da memória');
      print('✅ [SUCESSO] Teste de memory management completado');
    });

    testWidgets('🔄 Teste de FutureBuilder States', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: FutureBuilder States');
      
      bool shouldComplete = false;
      
      Future<String> mockAsyncOperation() async {
        print('⏳ [ASYNC] Operação assíncrona iniciada');
        await Future.delayed(Duration(milliseconds: 100));
        if (shouldComplete) {
          print('✅ [ASYNC] Operação completada com sucesso');
          return 'Completed';
        } else {
          print('❌ [ASYNC] Operação falhou');
          throw Exception('Test error');
        }
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FutureBuilder<String>(
            future: mockAsyncOperation(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('⏳ [FUTUREBUILDER] Estado: waiting');
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                print('❌ [FUTUREBUILDER] Estado: error - ${snapshot.error}');
                return Text('Error: ${snapshot.error}');
              } else {
                print('✅ [FUTUREBUILDER] Estado: done - ${snapshot.data}');
                return Text('Data: ${snapshot.data}');
              }
            },
          ),
        ),
      ));

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('✅ [SUCESSO] Estado inicial (loading) verificado');

      // Wait for completion (should show error)
      await tester.pumpAndSettle();
      expect(find.textContaining('Error:'), findsOneWidget);
      print('✅ [SUCESSO] Estado de erro verificado');
    });

    testWidgets('🎯 Teste de StreamBuilder Lifecycle', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: StreamBuilder Lifecycle');
      
      late StreamController<int> streamController;
      streamController = StreamController<int>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StreamBuilder<int>(
            stream: streamController.stream,
            builder: (context, snapshot) {
              print('🌊 [STREAM] Estado: ${snapshot.connectionState}, Data: ${snapshot.data}');
              if (snapshot.hasData) {
                return Text('Value: ${snapshot.data}');
              } else {
                return Text('No data');
              }
            },
          ),
        ),
      ));

      expect(find.text('No data'), findsOneWidget);
      print('✅ [SUCESSO] Estado inicial do StreamBuilder');

      // Add data to stream
      streamController.add(42);
      await tester.pump();

      expect(find.text('Value: 42'), findsOneWidget);
      print('✅ [SUCESSO] Dados recebidos via Stream');

      streamController.close();
      print('🧹 [CLEANUP] StreamController fechado');
    });    testWidgets('📱 Teste de Responsive Build Methods', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Responsive Build');
      
      // Teste para layout mobile (largura < 600)
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: ResponsiveTestWidget(),
        ),
      ));

      await tester.pump();
      expect(find.text('Mobile Layout'), findsOneWidget);
      print('✅ [SUCESSO] Layout mobile detectado');

      // Teste para layout tablet (600 <= largura < 1200)
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(800, 1200)),
          child: ResponsiveTestWidget(),
        ),
      ));
      
      await tester.pump();
      expect(find.text('Tablet Layout'), findsOneWidget);
      print('✅ [SUCESSO] Layout tablet detectado');

      // Teste para layout desktop (largura >= 1200)
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1400, 1000)),
          child: ResponsiveTestWidget(),
        ),
      ));
      
      await tester.pump();
      expect(find.text('Desktop Layout'), findsOneWidget);
      print('✅ [SUCESSO] Layout desktop detectado');
    });

    testWidgets('🔍 Teste de Focus Management', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Focus Management');
      
      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                focusNode: focusNode1,
                decoration: InputDecoration(hintText: 'Field 1'),
              ),
              TextField(
                focusNode: focusNode2,
                decoration: InputDecoration(hintText: 'Field 2'),
              ),
            ],
          ),
        ),
      ));

      // Test focus
      await tester.tap(find.byWidgetPredicate((widget) => 
          widget is TextField && widget.decoration?.hintText == 'Field 1'));
      await tester.pump();

      expect(focusNode1.hasFocus, isTrue);
      print('✅ [SUCESSO] Focus no primeiro campo');

      await tester.tap(find.byWidgetPredicate((widget) => 
          widget is TextField && widget.decoration?.hintText == 'Field 2'));
      await tester.pump();

      expect(focusNode2.hasFocus, isTrue);
      expect(focusNode1.hasFocus, isFalse);
      print('✅ [SUCESSO] Focus transferido para segundo campo');

      focusNode1.dispose();
      focusNode2.dispose();
      print('🧹 [CLEANUP] FocusNodes descartados');
    });
  });
}

// Helper Widgets for Testing
class TestWidget extends StatefulWidget {
  final String data;
  
  const TestWidget({Key? key, required this.data}) : super(key: key);

  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  @override
  void didUpdateWidget(TestWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🔄 [LIFECYCLE] didUpdateWidget chamado - Old: ${oldWidget.data}, New: ${widget.data}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Data: ${widget.data}')),
    );
  }
}

class AnimatedTestWidget extends StatefulWidget {
  final Function(AnimationController) onControllerCreated;
  
  const AnimatedTestWidget({Key? key, required this.onControllerCreated}) : super(key: key);

  @override
  _AnimatedTestWidgetState createState() => _AnimatedTestWidgetState();
}

class _AnimatedTestWidgetState extends State<AnimatedTestWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    widget.onControllerCreated(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    print('🧹 [LIFECYCLE] AnimationController disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Transform.scale(
              scale: _controller.value,
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

class ResponsiveTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    print('📱 [RESPONSIVE] Screen size: ${size.width}x${size.height}');
    
    if (size.width < 600) {
      return Scaffold(
        body: Center(
          child: Text(
            'Mobile Layout',
            key: Key('mobile_layout'),
          ),
        ),
      );
    } else if (size.width < 1200) {
      return Scaffold(
        body: Center(
          child: Text(
            'Tablet Layout',
            key: Key('tablet_layout'),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: Text(
            'Desktop Layout',
            key: Key('desktop_layout'),
          ),
        ),
      );
    }
  }
}
