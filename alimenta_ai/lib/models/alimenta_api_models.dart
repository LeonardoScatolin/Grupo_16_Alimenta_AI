import 'package:flutter/foundation.dart';

/// Modelo para resumo diário (meta vs consumo)
class ResumoDiario {
  final String data;
  final MetaDiaria metaDiaria;
  final ConsumoAtual consumoAtual;
  final MacrosRestantes restante;
  final PercentualAtingido percentualAtingido;
  final bool registroEncontrado;

  ResumoDiario({
    required this.data,
    required this.metaDiaria,
    required this.consumoAtual,
    required this.restante,
    required this.percentualAtingido,
    required this.registroEncontrado,
  });

  factory ResumoDiario.fromJson(Map<String, dynamic> json) {
    // Debug logging completo
    debugPrint('🔍 Parsing ResumoDiario from JSON: $json');
    debugPrint('🔍 JSON keys: ${json.keys.toList()}');
    debugPrint('🔍 Data field type: ${json['data']?.runtimeType}');
    debugPrint('🔍 Data field content: ${json['data']}');

    // Extrair a data de forma segura
    String dataValue = '';
    final dataField = json['data'];
    if (dataField is String) {
      dataValue = dataField;
    } else if (dataField is Map) {
      // Se 'data' é um Map, pode ser que contenha uma data como string
      dataValue = dataField['data']?.toString() ??
          dataField['date']?.toString() ??
          DateTime.now().toString().split(' ')[0];
    } else {
      dataValue = DateTime.now().toString().split(' ')[0];
    }

    // Verificar se os dados estão no nível raiz ou dentro de um campo 'data'
    Map<String, dynamic> dadosNutricionais = json;
    if (json['data'] is Map<String, dynamic>) {
      dadosNutricionais = json['data'] as Map<String, dynamic>;
      debugPrint('🔍 Dados estão dentro do campo data: $dadosNutricionais');
    }

    // Extrair campos de nutrição
    final metaData = dadosNutricionais['meta'] ??
        dadosNutricionais['metaDiaria'] ??
        json['meta'] ??
        {};
    final consumoData = dadosNutricionais['consumo'] ??
        dadosNutricionais['consumoAtual'] ??
        json['consumo'] ??
        {};
    final restanteData = dadosNutricionais['restante'] ??
        dadosNutricionais['macrosRestantes'] ??
        json['restante'] ??
        {};
    final percentuaisData = dadosNutricionais['percentuais'] ??
        dadosNutricionais['percentualAtingido'] ??
        json['percentuais'] ??
        {};

    debugPrint('📊 Meta: $metaData');
    debugPrint('🍽️ Consumo: $consumoData');
    debugPrint('📈 Restante: $restanteData');
    debugPrint('📉 Percentuais: $percentuaisData');

    return ResumoDiario(
      data: dataValue,
      metaDiaria: MetaDiaria.fromJson(metaData),
      consumoAtual: ConsumoAtual.fromJson(consumoData),
      restante: MacrosRestantes.fromJson(restanteData),
      percentualAtingido: PercentualAtingido.fromJson(percentuaisData),
      registroEncontrado: json['registro_encontrado'] ??
          dadosNutricionais['registro_encontrado'] ??
          true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'meta_diaria': metaDiaria.toJson(),
      'consumo_atual': consumoAtual.toJson(),
      'restante': restante.toJson(),
      'percentual_atingido': percentualAtingido.toJson(),
      'registro_encontrado': registroEncontrado,
    };
  }
}

/// Modelo para meta diária definida pela nutricionista
class MetaDiaria {
  final double proteina;
  final double carbo;
  final double gordura;
  final double calorias;

