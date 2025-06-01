import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:alimenta_ai/services/openai_service.dart';
import 'package:dio/dio.dart';

class AudioService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final OpenAIService _openAIService = OpenAIService();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isTranscribing = false;
  String? _currentRecordingPath;
  String? _lastTranscription;
  Map<String, dynamic>? _lastFoodSearchResult; // 🆕 Resultado da última busca
  String?
      _currentMealType; // 🆕 Tipo de refeição atual (Café da Manhã, Almoço, etc.)
  Duration _recordingDuration = Duration.zero; // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isTranscribing => _isTranscribing;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get lastTranscription => _lastTranscription;
  Map<String, dynamic>? get lastFoodSearchResult =>
      _lastFoodSearchResult; // 🆕 Getter para resultado da busca
  String? get currentMealType =>
      _currentMealType; // 🆕 Getter para tipo de refeição atual
  Duration get recordingDuration => _recordingDuration;

  /// Verificar e solicitar permissões de microfone
  Future<bool> checkAndRequestPermissions() async {
    if (kIsWeb) {
      // Para web, usar a API nativa do navegador
      try {
        final hasPermission = await _recorder.hasPermission();
        debugPrint('🌐 Permissão de microfone na web: $hasPermission');
        return hasPermission;
      } catch (e) {
        debugPrint('❌ Erro ao verificar permissão na web: $e');
        return false;
      }
    }

    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    return status.isGranted;
  }

  /// Iniciar gravação de áudio
  Future<bool> startRecording() async {
    try {
      // Verificar permissões
      if (!await checkAndRequestPermissions()) {
        debugPrint('❌ Permissão de microfone negada');
        return false;
      }

      // Criar diretório de áudios se não existir
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String recordingPath;

      if (kIsWeb) {
        // Para web, usar nome simples
        recordingPath = 'recording_$timestamp.wav';
      } else {
        // Para todas as plataformas nativas, usar um diretório persistente
        recordingPath = await _createAudioStoragePath(timestamp);
      }

      _currentRecordingPath = recordingPath;

      // Configurar gravação
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Iniciar gravação
      await _recorder.start(config, path: _currentRecordingPath!);

      _isRecording = true;
      _recordingDuration = Duration.zero;

      // Iniciar timer para duração
      _startDurationTimer();

      debugPrint('🎤 Gravação iniciada: $_currentRecordingPath');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao iniciar gravação: $e');
      return false;
    }
  }

  /// Parar gravação de áudio e transcrever automaticamente
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      await _recorder.stop();
      _isRecording = false;

      debugPrint('🔴 Gravação finalizada: $_currentRecordingPath');
      debugPrint('⏱️ Duração: ${_recordingDuration.inSeconds}s');

      // Verificar se o arquivo foi criado corretamente
      if (_currentRecordingPath != null) {
        final fileExists = await _ensureAudioFileExists(_currentRecordingPath!);
        if (!fileExists) {
          debugPrint('❌ Arquivo de áudio não foi criado corretamente');
          _currentRecordingPath = null;
        } else {
          // Fazer limpeza de arquivos antigos
          await cleanOldAudioFiles();
        }
      }

      notifyListeners();

      // Transcrever automaticamente apenas se não estivermos na web
      if (_currentRecordingPath != null && !kIsWeb) {
        await _transcribeCurrentRecording();
      } else if (kIsWeb) {
        debugPrint('🌐 Na web - transcrição automática desabilitada');
        debugPrint(
            '💡 Use a transcrição manual ou execute em dispositivo móvel/desktop');
      }

      return _currentRecordingPath;
    } catch (e) {
      debugPrint('❌ Erro ao parar gravação: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Transcrever a gravação atual usando OpenAI
  Future<void> _transcribeCurrentRecording() async {
    if (_currentRecordingPath == null) return;

    try {
      _isTranscribing = true;
      _lastTranscription = null;
      notifyListeners();

      debugPrint('🤖 Iniciando transcrição do áudio...');

      final transcription =
          await _openAIService.transcribeAudio(_currentRecordingPath!);

      if (transcription != null && transcription.isNotEmpty) {
        _lastTranscription = transcription;
        debugPrint(
            '✅ Transcrição concluída: $transcription'); // 🎯 BUSCAR ALIMENTOS AUTOMATICAMENTE APÓS TRANSCRIÇÃO
        debugPrint('🔍 =================================');
        debugPrint('🔍 INICIANDO BUSCA AUTOMÁTICA...');
        debugPrint('🔍 Transcrição recebida: "$transcription"');
        debugPrint('🔍 =================================');

        try {
          final searchResult =
              await buscarAlimentosPorTranscricao(transcription);

          debugPrint('🔍 =================================');
          debugPrint('🔍 RESULTADO DA BUSCA AUTOMÁTICA:');
          if (searchResult != null) {
            debugPrint('🔍 Status: ${searchResult['status']}');
            if (searchResult['status'] == true) {
              final alimentos = searchResult['alimentos'] as List?;
              debugPrint(
                  '✅ Busca automática concluída: ${alimentos?.length ?? 0} alimentos encontrados');
              if (alimentos != null && alimentos.isNotEmpty) {
                debugPrint('✅ Primeiro alimento: ${alimentos[0]['nome']}');
              }
              // Salvar resultado para acesso posterior
              _lastFoodSearchResult = searchResult;
            } else {
              debugPrint('❌ Busca retornou status false');
              debugPrint(
                  '❌ Erro: ${searchResult['error'] ?? 'Erro desconhecido'}');
            }
          } else {
            debugPrint('❌ Busca automática falhou - resultado nulo');
          }
          debugPrint('🔍 =================================');
        } catch (searchError) {
          debugPrint('❌ =================================');
          debugPrint('❌ ERRO NA BUSCA AUTOMÁTICA:');
          debugPrint('❌ Tipo: ${searchError.runtimeType}');
          debugPrint('❌ Mensagem: $searchError');
          debugPrint('❌ =================================');
        }
      } else {
        debugPrint('❌ Falha na transcrição - resultado vazio');
      }
    } catch (e) {
      debugPrint('❌ Erro durante transcrição: $e');
    } finally {
      _isTranscribing = false;
      notifyListeners();
    }
  }

  /// Transcrever um arquivo específico (método público)
  Future<String?> transcribeAudio(String audioPath) async {
    try {
      _isTranscribing = true;
      notifyListeners();

      final transcription = await _openAIService.transcribeAudio(audioPath);

      _isTranscribing = false;
      notifyListeners();

      return transcription;
    } catch (e) {
      debugPrint('❌ Erro na transcrição: $e');
      _isTranscribing = false;
      notifyListeners();
      return null;
    }
  }

  /// Reproduzir áudio gravado
  Future<void> playRecording() async {
    if (_currentRecordingPath == null) {
      debugPrint('❌ Arquivo de áudio não encontrado');
      return;
    }

    // Para web, não verificar existência do arquivo
    if (!kIsWeb && !File(_currentRecordingPath!).existsSync()) {
      debugPrint('❌ Arquivo de áudio não encontrado');
      return;
    }

    try {
      _isPlaying = true;
      notifyListeners();

      await _player.setFilePath(_currentRecordingPath!);
      await _player.play();

      // Escutar quando terminar
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          notifyListeners();
        }
      });

      debugPrint('▶️ Reproduzindo áudio: $_currentRecordingPath');
    } catch (e) {
      debugPrint('❌ Erro ao reproduzir áudio: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Parar reprodução
  Future<void> stopPlaying() async {
    try {
      await _player.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao parar reprodução: $e');
    }
  }

  /// Deletar gravação atual
  Future<void> deleteCurrentRecording() async {
    if (_currentRecordingPath != null) {
      try {
        if (!kIsWeb) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Arquivo deletado: $_currentRecordingPath');
          } else {
            debugPrint(
                '⚠️ Arquivo não encontrado para deletar: $_currentRecordingPath');
          }
        }
      } catch (e) {
        debugPrint('❌ Erro ao deletar arquivo: $e');
      }
    }

    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
    _lastTranscription = null;
    notifyListeners();
  }

  /// Limpar apenas a transcrição
  void clearTranscription() {
    _lastTranscription = null;
    notifyListeners();
  }

  /// Configurar API key da OpenAI
  void setOpenAIApiKey(String apiKey) {
    _openAIService.updateApiKey(apiKey);
    debugPrint('🔑 API Key configurada para transcrição');
  }

  /// Verificar se a API key está configurada
  bool get isOpenAIConfigured => _openAIService.isApiKeyConfigured;

  /// Timer para duração da gravação
  void _startDurationTimer() {
    Stream.periodic(const Duration(seconds: 1), (i) => i).listen((count) {
      if (_isRecording) {
        _recordingDuration = Duration(seconds: count + 1);
        notifyListeners();
      }
    });
  }

  /// Limpar recursos
  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  /// Verificar se há gravação disponível
  bool get hasRecording =>
      _currentRecordingPath != null &&
      File(_currentRecordingPath!).existsSync();

  /// Formatar duração para exibição
  String get formattedDuration {
    final minutes = _recordingDuration.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (_recordingDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Criar caminho de armazenamento persistente para áudios
  Future<String> _createAudioStoragePath(int timestamp) async {
    try {
      Directory? storageDir;

      if (defaultTargetPlatform == TargetPlatform.windows) {
        // Para Windows, criar diretório na pasta Documents do usuário
        final documentsPath = Platform.environment['USERPROFILE'] ?? 'C:\\';
        storageDir = Directory('$documentsPath\\alimenta_ai_audios');
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        // Para mobile, usar diretório de aplicação permanente
        storageDir = await getApplicationDocumentsDirectory();
        storageDir = Directory('${storageDir.path}/audios');
      } else {
        // Para outras plataformas, usar temporary directory
        storageDir = await getTemporaryDirectory();
        storageDir = Directory('${storageDir.path}/audios');
      }

      // Criar diretório se não existir
      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
        debugPrint('📁 Diretório de áudios criado: ${storageDir.path}');
      }

      final fileName = 'recording_$timestamp.wav';
      final fullPath = '${storageDir.path}/$fileName';

      debugPrint('💾 Caminho de armazenamento: $fullPath');
      return fullPath;
    } catch (e) {
      debugPrint('❌ Erro ao criar caminho de armazenamento: $e');
      // Fallback para diretório atual
      return 'recording_$timestamp.wav';
    }
  }

  /// Verificar se o arquivo de áudio existe e criar backup se necessário
  Future<bool> _ensureAudioFileExists(String filePath) async {
    if (kIsWeb) return true; // Na web não podemos verificar arquivos locais

    try {
      final file = File(filePath);
      final exists = await file.exists();

      if (exists) {
        final size = await file.length();
        debugPrint('✅ Arquivo verificado: $filePath ($size bytes)');
        return true;
      } else {
        debugPrint('❌ Arquivo não encontrado: $filePath');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar arquivo: $e');
      return false;
    }
  }

  /// Listar todos os áudios armazenados localmente
  Future<List<String>> getStoredAudioFiles() async {
    try {
      if (kIsWeb) return []; // Na web não temos acesso ao sistema de arquivos

      Directory? storageDir;

      if (defaultTargetPlatform == TargetPlatform.windows) {
        final documentsPath = Platform.environment['USERPROFILE'] ?? 'C:\\';
        storageDir = Directory('$documentsPath\\alimenta_ai_audios');
      } else {
        storageDir = await getApplicationDocumentsDirectory();
        storageDir = Directory('${storageDir.path}/audios');
      }

      if (!await storageDir.exists()) {
        return [];
      }

      final files = storageDir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.wav'))
          .map((entity) => entity.path)
          .toList();

      debugPrint('📋 Arquivos de áudio encontrados: ${files.length}');
      return files;
    } catch (e) {
      debugPrint('❌ Erro ao listar arquivos: $e');
      return [];
    }
  }

  /// Limpar arquivos antigos (manter apenas os últimos 10)
  Future<void> cleanOldAudioFiles() async {
    try {
      final files = await getStoredAudioFiles();

      if (files.length <= 10) return; // Manter até 10 arquivos

      // Ordenar por data de modificação (mais antigos primeiro)
      files.sort((a, b) {
        final fileA = File(a);
        final fileB = File(b);
        return fileA.lastModifiedSync().compareTo(fileB.lastModifiedSync());
      });

      // Deletar os arquivos mais antigos
      final filesToDelete = files.take(files.length - 10);

      for (final filePath in filesToDelete) {
        try {
          await File(filePath).delete();
          debugPrint('🗑️ Arquivo antigo removido: $filePath');
        } catch (e) {
          debugPrint('❌ Erro ao remover arquivo $filePath: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro na limpeza de arquivos: $e');
    }
  }

  /// Verificar saúde do sistema de áudios
  Future<Map<String, dynamic>> checkAudioSystemHealth() async {
    final result = <String, dynamic>{
      'permissions': false,
      'storage_accessible': false,
      'stored_files_count': 0,
      'current_recording_exists': false,
      'openai_configured': false,
      'platform': defaultTargetPlatform.name,
    };

    try {
      // Verificar permissões
      result['permissions'] = await checkAndRequestPermissions();

      // Verificar OpenAI
      result['openai_configured'] = isOpenAIConfigured;

      // Verificar acesso ao armazenamento
      if (!kIsWeb) {
        try {
          final files = await getStoredAudioFiles();
          result['stored_files_count'] = files.length;
          result['storage_accessible'] = true;

          // Verificar se a gravação atual existe
          if (_currentRecordingPath != null) {
            result['current_recording_exists'] =
                await _ensureAudioFileExists(_currentRecordingPath!);
          }
        } catch (e) {
          result['storage_error'] = e.toString();
        }
      } else {
        result['storage_accessible'] =
            true; // Na web consideramos sempre acessível
      }
    } catch (e) {
      result['system_error'] = e.toString();
    }

    return result;
  }

  /// 🎯 NOVA FUNÇÃO: Buscar alimentos no backend usando texto transcrito
  Future<Map<String, dynamic>?> buscarAlimentosPorTranscricao(
      String textoTranscrito) async {
    try {
      debugPrint('🔍 =================================');
      debugPrint('🔍 INICIANDO BUSCA DE ALIMENTOS');
      debugPrint('🔍 Texto transcrito: "$textoTranscrito"');
      debugPrint(
          '🔍 ================================='); // URL do backend - detectar plataforma automaticamente
      String backendUrl;
      if (defaultTargetPlatform == TargetPlatform.android) {
        backendUrl = 'http://10.0.2.2:3333'; // Para Android Emulator
      } else {
        backendUrl = 'http://127.0.0.1:3333'; // Para Windows/iOS/Desktop
      }
      final String url = '$backendUrl/alimento/buscar-por-transcricao';

      debugPrint('🌐 Plataforma: ${defaultTargetPlatform.name}');
      debugPrint('🌐 URL da requisição: $url');

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      // Dados da requisição
      final requestData = {
        'texto_transcrito': textoTranscrito,
        'limite': 10,
      };

      debugPrint('📦 Dados da requisição: $requestData');
      debugPrint('⏱️ Enviando requisição POST...');

      // Fazer requisição POST para a nova rota
      final response = await dio.post(
        url,
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      debugPrint('📡 Status da resposta: ${response.statusCode}');
      debugPrint('📡 Headers da resposta: ${response.headers}');

      if (response.statusCode == 200) {
        final result = response.data as Map<String, dynamic>;
        debugPrint('✅ Busca concluída com sucesso!');
        debugPrint(
            '✅ Alimentos encontrados: ${result['alimentos']?.length ?? 0}');
        debugPrint('✅ Dados completos: $result');
        return result;
      } else {
        debugPrint('❌ Erro na busca - Status: ${response.statusCode}');
        debugPrint('❌ Resposta: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('❌ =================================');
      debugPrint('❌ ERRO DE CONEXÃO DIO:');
      debugPrint('❌ Tipo: ${e.type}');
      debugPrint('❌ Mensagem: ${e.message}');
      debugPrint('❌ URL: ${e.requestOptions.uri}');
      debugPrint('❌ Método: ${e.requestOptions.method}');
      debugPrint('❌ Headers: ${e.requestOptions.headers}');
      debugPrint('❌ Data: ${e.requestOptions.data}');
      if (e.response != null) {
        debugPrint('❌ Response Status: ${e.response?.statusCode}');
        debugPrint('❌ Response Data: ${e.response?.data}');
        debugPrint('❌ Response Headers: ${e.response?.headers}');
      }
      debugPrint('❌ =================================');
      return null;
    } catch (e) {
      debugPrint('❌ =================================');
      debugPrint('❌ ERRO INESPERADO:');
      debugPrint('❌ Tipo: ${e.runtimeType}');
      debugPrint('❌ Mensagem: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      debugPrint('❌ =================================');
      return null;
    }
  }

  /// 🎯 Transcrever e buscar alimentos automaticamente
  Future<Map<String, dynamic>?> transcribeAndSearchFood() async {
    try {
      // Se não há transcrição disponível, tentar transcrever primeiro
      if (_lastTranscription == null && _currentRecordingPath != null) {
        await _transcribeCurrentRecording();
      }

      // Se ainda não há transcrição, retornar erro
      if (_lastTranscription == null || _lastTranscription!.isEmpty) {
        debugPrint('❌ Nenhuma transcrição disponível para busca');
        return {
          'status': false,
          'error': 'Nenhuma transcrição disponível. Grave um áudio primeiro.',
        };
      }

      // Buscar alimentos baseado na transcrição
      final result = await buscarAlimentosPorTranscricao(_lastTranscription!);

      if (result != null) {
        return {
          'status': true,
          'transcricao_usada': _lastTranscription,
          ...result,
        };
      } else {
        return {
          'status': false,
          'error': 'Erro ao buscar alimentos no backend',
          'transcricao_usada': _lastTranscription,
        };
      }
    } catch (e) {
      debugPrint('❌ Erro no fluxo transcrever e buscar: $e');
      return {
        'status': false,
        'error': 'Erro inesperado: $e',
      };
    }
  }

  /// 🎯 Definir o tipo de refeição atual (para associar áudio gravado à refeição correta)
  void setCurrentMealType(String? mealType) {
    _currentMealType = mealType;
    debugPrint('🍽️ Tipo de refeição definido: $_currentMealType');
    notifyListeners();
  }

  /// 🎯 Limpar dados da sessão de gravação anterior
  void clearSession() {
    _lastTranscription = null;
    _lastFoodSearchResult = null;
    _currentMealType = null;
    debugPrint('🧹 Sessão de gravação limpa');
    notifyListeners();
  }

  /// 🎯 Converter resultado da busca em dados estruturados para a interface
  List<Map<String, dynamic>>? getStructuredFoodData() {
    debugPrint('🔍 DEBUG getStructuredFoodData:');
    debugPrint('🔍   _lastFoodSearchResult: $_lastFoodSearchResult');

    if (_lastFoodSearchResult == null) {
      debugPrint('🔍   ❌ _lastFoodSearchResult é null');
      return null;
    }

    debugPrint('🔍   Status: ${_lastFoodSearchResult!['status']}');

    if (_lastFoodSearchResult!['status'] != true) {
      debugPrint('🔍   ❌ Status não é true');
      return null;
    }

    if (_lastFoodSearchResult!['alimentos'] == null) {
      debugPrint('🔍   ❌ Campo alimentos é null');
      return null;
    }

    final alimentos = _lastFoodSearchResult!['alimentos'] as List;
    debugPrint('🔍   ✅ Encontrados ${alimentos.length} alimentos');

    return alimentos.map((alimento) {
      return {
        'id': alimento['id'],
        'nome': alimento['nome'],
        'calorias': alimento['calorias'] ?? 0,
        'proteinas': alimento['proteinas'] ?? 0.0,
        'carboidratos': alimento['carboidratos'] ?? 0.0,
        'gordura': alimento['gordura'] ?? 0.0,
        'categoria': alimento['categoria'] ?? 'Não informado',
        'codigo': alimento['codigo'] ?? '',
        'quantidade_sugerida': 100, // Quantidade padrão em gramas
        'transcricao_origem': _lastTranscription,
        'tipo_refeicao': _currentMealType,
      };
    }).toList();
  }

  /// 🎯 Obter o primeiro alimento encontrado (mais relevante)
  Map<String, dynamic>? getPrimaryFoodData() {
    final foods = getStructuredFoodData();
    return foods?.isNotEmpty == true ? foods!.first : null;
  }

  /// 🎯 Buscar alimentos usando a transcrição já disponível (sem retranscrever)
  Future<Map<String, dynamic>?> searchFoodFromExistingTranscription() async {
    if (_lastTranscription == null || _lastTranscription!.isEmpty) {
      debugPrint('❌ Nenhuma transcrição disponível para busca');
      return null;
    }

    try {
      debugPrint(
          '🔍 Buscando alimentos para transcrição existente: $_lastTranscription');
      final result = await buscarAlimentosPorTranscricao(_lastTranscription!);

      if (result != null) {
        _lastFoodSearchResult = result;
        debugPrint('✅ Busca de alimentos concluída com sucesso');
        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint('❌ Erro ao buscar alimentos: $e');
      return null;
    }
  }
}
