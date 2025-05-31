import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

@GenerateMocks([http.Client])
import 'api_service_test.mocks.dart';

class APIService {
  final http.Client httpClient;
  final String baseUrl = 'https://api.alimenta.ai';
  
  APIService(this.httpClient);
  
  // Métodos privados para análise de caixa branca
  Map<String, String> _buildHeaders(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  Future<T> _makeRequest<T>(
    String method,
    String endpoint,
    Map<String, dynamic>? body,
    String? token,
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = _buildHeaders(token);
    
    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await httpClient.get(uri, headers: headers);
        break;
      case 'POST':
        response = await httpClient.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PUT':
        response = await httpClient.put(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await httpClient.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('Método HTTP não suportado: $method');
    }
    
    return _handleResponse<T>(response);
  }
  
  T _handleResponse<T>(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as T;
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> getUserData(String userId, String token) async {
    return await _makeRequest('GET', '/users/$userId', null, token);
  }
  
  Future<Map<String, dynamic>> updateUserData(String userId, Map<String, dynamic> data, String token) async {
    return await _makeRequest('PUT', '/users/$userId', data, token);
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  
  @override
  String toString() => 'HttpException: $message';
}

void main() {
  group('🧪 CAIXA BRANCA - APIService Tests', () {
    late MockClient mockHttpClient;
    late APIService apiService;
    late Stopwatch stopwatch;

    setUp(() {
      print('🔧 [${DateTime.now()}] Setting up APIService test environment');
      mockHttpClient = MockClient();
      apiService = APIService(mockHttpClient);
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] Setup completed');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up test environment');
      stopwatch.reset();
      print('✅ [${DateTime.now()}] Teardown completed');
    });

    test('11. _buildHeaders - sem token', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: _buildHeaders sem token');
      stopwatch.start();
      
      final headers = apiService._buildHeaders(null);
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(headers, {'Content-Type': 'application/json'});
      expect(headers.containsKey('Authorization'), isFalse);
      print('✅ [SUCESSO] Headers construídos sem Authorization: $headers');
    });

    test('12. _buildHeaders - com token', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: _buildHeaders com token');
      stopwatch.start();
      
      final token = 'test_token_123';
      final headers = apiService._buildHeaders(token);
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['Authorization'], equals('Bearer $token'));
      print('✅ [SUCESSO] Headers com Authorization: $headers');
    });

    test('13. _handleResponse - resposta 200', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: _handleResponse 200');
      stopwatch.start();
      
      final response = http.Response('{"data": "success"}', 200);
      final result = apiService._handleResponse<Map<String, dynamic>>(response);
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['data'], equals('success'));
      print('✅ [SUCESSO] Resposta 200 processada: $result');
    });

    test('14. _handleResponse - erro 404', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: _handleResponse 404');
      stopwatch.start();
      
      final response = http.Response('{"error": "Not found"}', 404);
      
      expect(
        () => apiService._handleResponse(response),
        throwsA(isA<HttpException>()),
      );
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Erro 404 lançou HttpException corretamente');
    });

    test('15. getUserData - fluxo completo com mock', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: getUserData');
      stopwatch.start();
      
      final expectedData = {'id': '123', 'name': 'Test User', 'email': 'test@test.com'};
      
      when(mockHttpClient.get(
        Uri.parse('https://api.alimenta.ai/users/123'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode(expectedData),
        200,
      ));
      
      final result = await apiService.getUserData('123', 'test_token');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result, equals(expectedData));
      verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      print('✅ [SUCESSO] getUserData retornou: $result');
    });

    test('16. _makeRequest - método não suportado', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: método HTTP inválido');
      stopwatch.start();
      
      expect(
        () async => await apiService._makeRequest('PATCH', '/test', {}, 'token'),
        throwsA(isA<ArgumentError>()),
      );
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Método PATCH rejeitado corretamente');
    });

    test('17. Performance - múltiplas requisições simultâneas', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: performance múltiplas requisições');
      stopwatch.start();
      
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{"data": "ok"}', 200));
      
      final futures = List.generate(10, (i) => 
        apiService.getUserData('user$i', 'token$i')
      );
      
      final results = await Future.wait(futures);
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] 10 requisições em: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(results.length, equals(10));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Max 5 segundos
      print('✅ [SUCESSO] Todas as requisições completadas');
    });

    test('18. Timeout handling', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: timeout');
      stopwatch.start();
      
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 2));
        return http.Response('{"data": "delayed"}', 200);
      });
      
      final future = apiService.getUserData('123', 'token');
      final result = await future.timeout(Duration(seconds: 3));
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(result['data'], equals('delayed'));
      print('✅ [SUCESSO] Requisição com delay completada');
    });
  });
}
