import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Simular o comportamento exato do Flutter quando troca datas
void main() async {
  print('🧪 Iniciando teste de troca de datas Flutter...\n');
  
  // Simular dados de autenticação (como no SharedPreferences)
  String? authToken = await _getStoredToken();
  int? pacienteId = await _getStoredPacienteId();
  
  print('📱 Simulando cenário Flutter:');
  print('🔑 Token: ${authToken != null ? "Existe" : "Não encontrado"}');
  print('👤 Paciente ID: $pacienteId\n');
  
  if (authToken == null || pacienteId == null) {
    print('❌ Erro: Sem dados de autenticação. Simulando login...');
    var loginResult = await _simulateLogin();
    if (loginResult != null) {
      authToken = loginResult['token'];
      pacienteId = loginResult['paciente_id'];
      print('✅ Login simulado com sucesso');
    } else {
      print('❌ Falha no login simulado');
      return;
    }
  }
  
  // Testar o fluxo exato de troca de datas
  await _testDateSwitchingFlow(authToken!, pacienteId!);
}

Future<String?> _getStoredToken() async {
  // Simular leitura do SharedPreferences
  // Na prática, o app Flutter lerá isso do armazenamento local
  print('📂 Verificando token armazenado...');
  
  // Para teste, vamos tentar extrair de um login real
  return null; // Simular que não tem token armazenado
}

Future<int?> _getStoredPacienteId() async {
  // Simular leitura do SharedPreferences
  print('📂 Verificando paciente_id armazenado...');
  return null; // Simular que não tem paciente_id armazenado
}

Future<Map<String, dynamic>?> _simulateLogin() async {
  print('🔐 Tentando login simulado...');
  
  try {
    final response = await http.post(
      Uri.parse('http://localhost:3333/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'teste@teste.com',
        'senha': '123456'
      }),
    );
    
    print('📡 Status da resposta de login: ${response.statusCode}');
    print('📡 Resposta de login: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return {
          'token': data['token'],
          'paciente_id': data['user']['id']
        };
      }
    }
  } catch (e) {
    print('❌ Erro no login: $e');
  }
  
  return null;
}

Future<void> _testDateSwitchingFlow(String token, int pacienteId) async {
  print('\n🔄 Iniciando teste de troca de datas...\n');
  
  // Simular o cenário exato:
  // 1. Usuário está na data atual (hoje)
  DateTime today = DateTime.now();
  String todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  
  // 2. Usuário registra comida via áudio (vamos usar a data de teste onde sabemos que tem dados)
  String testDate = "2025-06-01"; // Data onde sabemos que tem 19 alimentos
  
  print('📅 Cenário de teste:');
  print('  📍 Data atual: $todayString');
  print('  📍 Data de teste (com dados): $testDate');
  print('  🎯 Paciente ID: $pacienteId\n');
  
  // 3. Carregar dados para a data de teste (onde tem alimentos)
  print('🔍 Passo 1: Carregando dados para $testDate (data com alimentos)...');
  await _loadDetailedFoodsForDate(testDate, token, pacienteId);
  
  print('\n' + '='*50 + '\n');
  
  // 4. Simular troca para hoje (onde provavelmente não tem dados)
  print('🔍 Passo 2: Trocando para data atual ($todayString)...');
  await _loadDetailedFoodsForDate(todayString, token, pacienteId);
  
  print('\n' + '='*50 + '\n');
  
  // 5. Simular volta para a data de teste (crucial - aqui é onde falha)
  print('🔍 Passo 3: Voltando para data com dados ($testDate)...');
  print('💡 Este é o passo onde o usuário espera ver os dados novamente!');
  await _loadDetailedFoodsForDate(testDate, token, pacienteId);
}

Future<void> _loadDetailedFoodsForDate(String dateString, String token, int pacienteId) async {
  print('📡 Fazendo requisição para: /alimentos-detalhados/data/$pacienteId');
  print('📅 Data: $dateString');
  
  try {
    final response = await http.get(
      Uri.parse('http://localhost:3333/alimentos-detalhados/data/$pacienteId?data=$dateString'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    print('📊 Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['status'] == true) {
        print('✅ Dados carregados com sucesso!');
        print('📊 Total de itens: ${data['data']['total_itens']}');
        print('🍽️ Refeições com dados:');
        
        final alimentos = data['data']['alimentos'];
        alimentos.forEach((refeicao, lista) {
          if (lista.length > 0) {
            print('  🍴 $refeicao: ${lista.length} alimentos');
          }
        });
        
        // Simular atualização do estado Flutter
        print('🔄 Simulando setState() do Flutter...');
        print('   -> detailedFoods = dados carregados');
        print('   -> isLoading = false');
        print('   -> Rebuild da UI\n');
        
      } else {
        print('⚠️ API retornou status false');
        print('📄 Resposta: ${response.body}\n');
      }
    } else if (response.statusCode == 401) {
      print('🔒 Erro 401: Token inválido ou expirado');
      print('💡 No Flutter real, isso deveria redirecionar para login\n');
    } else {
      print('❌ Erro ${response.statusCode}: ${response.body}\n');
    }
    
  } catch (e) {
    print('💥 Erro de conexão: $e\n');
  }
}
