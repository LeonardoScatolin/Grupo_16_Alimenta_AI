import 'package:flutter/foundation.dart';
import 'alimenta_api_service.dart';
import '../models/alimenta_api_models.dart';

class NutricaoService extends ChangeNotifier {
  // Usar uma instância singleton do AlimentaAPIService
  static final AlimentaAPIService _apiService = AlimentaAPIService();

  // Estado atual
  ResumoDiario? _resumoAtual;
  bool _isLoading = false;
  String? _error;
  int? _pacienteId;
  int? _nutriId;

  // Getters
  ResumoDiario? get resumoAtual => _resumoAtual;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get pacienteId => _pacienteId;
  int? get nutriId => _nutriId;

  // Getter para acessar o APIService
  AlimentaAPIService get apiService => _apiService;

  // Configurar IDs dos usuários
  void configurarUsuarios(int pacienteId, int nutriId) {
    _pacienteId = pacienteId;
    _nutriId = nutriId;
    notifyListeners();
  }

  // Limpar estado
  void limparEstado() {
    _resumoAtual = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ===============================================
  // 🍎 REGISTRO DE ALIMENTOS VIA ÁUDIO
  // ===============================================

  /// Processar áudio de refeição
  Future<ResultadoProcessamentoAudio?> processarAudioRefeicao({
    required String audioFilePath,
    String? tipoRefeicao,
    String? observacoes,
  }) async {
    if (_pacienteId == null || _nutriId == null) {
      _error = 'IDs de paciente e nutricionista não configurados';
      notifyListeners();
      return null;
    }

    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.processarAudioRefeicao(
        audioFilePath: audioFilePath,
        pacienteId: _pacienteId!,
        nutriId: _nutriId!,
        tipoRefeicao: tipoRefeicao,
        observacoes: observacoes,
      );

      if (result['success']) {
        final processamento =
            ResultadoProcessamentoAudio.fromJson(result['data']);

        // Atualizar resumo se disponível
        if (processamento.resumoDiario != null) {
          _resumoAtual = processamento.resumoDiario;
        }

        _setLoading(false);
        return processamento;
      } else {
        _error = result['error'] ?? 'Erro ao processar áudio';
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return null;
    }
  }

  // ===============================================
  // 🧮 REGISTRO MANUAL DE ALIMENTOS
  // ===============================================

  /// Calcular e registrar macros manualmente
  Future<bool> registrarAlimentoManual({
    required String nomeAlimento,
    required double quantidade,
    String? tipoRefeicao,
    String? observacoes,
  }) async {
    if (_pacienteId == null || _nutriId == null) {
      _error = 'IDs de paciente e nutricionista não configurados';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.calcularMacros(
        nomeAlimento: nomeAlimento,
        quantidade: quantidade,
        pacienteId: _pacienteId!,
        nutriId: _nutriId!,
        tipoRefeicao: tipoRefeicao,
        observacoes: observacoes,
      );

      if (result['success']) {
        // Atualizar resumo automaticamente
        await atualizarResumoDiario();
        _setLoading(false);
        return true;
      } else {
        _error = result['error'] ?? 'Erro ao registrar alimento';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Buscar alimentos similares
  Future<List<AlimentoEncontrado>> buscarAlimentos(String nome) async {
    if (nome.trim().isEmpty) return [];

    try {
      final result = await _apiService.buscarAlimentos(nome);

      if (result['success']) {
        final data = result['data'];
        if (data['alimentos'] != null) {
          final alimentosList = data['alimentos'] as List;
          return alimentosList
              .map((item) => AlimentoEncontrado.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar alimentos: $e');
      return [];
    }
  }

  // ===============================================
  // 📊 RESUMO E ESTATÍSTICAS
  // ===============================================
  /// Obter resumo diário (meta vs consumo)
  Future<void> atualizarResumoDiario([String? data]) async {
    if (_pacienteId == null) {
      _error = 'ID do paciente não configurado';
      notifyListeners();
      return;
    }

    debugPrint('🔄 Atualizando resumo diário para paciente $_pacienteId');
    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.obterResumoDiario(_pacienteId!, data);
      debugPrint('📄 Resposta completa da API: $result');
      debugPrint('📄 Tipo do campo data: ${result['data']?.runtimeType}');

      if (result['success']) {
        final apiData = result['data'];
        debugPrint('📋 Dados recebidos do campo data: $apiData');
        debugPrint('📋 Estrutura do JSON: ${apiData?.keys?.toList()}');

        // Tentar criar o ResumoDiario com logs detalhados
        try {
          _resumoAtual = ResumoDiario.fromJson(apiData);
          debugPrint('✅ ResumoDiario criado com sucesso');
          debugPrint('✅ Meta calorias: ${_resumoAtual?.metaDiaria.calorias}');
          debugPrint(
              '✅ Consumo calorias: ${_resumoAtual?.consumoAtual.calorias}');
        } catch (parseError) {
          debugPrint('💥 Erro ao fazer parse do ResumoDiario: $parseError');
          debugPrint('💥 Stack trace: ${parseError.toString()}');
          _error = 'Erro ao processar dados da API: $parseError';
        }

        _setLoading(false);
      } else {
        _error = result['error'] ?? 'Erro ao obter resumo';
        debugPrint('❌ Erro na API: $_error');
        _setLoading(false);
      }
    } catch (e) {
      _error = 'Erro inesperado: $e';
      debugPrint('💥 Erro inesperado: $e');
      _setLoading(false);
    }
  }

  /// Obter histórico de registros
  Future<List<RegistroHistorico>> obterHistorico([int dias = 7]) async {
    if (_pacienteId == null) {
      _error = 'ID do paciente não configurado';
      notifyListeners();
      return [];
    }

    try {
      final result =
          await _apiService.obterHistoricoRegistros(_pacienteId!, dias);

      if (result['success']) {
        final historico = HistoricoRegistros.fromJson(result['data']);
        return historico.historico;
      } else {
        _error = result['error'] ?? 'Erro ao obter histórico';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = 'Erro inesperado: $e';
      notifyListeners();
      return [];
    }
  }

  // ===============================================
  // 🛠️ OPERAÇÕES AUXILIARES
  // ===============================================

  /// Zerar registro do dia
  Future<bool> zerarRegistroDia([String? data]) async {
    if (_pacienteId == null) {
      _error = 'ID do paciente não configurado';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.zerarRegistroDia(_pacienteId!, data);

      if (result['success']) {
        // Atualizar resumo automaticamente
        await atualizarResumoDiario();
        _setLoading(false);
        return true;
      } else {
        _error = result['error'] ?? 'Erro ao zerar registro';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Remover alimento (subtrair macros)
  Future<bool> removerAlimento({
    required double proteina,
    required double carboidrato,
    required double gordura,
    required double calorias,
    String? data,
  }) async {
    if (_pacienteId == null) {
      _error = 'ID do paciente não configurado';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.subtrairMacros(
        pacienteId: _pacienteId!,
        proteina: proteina,
        carboidrato: carboidrato,
        gordura: gordura,
        calorias: calorias,
        data: data,
      );

      if (result['success']) {
        // Atualizar resumo automaticamente
        await atualizarResumoDiario();
        _setLoading(false);
        return true;
      } else {
        _error = result['error'] ?? 'Erro ao remover alimento';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  // ===============================================
  // 📈 METAS E ESTATÍSTICAS
  // ===============================================  /// Obter meta atual
  Future<MetaDiaria?> obterMeta([String? data]) async {
    if (_pacienteId == null || _nutriId == null) {
      _error = 'IDs do paciente e nutricionista não configurados';
      notifyListeners();
      return null;
    }

    try {
      final result = await _apiService.obterMeta(_pacienteId!, _nutriId!, data);

      if (result['success']) {
        // Verificar se 'data' é um Map ou String
        var metaData = result['data'];

        if (metaData is String) {
          // Se for string, pode ser JSON que precisa ser decodificado
          debugPrint('⚠️ Meta retornada como string: $metaData');
          return null; // Por enquanto, retornar null para strings
        } else if (metaData is Map<String, dynamic>) {
          // Acessar a estrutura correta da API
          final dietaData = metaData['dieta'] ?? metaData['meta'] ?? metaData;
          debugPrint('📊 Dados da meta: $dietaData');
          return MetaDiaria.fromJson(dietaData);
        } else {
          debugPrint('⚠️ Tipo inesperado para meta: ${metaData.runtimeType}');
          return null;
        }
      } else {
        _error = result['error'] ?? 'Erro ao obter meta';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Erro inesperado: $e';
      notifyListeners();
      return null;
    }
  }

  // ===============================================
  // 📊 METAS NUTRICIONAIS
  // ===============================================

  /// Buscar metas sem necessidade de autenticação
  Future<MetaDiaria?> buscarMetasPublicas({
    int? pacienteIdOverride,
    int? nutriIdOverride,
    String? data,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      // Usar IDs fornecidos ou os configurados no serviço
      final pId = pacienteIdOverride ?? _pacienteId;
      final nId = nutriIdOverride ?? _nutriId;

      if (pId == null || nId == null) {
        throw Exception('IDs de paciente e nutricionista são obrigatórios');
      }

      final response = await _apiService.buscarMetasPublicas(
        pacienteId: pId,
        nutriId: nId,
        data: data,
      );

      if (response['success'] == true && response['meta'] != null) {
        final meta = MetaDiaria.fromJson(response['meta']);
        debugPrint(
            '✅ Metas carregadas: ${meta.calorias} cal, ${meta.proteina}g prot');
        return meta;
      } else {
        _error = response['error'] ?? 'Erro ao buscar metas';
        return null;
      }
    } catch (e) {
      _error = 'Erro ao buscar metas: $e';
      debugPrint('❌ Erro ao buscar metas: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar se o servidor está online
  Future<bool> verificarConexao() async {
    return await _apiService.verificarConexao();
  }

  // ===============================================
  // 🛠️ MÉTODOS AUXILIARES PRIVADOS
  // ===============================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Métodos para compatibilidade com o código existente
  int get totalDailyCalories =>
      _resumoAtual?.consumoAtual.totalDailyCalories ?? 0;
  int get proteinTotal => _resumoAtual?.consumoAtual.proteinTotal ?? 0;
  int get fatTotal => _resumoAtual?.consumoAtual.fatTotal ?? 0;
  int get carbsTotal => _resumoAtual?.consumoAtual.carbsTotal ?? 0;

  int get caloriesGoal => _resumoAtual?.metaDiaria.caloriesGoal ?? 2500;
  int get proteinGoal => _resumoAtual?.metaDiaria.proteinGoal ?? 200;
  int get fatGoal => _resumoAtual?.metaDiaria.fatGoal ?? 140;
  int get carbsGoal => _resumoAtual?.metaDiaria.carbsGoal ?? 400;

  // Percentuais para os progress bars
  double get caloriesProgress => caloriesGoal > 0
      ? (totalDailyCalories / caloriesGoal).clamp(0.0, 1.0)
      : 0.0;
  double get proteinProgress =>
      proteinGoal > 0 ? (proteinTotal / proteinGoal).clamp(0.0, 1.0) : 0.0;
  double get fatProgress =>
      fatGoal > 0 ? (fatTotal / fatGoal).clamp(0.0, 1.0) : 0.0;
  double get carbsProgress =>
      carbsGoal > 0 ? (carbsTotal / carbsGoal).clamp(0.0, 1.0) : 0.0;
}
