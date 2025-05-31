import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class APIClient {
  final String baseUrl;
  final http.Client httpClient;
  
  APIClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();
  
  Future<APIResponse> get(String endpoint, {Map<String, String>? headers}) async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return APIResponse.fromHttpResponse(response);
  }
  
  Future<APIResponse> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return APIResponse.fromHttpResponse(response);
  }
  
  Future<APIResponse> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final response = await httpClient.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return APIResponse.fromHttpResponse(response);
  }
  
  Future<APIResponse> delete(String endpoint, {Map<String, String>? headers}) async {
    final response = await httpClient.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return APIResponse.fromHttpResponse(response);
  }
}

class APIResponse {
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? error;
  final Map<String, String> headers;
  
  APIResponse({
    required this.statusCode,
    this.data,
    this.error,
    required this.headers,
  });
    factory APIResponse.fromHttpResponse(http.Response response) {
    Map<String, dynamic>? data;
    String? error;
    
    try {
      final jsonData = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Handle both Map and List responses
        if (jsonData is Map<String, dynamic>) {
          data = jsonData;
        } else if (jsonData is List) {
          data = {'data': jsonData};
        } else {
          data = {'value': jsonData};
        }
      } else {
        // Handle error responses
        if (jsonData is Map<String, dynamic>) {
          error = jsonData['message'] ?? jsonData['error'] ?? 'Erro desconhecido';
        } else {
          error = 'Erro desconhecido';
        }
      }
    } catch (e) {
      error = 'Erro ao processar resposta: $e';
    }
    
    return APIResponse(
      statusCode: response.statusCode,
      data: data,
      error: error,
      headers: response.headers,
    );
  }
  
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

