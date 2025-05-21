import 'package:flutter/foundation.dart';

class WeightRecord {
  final DateTime date;
  final double weight;

  WeightRecord({required this.date, required this.weight});
}

class WeightService with ChangeNotifier {
  static final WeightService _instance = WeightService._internal();

  factory WeightService() {
    return _instance;
  }

  WeightService._internal() {
    _loadInitialData();
  }

  // Lista de registros de peso (persistirá entre telas)
  final List<WeightRecord> _weightRecords = [];

  List<WeightRecord> get weightRecords => List.unmodifiable(_weightRecords);

  // Retorna o último peso registrado ou um valor padrão se não houver registros
  double get lastWeight {
    if (_weightRecords.isEmpty) {
      return 0.0;
    }
    // Ordena por data (mais recente primeiro) e retorna o primeiro
    _weightRecords.sort((a, b) => b.date.compareTo(a.date));
    return _weightRecords.first.weight;
  }

  // Carrega dados iniciais (apenas para demonstração)
  void _loadInitialData() {
    final now = DateTime.now();
    // Se já tem dados, não carrega novamente
    if (_weightRecords.isNotEmpty) return;

    // Adicionando alguns dados iniciais para demonstração
    _weightRecords.addAll([
      WeightRecord(
        date: now.subtract(const Duration(days: 35)),
        weight: 85.0,
      ),
      WeightRecord(
        date: now.subtract(const Duration(days: 28)),
        weight: 84.2,
      ),
      WeightRecord(
        date: now.subtract(const Duration(days: 21)),
        weight: 83.5,
      ),
      WeightRecord(
        date: now.subtract(const Duration(days: 14)),
        weight: 82.1,
      ),
      WeightRecord(
        date: now.subtract(const Duration(days: 7)),
        weight: 81.0,
      ),
      WeightRecord(
        date: now,
        weight: 80.5,
      ),
    ]);

    // Ordenando por data (mais recente primeiro)
    _weightRecords.sort((a, b) => b.date.compareTo(a.date));
  }

  // Adicionar novo registro de peso
  void addWeightRecord(double weight) {
    _weightRecords.insert(
      0,
      WeightRecord(
        date: DateTime.now(),
        weight: weight,
      ),
    );
    notifyListeners();
  }

  // Remover um registro de peso
  void removeWeightRecord(int index) {
    if (index >= 0 && index < _weightRecords.length) {
      _weightRecords.removeAt(index);
      notifyListeners();
    }
  }

  // Calcular a diferença de peso
  double calculateWeightDifference() {
    if (_weightRecords.length >= 2) {
      final currentWeight = _weightRecords.first.weight;
      final startWeight = _weightRecords.last.weight;
      return currentWeight - startWeight;
    }
    return 0;
  }
}
