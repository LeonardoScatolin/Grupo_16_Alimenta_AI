import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AlimentaAPIService {
  // Singleton instance
  static final AlimentaAPIService _instance = AlimentaAPIService._internal();
  factory AlimentaAPIService() => _instance;
  AlimentaAPIService._internal();

  // Token de autenticação atual
  String? _currentToken;

  // Definir token de autenticação
  void setAuthToken(String? token) {
    _currentToken = token;
    debugPrint(
        '🔑 Token definido: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
  }

  // Obter token atual
  String? get currentToken => _currentToken; // Base URL da API
  String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3333'; // Para Android Emulator
    } else {
      return 'http://127.0.0.1:3333'; // Para Windows/iOS Simulator/Desktop
    }
  }

  // Headers padrão
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
  // Headers com autenticação usando token atual
  Map<String, String> get _headersWithAuth {
    final headers = Map<String, String>.from(_headers);
    if (_currentToken != null) {
      headers['Authorization'] = 'Bearer $_currentToken';
    }
    return headers;
  }

  // ===============================================
  // 🔐 AUTENTICAÇÃO
  // ===============================================
  /// Login de paciente
  Future<Map<String, dynamic>> loginPaciente(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/paciente/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Login de nutricionista
  Future<Map<String, dynamic>> loginNutri(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nutri/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===============================================
  // 🍎 REGISTRO DE ALIMENTOS E IA
  // ===============================================  /// Processar áudio de refeição com IA
  Future<Map<String, dynamic>> processarAudioRefeicao({
    required String audioFilePath,
    required int pacienteId,
    required int nutriId,
    String? tipoRefeicao,
    String? observacoes,
  }) async {
    try {
      debugPrint('🎵 Processando áudio: $audioFilePath');

      // Para Windows e outras plataformas desktop, sempre usar base64
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return _processarAudioBase64(
          audioFilePath: audioFilePath,
          pacienteId: pacienteId,
          nutriId: nutriId,
          tipoRefeicao: tipoRefeicao,
          observacoes: observacoes,
        );
      }

      // Para mobile (Android/iOS), usar MultipartFile
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ia/processar-audio-refeicao'),
      );

      // Adicionar headers de autenticação ao request
      request.headers.addAll(_headersWithAuth);

      // Adicionar arquivo de áudio
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFilePath),
      );

      // Adicionar campos
      request.fields['paciente_id'] = pacienteId.toString();
      request.fields['nutri_id'] = nutriId.toString();
      if (tipoRefeicao != null) request.fields['tipo_refeicao'] = tipoRefeicao;
      if (observacoes != null) request.fields['observacoes'] = observacoes;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(responseData)};
      } else {
        return {
          'success': false,
          'error': 'Erro ao processar áudio: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Processar áudio usando base64 (para web/desktop)
  Future<Map<String, dynamic>> _processarAudioBase64({
    required String audioFilePath,
    required int pacienteId,
    required int nutriId,
    String? tipoRefeicao,
    String? observacoes,
  }) async {
    try {
      debugPrint('📄 Processando arquivo base64: $audioFilePath');

      // Para web, não podemos processar arquivos locais diretamente
      if (kIsWeb) {
        debugPrint('❌ Processamento de áudio via base64 não suportado na web');
        return {
          'success': false,
          'error':
              'Processamento de áudio não suportado na plataforma web. Use em dispositivo móvel ou desktop.'
        };
      }

      // Verificar se o arquivo existe antes de tentar lê-lo (apenas plataformas nativas)
      final file = File(audioFilePath);
      if (!await file.exists()) {
        debugPrint('❌ Arquivo não encontrado: $audioFilePath');
        return {'success': false, 'error': 'Arquivo de áudio não encontrado'};
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint('❌ Arquivo de áudio vazio');
        return {'success': false, 'error': 'Arquivo de áudio vazio'};
      }

      final base64Audio = base64Encode(bytes);
      debugPrint('✅ Áudio convertido para base64 (${bytes.length} bytes)');

      // Enviar como JSON
      final response = await http.post(
        Uri.parse('$baseUrl/ia/processar-audio-refeicao-base64'),
        headers: _headersWithAuth,
        body: jsonEncode({
          'audio_base64': base64Audio,
          'paciente_id': pacienteId,
          'nutri_id': nutriId,
          'tipo_refeicao': tipoRefeicao,
          'observacoes': observacoes,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('💥 Erro ao processar base64: $e');
      return _handleError(e);
    }
  }

  /// Buscar alimentos similares
  Future<Map<String, dynamic>> buscarAlimentos(String nome) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/alimentos/buscar?nome=${Uri.encodeComponent(nome)}',
        ),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Calcular macros manualmente
  Future<Map<String, dynamic>> calcularMacros({
    required String nomeAlimento,
    required double quantidade,
    required int pacienteId,
    required int nutriId,
    String? tipoRefeicao,
    String? observacoes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/alimentos/calcular-macros'),
        headers: _headers,
        body: jsonEncode({
          'nome_alimento': nomeAlimento,
          'quantidade': quantidade,
          'paciente_id': pacienteId,
          'nutri_id': nutriId,
          'tipo_refeicao': tipoRefeicao ?? 'outro',
          'observacoes': observacoes,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===============================================
  // 📊 REGISTRO DIÁRIO E RESUMOS
  // ===============================================
  /// Obter resumo diário (meta vs consumo)
  Future<Map<String, dynamic>> obterResumoDiario(
    int pacienteId, [
    String? data,
  ]) async {
    try {
      String url = '$baseUrl/resumo-diario/$pacienteId';
      if (data != null) {
        url += '?data=$data';
      }

      final response =
          await http.get(Uri.parse(url), headers: _headersWithAuth);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Obter histórico de registros
  Future<Map<String, dynamic>> obterHistoricoRegistros(
    int pacienteId, [
    int dias = 7,
  ]) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/registro-diario/historico/$pacienteId?dias=$dias'),
        headers: _headersWithAuth,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Zerar registro do dia
  Future<Map<String, dynamic>> zerarRegistroDia(
    int pacienteId, [
    String? data,
  ]) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro-diario/zerar/$pacienteId'),
        headers: _headersWithAuth,
        body: jsonEncode({
          'data': data ?? DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Subtrair macros (quando usuário remove alimento)
  Future<Map<String, dynamic>> subtrairMacros({
    required int pacienteId,
    required double proteina,
    required double carboidrato,
    required double gordura,
    required double calorias,
    String? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro-diario/subtrair/$pacienteId'),
        headers: _headersWithAuth,
        body: jsonEncode({
          'proteina': proteina,
          'carboidrato': carboidrato,
          'gordura': gordura,
          'calorias': calorias,
          'data': data ?? DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===============================================
  // 🍽️ REGISTROS DETALHADOS DE ALIMENTOS
  // ===============================================

  /// Obter alimentos detalhados por refeição
  Future<Map<String, dynamic>> obterAlimentosPorRefeicao({
    required int pacienteId,
    required String tipoRefeicao,
    String? data,
  }) async {
    try {
      final dataParam = data ?? DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse(
            '$baseUrl/alimentos-detalhados/refeicao/$pacienteId?tipo_refeicao=$tipoRefeicao&data=$dataParam'),
        headers: _headersWithAuth,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Remover alimento detalhado específico
  Future<Map<String, dynamic>> removerAlimentoDetalhado(int registroId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/alimentos-detalhados/$registroId'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===============================================
  // 🎯 METAS NUTRICIONAIS
  // ===============================================  /// Obter meta atual do paciente
  Future<Map<String, dynamic>> obterMeta(int pacienteId, int nutriId,
      [String? data]) async {
    try {
      String url = '$baseUrl/dieta/meta/$pacienteId/$nutriId';
      if (data != null) {
        url += '/$data';
      }

      final response =
          await http.get(Uri.parse(url), headers: _headersWithAuth);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Obter histórico de metas
  Future<Map<String, dynamic>> obterHistoricoMetas(int pacienteId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dieta/meta/historico/$pacienteId'),
        headers: _headersWithAuth,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===============================================
  // 📈 ESTATÍSTICAS
  // ===============================================

  /// Obter estatísticas mensais
  Future<Map<String, dynamic>> obterEstatisticasMensais(
    int pacienteId,
    int ano,
    int mes,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/registro-diario/estatisticas/$pacienteId?ano=$ano&mes=$mes',
        ),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===============================================
  // 🛠️ MÉTODOS AUXILIARES
  // ===============================================
  /// Processar resposta HTTP
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('📡 Status da resposta: ${response.statusCode}');
    debugPrint('📄 Corpo da resposta: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);

        // VERIFICAR O STATUS INTERNO DA RESPOSTA (backend usa 'status')
        if (data['status'] == false) {
          return {
            'success': false,
            'error': data['message'] ?? data['error'] ?? 'Erro no login',
            'statusCode': response.statusCode,
          };
        }

        // Se status é true, retornar os dados diretamente
        return {
          'success': true,
          'data': data, // Retorna a resposta completa do backend
          'statusCode': response.statusCode,
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Erro ao processar resposta do servidor',
          'statusCode': response.statusCode,
        };
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error':
              errorData['message'] ?? errorData['error'] ?? 'Erro no servidor',
          'statusCode': response.statusCode,
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Erro do servidor (${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    }
  }

  /// Tratar erros de conexão
  Map<String, dynamic> _handleError(dynamic error) {
    debugPrint('💥 Erro de conexão: $error');
    return {
      'success': false,
      'error': 'Erro de conexão com o servidor',
    };
  }

  Future<bool> verificarConexao() async {
    try {
      debugPrint('🔍 Verificando conexão com o servidor...');

      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      final isConnected = response.statusCode == 200;
      debugPrint(isConnected ? '✅ Servidor online' : '❌ Servidor offline');

      return isConnected;
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      return false;
    }
  }

  // ===============================================
  // 📊 NUTRIÇÃO E METAS (PÚBLICO)
  // ===============================================

  /// Buscar metas do paciente - PÚBLICO (sem autenticação)
  Future<Map<String, dynamic>> buscarMetasPublicas({
    required int pacienteId,
    required int nutriId,
    String? data,
  }) async {
    try {
      final dataParam = data ?? _formatDate(DateTime.now());

      final response = await http.get(
        Uri.parse('$baseUrl/public/meta/$pacienteId/$nutriId/$dataParam'),
        headers: _headers, // Headers sem token
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===============================================
  // 🍽️ ALIMENTOS DETALHADOS
  // ===============================================

  /// Obter alimentos detalhados por data
  Future<Map<String, dynamic>> obterAlimentosDetalhados(int pacienteId,
      [String? data]) async {
    try {
      debugPrint('🔍 Buscando alimentos detalhados para paciente $pacienteId');

      final dataParam = data ?? _formatDate(DateTime.now());
      debugPrint('📅 Data da busca: $dataParam');
      final url =
          '$baseUrl/alimentos-detalhados/data/$pacienteId?data=$dataParam';
      debugPrint('🌐 URL da requisição: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _headers, // Headers sem token (rota pública)
      );

      final result = _handleResponse(response);

      if (result['success']) {
        debugPrint('✅ Alimentos detalhados obtidos com sucesso');
        debugPrint('📊 Dados retornados: ${result['data']}');
      } else {
        debugPrint('❌ Erro ao obter alimentos detalhados: ${result['error']}');
      }

      return result;
    } catch (e) {
      debugPrint('💥 Erro ao buscar alimentos detalhados: $e');
      return _handleError(e);
    }
  }

  /// Salvar alimento detalhado no backend
  Future<Map<String, dynamic>> salvarAlimentoDetalhado(
      Map<String, dynamic> alimentoData) async {
    try {
      debugPrint(
          '💾 Salvando alimento no backend: ${alimentoData['nomeAlimento']}'); // Preparar dados para o endpoint /alimentos/calcular-macros
      final payload = {
        'nome_alimento': alimentoData['nomeAlimento'],
        'quantidade': alimentoData['quantidade'],
        'paciente_id': alimentoData['pacienteId'],
        'nutri_id': alimentoData['nutriId'],
        'tipo_refeicao': alimentoData['tipoRefeicao'] ?? 'outro',
        'data_consumo': alimentoData['dataConsumo'], // 🔥 NOVA: Data específica
        'observacoes': alimentoData['observacoes'],
      };

      debugPrint('📤 Payload enviado: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/alimentos/calcular-macros'),
        headers: _headers,
        body: json.encode(payload),
      );

      final result = _handleResponse(response);

      if (result['success'] == true) {
        debugPrint('✅ Alimento salvo com sucesso no backend');
      } else {
        debugPrint('❌ Erro ao salvar alimento: ${result['error']}');
      }

      return result;
    } catch (e) {
      debugPrint('💥 Erro ao salvar alimento: $e');
      return _handleError(e);
    }
  }

  /// Formatar data para API (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
