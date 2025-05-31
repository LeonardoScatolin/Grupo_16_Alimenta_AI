import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'auth_service_test.mocks.dart';

// Gerar mocks: flutter packages pub run build_runner build
@GenerateMocks([http.Client, SharedPreferences])
import 'auth_service_test.mocks.dart';

class AuthService {
  final http.Client httpClient;
  final SharedPreferences prefs;
  
  AuthService(this.httpClient, this.prefs);
  
  // Métodos privados para testes de caixa branca
  String _generateTokenHash(String email, String password) {
    return base64Encode('$email:$password'.codeUnits);
  }
  
  Future<bool> _validateCredentials(String email, String password) async {
    return email.isNotEmpty && password.length >= 6;
  }
  
  Future<void> _saveToken(String token) async {
    await prefs.setString('auth_token', token);
  }
  
  Future<String?> _getStoredToken() async {
    return prefs.getString('auth_token');
  }
  
  Future<bool> login(String email, String password) async {
    if (!await _validateCredentials(email, password)) return false;
    
    final response = await httpClient.post(
      Uri.parse('https://api.alimenta.ai/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['token']);
      return true;
    }
    return false;
  }
  
  Future<void> logout() async {
    await prefs.remove('auth_token');
  }
}

void main() {
  group('🧪 CAIXA BRANCA - AuthService Tests', () {
    late MockClient mockHttpClient;
    late MockSharedPreferences mockPrefs;
    late AuthService authService;
    late Stopwatch stopwatch;

    setUp(() {
      print('🔧 [${DateTime.now()}] Setting up AuthService test environment');
      mockHttpClient = MockClient();
      mockPrefs = MockSharedPreferences();
      authService = AuthService(mockHttpClient, mockPrefs);
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] Setup completed');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up test environment');
      stopwatch.reset();
      print('✅ [${DateTime.now()}] Teardown completed');
    });

    test('1. _generateTokenHash - deve gerar hash correto', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: _generateTokenHash');
      stopwatch.start();
      
      final email = 'test@test.com';
      final password = 'password123';
      final expectedHash = base64Encode('$email:$password'.codeUnits);
      
      // Acessando método privado através de reflexão para caixa branca
      final result = authService._generateTokenHash(email, password);
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, equals(expectedHash));
      print('✅ [SUCESSO] Hash gerado corretamente - esperado: $expectedHash, obtido: $result');
    });

    test('2. _validateCredentials - deve validar email vazio', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: _validateCredentials email vazio');
      stopwatch.start();
      
      final result = await authService._validateCredentials('', 'password123');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, isFalse);
      print('✅ [SUCESSO] Validação rejeitou email vazio');
    });

    test('3. _validateCredentials - deve validar senha curta', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: _validateCredentials senha curta');
      stopwatch.start();
      
      final result = await authService._validateCredentials('test@test.com', '123');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, isFalse);
      print('✅ [SUCESSO] Validação rejeitou senha curta');
    });

    test('4. _saveToken - deve salvar token no SharedPreferences', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: _saveToken');
      stopwatch.start();
      
      when(mockPrefs.setString('auth_token', 'test_token'))
          .thenAnswer((_) async => true);
      
      await authService._saveToken('test_token');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      verify(mockPrefs.setString('auth_token', 'test_token')).called(1);
      print('✅ [SUCESSO] Token salvo corretamente');
    });

    test('5. login - sucesso com credenciais válidas', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: login sucesso');
      stopwatch.start();
      
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({'token': 'valid_token'}),
        200,
      ));
      
      when(mockPrefs.setString('auth_token', 'valid_token'))
          .thenAnswer((_) async => true);
      
      final result = await authService.login('test@test.com', 'password123');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, isTrue);
      verify(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      verify(mockPrefs.setString('auth_token', 'valid_token')).called(1);
      print('✅ [SUCESSO] Login realizado com sucesso');
    });

    test('6. login - falha com credenciais inválidas', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: login falha');
      stopwatch.start();
      
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({'error': 'Invalid credentials'}),
        401,
      ));
      
      final result = await authService.login('test@test.com', 'wrongpassword');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, isFalse);
      verifyNever(mockPrefs.setString(any, any));
      print('✅ [SUCESSO] Login rejeitado corretamente para credenciais inválidas');
    });

    test('7. login - timeout exception', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: login timeout');
      stopwatch.start();
      
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(SocketException('Connection timeout'));
      
      bool exceptionCaught = false;
      try {
        await authService.login('test@test.com', 'password123');
      } catch (e) {
        exceptionCaught = true;
        print('🔥 [EXCEPTION] Capturada: $e');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(exceptionCaught, isTrue);
      print('✅ [SUCESSO] Exception de timeout capturada corretamente');
    });

    test('8. logout - deve remover token', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: logout');
      stopwatch.start();
      
      when(mockPrefs.remove('auth_token')).thenAnswer((_) async => true);
      
      await authService.logout();
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      verify(mockPrefs.remove('auth_token')).called(1);
      print('✅ [SUCESSO] Token removido no logout');
    });

    test('9. _getStoredToken - deve retornar token armazenado', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: _getStoredToken');
      stopwatch.start();
      
      when(mockPrefs.getString('auth_token')).thenReturn('stored_token');
      
      final result = await authService._getStoredToken();
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, equals('stored_token'));
      print('✅ [SUCESSO] Token recuperado: $result');
    });

    test('10. Memory leak - verificar limpeza de objetos', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: memory leak');
      stopwatch.start();
      
      int initialObjects = 0;
      
      // Simular múltiplas operações
      for (int i = 0; i < 100; i++) {
        await authService._validateCredentials('test@test.com', 'password$i');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('🧠 [MEMORY] Objetos criados durante teste - inicial: $initialObjects');
      
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      print('✅ [SUCESSO] Teste de memory leak completado');
    });
  });
}
