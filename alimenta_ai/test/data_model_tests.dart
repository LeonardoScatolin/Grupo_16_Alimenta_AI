import 'package:flutter_test/flutter_test.dart';
import 'package:alimenta_ai/models/modelo_categoria.dart';
import 'package:alimenta_ai/models/ver_dietanutri.dart';

void main() {
  group('Model Tests', () {
    test('ModeloCategoria initialization', () {
      final categorias = ModeloCategoria.getCategorias();
      
      expect(categorias, isNotEmpty);
      expect(categorias.first.name, isNotEmpty);
      expect(categorias.first.iconPath, isNotEmpty);
    });

    test('ModeloDieta initialization', () {
      final dietas = ModeloDieta.getDietas();
      
      expect(dietas, isNotEmpty);
      expect(dietas.first.name, isNotEmpty);
      expect(dietas.first.duracao, isNotEmpty);
      expect(dietas.first.calorias, isNotEmpty);
    });

    test('MealData calculations', () {
      final meal = MealData(
        title: "Test Meal",
        totalCalories: 0,
        items: [
          MealItemData(name: "Food 1", calories: 100, protein: 5, fat: 2, carbs: 15),
          MealItemData(name: "Food 2", calories: 150, protein: 8, fat: 3, carbs: 20),
        ],
      );

      var totalCalories = meal.items.fold(0, (sum, item) => sum + item.calories);
      var totalProtein = meal.items.fold(0, (sum, item) => sum + item.protein);
      var totalFat = meal.items.fold(0, (sum, item) => sum + item.fat);
      var totalCarbs = meal.items.fold(0, (sum, item) => sum + item.carbs);

      expect(totalCalories, 250);
      expect(totalProtein, 13);
      expect(totalFat, 5);
      expect(totalCarbs, 35);
    });
  });
}
