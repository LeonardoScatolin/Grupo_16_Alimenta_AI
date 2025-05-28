import 'package:flutter/material.dart';
import 'package:alimenta_ai/services/alimenta_api_service.dart';
import 'package:alimenta_ai/models/alimenta_api_models.dart';

class DebugTestPage extends StatefulWidget {
  const DebugTestPage({super.key});

  @override
  _DebugTestPageState createState() => _DebugTestPageState();
}

class _DebugTestPageState extends State<DebugTestPage> {
  final apiService = AlimentaAPIService();
  String testResult = '';
  bool isLoading = false;

  Future<void> testAPIConnection() async {
    setState(() {
      isLoading = true;
      testResult = 'Testando conexão...';
    });

    try {
      // Testar conexão básica
      final result = await apiService.obterResumoDiario(1);

      if (result['success']) {
        final resumo = ResumoDiario.fromJson(result['data']);
        setState(() {
          testResult = '''
✅ CONEXÃO OK!
📊 Meta de calorias: ${resumo.metaDiaria.calorias}
🥩 Meta de proteína: ${resumo.metaDiaria.proteina}g
🍞 Meta de carboidratos: ${resumo.metaDiaria.carbo}g
🥑 Meta de gordura: ${resumo.metaDiaria.gordura}g

💪 Consumo atual:
- Calorias: ${resumo.consumoAtual.calorias}
- Proteína: ${resumo.consumoAtual.proteina}g
- Carboidratos: ${resumo.consumoAtual.carbo}g
- Gordura: ${resumo.consumoAtual.gordura}g
          ''';
        });
      } else {
        setState(() {
          testResult = '❌ Erro: ${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        testResult = '💥 Erro de conexão: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste de API')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : testAPIConnection,
              child: const Text('Testar Conexão com Backend'),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    testResult.isEmpty
                        ? 'Clique no botão para testar'
                        : testResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
