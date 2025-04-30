import 'package:flutter/material.dart';

class TempFixes {
  static Widget buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
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
        const SizedBox(height: 5),
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

  static Widget getMealIcon(String mealTitle) {
    if (mealTitle.toLowerCase().contains('café') ||
        mealTitle.toLowerCase().contains('cafe') ||
        mealTitle.toLowerCase().contains('manhã')) {
      return const Icon(Icons.free_breakfast, color: Colors.white);
    } else if (mealTitle.toLowerCase().contains('almoço')) {
      return const Icon(Icons.restaurant, color: Colors.white);
    } else if (mealTitle.toLowerCase().contains('lanche')) {
      return const Icon(Icons.cookie, color: Colors.white);
    } else if (mealTitle.toLowerCase().contains('jantar')) {
      return const Icon(Icons.dinner_dining, color: Colors.white);
    }
    return const Icon(Icons.restaurant_menu, color: Colors.white);
  }
}
