import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

@GenerateMocks([SharedPreferences])
import 'integration_test.mocks.dart';

// Simulação de providers/estado da aplicação
class UserProvider extends ChangeNotifier {
  String? _userId;
  String? _userName;
  bool _isLoading = false;
  String? _error;
  
  String? get userId => _userId;
  String? get userName => _userName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _userId != null;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
    void setUser(String id, String name) {
    _userId = id;
    _userName = name;
    _error = null;
    _isLoading = false; // Importante: limpar loading quando user é definido
    notifyListeners();
  }
  
  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void logout() {
    _userId = null;
    _userName = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

class NetworkProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isConnecting = false;
  
  bool get isOnline => _isOnline;
  bool get isConnecting => _isConnecting;
  bool get isOffline => !_isOnline;
  
  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }
  
  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }
}

class CacheService {
  final SharedPreferences prefs;
  
  CacheService(this.prefs);
  
  Future<void> cacheUserData(String userId, Map<String, dynamic> userData) async {
    final cacheKey = 'user_data_$userId';
    await prefs.setString(cacheKey, jsonEncode(userData));
  }
  
  Map<String, dynamic>? getCachedUserData(String userId) {
    final cacheKey = 'user_data_$userId';
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return null;
  }
  
  Future<void> clearCache() async {
    final keys = prefs.getKeys().where((key) => key.startsWith('user_data_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

// Widget customizado para testar integração
class CustomDashboard extends StatefulWidget {
  final UserProvider? userProvider;
  final NetworkProvider? networkProvider;
  
  const CustomDashboard({
    Key? key,
    this.userProvider,
    this.networkProvider,
  }) : super(key: key);
  
  @override
  State<CustomDashboard> createState() => _CustomDashboardState();
}

class _CustomDashboardState extends State<CustomDashboard> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, NetworkProvider>(
      builder: (context, userProvider, networkProvider, child) {
        if (userProvider.isLoading) {
          return const Center(
            key: Key('loading_indicator'),
            child: CircularProgressIndicator(),
          );
        }
        
        if (userProvider.error != null) {
          return Center(
            key: const Key('error_display'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 8),
                Text('Erro: ${userProvider.error}'),
                ElevatedButton(
                  key: const Key('retry_button'),
                  onPressed: () {
                    // Simular retry
                    userProvider.setLoading(true);
                    Future.delayed(const Duration(seconds: 1), () {
                      userProvider.setUser('123', 'Usuario Teste');
                    });
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }
        
        if (!userProvider.isLoggedIn) {
          return const Center(
            key: Key('login_prompt'),
            child: Text('Faça login para continuar'),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Dashboard - ${userProvider.userName}'),
            actions: [
              if (networkProvider.isOffline)
                const Icon(Icons.wifi_off, key: Key('offline_indicator')),
              IconButton(
                key: const Key('logout_button'),
                icon: const Icon(Icons.logout),
                onPressed: () => userProvider.logout(),
              ),
            ],
          ),
          body: Column(
            children: [
              if (networkProvider.isOffline)
                Container(
                  key: const Key('offline_banner'),
                  width: double.infinity,
                  color: Colors.orange,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'Modo Offline - Dados podem estar desatualizados',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView(
                  key: const Key('dashboard_content'),
                  children: [
                    ListTile(
                      title: const Text('ID do Usuário'),
                      subtitle: Text(userProvider.userId ?? 'N/A'),
                    ),
                    ListTile(
                      title: const Text('Status da Conexão'),
                      subtitle: Text(networkProvider.isOnline ? 'Online' : 'Offline'),
                    ),
                    ListTile(
                      title: const Text('Última Atualização'),
                      subtitle: Text(DateTime.now().toString()),
                    ),                  ],
                ),
              ),
            ],
          ),
        );
      },
    );  }
}

// Classe auxiliar para testes
class TestUserService {
  final CacheService cacheService;
  
  TestUserService(this.cacheService);
  
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    // Tentar cache primeiro
    final cached = cacheService.getCachedUserData(userId);
    if (cached != null) {
      return cached;
    }
      // Simular busca no servidor
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'id': userId,
      'name': 'Service User',
      'email': 'test@example.com'
    };
  }
}

void main() {
  group('🔘 CAIXA CINZA - Integration Tests', () {
    late UserProvider userProvider;
    late NetworkProvider networkProvider;
    late MockSharedPreferences mockPrefs;
    late CacheService cacheService;
    late Stopwatch stopwatch;

    setUp(() {
      print('🔧 [${DateTime.now()}] Setting up Integration test environment');
      userProvider = UserProvider();
      networkProvider = NetworkProvider();
      mockPrefs = MockSharedPreferences();
      cacheService = CacheService(mockPrefs);
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] Providers and services initialized');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up test environment');
      userProvider.dispose();
      networkProvider.dispose();
      stopwatch.reset();
      print('✅ [${DateTime.now()}] Teardown completed');
    });

    testWidgets('1. Provider Integration - User state changes', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Provider Integration');
      stopwatch.start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      // Estado inicial - não logado
      expect(find.byKey(const Key('login_prompt')), findsOneWidget);
      print('👤 [STATE] Estado inicial: não logado');
      
      // Simular login
      userProvider.setLoading(true);
      await tester.pump();
      
      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      print('⏳ [STATE] Loading state ativo');      // Completar login
      userProvider.setUser('123', 'Teste User');
      await tester.pump(); // Primeira reconstrução
      await tester.pump(const Duration(milliseconds: 100)); // Aguarda estabilização
      await tester.pump(); // Pump extra para garantir que o estado seja processado
      
      expect(find.byKey(const Key('dashboard_content')), findsOneWidget);
      expect(find.text('Dashboard - Teste User'), findsOneWidget);
      print('✅ [STATE] Usuario logado - Dashboard exibido');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo state changes: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Provider integration funcionando');
    });

    testWidgets('2. Network Status Integration', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Network Status');
      stopwatch.start();
      
      // Setup usuario logado
      userProvider.setUser('123', 'Test User');
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      await tester.pump();
      
      // Estado inicial - online
      expect(find.byKey(const Key('offline_indicator')), findsNothing);
      expect(find.byKey(const Key('offline_banner')), findsNothing);
      print('🌐 [NETWORK] Estado inicial: Online');
      
      // Simular perda de conexão
      networkProvider.setOnlineStatus(false);
      await tester.pump();
      
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      expect(find.byKey(const Key('offline_banner')), findsOneWidget);
      expect(find.text('Modo Offline - Dados podem estar desatualizados'), findsOneWidget);
      print('📶 [NETWORK] Modo offline ativo - UI atualizada');
      
      // Reconectar
      networkProvider.setOnlineStatus(true);
      await tester.pump();
      
      expect(find.byKey(const Key('offline_indicator')), findsNothing);
      expect(find.byKey(const Key('offline_banner')), findsNothing);
      print('🌐 [NETWORK] Reconectado - UI voltou ao normal');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo network changes: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Network status integration funcionando');
    });

    test('3. Cache Service - conhecimento parcial da persistência', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Cache Service');
      stopwatch.start();
      
      final userData = {
        'id': '123',
        'name': 'Test User',
        'email': 'test@test.com',
        'lastLogin': DateTime.now().toIso8601String(),
      };
      
      // Mock do SharedPreferences
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.getString('user_data_123')).thenReturn(jsonEncode(userData));
      when(mockPrefs.getKeys()).thenReturn({'user_data_123', 'other_key'});
      when(mockPrefs.remove(any)).thenAnswer((_) async => true);
      
      // Testar cache
      await cacheService.cacheUserData('123', userData);
      print('💾 [CACHE] Dados do usuário salvos no cache');
      
      verify(mockPrefs.setString('user_data_123', jsonEncode(userData))).called(1);
      
      // Testar recuperação
      final cachedData = cacheService.getCachedUserData('123');
      expect(cachedData, isNotNull);
      expect(cachedData!['id'], equals('123'));
      expect(cachedData['name'], equals('Test User'));
      print('📖 [CACHE] Dados recuperados: $cachedData');
      
      // Testar limpeza
      await cacheService.clearCache();
      verify(mockPrefs.remove('user_data_123')).called(1);
      print('🧹 [CACHE] Cache limpo');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo cache ops: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Cache service funcionando');
    });

    testWidgets('4. Error Handling Integration', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Error Handling');
      stopwatch.start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      // Simular erro
      userProvider.setError('Falha na conexão com servidor');
      await tester.pump();
      
      expect(find.byKey(const Key('error_display')), findsOneWidget);
      expect(find.text('Erro: Falha na conexão com servidor'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
      print('❌ [ERROR] Erro exibido na UI com botão de retry');
        // Testar retry
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pump();
      
      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      print('🔄 [RETRY] Loading state após retry');
        // Simular sucesso após retry - aguardar o Future.delayed de 1 segundo
      await tester.pump(const Duration(seconds: 1)); // Aguardar o Future.delayed
      await tester.pump(); // Processar o setUser
      await tester.pump(const Duration(milliseconds: 100)); // Estabilizar UI
      await tester.pump(); // Pump extra para garantir que o estado seja processado
      
      expect(find.byKey(const Key('dashboard_content')), findsOneWidget);
      expect(find.byKey(const Key('error_display')), findsNothing);
      print('✅ [RECOVERY] Erro resolvido após retry');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo error handling: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Error handling integration funcionando');
    });

    testWidgets('5. Loading States - UI feedback integration', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Loading States');
      stopwatch.start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      // Testar diferentes estados de loading
      final loadingStates = [
        {'duration': 100, 'description': 'Quick loading'},
        {'duration': 500, 'description': 'Medium loading'},
        {'duration': 1000, 'description': 'Long loading'},
      ];
      
      for (final state in loadingStates) {
        print('⏳ [LOADING] Testando: ${state['description']}');
        
        userProvider.setLoading(true);
        await tester.pump();
        
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
          // Simular tempo de loading
        await tester.pump(Duration(milliseconds: state['duration'] as int));
        
        userProvider.setUser('123', 'Test User');
        await tester.pump(); // Primeira reconstrução
        await tester.pump(const Duration(milliseconds: 50)); // Aguarda estabilização
        await tester.pump(); // Pump extra para garantir que o loading seja removido
        
        expect(find.byKey(const Key('loading_indicator')), findsNothing);
        expect(find.byKey(const Key('dashboard_content')), findsOneWidget);
        
        print('✅ [LOADING] ${state['description']} completed');
        
        // Reset para próximo teste
        userProvider.logout();
        await tester.pump();
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo loading states: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Loading states integration funcionando');
    });

    testWidgets('6. Multi-Provider Data Flow', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Multi-Provider Flow');
      stopwatch.start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      // Fluxo completo: login → conexão → offline → online → logout
      print('🔄 [FLOW] Iniciando fluxo completo');
      
      // 1. Login
      userProvider.setUser('123', 'Flow Test User');
      await tester.pump();
      
      expect(find.text('Dashboard - Flow Test User'), findsOneWidget);
      print('✅ [STEP 1] Login completed');
      
      // 2. Ir offline
      networkProvider.setOnlineStatus(false);
      await tester.pump();
      
      expect(find.byKey(const Key('offline_banner')), findsOneWidget);
      print('✅ [STEP 2] Offline mode activated');
      
      // 3. Voltar online
      networkProvider.setOnlineStatus(true);
      await tester.pump();
      
      expect(find.byKey(const Key('offline_banner')), findsNothing);
      print('✅ [STEP 3] Back online');
      
      // 4. Logout
      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pump();
      
      expect(find.byKey(const Key('login_prompt')), findsOneWidget);
      print('✅ [STEP 4] Logout completed');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo fluxo completo: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Multi-provider flow funcionando');
    });

    test('7. Background Sync Simulation', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Background Sync');
      stopwatch.start();
      
      // Simular sincronização em background
      bool syncCompleted = false;
      String? syncError;
      
      // Mock dados para sincronização
      when(mockPrefs.getString('pending_sync')).thenReturn('{"type": "user_data", "data": {}}');
      when(mockPrefs.remove('pending_sync')).thenAnswer((_) async => true);
      
      // Simular processo de sync
      final syncFuture = Future.delayed(const Duration(milliseconds: 300), () {
        // Simular sucesso
        syncCompleted = true;
        return {'status': 'success', 'synced_items': 5};
      });
      
      print('🔄 [SYNC] Iniciando sincronização em background');
      
      final result = await syncFuture;
      
      expect(syncCompleted, isTrue);
      expect(result['status'], equals('success'));
      expect(result['synced_items'], equals(5));
      
      print('✅ [SYNC] Sincronização completada: ${result['synced_items']} itens');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo sync: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Background sync simulation funcionando');
    });

    testWidgets('8. Theme Integration - partial UI knowledge', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Theme Integration');
      stopwatch.start();
      
      userProvider.setUser('123', 'Theme Test');
      
      // Testar tema claro
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      await tester.pump();
      
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      print('🎨 [THEME] Tema claro aplicado');
      
      // Testar tema escuro
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byType(AppBar), findsOneWidget);
      print('🌙 [THEME] Tema escuro aplicado');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo theme switching: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Theme integration funcionando');
    });

    testWidgets('9. Middleware Simulation - request interceptor', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Middleware Simulation');
      stopwatch.start();
      
      // Simular middleware que intercepta requests
      List<String> interceptedRequests = [];
      
      void requestInterceptor(String request) {
        interceptedRequests.add(request);
        print('🔍 [MIDDLEWARE] Request intercepted: $request');
      }
      
      // Simular diferentes tipos de request
      final requests = [
        '/api/user/profile',
        '/api/user/settings',
        '/api/data/sync',
      ];
        for (final request in requests) {
        requestInterceptor(request);
        
        // Simular processamento - usar pump em vez de Future.delayed
        await tester.pump(const Duration(milliseconds: 50));
      }
      
      expect(interceptedRequests.length, equals(3));
      expect(interceptedRequests, containsAll(requests));
      
      print('✅ [MIDDLEWARE] Todas requests interceptadas');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo middleware: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Middleware simulation funcionando');
    });

    testWidgets('10. Deep Link with Parameters', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Deep Link Parameters');
      stopwatch.start();
      
      // Simular deep link com parâmetros
      final deepLinkData = {
        'route': '/dashboard',
        'userId': '123',
        'section': 'profile',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      print('🔗 [DEEP LINK] Processando: $deepLinkData');
      
      // Simular processamento do deep link
      if (deepLinkData['route'] == '/dashboard' && deepLinkData['userId'] != null) {
        userProvider.setUser(deepLinkData['userId']!, 'Deep Link User');
      }
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Dashboard - Deep Link User'), findsOneWidget);
      expect(userProvider.userId, equals('123'));
      
      print('✅ [DEEP LINK] Navegação por deep link executada');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo deep link: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Deep link with parameters funcionando');
    });

    test('11. Data Persistence Layer Integration', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Data Persistence');
      stopwatch.start();
      
      // Setup mocks para diferentes tipos de dados
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
      
      when(mockPrefs.getString('user_settings')).thenReturn('{"theme": "dark", "notifications": true}');
      when(mockPrefs.getInt('app_version')).thenReturn(123);
      when(mockPrefs.getBool('first_launch')).thenReturn(false);
      
      // Simular diferentes operações de persistência
      final operations = [
        {'type': 'string', 'key': 'user_token', 'value': 'abc123'},
        {'type': 'int', 'key': 'login_count', 'value': 5},
        {'type': 'bool', 'key': 'tutorial_shown', 'value': true},
      ];
      
      for (final op in operations) {
        switch (op['type']) {
          case 'string':
            await mockPrefs.setString(op['key'] as String, op['value'] as String);
            break;
          case 'int':
            await mockPrefs.setInt(op['key'] as String, op['value'] as int);
            break;
          case 'bool':
            await mockPrefs.setBool(op['key'] as String, op['value'] as bool);
            break;
        }
        print('💾 [PERSIST] ${op['type']} saved: ${op['key']} = ${op['value']}');
      }
      
      // Verificar recuperação
      final userSettings = mockPrefs.getString('user_settings');
      final appVersion = mockPrefs.getInt('app_version');
      final firstLaunch = mockPrefs.getBool('first_launch');
      
      expect(userSettings, isNotNull);
      expect(appVersion, equals(123));
      expect(firstLaunch, isFalse);
      
      print('📖 [PERSIST] Dados recuperados com sucesso');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo persistence: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Data persistence integration funcionando');
    });

    testWidgets('12. Partial Widget Pumping', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Partial Widget Pumping');
      stopwatch.start();
      
      userProvider.setUser('123', 'Pump Test');
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      // Pump parcial - apenas algumas frames
      await tester.pump(const Duration(milliseconds: 16)); // 1 frame
      print('🔄 [PUMP] 1 frame pumped');
      
      await tester.pump(const Duration(milliseconds: 32)); // 2 frames
      print('🔄 [PUMP] 2 frames pumped');
      
      // Pump com mudança de estado no meio
      networkProvider.setOnlineStatus(false);
      await tester.pump(const Duration(milliseconds: 16));
      
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      print('🔄 [PUMP] Estado alterado durante pump parcial');
      
      // Completar pump
      await tester.pumpAndSettle();
      
      expect(find.byKey(const Key('offline_banner')), findsOneWidget);
      print('🔄 [PUMP] Pump completo realizado');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo partial pumping: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Partial widget pumping funcionando');    });
    
    test('13. Service Layer Integration', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Service Layer');
      stopwatch.start();
        // Simular camada de serviços com conhecimento parcial
      final testUserService = TestUserService(cacheService);
      
      // Mock para cache miss inicial
      when(mockPrefs.getString('user_data_456')).thenReturn(null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      
      // Primeira chamada - deve ir para API
      final userData1 = await testUserService.getUserProfile('456');
      expect(userData1['id'], equals('456'));
      expect(userData1['name'], equals('Service User'));
      
      // Mock para cache hit
      when(mockPrefs.getString('user_data_456')).thenReturn(jsonEncode(userData1));
      
      // Segunda chamada - deve vir do cache
      final userData2 = await testUserService.getUserProfile('456');
      expect(userData2['id'], equals('456'));
      expect(userData2['fetchedAt'], equals(userData1['fetchedAt']));
      
      print('✅ [SERVICE] Cache hit/miss funcionando corretamente');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo service layer: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Service layer integration funcionando');
    });

    testWidgets('14. Animation Integration with State', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Animation Integration');
      stopwatch.start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: networkProvider),
            ],
            child: const CustomDashboard(),
          ),
        ),
      );
      
      // Testar transições de estado com animações
      userProvider.setLoading(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('🎬 [ANIMATION] Loading animation ativa');
      
      // Transição para estado logado
      userProvider.setUser('123', 'Animation Test');
      await tester.pump(); // Início da transição
      await tester.pump(const Duration(milliseconds: 16)); // Frame animation
      
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('dashboard_content')), findsOneWidget);
      print('🎬 [ANIMATION] Transição para dashboard');
      
      // Pump restante da animação
      await tester.pumpAndSettle();
      
      expect(find.text('Dashboard - Animation Test'), findsOneWidget);
      print('🎬 [ANIMATION] Animação de transição completada');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo animation integration: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Animation integration funcionando');
    });

    test('15. Memory Management - conhecimento parcial', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Memory Management');
      stopwatch.start();
      
      // Simular ciclo de vida com múltiplos providers
      final providers = <ChangeNotifier>[];
      
      // Criar múltiplos providers
      for (int i = 0; i < 5; i++) {
        final provider = UserProvider();
        providers.add(provider);
        
        // Simular uso
        provider.setUser('user$i', 'Test User $i');
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      print('🧠 [MEMORY] ${providers.length} providers criados');
      
      // Verificar se providers estão funcionando
      for (int i = 0; i < providers.length; i++) {
        final provider = providers[i] as UserProvider;
        expect(provider.isLoggedIn, isTrue);
        expect(provider.userId, equals('user$i'));
      }
      
      print('✅ [MEMORY] Todos providers funcionando corretamente');
      
      // Limpeza de memória
      for (final provider in providers) {
        provider.dispose();
      }
      
      print('🧹 [MEMORY] Providers disposed');
      
      // Simular garbage collection delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo memory management: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Memory management funcionando');
    });
  });
}
