import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testando conectividade com backend...');

  try {
    // Testar endpoint básico
    final response = await http.get(
      Uri.parse('http://127.0.0.1:3333/api/test'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('📡 Status: ${response.statusCode}');
    print('📝 Response: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Backend está respondendo corretamente!');
    } else {
      print('⚠️ Backend retornou status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erro de conectividade: $e');
  }

  // Testar endpoint de alimentos detalhados
  try {
    print('\n🔍 Testando endpoint de alimentos detalhados...');
    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:3333/alimentos-detalhados/data/1?data=2025-06-01'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('📡 Status: ${response.statusCode}');
    print('📝 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(
          '✅ Endpoint de alimentos funcionando! Registros encontrados: ${data.length}');
    }
  } catch (e) {
    print('❌ Erro no endpoint de alimentos: $e');
  }
}
