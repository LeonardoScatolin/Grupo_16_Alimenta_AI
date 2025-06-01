import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(DebugApp());
}

class DebugApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug Date Switching',
      home: DebugPage(),
    );
  }
}

class DebugPage extends StatefulWidget {
  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String _result = '';
  DateTime _selectedDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Date Switching Issue'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data selecionada: ${_formatDate(_selectedDate)}'),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _testAPI(_selectedDate),
                  child: Text('Testar API para hoje'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final yesterday = _selectedDate.subtract(Duration(days: 1));
                    setState(() => _selectedDate = yesterday);
                    _testAPI(yesterday);
                  },
                  child: Text('Switch para ontem'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final today = DateTime.now();
                    setState(() => _selectedDate = today);
                    _testAPI(today);
                  },
                  child: Text('Voltar para hoje'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _testAPI(DateTime date) async {
    final dateString = _formatDate(date);
    _log('🧪 Testando API para $dateString');
    
    try {
      final url = 'http://localhost:3333/alimentos-detalhados/data/1?data=$dateString';
      _log('🌐 URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      _log('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('✅ Sucesso!');
        
        if (data['data'] != null && data['data']['refeicoes'] != null) {
          final refeicoes = data['data']['refeicoes'] as Map<String, dynamic>;
          _log('📋 Refeições encontradas: ${refeicoes.keys.toList()}');
          
          int totalAlimentos = 0;
          refeicoes.forEach((tipo, alimentos) {
            if (alimentos is List) {
              totalAlimentos += alimentos.length;
              _log('   $tipo: ${alimentos.length} alimentos');
            }
          });
          
          _log('📊 Total: $totalAlimentos alimentos');
          
          if (totalAlimentos == 0) {
            _log('⚠️ PROBLEMA: Nenhum alimento encontrado!');
          }
        } else {
          _log('⚠️ Estrutura de dados inesperada: ${data.keys}');
        }
      } else {
        _log('❌ Erro HTTP: ${response.statusCode}');
        _log('❌ Response: ${response.body}');
      }
    } catch (e) {
      _log('💥 Erro: $e');
    }
    
    _log('─' * 50);
  }
  
  void _log(String message) {
    setState(() {
      _result += '$message\n';
    });
    print(message);
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
