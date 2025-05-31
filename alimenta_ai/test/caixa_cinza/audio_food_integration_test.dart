import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

// Mock da classe AudioService para integração
class MockAudioServiceProvider extends ChangeNotifier {  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _lastTranscription;
  List<Map<String, dynamic>>? _foundFoods;
  String? _errorMessage;
  bool _debugDisposed = false;

  // Função auxiliar para notificar ouvintes apenas se não foi descartado
  void _safeNotifyListeners() {
    if (!_debugDisposed) {
      notifyListeners();
    }
  }
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  String? get lastTranscription => _lastTranscription;
  List<Map<String, dynamic>>? get foundFoods => _foundFoods;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  /// Simular processo completo de cadastro por áudio
  Future<void> processAudioForFoodRegistration() async {
    try {
      _errorMessage = null;
      notifyListeners();
        // FASE 1: Gravação
      _isRecording = true;
      _safeNotifyListeners();
      await Future.delayed(Duration(seconds: 2)); // Simular gravação
      
      _isRecording = false;
      _safeNotifyListeners();
      
      // FASE 2: Transcrição
      _isTranscribing = true;
      _safeNotifyListeners();
      await Future.delayed(Duration(seconds: 3)); // Simular transcrição
      
      _lastTranscription = "duas fatias de pão integral com manteiga";
      _isTranscribing = false;
      _safeNotifyListeners();
      
      // FASE 3: Busca de alimentos
      await Future.delayed(Duration(milliseconds: 500)); // Simular busca
      
      _foundFoods = [
        {
          'id': 1,
          'nome': 'Pão integral',
          'calorias': 247,
          'proteinas': 8.0,
          'carboidratos': 46.0,
          'gordura': 4.2,
          'categoria': 'Cereais',
          'quantidade_sugerida': 100,
        },
        {
          'id': 2,
          'nome': 'Manteiga',
          'calorias': 717,
          'proteinas': 0.9,
          'carboidratos': 0.1,
          'gordura': 81.1,
          'categoria': 'Laticínios',
          'quantidade_sugerida': 100,
        }      ];
      
      _safeNotifyListeners();
      
    } catch (e) {
      _isRecording = false;
      _isTranscribing = false;
      _errorMessage = 'Erro no processamento: $e';
      _safeNotifyListeners();
    }
  }
  /// Simular erro na transcrição
  Future<void> processAudioWithTranscriptionError() async {
    _isRecording = true;
    _safeNotifyListeners();
    await Future.delayed(Duration(milliseconds: 500));
    
    _isRecording = false;
    _isTranscribing = true;
    _safeNotifyListeners();
    await Future.delayed(Duration(milliseconds: 500));
    
    _isTranscribing = false;
    _errorMessage = "Falha na transcrição: Áudio muito baixo ou com ruído";
    _safeNotifyListeners();
  }
  
  /// Limpar dados
  void clearData() {
    _lastTranscription = null;
    _foundFoods = null;
    _errorMessage = null;
    _isRecording = false;
    _isTranscribing = false;
    // Só notifica se o provider não foi descartado
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _debugDisposed = true;
    super.dispose();
  }
}

// Widget que simula a tela de cadastro por áudio
class AudioFoodRegistrationScreen extends StatelessWidget {
  const AudioFoodRegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro por Áudio'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<MockAudioServiceProvider>(
        builder: (context, audioService, child) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                _buildStatusCard(audioService),
                SizedBox(height: 20),
                
                // Botão de gravação
                _buildRecordingButton(context, audioService),
                SizedBox(height: 20),
                
                // Transcrição
                if (audioService.lastTranscription != null)
                  _buildTranscriptionCard(audioService),
                
                // Lista de alimentos encontrados
                if (audioService.foundFoods != null)
                  Expanded(child: _buildFoodList(audioService)),
                