  MetaDiaria({
    required this.proteina,
    required this.carbo,
    required this.gordura,
    required this.calorias,
  });
  factory MetaDiaria.fromJson(Map<String, dynamic> json) {
    return MetaDiaria(
      proteina: (json['proteina'] ?? 0).toDouble(),
      carbo: (json['carboidrato'] ?? json['carbo'] ?? 0).toDouble(),
      gordura: (json['gordura'] ?? 0).toDouble(),
      calorias: (json['kcal'] ?? json['calorias'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proteina': proteina,
      'carbo': carbo,
      'gordura': gordura,
      'calorias': calorias,
    };
  }

  // Getters para compatibilidade com o código existente
  int get proteinGoal => proteina.round();
  int get carbsGoal => carbo.round();
  int get fatGoal => gordura.round();
  int get caloriesGoal => calorias.round();
}

/// Modelo para consumo atual do dia
class ConsumoAtual {
  final double proteina;
  final double carbo;
  final double gordura;
  final double calorias;

  ConsumoAtual({
    required this.proteina,
    required this.carbo,
    required this.gordura,
    required this.calorias,
  });
  factory ConsumoAtual.fromJson(Map<String, dynamic> json) {
    return ConsumoAtual(
      proteina: (json['proteina'] ?? 0).toDouble(),
      carbo: (json['carboidrato'] ?? json['carbo'] ?? 0).toDouble(),
      gordura: (json['gordura'] ?? 0).toDouble(),
      calorias: (json['kcal'] ?? json['calorias'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proteina': proteina,
      'carbo': carbo,
      'gordura': gordura,
      'calorias': calorias,
    };
  }

  // Getters para compatibilidade com o código existente
  int get proteinTotal => proteina.round();
  int get carbsTotal => carbo.round();
  int get fatTotal => gordura.round();
  int get totalDailyCalories => calorias.round();
}

/// Modelo para macros restantes
class MacrosRestantes {
  final double proteina;
  final double carbo;
  final double gordura;
  final double calorias;

  MacrosRestantes({
    required this.proteina,
    required this.carbo,
    required this.gordura,
    required this.calorias,
  });
  factory MacrosRestantes.fromJson(Map<String, dynamic> json) {
    return MacrosRestantes(
      proteina: (json['proteina'] ?? 0).toDouble(),
      carbo: (json['carboidrato'] ?? json['carbo'] ?? 0).toDouble(),
      gordura: (json['gordura'] ?? 0).toDouble(),
      calorias: (json['kcal'] ?? json['calorias'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proteina': proteina,
      'carbo': carbo,
      'gordura': gordura,
      'calorias': calorias,
    };
  }
}

/// Modelo para percentual atingido da meta
class PercentualAtingido {
  final int proteina;
  final int carbo;
  final int gordura;
  final int calorias;

  PercentualAtingido({
    required this.proteina,
    required this.carbo,
    required this.gordura,
    required this.calorias,
  });
  factory PercentualAtingido.fromJson(Map<String, dynamic> json) {
    return PercentualAtingido(
      proteina: (json['proteina'] ?? 0).toInt(),
      carbo: (json['carboidrato'] ?? json['carbo'] ?? 0).toInt(),
      gordura: (json['gordura'] ?? 0).toInt(),
      calorias: (json['kcal'] ?? json['calorias'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proteina': proteina,
      'carbo': carbo,
      'gordura': gordura,
      'calorias': calorias,
    };
  }
}

/// Modelo para resultado do processamento de áudio
class ResultadoProcessamentoAudio {
  final bool status;
  final String? error;
  final String? message;
  final ProcessamentoAudio? processamento;

  ResultadoProcessamentoAudio({
    required this.status,
    this.error,
    this.message,
    this.processamento,
  });

  factory ResultadoProcessamentoAudio.fromJson(Map<String, dynamic> json) {
    return ResultadoProcessamentoAudio(
      status: json['status'] ?? false,
      error: json['error'],
      message: json['message'],
      processamento: json['processamento'] != null
          ? ProcessamentoAudio.fromJson(json['processamento'])
          : null,
    );
  }

  // Getters para compatibilidade
  String? get transcricao => processamento?.transcricao;
  AlimentoExtraido? get alimentoExtraido => processamento?.alimentoExtraido;
  CalculoMacros? get calculoMacros => processamento?.calculoMacros;
  ResumoDiario? get resumoDiario => processamento?.resumoDiario;
}

/// Modelo para dados de processamento de áudio
class ProcessamentoAudio {
  final String? transcricao;
  final AlimentoExtraido? alimentoExtraido;
  final CalculoMacros? calculoMacros;
  final ResumoDiario? resumoDiario;

  ProcessamentoAudio({
    this.transcricao,
    this.alimentoExtraido,
    this.calculoMacros,
    this.resumoDiario,
  });

  factory ProcessamentoAudio.fromJson(Map<String, dynamic> json) {
    return ProcessamentoAudio(
      transcricao: json['transcricao'],
      alimentoExtraido: json['alimento_extraido'] != null
          ? AlimentoExtraido.fromJson(json['alimento_extraido'])
          : null,
      calculoMacros: json['calculo_macros'] != null
          ? CalculoMacros.fromJson(json['calculo_macros'])
          : null,
      resumoDiario: json['resumo_diario'] != null
          ? ResumoDiario.fromJson(json['resumo_diario'])
          : null,
    );
  }
}

/// Modelo para alimento extraído do áudio
class AlimentoExtraido {
  final String nome;
  final int quantidade;
  final double confianca;

  AlimentoExtraido({
    required this.nome,
    required this.quantidade,
    required this.confianca,
  });

  factory AlimentoExtraido.fromJson(Map<String, dynamic> json) {
    return AlimentoExtraido(
      nome: json['nome'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      confianca: (json['confianca'] ?? 0.0).toDouble(),
    );
  }
}

/// Modelo para cálculo de macros
class CalculoMacros {
  final bool status;
  final String? alimento;
  final int? quantidade;
  final MacrosNutricionais? macros;

  CalculoMacros({
    required this.status,
    this.alimento,
    this.quantidade,
    this.macros,
  });

  factory CalculoMacros.fromJson(Map<String, dynamic> json) {
    return CalculoMacros(
      status: json['status'] ?? false,
      alimento: json['alimento'],
      quantidade: json['quantidade'],
      macros: json['macros'] != null
          ? MacrosNutricionais.fromJson(json['macros'])
          : null,
    );
  }
}

/// Modelo para macros nutricionais
class MacrosNutricionais {
  final double calorias;
  final double proteina;
  final double carboidrato;
  final double gordura;

  MacrosNutricionais({
    required this.calorias,
    required this.proteina,
    required this.carboidrato,
    required this.gordura,
  });

  factory MacrosNutricionais.fromJson(Map<String, dynamic> json) {
    return MacrosNutricionais(
      calorias: (json['calorias'] ?? 0).toDouble(),
      proteina: (json['proteina'] ?? 0).toDouble(),
      carboidrato: (json['carboidrato'] ?? 0).toDouble(),
      gordura: (json['gordura'] ?? 0).toDouble(),
    );
  }
}

/// Modelo para alimento encontrado na base TACO
class AlimentoEncontrado {
  final int id;
  final String nome;
  final String categoria;

  AlimentoEncontrado({
    required this.id,
    required this.nome,
    required this.categoria,
  });

  factory AlimentoEncontrado.fromJson(Map<String, dynamic> json) {
    return AlimentoEncontrado(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? '',
      categoria: json['categoria'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'categoria': categoria};
  }
}

/// Modelo para macros calculados
class MacrosCalculados {
  final double calorias;
  final double proteinas;
  final double carboidratos;
  final double gordura;

  MacrosCalculados({
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gordura,
  });

  factory MacrosCalculados.fromJson(Map<String, dynamic> json) {
    return MacrosCalculados(
      calorias: (json['calorias'] ?? 0).toDouble(),
      proteinas: (json['proteinas'] ?? 0).toDouble(),
      carboidratos: (json['carboidratos'] ?? 0).toDouble(),
      gordura: (json['gordura'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calorias': calorias,
      'proteinas': proteinas,
      'carboidratos': carboidratos,
      'gordura': gordura,
    };
  }
}

/// Modelo para dados originais (100g)
class DadosOriginais100g {
  final double calorias;
  final double proteinas;
  final double carboidratos;
  final double gordura;

  DadosOriginais100g({
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gordura,
  });

  factory DadosOriginais100g.fromJson(Map<String, dynamic> json) {
    return DadosOriginais100g(
      calorias: (json['calorias'] ?? 0).toDouble(),
      proteinas: (json['proteinas'] ?? 0).toDouble(),
      carboidratos: (json['carboidratos'] ?? 0).toDouble(),
      gordura: (json['gordura'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calorias': calorias,
      'proteinas': proteinas,
      'carboidratos': carboidratos,
      'gordura': gordura,
    };
  }
}

/// Modelo para registro criado
class RegistroCriado {
  final String? registroId;
  final String dataConsumo;
  final String? horaConsumo;
  final String tipoRefeicao;
  final String origem;

  RegistroCriado({
    this.registroId,
    required this.dataConsumo,
    this.horaConsumo,
    required this.tipoRefeicao,
    required this.origem,
  });

  factory RegistroCriado.fromJson(Map<String, dynamic> json) {
    return RegistroCriado(
      registroId: json['registro_id']?.toString(),
      dataConsumo: json['data_consumo'] ?? '',
      horaConsumo: json['hora_consumo'],
      tipoRefeicao: json['tipo_refeicao'] ?? 'outro',
      origem: json['origem'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registro_id': registroId,
      'data_consumo': dataConsumo,
      'hora_consumo': horaConsumo,
      'tipo_refeicao': tipoRefeicao,
      'origem': origem,
    };
  }
}

/// Modelo para histórico de registros
class HistoricoRegistros {
  final bool status;
  final List<RegistroHistorico> historico;

  HistoricoRegistros({required this.status, required this.historico});

  factory HistoricoRegistros.fromJson(Map<String, dynamic> json) {
    final historicoList = json['historico'] as List<dynamic>? ?? [];
    return HistoricoRegistros(
      status: json['status'] ?? false,
      historico: historicoList
          .map((item) => RegistroHistorico.fromJson(item))
          .toList(),
    );
  }
}

/// Modelo para item do histórico
class RegistroHistorico {
  final String data;
  final MacrosCalculados macros;
  final String? ultimaAtualizacao;

  RegistroHistorico({
    required this.data,
    required this.macros,
    this.ultimaAtualizacao,
  });

  factory RegistroHistorico.fromJson(Map<String, dynamic> json) {
    return RegistroHistorico(
      data: json['data'] ?? '',
      macros: MacrosCalculados.fromJson(json['macros'] ?? {}),
      ultimaAtualizacao: json['ultima_atualizacao'],
    );
  }
}
