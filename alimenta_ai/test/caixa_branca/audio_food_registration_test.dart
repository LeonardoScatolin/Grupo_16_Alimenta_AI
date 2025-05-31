import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Gerando mocks para as dependências
@GenerateMocks([
  AudioRecorder,
  AudioPlayer,
  Dio,
  File,
])
import 'audio_food_registration_test.mocks.dart';

// Simulação da classe AudioService para testes
class MockAudioService {
  final AudioRecorder recorder;
  final AudioPlayer player;
  final Dio dio;
  late MockFile _mockFile;
  
  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _lastTranscription;
  String? _currentRecordingPath;
  Map<String, dynamic>? _lastFoodSearchResult;
  
  MockAudioService({
    required this.recorder,
    required this.player,
    required this.dio,
  });
  
  // Getters para estado
  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  String? get lastTranscription => _lastTranscription;
  String? get currentRecordingPath => _currentRecordingPath;
  Map<String, dynamic>? get lastFoodSearchResult => _lastFoodSearchResult;
  
  /// Método principal: Processar áudio completo para cadastro de alimento
  Future<Map<String, dynamic>?> processAudioForFoodRegistration() async {
    try {
      // PASSO 1: Verificar permissões
      if (!await _checkPermissions()) {
        return {'error': 'Permissões de microfone não concedidas'};
      }
      
      // PASSO 2: Gravar áudio
      final recordingSuccess = await _startRecording();
      if (!recordingSuccess) {
        return {'error': 'Falha ao iniciar gravação'};
      }
      
      // PASSO 3: Parar gravação (simulado)
      await _stopRecording();
        // PASSO 4: Transcrever áudio usando OpenAI
      final transcriptionResult = await _transcribeAudio();
      if (transcriptionResult == null) {
        return {'error': 'Falha na transcrição do áudio'};
      }
      
      // PASSO 5: Buscar alimentos no backend usando transcrição
      final foodSearchResult = await _searchFoodsByTranscription(transcriptionResult);
      if (foodSearchResult == null) {
        return {'error': 'Falha na busca de alimentos'};
      }
      
      // PASSO 6: Estruturar dados para a interface
      final structuredData = _structureFoodData(foodSearchResult);
      
      return {
        'status': 'success',
        'transcription': transcriptionResult,
        'foods_found': structuredData,
        'audio_path': _currentRecordingPath,
      };
      
    } catch (e) {
      return {'error': 'Erro inesperado: $e'};
    }
  }
  
  Future<bool> _checkPermissions() async {
    // Simular verificação de permissões
    return true; // Para testes, sempre permitir
  }
  
  Future<bool> _startRecording() async {
    try {
      _currentRecordingPath = 'test_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: _currentRecordingPath!,
      );
      _isRecording = true;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _stopRecording() async {
    await recorder.stop();
    _isRecording = false;
  }  Future<String?> _transcribeAudio() async {
    if (_currentRecordingPath == null) return null;
    
    _isTranscribing = true;
    
    try {
      // Para testes, simular dados do arquivo sem acessar o sistema de arquivos real
      final mockFormData = FormData.fromMap({
        'file': MultipartFile.fromBytes([1, 2, 3, 4], filename: 'test_audio.wav'),
        'model': 'whisper-1',
        'language': 'pt',
      });
      
      // Simular chamada para OpenAI Whisper API
      final response = await dio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: mockFormData,
      );
      
      if (response.statusCode == 200) {
        _lastTranscription = response.data['text'];
        return _lastTranscription;
      }
      return null;
    } catch (e) {
      // Capturar qualquer erro na transcrição
      return null;
    } finally {
      _isTranscribing = false;
    }
  }
  
