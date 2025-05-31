import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'dart:io';

@GenerateMocks([Dio])
import 'detailed_api_test.mocks.dart';

class DetailedAPIService {
  final Dio dio;
  final String baseUrl;
  
  DetailedAPIService({
    required this.dio,
    required this.baseUrl,
  }) {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);
    
    // Interceptors para logs
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('🌐 [DIO] $obj'),
    ));
  }
  
  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get(path, queryParameters: queryParameters, options: options);
  }
  
  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  Future<Response> put(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  Future<Response> delete(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  Future<Response> patch(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }
}

class AuthenticationService {
  final DetailedAPIService apiService;
  String? _accessToken;
  String? _refreshToken;
  
  AuthenticationService(this.apiService);
  
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        _refreshToken = response.data['refresh_token'];
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [AUTH] Login error: $e');
      return false;
    }
  }
  
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await apiService.post('/auth/refresh', data: {
        'refresh_token': _refreshToken,
      });
      
      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [AUTH] Refresh error: $e');
      return false;
    }
  }
  
  Options getAuthenticatedOptions() {
    return Options(
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );
  }
}

void main() {
  group('🔗 API DETALHADA - Comprehensive API Tests', () {
    late MockDio mockDio;
    late DetailedAPIService apiService;
    late AuthenticationService authService;
    late Stopwatch stopwatch;

    setUpAll(() {
      print('🔧 [${DateTime.now()}] Setting up Detailed API test environment');
      mockDio = MockDio();
      apiService = DetailedAPIService(
        dio: mockDio,
        baseUrl: 'https://api.alimenta.ai',
      );
      authService = AuthenticationService(apiService);
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] API services configured');
    });

    setUp(() {
      stopwatch.reset();
    });    tearDown(() {
      print('🧹 [${DateTime.now()}] Test completed - ${stopwatch.elapsedMilliseconds}ms');
    });

    test('1. GET Request - Status 200 Success', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: GET 200');
      stopwatch.start();
      
      final responseData = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@test.com',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      when(mockDio.get(
        '/users/1',
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/users/1'),
        headers: Headers.fromMap({
          'content-type': ['application/json'],
          'x-rate-limit': ['100'],
          'x-rate-remaining': ['99'],
        }),
      ));
      
      print('📤 [REQUEST] GET /users/1');
      final response = await apiService.get('/users/1');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      print('📋 [HEADERS] Rate Limit: ${response.headers.value('x-rate-limit')}');
      
      expect(response.statusCode, equals(200));
      expect(response.data['id'], equals(1));
      expect(response.data['email'], equals('test@test.com'));
      expect(response.headers.value('content-type'), contains('application/json'));
      
      verify(mockDio.get('/users/1', queryParameters: anyNamed('queryParameters'), options: anyNamed('options'))).called(1);
      print('✅ [SUCESSO] GET request 200 funcionando');
    });

    test('2. POST Request - Status 201 Created', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: POST 201');
      stopwatch.start();
      
      final requestData = {
        'name': 'New User',
        'email': 'newuser@test.com',
        'password': 'SecurePass123',
      };
      
      final responseData = {
        'id': 123,
        'name': 'New User',
        'email': 'newuser@test.com',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      when(mockDio.post(
        '/users',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 201,
        requestOptions: RequestOptions(path: '/users'),
        headers: Headers.fromMap({
          'content-type': ['application/json'],
          'location': ['/users/123'],
        }),
      ));
      
      print('📤 [REQUEST] POST /users');
      print('📋 [BODY] $requestData');
      
      final response = await apiService.post('/users', data: requestData);
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      print('📋 [LOCATION] ${response.headers.value('location')}');
      
      expect(response.statusCode, equals(201));
      expect(response.data['id'], equals(123));
      expect(response.data['name'], equals(requestData['name']));
      expect(response.headers.value('location'), equals('/users/123'));
      
      verify(mockDio.post('/users', data: requestData, queryParameters: anyNamed('queryParameters'), options: anyNamed('options'))).called(1);
      print('✅ [SUCESSO] POST request 201 funcionando');
    });

    test('3. PUT Request - Status 200 Updated', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: PUT 200');
      stopwatch.start();
      
      final updateData = {
        'name': 'Updated User',
        'email': 'updated@test.com',
      };
      
      final responseData = {
        'id': 123,
        'name': 'Updated User',
        'email': 'updated@test.com',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      when(mockDio.put(
        '/users/123',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/users/123'),
        headers: Headers.fromMap({
          'content-type': ['application/json'],
          'last-modified': [DateTime.now().toUtc().toIso8601String()],
        }),
      ));
      
      print('📤 [REQUEST] PUT /users/123');
      print('📋 [BODY] $updateData');
      
      final response = await apiService.put('/users/123', data: updateData);
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.statusCode, equals(200));
      expect(response.data['name'], equals(updateData['name']));
      expect(response.data['updated_at'], isNotNull);
      
      print('✅ [SUCESSO] PUT request 200 funcionando');
    });

    test('4. DELETE Request - Status 204 No Content', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: DELETE 204');
      stopwatch.start();
      
      when(mockDio.delete(
        '/users/123',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        statusCode: 204,
        requestOptions: RequestOptions(path: '/users/123'),
        headers: Headers.fromMap({
          'x-deleted-at': [DateTime.now().toIso8601String()],
        }),
      ));
      
      print('📤 [REQUEST] DELETE /users/123');
      
      final response = await apiService.delete('/users/123');
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.statusCode, equals(204));
      expect(response.data, isNull);
      
      print('✅ [SUCESSO] DELETE request 204 funcionando');
    });

    test('5. PATCH Request - Partial Update', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: PATCH');
      stopwatch.start();
      
      final patchData = {'email': 'patched@test.com'};
      
      final responseData = {
        'id': 123,
        'name': 'Existing User',
        'email': 'patched@test.com',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      when(mockDio.patch(
        '/users/123',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/users/123'),
      ));
      
      print('📤 [REQUEST] PATCH /users/123');
      print('📋 [BODY] $patchData');
      
      final response = await apiService.patch('/users/123', data: patchData);
      
      stopwatch.stop();
      print('📥 [RESPONSE] Status: ${response.statusCode}');
      print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(response.statusCode, equals(200));
      expect(response.data['email'], equals(patchData['email']));
      
      print('✅ [SUCESSO] PATCH request funcionando');
    });

    test('6. Status 400 - Bad Request', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Status 400');
      stopwatch.start();
      
      final errorResponse = {
        'error': 'validation_failed',
        'message': 'Email format is invalid',
        'details': {
          'field': 'email',
          'code': 'INVALID_FORMAT',
        },
      };
      
      when(mockDio.post(
        '/users',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/users'),
        response: Response(
          data: errorResponse,
          statusCode: 400,
          requestOptions: RequestOptions(path: '/users'),
        ),
        type: DioExceptionType.badResponse,
      ));
      
      print('📤 [REQUEST] POST /users (invalid data)');
      
      try {
        await apiService.post('/users', data: {'email': 'invalid-email'});
        fail('Deveria ter lançado exceção');
      } catch (e) {
        stopwatch.stop();
        print('📥 [RESPONSE] Status: 400 - Error caught');
        print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
        print('❌ [ERROR] ${(e as DioException).response?.data['message']}');
        
        expect(e, isA<DioException>());
        expect(e.response?.statusCode, equals(400));
        expect(e.response?.data['error'], equals('validation_failed'));
      }
      
      print('✅ [SUCESSO] Status 400 handling funcionando');
    });

    test('7. Status 401 - Unauthorized', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Status 401');
      stopwatch.start();
      
      when(mockDio.get(
        '/users/profile',
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/users/profile'),
        response: Response(
          data: {'error': 'unauthorized', 'message': 'Token expired'},
          statusCode: 401,
          requestOptions: RequestOptions(path: '/users/profile'),
        ),
        type: DioExceptionType.badResponse,
      ));
      
      print('📤 [REQUEST] GET /users/profile (without auth)');
      
      try {
        await apiService.get('/users/profile');
        fail('Deveria ter lançado exceção');
      } catch (e) {
        stopwatch.stop();
        print('📥 [RESPONSE] Status: 401 - Unauthorized');
        print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
        
        expect(e, isA<DioException>());
        expect(e.response?.statusCode, equals(401));
      }
      
      print('✅ [SUCESSO] Status 401 handling funcionando');
    });

    test('8. Status 403 - Forbidden', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Status 403');
      stopwatch.start();
      
      when(mockDio.delete(
        '/admin/users/123',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/admin/users/123'),
        response: Response(
          data: {'error': 'forbidden', 'message': 'Insufficient permissions'},
          statusCode: 403,
          requestOptions: RequestOptions(path: '/admin/users/123'),
        ),
        type: DioExceptionType.badResponse,
      ));
      
      print('📤 [REQUEST] DELETE /admin/users/123 (insufficient permissions)');
      
      try {
        await apiService.delete('/admin/users/123');
        fail('Deveria ter lançado exceção');
      } catch (e) {
        stopwatch.stop();
        print('📥 [RESPONSE] Status: 403 - Forbidden');
        print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
        
        expect(e, isA<DioException>());
        expect(e.response?.statusCode, equals(403));
      }
      
      print('✅ [SUCESSO] Status 403 handling funcionando');
    });

    test('9. Status 404 - Not Found', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Status 404');
      stopwatch.start();
      
      when(mockDio.get(
        '/users/999999',
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/users/999999'),
        response: Response(
          data: {'error': 'not_found', 'message': 'User not found'},
          statusCode: 404,
          requestOptions: RequestOptions(path: '/users/999999'),
        ),
        type: DioExceptionType.badResponse,
      ));
      
      print('📤 [REQUEST] GET /users/999999 (non-existent)');
      
      try {
        await apiService.get('/users/999999');
        fail('Deveria ter lançado exceção');
      } catch (e) {
        stopwatch.stop();
        print('📥 [RESPONSE] Status: 404 - Not Found');
        print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
        
        expect(e, isA<DioException>());
        expect(e.response?.statusCode, equals(404));
      }
      
      print('✅ [SUCESSO] Status 404 handling funcionando');
    });

    test('10. Status 500 - Internal Server Error', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Status 500');
      stopwatch.start();
      
      when(mockDio.post(
        '/users',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/users'),
        response: Response(
          data: {'error': 'internal_error', 'message': 'Database connection failed'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/users'),
        ),
        type: DioExceptionType.badResponse,
      ));
      
      print('📤 [REQUEST] POST /users (server error)');
      
      try {
        await apiService.post('/users', data: {'name': 'Test'});
        fail('Deveria ter lançado exceção');
      } catch (e) {
        stopwatch.stop();
        print('📥 [RESPONSE] Status: 500 - Internal Server Error');
        print('📊 [PERFORMANCE] Tempo resposta: ${stopwatch.elapsedMilliseconds}ms');
        
        expect(e, isA<DioException>());
        expect(e.response?.statusCode, equals(500));
      }
      
      print('✅ [SUCESSO] Status 500 handling funcionando');
    });

    test('11. Timeout e Retry Logic', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Timeout & Retry');
      stopwatch.start();
      
      // Primeira tentativa - timeout
      when(mockDio.get(
        '/users/1',
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/users/1'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout',
      ));
      
      print('📤 [REQUEST] GET /users/1 (primeira tentativa)');
      
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          await apiService.get('/users/1');
          break;
        } catch (e) {
          retryCount++;
          print('🔄 [RETRY] Tentativa $retryCount/$maxRetries falhou');
          
          if (retryCount >= maxRetries) {
            print('❌ [TIMEOUT] Todas tentativas falharam');
            expect(e, isA<DioException>());
            expect((e as DioException).type, equals(DioExceptionType.connectionTimeout));
          } else {
            await Future.delayed(Duration(milliseconds: 100 * retryCount));
          }
        }
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo total com retries: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Timeout e retry logic funcionando');
    });

    test('12. Bearer Token Authentication', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Bearer Token Auth');
      stopwatch.start();
      
      // Mock login
      when(mockDio.post(
        '/auth/login',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: {
          'access_token': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...',
          'refresh_token': 'refresh_token_here',
          'expires_in': 3600,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/auth/login'),
      ));
      
      // Fazer login
      print('🔑 [AUTH] Fazendo login');
      final loginSuccess = await authService.login('test@test.com', 'password123');
      
      expect(loginSuccess, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.accessToken, isNotNull);
      print('✅ [AUTH] Login realizado - Token: ${authService.accessToken?.substring(0, 20)}...');
      
      // Mock request autenticado
      when(mockDio.get(
        '/users/profile',
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: {'id': 1, 'name': 'Authenticated User'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/users/profile'),
      ));
      
      // Fazer request autenticado
      print('🔒 [AUTH] Request autenticado');
      final response = await apiService.get('/users/profile', options: authService.getAuthenticatedOptions());
      
      expect(response.statusCode, equals(200));
      expect(response.data['name'], equals('Authenticated User'));
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo auth flow: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Bearer token authentication funcionando');
    });

    test('13. Refresh Token Logic', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Refresh Token');
      stopwatch.start();
      
      // Setup tokens iniciais
      authService._accessToken = 'expired_token';
      authService._refreshToken = 'valid_refresh_token';
      
      // Mock refresh token
      when(mockDio.post(
        '/auth/refresh',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: {
          'access_token': 'new_access_token_123',
          'expires_in': 3600,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/auth/refresh'),
      ));
      
      print('🔄 [AUTH] Renovando access token');
      final refreshSuccess = await authService.refreshAccessToken();
      
      expect(refreshSuccess, isTrue);
      expect(authService.accessToken, equals('new_access_token_123'));
      print('✅ [AUTH] Token renovado: ${authService.accessToken}');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo refresh: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Refresh token logic funcionando');
    });

    test('14. Custom Headers e Content-Type', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Custom Headers');
      stopwatch.start();
      
      final customHeaders = {
        'X-API-Version': '2.0',
        'X-Client-ID': 'flutter-app',
        'X-Request-ID': 'req-${DateTime.now().millisecondsSinceEpoch}',
        'Accept-Language': 'pt-BR',
        'Content-Type': 'application/json; charset=utf-8',
      };
      
      when(mockDio.post(
        '/users',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: {'id': 1, 'created': true},
        statusCode: 201,
        requestOptions: RequestOptions(path: '/users'),
        headers: Headers.fromMap({
          'content-type': ['application/json; charset=utf-8'],
          'x-api-version': ['2.0'],
          'x-server-id': ['server-001'],
        }),
      ));
      
      print('📤 [REQUEST] POST /users com headers customizados');
      print('📋 [HEADERS] $customHeaders');
      
      final response = await apiService.post(
        '/users',
        data: {'name': 'Test User'},
        options: Options(headers: customHeaders),
      );
      
      expect(response.statusCode, equals(201));
      expect(response.headers.value('content-type'), contains('application/json'));
      expect(response.headers.value('x-api-version'), equals('2.0'));
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo custom headers: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Custom headers funcionando');
    });

    test('15. JSON Serialization Complex Data', () async {
      print('🧪 [${DateTime.now()}] Iniciando teste: Complex JSON');
      stopwatch.start();
      
      final complexData = {
        'user': {
          'personal_info': {
            'first_name': 'João',
            'last_name': 'Silva',
            'birth_date': '1990-05-15',
          },
          'preferences': {
            'theme': 'dark',
            'notifications': {
              'email': true,
              'push': false,
              'sms': null,
            },
            'languages': ['pt-BR', 'en-US'],
          },
          'metadata': {
            'created_at': DateTime.now().toIso8601String(),
            'device_info': {
              'platform': 'iOS',
              'version': '14.0',
              'app_version': '1.2.3',
            },
            'coordinates': {
              'latitude': -23.5505,
              'longitude': -46.6333,
            },
          },
        },
        'settings': [
          {'key': 'auto_backup', 'value': true, 'type': 'boolean'},
          {'key': 'max_cache_size', 'value': 100, 'type': 'integer'},
          {'key': 'api_endpoint', 'value': 'https://api.example.com', 'type': 'string'},
        ],
      };
      
      when(mockDio.post(
        '/users/complex',
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: {
          'id': 123,
          'created': true,
          'data': complexData,
          'checksum': 'abc123def456',
        },
        statusCode: 201,
        requestOptions: RequestOptions(path: '/users/complex'),
      ));
      
      print('📤 [REQUEST] POST /users/complex');
      print('📋 [COMPLEX DATA] Nested objects, arrays, null values, different types');
        final response = await apiService.post('/users/complex', data: complexData);
      
      expect(response.statusCode, equals(201));
      expect(response.data['data']['user']['personal_info']['first_name'], equals('João'));
      expect(response.data['data']['user']['preferences']['languages'], isA<List>());
      expect(response.data['data']['user']['preferences']['notifications']['sms'], isNull);
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo complex JSON: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Complex JSON serialization funcionando');
    });
  });
}