import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/services/nutricao_service.dart';
import 'package:alimenta_ai/services/alimenta_api_service.dart';

void main() {
  group('Food Persistence Tests', () {
    late NutricaoService nutricaoService;
    late AlimentaAPIService apiService;

    setUp(() {
      apiService = AlimentaAPIService();
      nutricaoService = NutricaoService();
      nutricaoService.apiService = apiService;
      nutricaoService.configurarUsuarios(1, 1); // IDs padrão
    });

    test('deve carregar alimentos por data', () async {
      const String dateString = '2025-06-01';

      print('🧪 Testando carregamento de alimentos para $dateString');

      try {
        final alimentosAgrupados =
            await nutricaoService.obterAlimentosPorData(dateString);

        print('📊 Resultado da busca:');
        print(
            '- Tipos de refeição encontrados: ${alimentosAgrupados.keys.toList()}');
        print(
            '- Total de alimentos: ${alimentosAgrupados.values.expand((x) => x).length}');

        alimentosAgrupados.forEach((tipoRefeicao, alimentos) {
          print('🍽️ $tipoRefeicao: ${alimentos.length} alimentos');
          for (var alimento in alimentos) {
            print(
                '  - ${alimento.nomeAlimento} (${alimento.quantidade}g) - ${alimento.calorias}kcal');
          }
        });

        // Verificações
        expect(alimentosAgrupados, isNotEmpty,
            reason: 'Deve encontrar alimentos salvos');
        expect(alimentosAgrupados.containsKey('cafe_manha'), isTrue,
            reason: 'Deve ter café da manhã');
        expect(alimentosAgrupados.containsKey('lanches'), isTrue,
            reason: 'Deve ter lanches');

        print('✅ Teste passou - alimentos carregados com sucesso!');
      } catch (e, stackTrace) {
        print('❌ Erro no teste: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('deve mapear campos corretamente', () async {
      const String dateString = '2025-06-01';

      final alimentosAgrupados =
          await nutricaoService.obterAlimentosPorData(dateString);

      if (alimentosAgrupados.isNotEmpty) {
        final primeiroGrupo = alimentosAgrupados.values.first;
        if (primeiroGrupo.isNotEmpty) {
          final primeiroAlimento = primeiroGrupo.first;

          print('🔍 Verificando mapeamento de campos:');
          print('- ID: ${primeiroAlimento.id}');
          print('- Nome: ${primeiroAlimento.nomeAlimento}');
          print('- Quantidade: ${primeiroAlimento.quantidade}');
          print('- Calorias: ${primeiroAlimento.calorias}');
          print('- Proteínas: ${primeiroAlimento.proteinas}');
          print('- Carboidratos: ${primeiroAlimento.carboidratos}');
          print('- Gorduras: ${primeiroAlimento.gorduras}');

          expect(primeiroAlimento.id, isNotNull,
              reason: 'ID deve estar presente');
          expect(primeiroAlimento.nomeAlimento, isNotEmpty,
              reason: 'Nome deve estar presente');
          expect(primeiroAlimento.quantidade, greaterThan(0),
              reason: 'Quantidade deve ser positiva');
          expect(primeiroAlimento.calorias, greaterThan(0),
              reason: 'Calorias devem ser positivas');
        }
      }
    });
  });
}