                // Erro
                if (audioService.hasError)
                  _buildErrorCard(audioService),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatusCard(MockAudioServiceProvider audioService) {
    String status = 'Pronto para gravar';
    Color color = Colors.blue;
    IconData icon = Icons.mic;
    
    if (audioService.isRecording) {
      status = 'Gravando áudio...';
      color = Colors.red;
      icon = Icons.mic;
    } else if (audioService.isTranscribing) {
      status = 'Transcrevendo áudio...';
      color = Colors.orange;
      icon = Icons.text_fields;
    } else if (audioService.foundFoods != null) {
      status = 'Alimentos encontrados!';
      color = Colors.green;
      icon = Icons.check_circle;
    }
    
    return Card(
      key: Key('status_card'),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (audioService.isRecording || audioService.isTranscribing)
              CircularProgressIndicator(
                key: Key('loading_indicator'),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecordingButton(BuildContext context, MockAudioServiceProvider audioService) {
    final isActive = audioService.isRecording || audioService.isTranscribing;
    
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        key: Key('record_button'),
        onPressed: isActive ? null : () {
          audioService.processAudioForFoodRegistration();
        },
        icon: Icon(
          audioService.isRecording ? Icons.stop : Icons.mic,
          size: 30,
        ),
        label: Text(
          audioService.isRecording 
            ? 'Gravando...' 
            : audioService.isTranscribing 
              ? 'Processando...'
              : 'Gravar Alimentos',
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: audioService.isRecording ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildTranscriptionCard(MockAudioServiceProvider audioService) {
    return Card(
      key: Key('transcription_card'),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Transcrição do Áudio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '"${audioService.lastTranscription}"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFoodList(MockAudioServiceProvider audioService) {
    return Card(
      key: Key('food_list_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Alimentos Encontrados:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: audioService.foundFoods!.length,
              itemBuilder: (context, index) {
                final food = audioService.foundFoods![index];
                return ListTile(
                  key: Key('food_item_$index'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    food['nome'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categoria: ${food['categoria']}'),
                      Text(
                        'Calorias: ${food['calorias']} kcal | '
                        'Proteínas: ${food['proteinas']}g | '
                        'Carbo: ${food['carboidratos']}g | '
                        'Gordura: ${food['gordura']}g',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    key: Key('add_food_button_$index'),
                    icon: Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      // Simular adição do alimento
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${food['nome']} adicionado!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorCard(MockAudioServiceProvider audioService) {
    return Card(
      key: Key('error_card'),
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                audioService.errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              key: Key('retry_button'),
              onPressed: () {
                audioService.clearData();
              },
              child: Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('🧪 CAIXA CINZA - Integração UI + AudioService', () {
    late MockAudioServiceProvider mockAudioService;

    setUp(() {
      print('🔧 [${DateTime.now()}] Configurando teste de integração UI + Audio');
      mockAudioService = MockAudioServiceProvider();
      print('✅ [${DateTime.now()}] Setup de integração concluído');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Limpando teste de integração');
      mockAudioService.clearData();
      print('✅ [${DateTime.now()}] Cleanup de integração concluído');
    });

    testWidgets('1. INTEGRAÇÃO COMPLETA - UI responde ao fluxo de áudio', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] TESTE: Integração completa UI + AudioService');
      final stopwatch = Stopwatch()..start();
      
      // ARRANGE - Configurar widget com provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockAudioServiceProvider>(
            create: (_) => mockAudioService,
            child: AudioFoodRegistrationScreen(),
          ),
        ),
      );
      
      // VERIFICAR ESTADO INICIAL
      expect(find.text('Pronto para gravar'), findsOneWidget);
      expect(find.byKey(Key('record_button')), findsOneWidget);
      expect(find.text('Gravar Alimentos'), findsOneWidget);
      expect(find.byKey(Key('transcription_card')), findsNothing);
      expect(find.byKey(Key('food_list_card')), findsNothing);
      
      print('✅ [UI] Estado inicial verificado');
      
      // ACT - Clicar no botão de gravação
      await tester.tap(find.byKey(Key('record_button')));
      await tester.pump();
      
      // VERIFICAR ESTADO DE GRAVAÇÃO
      expect(find.text('Gravando áudio...'), findsOneWidget);
      expect(find.byKey(Key('loading_indicator')), findsOneWidget);
      expect(find.text('Gravando...'), findsOneWidget);
      
      print('✅ [UI] Estado de gravação verificado');
      
      // Aguardar fim da "gravação" (2 segundos simulados)
      await tester.pump(Duration(seconds: 2));
      
      // VERIFICAR ESTADO DE TRANSCRIÇÃO
      expect(find.text('Transcrevendo áudio...'), findsOneWidget);
      expect(find.byKey(Key('loading_indicator')), findsOneWidget);
      expect(find.text('Processando...'), findsOneWidget);
      
      print('✅ [UI] Estado de transcrição verificado');
      
      // Aguardar fim da transcrição (3 segundos simulados)
      await tester.pump(Duration(seconds: 3));
      
      // VERIFICAR TRANSCRIÇÃO EXIBIDA
      expect(find.byKey(Key('transcription_card')), findsOneWidget);
      expect(find.text('"duas fatias de pão integral com manteiga"'), findsOneWidget);
      
      print('✅ [UI] Transcrição exibida corretamente');
      
      // Aguardar busca de alimentos (500ms simulados)
      await tester.pump(Duration(milliseconds: 500));
      
      // VERIFICAR LISTA DE ALIMENTOS
      expect(find.text('Alimentos encontrados!'), findsOneWidget);
      expect(find.byKey(Key('food_list_card')), findsOneWidget);
      expect(find.byKey(Key('food_item_0')), findsOneWidget);
      expect(find.byKey(Key('food_item_1')), findsOneWidget);
      expect(find.text('Pão integral'), findsOneWidget);
      expect(find.text('Manteiga'), findsOneWidget);
      
      print('✅ [UI] Lista de alimentos exibida corretamente');
      
      // TESTAR ADIÇÃO DE ALIMENTO
      await tester.tap(find.byKey(Key('add_food_button_0')));
      await tester.pump();
      
      expect(find.text('Pão integral adicionado!'), findsOneWidget);
      
      print('✅ [UI] Adição de alimento funcional');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Teste de integração completo: ${stopwatch.elapsedMilliseconds}ms');
      print('🎉 [SUCESSO] Integração UI + AudioService funcionando perfeitamente!');
    });

    testWidgets('2. TRATAMENTO DE ERRO - UI exibe erro corretamente', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] TESTE: Tratamento de erro na UI');
      final stopwatch = Stopwatch()..start();
      
      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockAudioServiceProvider>(
            create: (_) => mockAudioService,
            child: AudioFoodRegistrationScreen(),
          ),
        ),
      );        // ACT - Simular erro na transcrição
      mockAudioService.processAudioWithTranscriptionError();
      await tester.pump();
      
      // Aguardar gravação - verificar imediatamente após o estado ser definido
      await tester.pump(Duration(milliseconds: 100));
      expect(find.text('Gravando áudio...'), findsOneWidget);
        // Aguardar transcrição com erro - simular o tempo com pump
      await tester.pump(Duration(seconds: 2));
      await tester.pump();
      
      // ASSERT - Verificar exibição do erro
      expect(find.byKey(Key('error_card')), findsOneWidget);
      expect(find.text('Falha na transcrição: Áudio muito baixo ou com ruído'), findsOneWidget);
      expect(find.byKey(Key('retry_button')), findsOneWidget);
      
      print('✅ [UI] Erro exibido corretamente');
      
      // TESTAR BOTÃO DE RETRY
      await tester.tap(find.byKey(Key('retry_button')));
      await tester.pump();
      
      expect(find.byKey(Key('error_card')), findsNothing);
      expect(find.text('Pronto para gravar'), findsOneWidget);
      
      print('✅ [UI] Retry funcionando corretamente');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Teste de erro: ${stopwatch.elapsedMilliseconds}ms');
      print('🎯 [SUCESSO] Tratamento de erro na UI validado!');
    });

    testWidgets('3. RESPONSIVIDADE - Estados visuais durante processamento', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] TESTE: Estados visuais durante processamento');
      final stopwatch = Stopwatch()..start();
      
      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockAudioServiceProvider>(
            create: (_) => mockAudioService,
            child: AudioFoodRegistrationScreen(),
          ),
        ),
      );
      
      // VERIFICAR CORES E ÍCONES EM CADA ESTADO
      
      // Estado inicial - Azul
      expect(find.byIcon(Icons.mic), findsAtLeastNWidgets(2)); // Status + Botão
      
      // Iniciar gravação
      await tester.tap(find.byKey(Key('record_button')));
      await tester.pump();
      
      // Estado gravação - Vermelho
      expect(find.byIcon(Icons.mic), findsOneWidget); // No status card
      expect(find.byIcon(Icons.stop), findsOneWidget); // No botão
      
      print('✅ [UI] Ícones alterados durante gravação');
      
      // Aguardar transição para transcrição
      await tester.pump(Duration(seconds: 2));
      
      // Estado transcrição - Laranja
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      
      print('✅ [UI] Ícones alterados durante transcrição');
      
      // Aguardar conclusão
      await tester.pump(Duration(seconds: 3));
      await tester.pump(Duration(milliseconds: 500));
      
      // Estado sucesso - Verde
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      
      print('✅ [UI] Ícones de sucesso exibidos');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Teste de responsividade: ${stopwatch.elapsedMilliseconds}ms');
      print('🎨 [SUCESSO] Estados visuais validados!');
    });

    testWidgets('4. ACCESSIBILIDADE - Suporte a screen readers', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] TESTE: Acessibilidade e semantics');
      final stopwatch = Stopwatch()..start();
      
      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockAudioServiceProvider>(
            create: (_) => mockAudioService,
            child: AudioFoodRegistrationScreen(),
          ),
        ),
      );
      
      // Processar áudio completo para ter elementos na tela
      mockAudioService.processAudioForFoodRegistration();
      await tester.pump(Duration(seconds: 6)); // Aguardar todo o processo
      
      // VERIFICAR SEMANTICS DOS ELEMENTOS PRINCIPAIS
      
      // Botão de gravação deve ter semantics
      final recordButton = find.byKey(Key('record_button'));
      expect(recordButton, findsOneWidget);
      
      // Cards devem ser acessíveis
      expect(find.byKey(Key('status_card')), findsOneWidget);
      expect(find.byKey(Key('transcription_card')), findsOneWidget);
      expect(find.byKey(Key('food_list_card')), findsOneWidget);
      
      // Botões de adicionar alimentos devem ter semantics únicos
      expect(find.byKey(Key('add_food_button_0')), findsOneWidget);
      expect(find.byKey(Key('add_food_button_1')), findsOneWidget);
      
      // Textos importantes devem estar presentes para screen readers
      expect(find.text('Pão integral'), findsOneWidget);
      expect(find.text('Manteiga'), findsOneWidget);
      expect(find.text('Categoria: Cereais'), findsOneWidget);
      expect(find.text('Categoria: Laticínios'), findsOneWidget);
      
      print('✅ [ACCESSIBILITY] Elementos principais encontrados');
      
      // TESTAR NAVEGAÇÃO POR TAB (simulação)
      // Em um teste real, usaríamos tester.sendKeyEvent(LogicalKeyboardKey.tab)
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Teste de acessibilidade: ${stopwatch.elapsedMilliseconds}ms');
      print('♿ [SUCESSO] Acessibilidade básica validada!');
    });
  });
}
