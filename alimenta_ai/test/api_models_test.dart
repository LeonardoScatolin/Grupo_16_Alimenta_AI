import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/models/alimenta_api_models.dart';

void main() {
  group('API Models Tests', () {
    test('ResumoDiario should parse API response correctly', () {
      // Exemplo da resposta real da API
      final jsonResponse = {
        "data": "2025-05-28",
        "paciente_id": 1,
        "meta": {
          "kcal": 2000,
          "proteina": 150,
          "carboidrato": 250,
          "gordura": 67
        },
        "consumo": {"kcal": 0, "proteina": 0, "carboidrato": 0, "gordura": 0},
        "restante": {
          "proteina": 150,
          "carboidrato": 250,
          "gordura": 67,
          "kcal": 2000
        },
        "percentuais": {
          "proteina": 0,
          "carboidrato": 0,
          "gordura": 0,
          "kcal": 0
        }
      };

      final resumo = ResumoDiario.fromJson(jsonResponse);

      expect(resumo.data, '2025-05-28');
      expect(resumo.metaDiaria.calorias, 2000);
      expect(resumo.metaDiaria.proteina, 150);
      expect(resumo.metaDiaria.carbo, 250);
      expect(resumo.metaDiaria.gordura, 67);

      expect(resumo.consumoAtual.calorias, 0);
      expect(resumo.consumoAtual.proteina, 0);
      expect(resumo.consumoAtual.carbo, 0);
      expect(resumo.consumoAtual.gordura, 0);

      expect(resumo.restante.calorias, 2000);
      expect(resumo.restante.proteina, 150);
      expect(resumo.restante.carbo, 250);
      expect(resumo.restante.gordura, 67);
    });
  });
}
