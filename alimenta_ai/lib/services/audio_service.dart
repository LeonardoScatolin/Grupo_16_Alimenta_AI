import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class AudioService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
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

      // Para Windows, usar um path simples no diretório atual
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String recordingPath;

      if (kIsWeb) {
        // Para web, usar nome simples
        recordingPath = 'recording_$timestamp.wav';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        // Para Windows, usar diretório temporário do sistema
        recordingPath = 'C:\\Windows\\Temp\\recording_$timestamp.wav';
      } else {
        // Para outras plataformas, tentar path_provider
        try {
          final directory = await getTemporaryDirectory();
          recordingPath = '${directory.path}/recording_$timestamp.wav';
        } catch (e) {
          debugPrint('! Fallback: usando diretório atual');
          recordingPath = 'recording_$timestamp.wav';
        }
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

  /// Parar gravação de áudio
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      await _recorder.stop();
      _isRecording = false;

      debugPrint('🔴 Gravação finalizada: $_currentRecordingPath');
      debugPrint('⏱️ Duração: ${_recordingDuration.inSeconds}s');

      notifyListeners();
      return _currentRecordingPath;
    } catch (e) {
      debugPrint('❌ Erro ao parar gravação: $e');
      _isRecording = false;
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
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Arquivo deletado: $_currentRecordingPath');
        }
      } catch (e) {
        debugPrint('❌ Erro ao deletar arquivo: $e');
      }
    }

    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

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
}
