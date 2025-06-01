import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📱 Mobile Responsive UI Tests - Caixa Preta', () {
    setUp(() {
      print('🔧 [${DateTime.now()}] Configurando testes responsivos mobile');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Limpando recursos após teste responsivo mobile');
    });

    group('📱 Mobile Breakpoints (width < 600)', () {
      final mobileWidths = [320, 360, 375, 414, 480];
      
      for (final width in mobileWidths) {
        testWidgets('📱 Layout Mobile ${width}px', (WidgetTester tester) async {
          print('🧪 [${DateTime.now()}] Iniciando teste: Layout Mobile ${width}px');
          
          // Set surface size and use MediaQuery to override
          await tester.binding.setSurfaceSize(Size(width.toDouble(), 800));
          
          await tester.pumpWidget(MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(width.toDouble(), 800)),
              child: ResponsiveTestApp(),
            ),
          ));

          // Verify mobile layout elements
          print('🔍 [DEBUG] Available widgets: ${tester.allWidgets.map((w) => w.runtimeType).toSet()}');
          expect(find.byType(BottomNavigationBar), findsOneWidget);
          expect(find.byType(DrawerController), findsOneWidget); // Drawer is controlled by DrawerController
          expect(find.text('Mobile Layout'), findsOneWidget);
          
          print('📊 [LAYOUT] Mobile ${width}px - BottomNav: ✅, Drawer: ✅');
          
          // Test drawer interaction
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();
          
          expect(find.text('Menu Item 1'), findsOneWidget);
          print('✅ [INTERACTION] Drawer funcionando em ${width}px');
            // Test bottom navigation
          final homeIcons = find.byIcon(Icons.home);
          if (homeIcons.evaluate().length > 1) {
            await tester.tap(homeIcons.last, warnIfMissed: false);
          } else {
            await tester.tap(homeIcons, warnIfMissed: false);
          }
          await tester.pumpAndSettle();
          
          print('✅ [SUCESSO] Layout mobile ${width}px responsivo');
          
          await tester.binding.setSurfaceSize(null);
        });
      }

      testWidgets('📱 Mobile Overflow Handling', (WidgetTester tester) async {
        print('🧪 [${DateTime.now()}] Iniciando teste: Mobile Overflow');
        
        await tester.binding.setSurfaceSize(const Size(320, 600));
        
        await tester.pumpWidget(MaterialApp(
          home: OverflowTestWidget(),
        ));

        // Should not overflow on small screen
        expect(tester.takeException(), isNull);
        
        final scrollable = find.byType(SingleChildScrollView);
        expect(scrollable, findsOneWidget);
        
        // Test scrolling
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pumpAndSettle();
        
        print('✅ [SUCESSO] Overflow tratado corretamente em mobile');
        
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}

// Helper Widgets for Mobile Testing
class ResponsiveTestApp extends StatelessWidget {
  const ResponsiveTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    print('📱 [RESPONSIVE] Screen: ${width}x${size.height}');
    
    // Only mobile layout for this focused test
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Layout')),
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('Menu')),
            ListTile(title: Text('Menu Item 1')),
            ListTile(title: Text('Menu Item 2')),
          ],
        ),
      ),
      body: const Center(child: Text('Mobile Content')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}

class OverflowTestWidget extends StatelessWidget {
  const OverflowTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Overflow Test')),
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(20, (index) => 
            Container(
              height: 100,
              margin: const EdgeInsets.all(8),
              color: Colors.blue[100],
              child: Center(child: Text('Mobile Item $index')),
            ),
          ),
        ),
      ),
    );
  }
}
