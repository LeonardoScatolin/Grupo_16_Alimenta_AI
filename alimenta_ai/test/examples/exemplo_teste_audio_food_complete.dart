import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

// Importações do projeto
import 'package:alimenta_ai/services/audio_service.dart';
import 'package:alimenta_ai/models/alimento.dart';

// Geração automática de mocks
@GenerateMocks([AudioRecorder, AudioPlayer, Dio])
import 'exemplo_teste_audio_food_complete.mocks.dart';

/// EXEMPLO COMPLETO DE TESTE PARA CADASTRO DE ALIMENTO POR ÁUDIO
/// 
/// Este arquivo demonstra como testar o fluxo completo de cadastro de alimento
/// através de comando de voz, incluindo:
/// - Gravação de áudio
/// - Transcrição via OpenAI Whisper
/// - Busca no backend
/// - Validação de dados
/// - Interface do usuário
///
/// Metodologias demonstradas:
/// - Caixa Branca: Testa lógica interna do AudioService
/// - Caixa Cinza: Testa integração UI + Service
/// - Caixa Preta: Testa experiência completa do usuário

void main() {
  group('🎤 CADASTRO DE ALIMENTO POR ÁUDIO - EXEMPLO COMPLETO', () {
    late MockAudioRecorder mockRecorder;
    late MockAudioPlayer mockPlayer;
    late MockDio mockDio;
    late AudioService audioService;

    setUp(() {
      mockRecorder = MockAudioRecorder();
      mockPlayer = MockAudioPlayer();
      mockDio = MockDio();
      
      // Inicializa o service com mocks
      audioService = AudioService(
        recorder: mockRecorder,
        player: mockPlayer,
        dio: mockDio,
      );
    });

    /// TESTE 1: CAIXA BRANCA - Lógica Interna do AudioService
    /// Testa o fluxo interno de processamento de áudio
    testWidgets('🔍 [CAIXA BRANCA] Fluxo completo de processamento de áudio', 
        (WidgetTester tester) async {
      
      // ARRANGE: Configurar mocks para simular comportamento real
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(mockRecorder.start(any)).thenAnswer((_) async {});
      when(mockRecorder.stop()).thenAnswer((_) async => 'path/to/audio.m4a');
      
      // Mock da resposta do OpenAI Whisper
      when(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: {'text': 'arroz integral com feijão preto'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // Mock da busca no backend
      when(mockDio.get('/alimento/buscar-por-transcricao',
          queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => Response(
        data: {
          'alimentos': [
            {
              'id': 1,
              'nome': 'Arroz Integral',
              'categoria': 'Cereais',
              'calorias_por_100g': 123,
              'carboidratos': 23.0,
              'proteinas': 2.6,
              'gorduras': 0.9,
              'fibras': 1.7
            },
            {
              'id': 2,
              'nome': 'Feijão Preto',
              'categoria': 'Leguminosas',
              'calorias_por_100g': 132,
              'carboidratos': 14.0,
              'proteinas': 8.9,
              'gorduras': 0.5,
              'fibras': 8.4
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // ACT: Executar o fluxo completo
      final stopwatch = Stopwatch()..start();
      
      await audioService.startRecording();
      await Future.delayed(Duration(seconds: 2)); // Simula gravação
      final audioPath = await audioService.stopRecording();
      
      final transcricao = await audioService.transcribeAudio(audioPath!);
      final alimentos = await audioService.buscarAlimentosPorTranscricao(transcricao);
      
      stopwatch.stop();

      // ASSERT: Verificar resultados
      expect(transcricao, equals('arroz integral com feijão preto'));
      expect(alimentos, hasLength(2));
      expect(alimentos[0].nome, equals('Arroz Integral'));
      expect(alimentos[1].nome, equals('Feijão Preto'));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Performance
      
      // Verificar chamadas para APIs
      verify(mockDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).called(1);
      
      verify(mockDio.get('/alimento/buscar-por-transcricao',
          queryParameters: {'transcricao': 'arroz integral com feijão preto'}))
          .called(1);

      print('✅ Teste de Caixa Branca concluído em ${stopwatch.elapsedMilliseconds}ms');
    });

    /// TESTE 2: CAIXA CINZA - Integração UI + Service
    /// Testa a integração entre interface e serviços
    testWidgets('🔗 [CAIXA CINZA] Integração completa UI + AudioService', 
        (WidgetTester tester) async {
      
      // Configurar mocks
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(mockRecorder.start(any)).thenAnswer((_) async {});
      when(mockRecorder.stop()).thenAnswer((_) async => 'audio.m4a');
      
      when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
          .thenAnswer((_) async => Response(
        data: {'text': 'banana prata'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => Response(
        data: {
          'alimentos': [{
            'id': 3,
            'nome': 'Banana Prata',
            'categoria': 'Frutas',
            'calorias_por_100g': 89,
            'carboidratos': 22.8,
            'proteinas': 1.1,
            'gorduras': 0.2,
            'fibras': 2.6
          }]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // Construir widget com Provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AudioFoodProvider(audioService),
            child: AudioFoodRegistrationScreen(),
          ),
        ),
      );

      // ACT: Simular interação do usuário
      
      // 1. Encontrar e pressionar botão de gravação
      final recordButton = find.byKey(Key('record_button'));
      expect(recordButton, findsOneWidget);
      await tester.tap(recordButton);
      await tester.pump();

      // 2. Verificar estado de gravação
      expect(find.text('🎤 Gravando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 3. Simular fim da gravação
      await tester.pump(Duration(seconds: 2));
      await tester.tap(find.byKey(Key('stop_button')));
      await tester.pump();

      // 4. Aguardar processamento
      await tester.pump(Duration(seconds: 1));

      // ASSERT: Verificar resultados na UI
      expect(find.text('Transcrição: banana prata'), findsOneWidget);
      expect(find.text('Banana Prata'), findsOneWidget);
      expect(find.text('89 kcal/100g'), findsOneWidget);
      expect(find.byKey(Key('alimento_card_3')), findsOneWidget);

      print('✅ Teste de Caixa Cinza: UI integrada com sucesso');
    });

    /// TESTE 3: CAIXA PRETA - Experiência Completa do Usuário
    /// Testa o fluxo como o usuário final experimenta
    testWidgets('👤 [CAIXA PRETA] Experiência completa do usuário', 
        (WidgetTester tester) async {
      
      // Setup para cenário real
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(mockRecorder.start(any)).thenAnswer((_) async {});
      when(mockRecorder.stop()).thenAnswer((_) async => 'user_audio.m4a');
      
      // Simular resposta realista
      when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
          .thenAnswer((_) async => Response(
        data: {'text': 'quero cadastrar uma maçã vermelha'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => Response(
        data: {
          'alimentos': [{
            'id': 4,
            'nome': 'Maçã Vermelha',
            'categoria': 'Frutas',
            'calorias_por_100g': 52,
            'carboidratos': 14.0,
            'proteinas': 0.3,
            'gorduras': 0.2,
            'fibras': 2.4
          }]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AudioFoodProvider(audioService),
            child: AudioFoodRegistrationScreen(),
          ),
        ),
      );

      // CENÁRIO: Usuário quer cadastrar alimento falando
      
      // 1. Usuário vê a tela inicial
      expect(find.text('Cadastro por Áudio'), findsOneWidget);
      expect(find.text('Pressione para falar'), findsOneWidget);
      
      // 2. Usuário pressiona para gravar
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      
      // 3. Sistema mostra feedback visual
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // 4. Usuário para a gravação
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      
      // 5. Sistema processa e mostra resultados
      expect(find.text('Maçã Vermelha'), findsOneWidget);
      expect(find.text('52 kcal'), findsOneWidget);
      
      // 6. Usuário pode confirmar o cadastro
      final confirmButton = find.text('Adicionar à Dieta');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pump();
      
      // 7. Sistema confirma sucesso
      expect(find.text('Alimento adicionado com sucesso!'), findsOneWidget);

      print('✅ Teste de Caixa Preta: Experiência do usuário validada');
    });

    /// TESTE 4: Tratamento de Erros
    /// Testa como o sistema lida com falhas
    testWidgets('❌ [ROBUSTEZ] Tratamento de erros e edge cases', 
        (WidgetTester tester) async {
      
      // CENÁRIO 1: Falha na transcrição
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(mockRecorder.start(any)).thenAnswer((_) async {});
      when(mockRecorder.stop()).thenAnswer((_) async => 'error_audio.m4a');
      
      when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Falha na conexão com OpenAI',
      ));

      expect(
        () async => await audioService.transcribeAudio('error_audio.m4a'),
        throwsA(isA<DioException>()),
      );

      // CENÁRIO 2: Backend indisponível
      when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
          .thenAnswer((_) async => Response(
        data: {'text': 'teste'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () async => await audioService.buscarAlimentosPorTranscricao('teste'),
        throwsA(isA<DioException>()),
      );

      print('✅ Teste de Robustez: Tratamento de erros validado');
    });

    /// TESTE 5: Performance e Otimização
    /// Testa aspectos de performance do sistema
    test('⚡ [PERFORMANCE] Benchmarks de tempo de resposta', () async {
      
      // Configurar mocks para resposta rápida
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(mockRecorder.start(any)).thenAnswer((_) async {});
      when(mockRecorder.stop()).thenAnswer((_) async => 'fast_audio.m4a');
      
      when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
          .thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 800)); // Simula OpenAI
        return Response(
          data: {'text': 'performance test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 200)); // Simula backend
        return Response(
          data: {'alimentos': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      // Benchmark de transcrição
      final stopwatchTranscricao = Stopwatch()..start();
      final transcricao = await audioService.transcribeAudio('fast_audio.m4a');
      stopwatchTranscricao.stop();

      expect(stopwatchTranscricao.elapsedMilliseconds, lessThan(2000));
      expect(transcricao, equals('performance test'));

      // Benchmark de busca
      final stopwatchBusca = Stopwatch()..start();
      final alimentos = await audioService.buscarAlimentosPorTranscricao(transcricao);
      stopwatchBusca.stop();

      expect(stopwatchBusca.elapsedMilliseconds, lessThan(500));
      expect(alimentos, isA<List<Alimento>>());

      print('⚡ Transcrição: ${stopwatchTranscricao.elapsedMilliseconds}ms');
      print('⚡ Busca: ${stopwatchBusca.elapsedMilliseconds}ms');
      print('✅ Teste de Performance: Benchmarks dentro do esperado');
    });
  });
}

/// CLASSE PROVIDER PARA GERENCIAMENTO DE ESTADO
/// Demonstra como integrar AudioService com Provider pattern
class AudioFoodProvider extends ChangeNotifier {
  final AudioService _audioService;
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _transcricao;
  List<Alimento> _alimentos = [];
  String? _errorMessage;

  AudioFoodProvider(this._audioService);

  // Getters
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  String? get transcricao => _transcricao;
  List<Alimento> get alimentos => _alimentos;
  String? get errorMessage => _errorMessage;

  /// Inicia o processo de gravação e processamento
  Future<void> processarAudio() async {
    try {
      _isRecording = true;
      _errorMessage = null;
      notifyListeners();

      // Simula gravação
      await _audioService.startRecording();
      await Future.delayed(Duration(seconds: 2));
      final audioPath = await _audioService.stopRecording();

      _isRecording = false;
      _isProcessing = true;
      notifyListeners();

      // Transcrição e busca
      _transcricao = await _audioService.transcribeAudio(audioPath!);
      _alimentos = await _audioService.buscarAlimentosPorTranscricao(_transcricao!);

      _isProcessing = false;
      notifyListeners();
      
    } catch (e) {
      _isRecording = false;
      _isProcessing = false;
      _errorMessage = 'Erro ao processar áudio: ${e.toString()}';
      notifyListeners();
    }
  }
}

/// WIDGET DE TELA PARA CADASTRO POR ÁUDIO
/// Interface completa para demonstrar integração
class AudioFoodRegistrationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro por Áudio'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<AudioFoodProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (provider.isRecording) ...[
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('🎤 Gravando...', style: TextStyle(fontSize: 18)),
                        ] else if (provider.isProcessing) ...[
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('🔄 Processando...', style: TextStyle(fontSize: 18)),
                        ] else ...[
                          Icon(Icons.mic, size: 48, color: Colors.green),
                          SizedBox(height: 8),
                          Text('Pressione para falar', style: TextStyle(fontSize: 18)),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Botões de controle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      key: Key('record_button'),
                      onPressed: provider.isRecording || provider.isProcessing 
                          ? null 
                          : () => provider.processarAudio(),
                      child: Icon(Icons.mic),
                    ),
                    ElevatedButton(
                      key: Key('stop_button'),
                      onPressed: provider.isRecording 
                          ? () => provider.processarAudio() 
                          : null,
                      child: Icon(Icons.stop),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Transcrição
                if (provider.transcricao != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transcrição:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(provider.transcricao!),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 16),

                // Lista de alimentos encontrados
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.alimentos.length,
                    itemBuilder: (context, index) {
                      final alimento = provider.alimentos[index];
                      return Card(
                        key: Key('alimento_card_${alimento.id}'),
                        child: ListTile(
                          title: Text(alimento.nome),
                          subtitle: Text('${alimento.calorias_por_100g} kcal/100g'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Alimento adicionado com sucesso!')),
                              );
                            },
                            child: Text('Adicionar à Dieta'),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Mensagem de erro
                if (provider.errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(16.0),
                    color: Colors.red[100],
                    child: Text(
                      provider.errorMessage!,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
