import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 Testando API de alimentos detalhados...');
  
  // Configurações de teste
  const String baseUrl = 'http://localhost:3000/api';
  const int pacienteId = 1;
  const String data = '2025-06-01';
  
  try {
    // Testar a URL que está sendo usada
    final url = '$baseUrl/alimentos-detalhados/data/$pacienteId?data=$data';
    print('🌐 URL de teste: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    print('📊 Status da resposta: ${response.statusCode}');
    print('📄 Headers da resposta: ${response.headers}');
    print('💬 Corpo da resposta: ${response.body}');
    
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      print('✅ JSON decodificado: $result');
      
      if (result['status'] == true) {
        print('🎉 API funcionando corretamente!');
        print('📊 Dados retornados: ${result['data']}');
      } else {
        print('❌ API retornou erro: ${result['message'] ?? 'Sem mensagem'}');
      }
    } else {
      print('❌ Erro HTTP: ${response.statusCode}');
      print('❌ Corpo do erro: ${response.body}');
    }
    
  } catch (e) {
    print('💥 Erro durante o teste: $e');
  }
}
