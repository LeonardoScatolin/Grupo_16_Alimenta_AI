import 'dart:io';
import 'dart:convert';

/// Teste simples para debug do problema de switching de datas
void main() async {
  print('🧪 [SIMPLE TEST] Testando problema de switching de datas');
  
  final today = DateTime.now();
  final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final yesterday = today.subtract(Duration(days: 1));
  final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  
  print('📅 Hoje: $todayString');
  print('📅 Ontem: $yesterdayString');
  
  // Usar curl para testar a API
  await testDateSwitch(todayString, yesterdayString);
}

Future<void> testDateSwitch(String today, String yesterday) async {
  print('\n=== SIMULANDO COMPORTAMENTO DO USUÁRIO ===');
  
  // 1. Verificar alimentos para hoje (após registro por áudio)
  print('\n1️⃣ Verificando alimentos para HOJE ($today)...');
  await callAPI(today);
  
  // 2. Switch para ontem
  print('\n2️⃣ Usuário muda para ONTEM ($yesterday)...');
  await callAPI(yesterday);
  
  // 3. Switch de volta para hoje - AQUI É ONDE O PROBLEMA ACONTECE
  print('\n3️⃣ Usuário volta para HOJE ($today) - TESTE CRÍTICO...');
  await callAPI(today);
  
  print('\n🎯 Se os dados de hoje sumiram na etapa 3, encontramos o bug!');
}

Future<void> callAPI(String date) async {
  try {
    // Usar curl do sistema para fazer a requisição
    final result = await Process.run('curl', [
      '-s',
      '-X', 'GET',
      'http://localhost:3333/alimentos-detalhados/data/$date/1',
      '-H', 'Content-Type: application/json'
    ]);
    
    if (result.exitCode == 0) {
      try {
        final data = jsonDecode(result.stdout);
        final alimentosAgrupados = data['data'];
        
        print('📊 Status: Sucesso');
        print('📊 Tipos de refeição: ${alimentosAgrupados.keys.toList()}');
        
        int totalAlimentos = 0;
        alimentosAgrupados.forEach((tipo, alimentos) {
          final count = (alimentos as List).length;
          totalAlimentos += count;
          if (count > 0) {
            print('   $tipo: $count alimentos');
          }
        });
        
        print('📊 Total: $totalAlimentos alimentos');
        
        if (totalAlimentos > 0) {
          print('✅ DADOS ENCONTRADOS para $date');
        } else {
          print('⚠️ NENHUM DADO para $date');
        }
      } catch (e) {
        print('❌ Erro ao parsear JSON: $e');
        print('Raw response: ${result.stdout}');
      }
    } else {
      print('❌ Curl falhou: ${result.stderr}');
    }
  } catch (e) {
    print('❌ Erro: $e');
  }
}
