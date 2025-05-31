import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import dos serviços e modelos para gerar mocks
import 'package:alimenta_ai/services/alimenta_api_service.dart';
import 'package:alimenta_ai/services/nutricao_service.dart';
import 'package:alimenta_ai/services/auth_service.dart';
import 'package:alimenta_ai/config/theme_provider.dart';

// Generate mocks
@GenerateMocks([
  AlimentaAPIService,
  NutricaoService,
  AuthService,
  ThemeProvider,
])
import 'mock_setup.mocks.dart';

/// Configure um widget de teste com providers mockados
Widget createTestWidget({
  required Widget child,
  MockAlimentaAPIService? mockApiService,
  MockNutricaoService? mockNutricaoService,
  MockAuthService? mockAuthService,
  MockThemeProvider? mockThemeProvider,
}) {
  // Criar mocks padrão se não fornecidos
  final apiService = mockApiService ?? MockAlimentaAPIService();
  final nutricaoService = mockNutricaoService ?? MockNutricaoService();
  final authService = mockAuthService ?? MockAuthService();
  final themeProvider = mockThemeProvider ?? MockThemeProvider();

  // Configurar comportamentos padrão dos mocks
  _setupDefaultMockBehaviors(apiService, nutricaoService, authService, themeProvider);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NutricaoService>.value(value: nutricaoService),
      ChangeNotifierProvider<AuthService>.value(value: authService),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      Provider<AlimentaAPIService>.value(value: apiService),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: child,
    ),
  );
}

/// Configure comportamentos padrão para os mocks
void _setupDefaultMockBehaviors(
  MockAlimentaAPIService apiService,
  MockNutricaoService nutricaoService,
  MockAuthService authService,
  MockThemeProvider themeProvider,
) {
  // Mock API Service
  when(apiService.verificarConexao()).thenAnswer((_) async => true);
  when(apiService.loginPaciente(any, any)).thenAnswer(
    (_) async => {
      'success': true,
      'data': {
        'id': 1,
        'nome': 'Test User',
        'email': 'test@example.com',
        'token': 'mock_token'
      }
    },
  );

  // Mock Nutrição Service
  when(nutricaoService.isLoading).thenReturn(false);
  when(nutricaoService.error).thenReturn(null);
  when(nutricaoService.pacienteId).thenReturn(1);
  when(nutricaoService.nutriId).thenReturn(1);

  // Mock Auth Service
  when(authService.isLoading).thenReturn(false);
  when(authService.error).thenReturn(null);
  when(authService.isLoggedIn).thenReturn(true);
  when(authService.currentUser).thenReturn({
    'id': 1,
    'nome': 'Test User',
    'email': 'test@example.com',
  });

  // Mock Theme Provider
  when(themeProvider.isDarkMode).thenReturn(false);
  when(themeProvider.themeMode).thenReturn(ThemeMode.light);
}

/// Helper para pump widget com providers
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget child, {
  MockAlimentaAPIService? mockApiService,
  MockNutricaoService? mockNutricaoService,
  MockAuthService? mockAuthService,
  MockThemeProvider? mockThemeProvider,
}) async {
  await tester.pumpWidget(
    createTestWidget(
      child: child,
      mockApiService: mockApiService,
      mockNutricaoService: mockNutricaoService,
      mockAuthService: mockAuthService,
      mockThemeProvider: mockThemeProvider,
    ),
  );
}
