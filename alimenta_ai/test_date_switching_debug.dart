import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to debug the date switching issue
/// This simulates the user behavior: register food via audio, switch dates, return to current date
void main() async {
  print('🧪 [DEBUG] Iniciando teste de switching de datas');
  
  final today = DateTime.now();
  final todayString = formatDate(today);
  final yesterday = today.subtract(Duration(days: 1));
  final yesterdayString = formatDate(yesterday);
  
  print('📅 Data atual: $todayString');
  print('📅 Data anterior: $yesterdayString');
  
  // Step 1: Check if there are foods for today (after audio registration)
  print('\n1️⃣ Verificando alimentos registrados para hoje...');
  await checkFoodsForDate(todayString);
  
  // Step 2: Switch to yesterday and check
  print('\n2️⃣ Simulando switch para ontem...');
  await checkFoodsForDate(yesterdayString);
  
  // Step 3: Switch back to today and check again
  print('\n3️⃣ Simulando volta para hoje...');
  await checkFoodsForDate(todayString);
  
  print('\n✅ [DEBUG] Teste concluído');
}

Future<void> checkFoodsForDate(String dateString) async {
  try {    final response = await http.get(
      Uri.parse('http://localhost:3333/alimentos-detalhados/data/$dateString/1'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final alimentosAgrupados = data['data'];
      
      print('📊 Status: ${response.statusCode}');
      print('📊 Tipos de refeição: ${alimentosAgrupados.keys.toList()}');
      
      int totalAlimentos = 0;
      alimentosAgrupados.forEach((tipo, alimentos) {
        totalAlimentos += (alimentos as List).length;
        print('   $tipo: ${(alimentos as List).length} alimentos');
      });
      
      print('📊 Total de alimentos: $totalAlimentos');
      
      if (totalAlimentos > 0) {
        print('✅ Dados encontrados para $dateString');
      } else {
        print('⚠️ NENHUM alimento encontrado para $dateString');
      }
    } else {
      print('❌ Erro na API: ${response.statusCode}');
      print('❌ Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Erro de conexão: $e');
  }
}

String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
