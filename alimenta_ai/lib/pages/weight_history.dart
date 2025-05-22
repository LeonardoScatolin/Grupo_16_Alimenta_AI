import 'package:flutter/material.dart';
import 'dart:math';
import '../services/weight_service.dart';

class WeightHistoryPage extends StatefulWidget {
  const WeightHistoryPage({Key? key}) : super(key: key);

  @override
  _WeightHistoryPageState createState() => _WeightHistoryPageState();
}

class _WeightHistoryPageState extends State<WeightHistoryPage> {
  // Controlador para o campo de texto
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _isLoading = false;

  // Usando o WeightService para gerenciar os registros de peso
  final WeightService _weightService = WeightService();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // Adicionar novo registro de peso
  void _addWeightRecord() {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      setState(() {
        _weightService.addWeightRecord(weight);
        _weightController.clear();
      });
      // Mostrar uma confirmação
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peso registrado com sucesso!'),
          backgroundColor: Color(0xff92A3FD),
        ),
      );
    }
  }

  // Remover um registro de peso
  Future<void> _deleteWeightRecord(int index) async {
    // Confirmar antes de excluir
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro'),
        content: Text(
            'Tem certeza que deseja excluir o registro de ${_weightService.weightRecords[index].weight} kg?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _weightService.removeWeightRecord(index);
      });
      // Mostrar uma confirmação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro removido'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _weightService,
      builder: (context, _) {
        final weightDifference = _weightService.calculateWeightDifference();
        final weightDifferenceText = weightDifference >= 0
            ? '+${weightDifference.toStringAsFixed(1)} kg'
            : '${weightDifference.toStringAsFixed(1)} kg';
        final isWeightLoss = weightDifference < 0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Histórico de Peso',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0.0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffF7F8F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildWeightSummaryCard(weightDifferenceText, isWeightLoss),
                    _buildWeightChart(),
                    _buildWeightInputSection(),
                    Expanded(
                      child: _buildWeightHistoryList(),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildWeightSummaryCard(
      String weightDifferenceText, bool isWeightLoss) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff9DCEFF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progresso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Seu progresso desde o começo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isWeightLoss ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              weightDifferenceText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evolução do Peso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Último mês',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _weightService.weightRecords.length < 2
                ? const Center(
                    child: Text(
                      'Adicione mais registros para visualizar o gráfico',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: WeightChartPainter(
                      weightRecords: _weightService.weightRecords,
                      gradientColors: const [
                        Color(0xff9DCEFF),
                        Color(0xff92A3FD),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInputSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Novo Peso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Digite seu peso atual (em kg)',
                filled: true,
                fillColor: const Color(0xffF7F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira seu peso';
                }
                try {
                  final weight = double.parse(value);
                  if (weight <= 0 || weight > 300) {
                    return 'Por favor, insira um peso válido';
                  }
                } catch (e) {
                  return 'Por favor, insira um número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addWeightRecord,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff92A3FD),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Registrar Peso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistoryList() {
    final records = _weightService.weightRecords;
    return records.isEmpty
        ? const Center(
            child: Text(
              'Nenhum registro de peso ainda. Adicione um!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          )
        : Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              itemCount: records.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final record = records[index];
                final formattedDate =
                    '${record.date.day}/${record.date.month}/${record.date.year}';
                final weightChange = index < records.length - 1
                    ? record.weight - records[index + 1].weight
                    : 0.0;
                final hasChange = index < records.length - 1;                return Dismissible(
                  key: Key('weight-${record.date.millisecondsSinceEpoch}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Excluir registro'),
                        content: Text(
                            'Tem certeza que deseja excluir o registro de ${record.weight} kg?'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Excluir',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    _deleteWeightRecord(index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F8F8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${record.weight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (hasChange)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: weightChange > 0
                                  ? Colors.red.withOpacity(0.1)
                                  : weightChange < 0
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              weightChange > 0
                                  ? '+${weightChange.toStringAsFixed(1)}'
                                  : weightChange < 0
                                      ? weightChange.toStringAsFixed(1)
                                      : '0.0',
                              style: TextStyle(
                                color: weightChange > 0
                                    ? Colors.red
                                    : weightChange < 0
                                        ? Colors.green
                                        : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}

// Classe para desenhar o gráfico de peso
class WeightChartPainter extends CustomPainter {
  final List<WeightRecord> weightRecords;
  final List<Color> gradientColors;

  WeightChartPainter({
    required this.weightRecords,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightRecords.isEmpty) return;

    // Ordenar registros por data (mais novo para mais antigo)
    final sortedRecords = List<WeightRecord>.from(weightRecords)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Encontrar valores mínimos e máximos para escalar corretamente
    final minWeight =
        sortedRecords.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight =
        sortedRecords.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final weightRange =
        max(0.1, maxWeight - minWeight); // Evitar divisão por zero

    // Configurar o pincel para a linha
    final linePaint = Paint()
      ..color = gradientColors[1]
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Configurar o pincel para o preenchimento abaixo da linha
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          gradientColors[0].withOpacity(0.4),
          gradientColors[1].withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Criar um caminho para a linha
    final linePath = Path();
    final fillPath = Path();

    // Calcular as posições de todos os pontos
    List<Offset> points = [];
    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      // Normalizar a posição horizontal
      final x = size.width * i / (sortedRecords.length - 1);
      // Normalizar a posição vertical (invertida porque o eixo Y cresce para baixo)
      final normalizedWeight = (record.weight - minWeight) / weightRange;
      final y = size.height -
          (normalizedWeight * size.height * 0.8 + size.height * 0.1);
      points.add(Offset(x, y));
    }

    // Desenhar a linha conectando os pontos
    if (points.isNotEmpty) {
      linePath.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);
    }

    // Desenhar pontos em cada registro
    final pointFillPaint = Paint()..color = gradientColors[1];
    for (var point in points) {
      canvas.drawCircle(point, 4, pointFillPaint);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(WeightChartPainter oldDelegate) => true;
}
