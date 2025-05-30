import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:alimenta_ai/config/openai_config.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static String _apiKey = OpenAIConfig.apiKey;

  final Dio _dio = Dio();

  OpenAIService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'multipart/form-data',
    };
    _dio.options.connectTimeout = OpenAIConfig.connectTimeout;
    _dio.options.receiveTimeout = OpenAIConfig.receiveTimeout;
  }

  /// Transcreve um arquivo de áudio usando o Whisper da OpenAI
  Future<String?> transcribeAudio(String audioFilePath) async {
    try {
      debugPrint('🎯 Iniciando transcrição do áudio: $audioFilePath');

      // Para web, tratar de forma diferente
      if (kIsWeb) {
        return await _transcribeAudioWeb(audioFilePath);
      }

      // Para plataformas nativas
      final file = File(audioFilePath);
      if (!file.existsSync()) {
        debugPrint('❌ Arquivo de áudio não encontrado: $audioFilePath');
        return null;
      }

      // Verificar tamanho do arquivo
      final fileSize = await file.length();
      debugPrint('📊 Tamanho do arquivo: ${fileSize} bytes');

      if (fileSize == 0) {
        debugPrint('❌ Arquivo de áudio está vazio');
        return null;
      }

      // Preparar o FormData
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.wav',
          contentType: DioMediaType('audio', 'wav'),
        ),
        'model': OpenAIConfig.model,
        'language': OpenAIConfig.language,
        'response_format': 'text',
        'temperature': OpenAIConfig.temperature,
      });

      debugPrint('🚀 Enviando áudio para OpenAI Whisper...');

      // Fazer a requisição
      final response = await _dio.post(
        '/audio/transcriptions',
        data: formData,
      );

      if (response.statusCode == 200) {
        final transcription = response.data.toString().trim();
        debugPrint('✅ Transcrição recebida: $transcription');
        return transcription;
      } else {
        debugPrint('❌ Erro na resposta da API: ${response.statusCode}');
        debugPrint('Resposta: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('❌ Erro DioException na transcrição:');
      debugPrint('Tipo: ${e.type}');
      debugPrint('Mensagem: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Erro inesperado na transcrição: $e');
      return null;
    }
  }

  /// Transcrição específica para web
  Future<String?> _transcribeAudioWeb(String audioFilePath) async {
    try {
      debugPrint('🌐 Processando áudio para web: $audioFilePath');

      // TODO: Implementar suporte para web se necessário
      // Por enquanto, retornar erro amigável
      debugPrint('❌ Transcrição não suportada na web no momento');
      return 'Transcrição não suportada na plataforma web. Use em dispositivo móvel ou desktop.';
    } catch (e) {
      debugPrint('❌ Erro na transcrição web: $e');
      return null;
    }
  }

  /// Transcreve um arquivo de áudio com resposta detalhada (JSON)
  Future<Map<String, dynamic>?> transcribeAudioDetailed(
      String audioFilePath) async {
    try {
      debugPrint('🎯 Iniciando transcrição detalhada do áudio: $audioFilePath');

      final file = File(audioFilePath);
      if (!file.existsSync()) {
        debugPrint('❌ Arquivo de áudio não encontrado: $audioFilePath');
        return null;
      }
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.wav',
        ),
        'model': OpenAIConfig.model,
        'language': OpenAIConfig.language,
        'response_format': 'verbose_json', // Retorna JSON detalhado
        'temperature': OpenAIConfig.temperature,
        'timestamp_granularities[]': 'word', // Timestamps por palavra
      });

      debugPrint('🚀 Enviando áudio para OpenAI Whisper (modo detalhado)...');

      final response = await _dio.post(
        '/audio/transcriptions',
        data: formData,
      );

      if (response.statusCode == 200) {
        final result = response.data as Map<String, dynamic>;
        debugPrint('✅ Transcrição detalhada recebida');
        return result;
      } else {
        debugPrint('❌ Erro na resposta da API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro na transcrição detalhada: $e');
      return null;
    }
  }

  /// Atualizar a API key (para configuração dinâmica)
  void updateApiKey(String newApiKey) {
    _apiKey = newApiKey;
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    debugPrint('🔑 API Key atualizada no OpenAI Service');
  }

  /// Verificar se a API key está configurada
  bool get isApiKeyConfigured {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_OPENAI_API_KEY';
  }
}
