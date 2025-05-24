import 'package:flutter/material.dart';

class RefeicoesPage extends StatefulWidget {
  const RefeicoesPage({super.key});

  @override
  State<RefeicoesPage> createState() => _RefeicoesPageState();
}

class _RefeicoesPageState extends State<RefeicoesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Refeições',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(),
              const SizedBox(height: 20),
              _buildMealCard(
                title: "Café da Manhã",
                totalCalories: 630,
                items: [
                  MealItem(name: "Pão Francês", calories: 230),
                  MealItem(name: "Ovo", calories: 400),
                ],
              ),
              _buildMealCard(
                title: "Almoço",
                totalCalories: 475,
                items: [
                  MealItem(name: "Arroz Branco Cozido", calories: 375),
                  MealItem(name: "Feijão Cozido", calories: 100),
                ],
              ),
              _buildMealCard(
                title: "Lanches",
                totalCalories: 140,
                items: [
                  MealItem(name: "Maçã", calories: 70),
                  MealItem(name: "Iogurte", calories: 70),
                ],
              ),
              _buildMealCard(
                title: "Janta",
                totalCalories: 120,
                items: [
                  MealItem(name: "Coca-Cola", calories: 150),
                  MealItem(name: "Arroz Branco Cozido", calories: 300),
                  MealItem(name: "Filé de Frango", calories: 400),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Macros Totais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildMacroBar(label: "Calorias", emoji: "🔥", current: 1800, total: 2500),
              _buildMacroBar(label: "Proteinas", emoji: "🏋️‍♂️", current: 100, total: 200),
              _buildMacroBar(label: "Gordura", emoji: "🥜", current: 50, total: 140),
              _buildMacroBar(label: "Carbo", emoji: "🌾", current: 100, total: 400),
              const SizedBox(height: 30),
              // Exemplo de botão com cor primária
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {},
                child: Text('Botão'),
              ),
              const SizedBox(height: 20),
              // Exemplo de ícone com cor primária
              Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              // Exemplo de container com gradiente e cor primária
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                height: 100,
                width: double.infinity,
              ),
              Container(
                color: Theme.of(context).colorScheme.background,
                child: Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Exemplo de Card',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 15));
    const totalDays = 30;

    return Column(
      children: [
        Text(
          "${_getMonthName(today.month)} ${today.year}",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalDays,
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              final bool isToday = date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;

              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 60,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xff92A3FD) : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getWeekdayAbbr(date.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${date.day}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getWeekdayAbbr(int weekday) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
      "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ];
    return months[month - 1];
  }

  Widget _buildMacroBar({
    required String label,
    required String emoji,
    required double current,
    required double total,
  }) {
    final progress = (current / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Text(
                '${current.toInt()} / ${total.toInt()}${label == 'Calorias' ? ' kCal' : 'g'}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9DCEFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required String title,
    required int totalCalories,
    required List<MealItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '| $totalCalories calorias',
                style: const TextStyle(fontSize: 14, color: Color(0xFF7B6F72)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => item),
          const SizedBox(height: 10),
          Divider(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}

class MealItem extends StatelessWidget {
  final String name;
  final int calories;

  const MealItem({required this.name, required this.calories, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
          Text(
            '$calories Calorias',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