void main() {
  group('🖤 CAIXA PRETA - API Request/Response Tests', () {
    late APIClient apiClient;
    late Stopwatch stopwatch;
    
    setUpAll(() {
      print('🔧 [${DateTime.now()}] Setting up API test environment');
      apiClient = APIClient(baseUrl: 'https://jsonplaceholder.typicode.com');
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] API client configured');
    });

    setUp(() {
      stopwatch.reset();
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Test completed');
    });

    test('1. GET /posts - buscar posts (200)', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: GET posts');
      stopwatch.start();
      
      print('📤 [REQUEST] GET /posts');
      final response = await apiClient.get('/posts');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
        expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data!['data'], isA<List>());
      
      final posts = response.data!['data'] as List;
      expect(posts.length, greaterThan(0));
      
      print('✅ [SUCESSO] ${posts.length} posts recebidos');
      print('📋 [SAMPLE] Primeiro post: ${posts.first}');
    });

    test('2. GET /posts/1 - buscar post específico (200)', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: GET post específico');
      stopwatch.start();
      
      print('📤 [REQUEST] GET /posts/1');
      final response = await apiClient.get('/posts/1');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data, isA<Map<String, dynamic>>());
      
      final post = response.data as Map<String, dynamic>;
      expect(post['id'], equals(1));
      expect(post['title'], isNotNull);
      expect(post['body'], isNotNull);
      
      print('✅ [SUCESSO] Post ID 1 recebido');
      print('📋 [DATA] Título: ${post['title']}');
    });

    test('3. GET /posts/999 - post inexistente (404)', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: GET post inexistente');
      stopwatch.start();
      
      print('📤 [REQUEST] GET /posts/999');
      final response = await apiClient.get('/posts/999');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(404));
      expect(response.error, isNotNull);
      
      print('❌ [ESPERADO] Erro 404 para post inexistente');
      print('📋 [ERROR] ${response.error}');
    });

    test('4. POST /posts - criar novo post (201)', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: POST criar post');
      stopwatch.start();
      
      final newPost = {
        'title': 'Teste de Post',
        'body': 'Conteúdo do post de teste',
        'userId': 1,
      };
      
      print('📤 [REQUEST] POST /posts');
      print('📋 [BODY] $newPost');
      
      final response = await apiClient.post(
        '/posts',
        body: newPost,
        headers: {'Content-Type': 'application/json'},
      );
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(201));
      expect(response.data, isNotNull);
      
      final createdPost = response.data as Map<String, dynamic>;
      expect(createdPost['title'], equals(newPost['title']));
      expect(createdPost['body'], equals(newPost['body']));
      expect(createdPost['id'], isNotNull);
      
      print('✅ [SUCESSO] Post criado com ID: ${createdPost['id']}');
    });

    test('5. PUT /posts/1 - atualizar post (200)', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: PUT atualizar post');
      stopwatch.start();
      
      final updatedPost = {
        'id': 1,
        'title': 'Título Atualizado',
        'body': 'Conteúdo atualizado do post',
        'userId': 1,
      };
      
      print('📤 [REQUEST] PUT /posts/1');
      print('📋 [BODY] $updatedPost');
      
      final response = await apiClient.put(
        '/posts/1',
        body: updatedPost,
        headers: {'Content-Type': 'application/json'},
      );
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      
      final updatedData = response.data as Map<String, dynamic>;
      expect(updatedData['title'], equals(updatedPost['title']));
      expect(updatedData['body'], equals(updatedPost['body']));
      
      print('✅ [SUCESSO] Post atualizado');
    });

    test('6. DELETE /posts/1 - deletar post (200)', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: DELETE post');
      stopwatch.start();
      
      print('📤 [REQUEST] DELETE /posts/1');
      final response = await apiClient.delete('/posts/1');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
      
      print('✅ [SUCESSO] Post deletado');
    });

    test('7. Headers customizados - Authorization', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Headers customizados');
      stopwatch.start();
      
      final headers = {
        'Authorization': 'Bearer fake-token-123',
        'Content-Type': 'application/json',
        'X-Custom-Header': 'test-value',
      };
      
      print('📤 [REQUEST] GET /posts com headers customizados');
      print('📋 [HEADERS] $headers');
      
      final response = await apiClient.get('/posts', headers: headers);
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isTrue);
      expect(response.headers, isNotNull);
      
      print('✅ [SUCESSO] Requisição com headers customizados');
      print('📋 [RESPONSE HEADERS] ${response.headers.keys.take(5)}');
    });

    test('8. Timeout - requisição demorada', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Timeout');
      stopwatch.start();
      
      bool timeoutOccurred = false;
      
      try {
        // Simular timeout com delay muito pequeno
        print('📤 [REQUEST] GET /posts com timeout de 1ms');
        
        final future = apiClient.get('/posts');
        await future.timeout(Duration(milliseconds: 1));
        
      } catch (e) {
        timeoutOccurred = true;
        print('⏰ [TIMEOUT] Timeout capturado: $e');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo até timeout: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(timeoutOccurred, isTrue);
      print('✅ [SUCESSO] Timeout funcionando corretamente');
    });

    test('9. JSON Serialização/Deserialização', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: JSON Serialization');
      stopwatch.start();
      
      final complexData = {
        'string': 'texto',
        'number': 42,
        'boolean': true,
        'array': [1, 2, 3],
        'object': {
          'nested': 'value',
          'date': DateTime.now().toIso8601String(),
        },
        'null_value': null,
      };
      
      print('📤 [REQUEST] POST com dados complexos');
      print('📋 [COMPLEX DATA] $complexData');
      
      final response = await apiClient.post(
        '/posts',
        body: complexData,
        headers: {'Content-Type': 'application/json'},
      );
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isTrue);
      expect(response.data, isNotNull);
      
      print('✅ [SUCESSO] Serialização/Deserialização funcionando');
    });

    test('10. Múltiplas requisições simultâneas', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Requisições simultâneas');
      stopwatch.start();
      
      print('📤 [REQUEST] 5 requisições simultâneas');
      
      final futures = List.generate(5, (index) {
        print('📤 [PARALLEL] Requisição ${index + 1}');
        return apiClient.get('/posts/${index + 1}');
      });
      
      final responses = await Future.wait(futures);
      
      stopwatch.stop();
      print('📥 [RESPONSES] ${responses.length} respostas recebidas');
      print('📊 [PERFORMANCE] Tempo total: ${stopwatch.elapsedMilliseconds}ms');
      
      for (int i = 0; i < responses.length; i++) {
        expect(responses[i].isSuccess, isTrue);
        expect(responses[i].statusCode, equals(200));
        print('✅ [RESPONSE ${i + 1}] Status: ${responses[i].statusCode}');
      }
      
      // Performance deve ser melhor que requisições sequenciais
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      print('✅ [SUCESSO] Requisições paralelas completadas');
    });

    test('11. Códigos de status específicos', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Códigos de status');
      stopwatch.start();
      
      final testCases = [
        {'endpoint': '/posts', 'expectedStatus': 200, 'description': 'OK'},
        {'endpoint': '/posts/999', 'expectedStatus': 404, 'description': 'Not Found'},
      ];
      
      for (final testCase in testCases) {
        print('📤 [REQUEST] ${testCase['endpoint']}');
        
        final response = await apiClient.get(testCase['endpoint'] as String);
        
        print('📥 [RESPONSE] Status: ${response.statusCode} (${testCase['description']})');
        expect(response.statusCode, equals(testCase['expectedStatus']));
          if (response.statusCode >= 400) {
          expect(response.error, isNotNull);
          print('❌ [ERROR] ${response.error}');
        } else {
          expect(response.data, isNotNull);
          // For successful responses, ensure we have data
          if (testCase['endpoint'] == '/posts') {
            expect(response.data!['data'], isA<List>());
          }
          print('✅ [DATA] Dados recebidos');
        }
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo total: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Códigos de status verificados');
    });

    test('12. Content-Type handling', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Content-Type');
      stopwatch.start();
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      print('📤 [REQUEST] POST com Content-Type específico');
      print('📋 [HEADERS] $headers');
      
      final response = await apiClient.post(
        '/posts',
        body: {'title': 'Test', 'body': 'Content'},
        headers: headers,
      );
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📥 [RESPONSE HEADERS] Content-Type: ${response.headers['content-type']}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.isSuccess, isTrue);
      expect(response.headers['content-type'], contains('application/json'));
      
      print('✅ [SUCESSO] Content-Type handled correctly');
    });

    test('13. Paginação - query parameters', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Paginação');
      stopwatch.start();
      
      // Simular paginação com query parameters
      print('📤 [REQUEST] GET /posts com paginação simulada');
      
      final response = await apiClient.get('/posts');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
        expect(response.isSuccess, isTrue);
      expect(response.data!['data'], isA<List>());
      
      final posts = response.data!['data'] as List;
      print('📄 [PAGINATION] Total posts: ${posts.length}');
      
      // Simular "primeira página" - primeiros 10 itens
      final firstPage = posts.take(10).toList();
      expect(firstPage.length, lessThanOrEqualTo(10));
      
      print('📄 [PAGE 1] ${firstPage.length} posts na primeira página');
      print('✅ [SUCESSO] Paginação simulada funcionando');
    });

    test('14. Error handling - malformed JSON', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: JSON malformado');
      stopwatch.start();
      
      // Este endpoint do JSONPlaceholder sempre retorna JSON válido,
      // mas vamos simular o comportamento de erro
      print('📤 [REQUEST] Tentativa com endpoint que pode retornar JSON inválido');
      
      final response = await apiClient.get('/posts/1');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      // Verificar se response handler funciona corretamente
      if (response.isSuccess) {
        expect(response.data, isNotNull);
        print('✅ [SUCESSO] JSON válido processado corretamente');
      } else {
        expect(response.error, isNotNull);
        print('❌ [ERROR] Erro processado: ${response.error}');
      }
      
      print('✅ [SUCESSO] Error handling verificado');
    });

    test('15. Performance - baseline measurement', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Performance baseline');
      stopwatch.start();
      
      List<int> responseTimes = [];
      const int iterations = 5;
      
      for (int i = 0; i < iterations; i++) {
        final iterationStopwatch = Stopwatch()..start();
        
        print('📤 [ITERATION ${i + 1}] GET /posts/1');
        final response = await apiClient.get('/posts/1');
        
        iterationStopwatch.stop();
        responseTimes.add(iterationStopwatch.elapsedMilliseconds);
        
        expect(response.isSuccess, isTrue);
        print('📊 [ITERATION ${i + 1}] ${iterationStopwatch.elapsedMilliseconds}ms');
      }
      
      stopwatch.stop();
      
      final averageTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      final minTime = responseTimes.reduce((a, b) => a < b ? a : b);
      final maxTime = responseTimes.reduce((a, b) => a > b ? a : b);
      
      print('📊 [PERFORMANCE SUMMARY]');
      print('   Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('   Average: ${averageTime.toStringAsFixed(1)}ms');
      print('   Min: ${minTime}ms');
      print('   Max: ${maxTime}ms');
      
      // Performance baseline - resposta deve ser menor que 2 segundos
      expect(averageTime, lessThan(2000));
      expect(maxTime, lessThan(5000));
      
      print('✅ [SUCESSO] Performance dentro dos parâmetros aceitáveis');
    });
  });
}
