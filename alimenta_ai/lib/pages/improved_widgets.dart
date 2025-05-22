import 'package:flutter/material.dart';

class ImprovedWidgets {
  final BuildContext context;
  final DateTime selectedDate;
  final Function(DateTime) loadMealsForDate;

  ImprovedWidgets(this.context, this.selectedDate, this.loadMealsForDate);

  DateTime _getBrasiliaTimeNow() {
    return DateTime.now().toUtc().subtract(const Duration(hours: 3));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return months[month - 1];
  }

  String _getWeekdayAbbr(int weekday) {
    const weekdays = ['', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
    return weekdays[weekday];
  }

  Widget buildDateSelector() {
    // Obtém a data atual no horário de Brasília
    final today = _getBrasiliaTimeNow();
    final startDate = today.subtract(const Duration(days: 15));
    const totalDays = 31; // Aumentando para mostrar mais dias

    // Scroll controller para posicionar o dia atual no centro
    final ScrollController scrollController =
        ScrollController(); // Calcula a posição inicial para centralizar o dia atual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Posição estimada do dia atual (15 dias atrás do dia atual)
      const dayWidth = 62 + 12;
      const todayIndex = 15;

      // Cálculo da posição de scroll desejada
      final screenWidth = MediaQuery.of(context).size.width;
      final offset =
          (dayWidth * todayIndex) - (screenWidth / 2) + (dayWidth / 2);

      // Scroll para a posição calculada
      if (offset > 0) {
        scrollController.jumpTo(offset);
      }
    });

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: Color(0xff92A3FD),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${_getMonthName(today.month)} ${today.year}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff92A3FD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: totalDays,
                  itemBuilder: (context, index) {
                    final date = startDate.add(Duration(days: index));
                    final bool isSelected = date.day == selectedDate.day &&
                        date.month == selectedDate.month &&
                        date.year == selectedDate.year;

                    return GestureDetector(
                      onTap: () {
                        loadMealsForDate(date);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 62,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff92A3FD)
                              : _isToday(date)
                                  ? const Color(0xff92A3FD).withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xff92A3FD)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                          border: _isToday(date) && !isSelected
                              ? Border.all(
                                  color: const Color(0xff92A3FD), width: 1.5)
                              : isSelected
                                  ? null
                                  : Border.all(
                                      color: Colors.grey.shade200, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getWeekdayAbbr(date.weekday),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : _isToday(date)
                                        ? const Color(0xff92A3FD)
                                        : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${date.day}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : _isToday(date)
                                        ? const Color(0xff92A3FD)
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildMacroBar({
    required String label,
    required String emoji,
    required double current,
    required double total,
  }) {
    final progress = (current / total).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).toInt();

    // Determine color based on progress
    Color progressColor;
    if (progressPercent < 30) {
      progressColor = Colors.redAccent;
    } else if (progressPercent < 70) {
      progressColor = const Color(0xFF9DCEFF);
    } else if (progressPercent < 100) {
      progressColor = Colors.greenAccent.shade700;
    } else {
      progressColor = Colors.greenAccent.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${current.toInt()} / ${total.toInt()}${label == 'Calorias' ? ' kCal' : 'g'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              // Background track
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
              ),
              // Progress indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 12,
                width: MediaQuery.of(context).size.width * 0.8 * progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [progressColor.withOpacity(0.8), progressColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
