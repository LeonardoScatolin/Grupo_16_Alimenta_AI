// Teste para verificar integração do Flutter com a API de persistência
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testando integração Flutter com API de persistência...\n');

  final String baseUrl = 'http://127.0.0.1:3333';

  try {
    // Teste 1: Verificar se API está rodando
    print('1. 🔌 Verificando se API está online...');
    final healthResponse = await http.get(Uri.parse('$baseUrl/'));
    print('✅ API respondeu: ${healthResponse.statusCode}');

    // Teste 2: Buscar alimentos detalhados para hoje
    print('\n2. 🔍 Buscando alimentos detalhados para hoje...');
    final today = DateTime.now().toIso8601String().split('T')[0];
    final detalhesResponse = await http.get(
      Uri.parse('$baseUrl/alimentos-detalhados/data/1?data=$today'),
      headers: {'Content-Type': 'application/json'},
    );

    print('Status: ${detalhesResponse.statusCode}');
    if (detalhesResponse.statusCode == 200) {
      final data = jsonDecode(detalhesResponse.body);
      print('✅ Dados recebidos: ${data['status']}');
      if (data['data'] is List) {
        print('📋 ${data['data'].length} alimentos encontrados');
      }
    }

    // Teste 3: Adicionar um alimento via calcular-macros
    print('\n3. ➕ Adicionando alimento via Flutter simulation...');
    final addResponse = await http.post(
      Uri.parse('$baseUrl/alimentos/calcular-macros'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome_alimento': 'Maçã',
        'quantidade': 150,
        'paciente_id': 1,
        'nutri_id': 1,
        'tipo_refeicao': 'Lanche da Tarde',
        'observacoes': 'Teste Flutter integration',
      }),
    );

    print('Status: ${addResponse.statusCode}');
    if (addResponse.statusCode == 200) {
      final data = jsonDecode(addResponse.body);
      print('✅ Alimento adicionado: ${data['status']}');
      if (data['registro_criado'] != null) {
        print(
            '🆔 ID do registro: ${data['registro_criado']['registro_detalhado_id']}');
      }
    }

    // Teste 4: Buscar alimentos detalhados novamente
    print('\n4. 🔍 Buscando alimentos detalhados após adição...');
    final detalhes2Response = await http.get(
      Uri.parse('$baseUrl/alimentos-detalhados/data/1?data=$today'),
      headers: {'Content-Type': 'application/json'},
    );

    if (detalhes2Response.statusCode == 200) {
      final data = jsonDecode(detalhes2Response.body);
      if (data['data'] is List) {
        print('✅ ${data['data'].length} alimentos encontrados após adição');

        // Mostrar o último alimento adicionado
        if ((data['data'] as List).isNotEmpty) {
          final ultimoAlimento = (data['data'] as List).last;
          print(
              '🍎 Último alimento: ${ultimoAlimento['nome_alimento']} - ${ultimoAlimento['quantidade']}g');
        }
      }
    }

    print('\n🎉 Teste de integração concluído com sucesso!');
  } catch (e) {
    print('❌ Erro durante o teste: $e');
  }
}
