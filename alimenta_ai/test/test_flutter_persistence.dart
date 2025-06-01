import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/services/alimenta_api_service.dart';
import 'package:alimenta_ai/services/nutricao_service.dart';

void main() async {
  group('Teste de Persistência Flutter', () {
    test('Deve carregar alimentos salvos do backend', () async {
      print('🧪 Iniciando teste de carregamento de alimentos...');

      // Criar serviço
      final nutricaoService = NutricaoService();
      nutricaoService.configurarUsuarios(1, 1); // IDs padrão

      try {
        // Testar busca de alimentos por data
        print('🔍 Buscando alimentos para 2025-06-01...');
        final alimentos =
            await nutricaoService.obterAlimentosPorData('2025-06-01');

        print('✅ Resultado da busca:');
        print('- Tipos de refeição encontrados: ${alimentos.keys.toList()}');
        print(
            '- Total de alimentos: ${alimentos.values.expand((x) => x).length}');

        for (final entry in alimentos.entries) {
          print('- ${entry.key}: ${entry.value.length} alimentos');
          for (final alimento in entry.value) {
            print(
                '  * ${alimento.nomeAlimento} (${alimento.quantidade}g) - ${alimento.calorias} kcal');
          }
        }

        // Verificar se encontrou alimentos
        expect(alimentos.isNotEmpty, true,
            reason: 'Deveria encontrar alimentos salvos');

        print('🎉 Teste concluído com sucesso!');
      } catch (e) {
        print('❌ Erro no teste: $e');
        fail('Erro ao buscar alimentos: $e');
      }
    });

    test('Deve testar API diretamente', () async {
      print('🧪 Testando API diretamente...');

      final apiService = AlimentaAPIService();

      try {
        final result =
            await apiService.obterAlimentosDetalhados(1, '2025-06-01');

        print('✅ Resposta da API:');
        print('- Success: ${result['success']}');
        print('- Data type: ${result['data']?.runtimeType}');

        if (result['success']) {
          print('- Data: ${result['data']}');
        } else {
          print('- Error: ${result['error']}');
        }

        expect(result['success'], true, reason: 'API deveria retornar sucesso');
      } catch (e) {
        print('❌ Erro na API: $e');
        fail('Erro na API: $e');
      }
    });
  });
}