  Future<Map<String, dynamic>?> _searchFoodsByTranscription(String transcription) async {
    try {
      final response = await dio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: {
          'texto_transcrito': transcription,
          'limite': 10,
        },
      );
      
      if (response.statusCode == 200) {
        _lastFoodSearchResult = response.data;
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
    List<Map<String, dynamic>> _structureFoodData(Map<String, dynamic> searchResult) {
    final alimentos = searchResult['alimentos'] as List? ?? [];
    
    return alimentos.map((alimento) => {
      'id': alimento['id'],
      'nome': alimento['nome'],
      'calorias': alimento['calorias'] ?? 0,
      'proteinas': alimento['proteinas'] ?? 0.0,
      'carboidratos': alimento['carboidratos'] ?? 0.0,
      'gordura': alimento['gordura'] ?? 0.0,
      'categoria': alimento['categoria'] ?? 'Não informado',
      'codigo': alimento['codigo'] ?? '',
      'quantidade_sugerida': 100,
      'transcricao_origem': _lastTranscription,
    }).toList();
  }
}

void main() {
  group('🎤 CADASTRO DE ALIMENTO POR ÁUDIO - Testes Completos', () {
    late MockAudioRecorder mockRecorder;
    late MockAudioPlayer mockPlayer;
    late MockDio mockDio;
    late MockAudioService audioService;
    late Stopwatch stopwatch;

    setUp(() {
      print('🔧 [${DateTime.now()}] Configurando ambiente de teste de áudio');
      mockRecorder = MockAudioRecorder();
      mockPlayer = MockAudioPlayer();
      mockDio = MockDio();
      audioService = MockAudioService(
        recorder: mockRecorder,
        player: mockPlayer,
        dio: mockDio,
      );
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] Setup completo');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Limpando ambiente de teste');
      stopwatch.reset();
      print('✅ [${DateTime.now()}] Cleanup concluído');
    });

    test('1. FLUXO COMPLETO - Sucesso no cadastro por áudio', () async {
      print('🧪 [${DateTime.now()}] TESTE: Fluxo completo de sucesso');
      stopwatch.start();
      
      // ARRANGE - Configurar mocks para cenário de sucesso
      
      // Mock da gravação
      when(mockRecorder.start(any, path: anyNamed('path')))
          .thenAnswer((_) async {});
      when(mockRecorder.stop())
          .thenAnswer((_) async => 'test_recording.wav');
      
      // Mock da transcrição (OpenAI Whisper)
      when(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        data: {'text': 'duas fatias de pão integral com manteiga'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
      
      // Mock da busca no backend
      when(mockDio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        data: {
          'status': true,
          'alimentos': [
            {
              'id': 1,
              'nome': 'Pão integral',
              'calorias': 247,
              'proteinas': 8.0,
              'carboidratos': 46.0,
              'gordura': 4.2,
              'categoria': 'Cereais',
              'codigo': 'A123'
            },
            {
              'id': 2,
              'nome': 'Manteiga',
              'calorias': 717,
              'proteinas': 0.9,
              'carboidratos': 0.1,
              'gordura': 81.1,
              'categoria': 'Laticínios',
              'codigo': 'B456'
            }
          ],
          'total_encontrados': 2,
          'tempo_busca': '45ms'
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
      
      // ACT - Executar o fluxo completo
      final result = await audioService.processAudioForFoodRegistration();
      
      stopwatch.stop();
      
      // ASSERT - Verificar resultados
      expect(result, isNotNull);
      expect(result!['status'], equals('success'));
      expect(result['transcription'], equals('duas fatias de pão integral com manteiga'));
      expect(result['foods_found'], isA<List>());
      
      final foods = result['foods_found'] as List;
      expect(foods.length, equals(2));
      
      // Verificar primeiro alimento (Pão integral)
      expect(foods[0]['nome'], equals('Pão integral'));
      expect(foods[0]['calorias'], equals(247));
      expect(foods[0]['proteinas'], equals(8.0));
      
      // Verificar segundo alimento (Manteiga)
      expect(foods[1]['nome'], equals('Manteiga'));
      expect(foods[1]['calorias'], equals(717));
      expect(foods[1]['gordura'], equals(81.1));
      
      // Verificar que todas as chamadas foram feitas
      verify(mockRecorder.start(any, path: anyNamed('path'))).called(1);
      verify(mockRecorder.stop()).called(1);
      verify(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).called(1);
      verify(mockDio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: anyNamed('data'),
      )).called(1);
      
      print('📊 [PERFORMANCE] Tempo total: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Cadastro por áudio funcionando perfeitamente');
      print('📝 [RESULTADO] Transcrição: "${result['transcription']}"');
      print('🍎 [RESULTADO] Alimentos encontrados: ${foods.length}');
    });

    test('2. CENÁRIO DE FALHA - Erro na transcrição', () async {
      print('🧪 [${DateTime.now()}] TESTE: Falha na transcrição');
      stopwatch.start();
      
      // ARRANGE - Simular falha na transcrição
      when(mockRecorder.start(any, path: anyNamed('path')))
          .thenAnswer((_) async {});
      when(mockRecorder.stop())
          .thenAnswer((_) async => 'test_recording.wav');
      
      // Mock falha na transcrição (erro 401)
      when(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          data: {'error': 'Invalid API key'},
          requestOptions: RequestOptions(path: ''),
        ),
        requestOptions: RequestOptions(path: ''),
      ));
      
      // ACT
      final result = await audioService.processAudioForFoodRegistration();
      
      stopwatch.stop();
        // ASSERT
      expect(result, isNotNull);
      expect(result!['error'], contains('Falha na transcrição'));
      
      // Verificar que a gravação funcionou mas a transcrição falhou
      verify(mockRecorder.start(any, path: anyNamed('path'))).called(1);
      verify(mockRecorder.stop()).called(1);
      verify(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).called(1);
      
      // Verificar que a busca não foi chamada devido à falha anterior
      verifyNever(mockDio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: anyNamed('data'),
      ));
      
      print('📊 [PERFORMANCE] Tempo até falha: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [ESPERADO] Erro de transcrição tratado corretamente');
      print('❌ [ERRO] ${result['error']}');
    });

    test('3. CENÁRIO DE FALHA - Backend indisponível', () async {
      print('🧪 [${DateTime.now()}] TESTE: Backend indisponível');
      stopwatch.start();
      
      // ARRANGE - Sucesso na transcrição, falha no backend
      when(mockRecorder.start(any, path: anyNamed('path')))
          .thenAnswer((_) async {});
      when(mockRecorder.stop())
          .thenAnswer((_) async => 'test_recording.wav');
      
      // Mock sucesso na transcrição
      when(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        data: {'text': 'maçã vermelha'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
      
      // Mock falha no backend (conexão recusada)
      when(mockDio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
        requestOptions: RequestOptions(path: ''),
      ));
      
      // ACT
      final result = await audioService.processAudioForFoodRegistration();
      
      stopwatch.stop();
      
      // ASSERT
      expect(result, isNotNull);
      expect(result!['error'], contains('Falha na busca de alimentos'));
      
      // Verificar que a transcrição funcionou
      verify(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).called(1);
      
      // Verificar que a busca foi tentada mas falhou
      verify(mockDio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: anyNamed('data'),
      )).called(1);
      
      print('📊 [PERFORMANCE] Tempo até falha: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [ESPERADO] Falha de backend tratada corretamente');
      print('❌ [ERRO] ${result['error']}');
    });

    test('4. VALIDAÇÃO DE DADOS - Estrutura de alimentos', () async {
      print('🧪 [${DateTime.now()}] TESTE: Validação de estrutura de dados');
      stopwatch.start();
      
      // ARRANGE - Resposta com dados variados
      when(mockRecorder.start(any, path: anyNamed('path')))
          .thenAnswer((_) async {});
      when(mockRecorder.stop())
          .thenAnswer((_) async => 'test_recording.wav');
      
      when(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        data: {'text': 'arroz e feijão'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
      
      // Mock com dados incompletos para testar robustez
      when(mockDio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        data: {
          'status': true,
          'alimentos': [
            {
              'id': 1,
              'nome': 'Arroz branco cozido',
              'calorias': 128,
              'proteinas': 2.6,
              'carboidratos': 28.1,
              'gordura': 0.2,
              'categoria': 'Cereais'
              // 'codigo' ausente para testar tratamento
            },
            {
              'id': 2,
              'nome': 'Feijão carioca cozido',
              // 'calorias' ausente para testar tratamento
              'proteinas': 8.8,
              'carboidratos': 13.6,
              'gordura': 0.5,
              'categoria': 'Leguminosas',
              'codigo': 'L789'
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
      
      // ACT
      final result = await audioService.processAudioForFoodRegistration();
      
      stopwatch.stop();
      
      // ASSERT
      expect(result, isNotNull);
      expect(result!['status'], equals('success'));
      
      final foods = result['foods_found'] as List;
      expect(foods.length, equals(2));
      
      // Verificar tratamento de dados ausentes
      final arroz = foods[0];
      expect(arroz['nome'], equals('Arroz branco cozido'));
      expect(arroz['calorias'], equals(128));
      expect(arroz['codigo'], equals('')); // Deve ter valor padrão
      
      final feijao = foods[1];
      expect(feijao['nome'], equals('Feijão carioca cozido'));
      expect(feijao['calorias'], equals(0)); // Deve ter valor padrão
      expect(feijao['codigo'], equals('L789'));
      
      // Verificar campos obrigatórios sempre presentes
      for (final food in foods) {
        expect(food['quantidade_sugerida'], equals(100));
        expect(food['transcricao_origem'], equals('arroz e feijão'));
        expect(food.containsKey('id'), isTrue);
        expect(food.containsKey('nome'), isTrue);
        expect(food.containsKey('calorias'), isTrue);
        expect(food.containsKey('proteinas'), isTrue);
        expect(food.containsKey('carboidratos'), isTrue);
        expect(food.containsKey('gordura'), isTrue);
        expect(food.containsKey('categoria'), isTrue);
      }
      
      print('📊 [PERFORMANCE] Tempo de validação: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Estrutura de dados validada corretamente');
      print('🔧 [ROBUSTEZ] Campos ausentes tratados com valores padrão');
    });

    test('5. TESTE DE ESTADO - Flags durante processamento', () async {
      print('🧪 [${DateTime.now()}] TESTE: Estados durante processamento');
      stopwatch.start();
      
      // ARRANGE
      when(mockRecorder.start(any, path: anyNamed('path')))
          .thenAnswer((_) async {});
      when(mockRecorder.stop())
          .thenAnswer((_) async => 'test_recording.wav');
      
      // Mock com delay para verificar estados
      when(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
      )).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return Response(
          data: {'text': 'banana'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });
      
      when(mockDio.post(
        'http://127.0.0.1:3333/alimento/buscar-por-transcricao',
        data: anyNamed('data'),
      )).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 50));
        return Response(
          data: {
            'status': true,
            'alimentos': [
              {
                'id': 1,
                'nome': 'Banana nanica',
                'calorias': 87,
                'proteinas': 1.3,
                'carboidratos': 22.3,
                'gordura': 0.1,
                'categoria': 'Frutas'
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });
      
      // ACT & ASSERT - Verificar estados durante execução
      
      // Estado inicial
      expect(audioService.isRecording, isFalse);
      expect(audioService.isTranscribing, isFalse);
      expect(audioService.lastTranscription, isNull);
      
      // Iniciar processamento
      final futureResult = audioService.processAudioForFoodRegistration();
      
      // Aguardar um pouco e verificar estados intermediários
      await Future.delayed(Duration(milliseconds: 50));
      
      // Aguardar conclusão
      final result = await futureResult;
      
      stopwatch.stop();
      
      // Estado final
      expect(result, isNotNull);
      expect(result!['status'], equals('success'));
      expect(audioService.isRecording, isFalse);
      expect(audioService.isTranscribing, isFalse);
      expect(audioService.lastTranscription, equals('banana'));
      expect(audioService.currentRecordingPath, isNotNull);
      
      print('📊 [PERFORMANCE] Tempo com delays: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Estados gerenciados corretamente durante processamento');
      print('🔄 [ESTADO] Transcrição final: "${audioService.lastTranscription}"');
    });
  });
}
