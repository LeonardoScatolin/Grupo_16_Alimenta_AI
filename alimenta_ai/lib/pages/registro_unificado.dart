import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:alimenta_ai/models/modelo_categoria.dart';
import 'package:alimenta_ai/models/ver_dietanutri.dart';

class RegistroUnificadoPage extends StatefulWidget {
  const RegistroUnificadoPage({Key? key}) : super(key: key);

  @override
  State<RegistroUnificadoPage> createState() => _RegistroUnificadoPageState();
}

class _RegistroUnificadoPageState extends State<RegistroUnificadoPage> {
  // Variáveis para controle de gravação de áudio
  bool isRecording = false;
  bool isPlayingAudio = false;
  bool hasRecordedAudio = false;
  bool isLongPress = false;
  double micButtonOffset = 0;
  late FocusNode textFieldFocus;
  int recordingDuration = 0;
  Timer? recordingTimer;
  Timer? recordingDelayTimer;

  // Controle de datas e calendário
  DateTime selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();
  bool _initialScrollDone = false;

  // Variáveis para dados
  List<ModeloCategoria> categorias = [];
  List<ModeloDieta> dietas = [];

  // Variáveis para cálculos de calorias e macro
  int totalDailyCalories = 0;
  int proteinTotal = 0;
  int fatTotal = 0;
  int carbsTotal = 0;

  // Meta diária padrão
  final int caloriesGoal = 2500;
  final int proteinGoal = 200;
  final int fatGoal = 140;
  final int carbsGoal = 400;

  // Modelo de dados para refeições
  late List<MealData> meals;

  // Controle de visibilidade do modal de gravação
  bool showRecordingModal = false;
  String selectedMealTitle = "";

  // Simulação de banco de dados de alimentos
  final Map<String, Map<String, dynamic>> foodDatabase = {
    "Pão Francês": {"calories": 150, "protein": 6, "fat": 2, "carbs": 30},
    "Ovo": {"calories": 70, "protein": 6, "fat": 5, "carbs": 0},
    "Arroz Branco Cozido": {
      "calories": 150,
      "protein": 3,
      "fat": 0,
      "carbs": 30
    },
    "Feijão Cozido": {"calories": 100, "protein": 7, "fat": 1, "carbs": 20},
    "Maçã": {"calories": 70, "protein": 0, "fat": 0, "carbs": 18},
    "Iogurte": {"calories": 100, "protein": 5, "fat": 3, "carbs": 12},
    "Coca-Cola": {"calories": 150, "protein": 0, "fat": 0, "carbs": 38},
    "Filé de Frango": {"calories": 120, "protein": 20, "fat": 3, "carbs": 0},
    "Banana": {"calories": 90, "protein": 1, "fat": 0, "carbs": 23},
    "Leite": {"calories": 120, "protein": 8, "fat": 5, "carbs": 12},
    "Queijo": {"calories": 110, "protein": 7, "fat": 9, "carbs": 1},
    "Alface": {"calories": 15, "protein": 1, "fat": 0, "carbs": 2},
    "Tomate": {"calories": 20, "protein": 1, "fat": 0, "carbs": 4},
    "Batata": {"calories": 150, "protein": 2, "fat": 0, "carbs": 35},
    "Carne Bovina": {"calories": 250, "protein": 26, "fat": 17, "carbs": 0},
  };
  @override
  void initState() {
    super.initState();
    textFieldFocus = FocusNode();
    categorias = ModeloCategoria.getCategorias();
    dietas = ModeloDieta.getDietas();
    selectedDate = _getBrasiliaTimeNow();
    _initialScrollDone = false;
    initializeMeals();
    calculateTotalCalories();
  }

  @override
  void dispose() {
    textFieldFocus.dispose();
    stopRecordingTimer();
    recordingDelayTimer?.cancel();
    _dateScrollController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  // Utilitários de data
  DateTime _getBrasiliaTimeNow() {
    final now = DateTime.now().toUtc();
    return now.subtract(const Duration(hours: 3));
  }

  bool _isToday(DateTime date) {
    final today = _getBrasiliaTimeNow();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // Inicializa refeições padrão
  void initializeMeals() {
    meals = [
      MealData(
        title: "Café da Manhã",
        totalCalories: 630,
        items: [
          MealItemData(
              name: "Pão Francês",
              calories: 230,
              protein: 6,
              fat: 2,
              carbs: 30),
          MealItemData(
              name: "Ovo", calories: 400, protein: 6, fat: 5, carbs: 0),
        ],
      ),
      MealData(
        title: "Almoço",
        totalCalories: 475,
        items: [
          MealItemData(
              name: "Arroz Branco Cozido",
              calories: 375,
              protein: 3,
              fat: 0,
              carbs: 30),
          MealItemData(
              name: "Feijão Cozido",
              calories: 100,
              protein: 7,
              fat: 1,
              carbs: 20),
        ],
      ),
      MealData(
        title: "Lanches",
        totalCalories: 140,
        items: [
          MealItemData(
              name: "Maçã", calories: 70, protein: 0, fat: 0, carbs: 18),
          MealItemData(
              name: "Iogurte", calories: 70, protein: 5, fat: 3, carbs: 12),
        ],
      ),
      MealData(
        title: "Janta",
        totalCalories: 850,
        items: [
          MealItemData(
              name: "Coca-Cola", calories: 150, protein: 0, fat: 0, carbs: 38),
          MealItemData(
              name: "Arroz Branco Cozido",
              calories: 300,
              protein: 3,
              fat: 0,
              carbs: 30),
          MealItemData(
              name: "Filé de Frango",
              calories: 400,
              protein: 20,
              fat: 3,
              carbs: 0),
        ],
      ),
    ];
  }

  // Carrega refeições de acordo com a data
  void _loadMealsForDate(DateTime date) {
    final dayOfMonth = date.day;
    setState(() {
      if (dayOfMonth % 3 == 0) {
        meals = [
          MealData(
            title: "Café da Manhã",
            totalCalories: 450,
            items: [
              MealItemData(
                  name: "Aveia com Banana",
                  calories: 280,
                  protein: 8,
                  fat: 4,
                  carbs: 50),
              MealItemData(
                  name: "Iogurte",
                  calories: 170,
                  protein: 10,
                  fat: 8,
                  carbs: 15),
            ],
          ),
          MealData(
            title: "Almoço",
            totalCalories: 580,
            items: [
              MealItemData(
                  name: "Frango Grelhado",
                  calories: 280,
                  protein: 35,
                  fat: 10,
                  carbs: 0),
              MealItemData(
                  name: "Salada Verde",
                  calories: 80,
                  protein: 4,
                  fat: 2,
                  carbs: 10),
              MealItemData(
                  name: "Batata Doce",
                  calories: 220,
                  protein: 2,
                  fat: 0,
                  carbs: 50),
            ],
          ),
          MealData(
            title: "Lanches",
            totalCalories: 200,
            items: [
              MealItemData(
                  name: "Mix de Castanhas",
                  calories: 200,
                  protein: 6,
                  fat: 15,
                  carbs: 8),
            ],
          ),
          MealData(
            title: "Janta",
            totalCalories: 420,
            items: [
              MealItemData(
                  name: "Omelete",
                  calories: 320,
                  protein: 20,
                  fat: 25,
                  carbs: 2),
              MealItemData(
                  name: "Torrada Integral",
                  calories: 100,
                  protein: 4,
                  fat: 1,
                  carbs: 20),
            ],
          ),
        ];
      } else if (dayOfMonth % 3 == 1) {
        initializeMeals();
      } else {
        meals = [
          MealData(
            title: "Café da Manhã",
            totalCalories: 380,
            items: [
              MealItemData(
                  name: "Tapioca com Queijo",
                  calories: 220,
                  protein: 10,
                  fat: 8,
                  carbs: 25),
              MealItemData(
                  name: "Café com Leite",
                  calories: 160,
                  protein: 8,
                  fat: 6,
                  carbs: 12),
            ],
          ),
          MealData(
            title: "Almoço",
            totalCalories: 650,
            items: [
              MealItemData(
                  name: "Salmão Grelhado",
                  calories: 300,
                  protein: 30,
                  fat: 18,
                  carbs: 0),
              MealItemData(
                  name: "Arroz Integral",
                  calories: 200,
                  protein: 4,
                  fat: 1,
                  carbs: 40),
              MealItemData(
                  name: "Brócolis",
                  calories: 50,
                  protein: 3,
                  fat: 0,
                  carbs: 10),
              MealItemData(
                  name: "Abacate",
                  calories: 100,
                  protein: 1,
                  fat: 10,
                  carbs: 5),
            ],
          ),
          MealData(
            title: "Lanches",
            totalCalories: 150,
            items: [
              MealItemData(
                  name: "Maçã", calories: 80, protein: 0, fat: 0, carbs: 20),
              MealItemData(
                  name: "Whey Protein",
                  calories: 70,
                  protein: 18,
                  fat: 0,
                  carbs: 0),
            ],
          ),
          MealData(
            title: "Janta",
            totalCalories: 480,
            items: [
              MealItemData(
                  name: "Sopa de Legumes",
                  calories: 180,
                  protein: 8,
                  fat: 5,
                  carbs: 25),
              MealItemData(
                  name: "Peito de Peru",
                  calories: 180,
                  protein: 25,
                  fat: 5,
                  carbs: 5),
              MealItemData(
                  name: "Pão Integral",
                  calories: 120,
                  protein: 6,
                  fat: 2,
                  carbs: 20),
            ],
          ),
        ];
      }
      calculateTotalCalories();
    });
  }

  // Cálculo de calorias e macros totais do dia
  void calculateTotalCalories() {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalFat = 0;
    int totalCarbs = 0;

    for (var meal in meals) {
      int mealCalories = 0;
      for (var item in meal.items) {
        // Skip placeholder items when calculating totals
        if (item.isPlaceholder) continue;

        mealCalories += item.calories;
        totalProtein += item.protein;
        totalFat += item.fat;
        totalCarbs += item.carbs;
      }
      meal.totalCalories = mealCalories;
      totalCalories += mealCalories;
    }

    setState(() {
      totalDailyCalories = totalCalories;
      proteinTotal = totalProtein;
      fatTotal = totalFat;
      carbsTotal = totalCarbs;
    });
  }

  // Adiciona alimento selecionado à refeição
  void addFoodToMeal(String mealTitle, String foodName) {
    final foodInfo = foodDatabase[foodName];
    int calories = 200, protein = 5, fat = 3, carbs = 10;
    if (foodInfo != null) {
      calories = foodInfo['calories'] as int;
      protein = foodInfo['protein'] as int;
      fat = foodInfo['fat'] as int;
      carbs = foodInfo['carbs'] as int;
    }
    final mealIndex = meals.indexWhere((m) => m.title == mealTitle);
    if (mealIndex != -1) {
      setState(() {
        // Remove placeholders if any exist when adding a real food item
        meals[mealIndex].items.removeWhere((item) => item.isPlaceholder);

        // Add the new food item
        meals[mealIndex].items.add(
              MealItemData(
                  name: foodName,
                  calories: calories,
                  protein: protein,
                  fat: fat,
                  carbs: carbs),
            );
        meals[mealIndex].totalCalories =
            meals[mealIndex].items.fold(0, (sum, i) => sum + i.calories);
        calculateTotalCalories();
      });
    }
  }

  // Remove alimento da refeição
  void removeFoodFromMeal(String mealTitle, int itemIndex) {
    final mealIndex = meals.indexWhere((m) => m.title == mealTitle);
    if (mealIndex != -1 &&
        itemIndex >= 0 &&
        itemIndex < meals[mealIndex].items.length) {
      setState(() {
        // Remove o item
        meals[mealIndex].items.removeAt(itemIndex);

        // Recalcula as calorias da refeição
        if (meals[mealIndex].items.isNotEmpty) {
          meals[mealIndex].totalCalories =
              meals[mealIndex].items.fold(0, (sum, i) => sum + i.calories);
        } else {
          meals[mealIndex].totalCalories = 0;
        }

        // Recalcula os totais diários
        calculateTotalCalories();
      });
    }
  }

  // Controle de timers de gravação
  void startRecordingTimer() {
    recordingDuration = 0;
    recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => recordingDuration++);
    });
  }

  void stopRecordingTimer() {
    recordingTimer?.cancel();
    recordingTimer = null;
  }

  String get formattedRecordingTime {
    final m = (recordingDuration ~/ 60).toString().padLeft(2, '0');
    final s = (recordingDuration % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void showAddFoodModal(String mealTitle) {
    setState(() {
      showRecordingModal = true;
      selectedMealTitle = mealTitle;
      hasRecordedAudio = false;
      isRecording = false;
      isLongPress = false;
      isPlayingAudio = false;
      micButtonOffset = 0;
    });
  }

  void hideAddFoodModal() => setState(() => showRecordingModal = false);

  void playRecordedAudio() {
    // só visual por enquanto
    setState(() => isPlayingAudio = true);
    Timer(Duration(seconds: recordingDuration), () {
      if (mounted) setState(() => isPlayingAudio = false);
    });
  }

  void deleteRecordedAudio() {
    setState(() {
      hasRecordedAudio = false;
      recordingDuration = 0;
      isRecording = false;
      isLongPress = false;
    });
  }

  void submitRecordedAudio() => registerFoodFromAudio();

  void registerFoodFromAudio() {
    if (hasRecordedAudio) {
      final foodNames = foodDatabase.keys.toList();
      final randomIndex = DateTime.now().microsecond % foodNames.length;
      addFoodToMeal(selectedMealTitle, foodNames[randomIndex]);
      setState(() {
        showRecordingModal = false;
        hasRecordedAudio = false;
        recordingDuration = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/seta_esquerda.svg',
              height: 20, width: 20),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
        title: const Text(
          'Refeições',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
              child: SvgPicture.asset('assets/icons/dots.svg',
                  height: 5, width: 5),
            ),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              return ScrollConfiguration(
                behavior: const _NoGlowScrollBehavior(),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateSelector(),
                        const SizedBox(height: 25),
                        _buildSummaryCard(),
                        const SizedBox(height: 25),
                        ...meals.map((meal) => _buildMealSection(meal)),
                        const SizedBox(height: 30),
                        _buildMacrosOverview(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          if (showRecordingModal) _buildRecordingModal(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    // Use selectedDate para definir o mês/ano exibido
    final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    final totalDays = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // Scroll to selected day only on first load
    if (!_initialScrollDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const itemWidth = 60 + 12;
        final screenW = MediaQuery.of(context).size.width;
        final offset = (itemWidth * (selectedDate.day - 1)) - (screenW / 2) + (itemWidth / 2);
        if (offset > 0) _dateScrollController.jumpTo(offset);
        _initialScrollDone = true;
      });
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<DateTime>(
              context: context,
              builder: (ctx) => _MonthYearPickerDialog(
                initialDate: selectedDate,
              ),
            );
            if (picked != null) {
              setState(() {
                selectedDate = picked;
                _loadMealsForDate(picked);
                _initialScrollDone = false;
              });
            }
          },
          child: Text(
            "${getMonthName(selectedDate.month)} ${selectedDate.year}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ScrollConfiguration(
            behavior: const _NoGlowScrollBehavior().copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _dateScrollController,
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: totalDays,
              itemBuilder: (_, i) {
                final date = startDate.add(Duration(days: i));
                final sel = date.day == selectedDate.day &&
                    date.month == selectedDate.month &&
                    date.year == selectedDate.year;
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedDate = date);
                    _loadMealsForDate(date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 62,
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xff92A3FD)
                          : _isToday(date)
                              ? const Color(0xff92A3FD).withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color:
                                      const Color(0xff92A3FD).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]
                          : null,
                      border: _isToday(date) && !sel
                          ? Border.all(
                              color: const Color(0xff92A3FD), width: 1.5)
                          : sel
                              ? null
                              : Border.all(
                                  color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_getWeekdayAbbr(date.weekday),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: sel
                                      ? Colors.white
                                      : _isToday(date)
                                          ? const Color(0xff92A3FD)
                                          : Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Text("${date.day}",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: sel
                                      ? Colors.white
                                      : _isToday(date)
                                          ? const Color(0xff92A3FD)
                                          : Colors.black87)),
                        ]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey.shade50, width: 1),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildSummaryItem(
            icon: Icons.local_fire_department_rounded,
            value: totalDailyCalories.toString(),
            label: 'Calorias',
            color: Colors.orange),
        Container(
            height: 50,
            width: 1,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              Colors.white,
              Colors.grey.shade200,
              Colors.white
            ]))),
        _buildSummaryItemSvg(
            svgPath: 'assets/icons/protein.svg',
            value: proteinTotal.toString(),
            label: 'Proteína (g)',
            color: Colors.green),
        Container(
            height: 50,
            width: 1,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              Colors.white,
              Colors.grey.shade200,
              Colors.white
            ]))),
        _buildSummaryItem(
            icon: Icons.fastfood_rounded,
            value: carbsTotal.toString(),
            label: 'Carbs (g)',
            color: Colors.blue),
      ]),
    );
  }

  Widget _buildSummaryItem(
      {required IconData icon,
      required String value,
      required String label,
      required Color color}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildSummaryItemSvg(
      {required String svgPath,
      required String value,
      required String label,
      required Color color}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: SvgPicture.asset(svgPath, color: color, width: 20, height: 20),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildMealSection(MealData meal) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
          border: Border.all(color: Colors.grey.shade50, width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cabeçalho da refeição
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Color(0xff92A3FD),
                    blurRadius: 2,
                    offset: Offset(0, 1))
              ],
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lado esquerdo com título da refeição
                  Expanded(
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: _getMealIcon(meal.title),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          meal.title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                  // Lado direito com calorias e botão de excluir
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 5),
                        Text('${meal.totalCalories} cal',
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 16),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Excluir Refeição'),
                            content: Text(
                                'Deseja excluir todos os itens de ${meal.title}?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Excluir')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          setState(() {
                            meal.items.clear();
                            meal.totalCalories = 0;
                            calculateTotalCalories();
                            // Add a placeholder item to avoid rendering issues
                            if (meal.items.isEmpty) {
                              meal.items.add(MealItemData(
                                name: "Adicione um alimento",
                                calories: 0,
                                protein: 0,
                                fat: 0,
                                carbs: 0,
                                isPlaceholder: true,
                              ));
                            }
                          });
                        }
                      },
                    ),
                  ]),
                ]),
          ),
          const SizedBox(height: 10),
          if (meal.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.restaurant, size: 30, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text("Nenhum alimento registrado",
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Adicione alimentos usando o botão abaixo",
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ]),
              ),
            )
          else
            ...meal.items.map((item) => _buildMealItem(item)),
          // Botão "Adicionar Alimento"
          Align(
            alignment: Alignment.center,
            child: InkWell(
              onTap: () => showAddFoodModal(meal.title),
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                    color: const Color(0xff92A3FD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xff92A3FD).withOpacity(0.2))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xff92A3FD).withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.add,
                            size: 16, color: Color(0xff92A3FD)),
                      ),
                      const SizedBox(width: 10),
                      const Text("Adicionar Alimento",
                          style: TextStyle(
                              color: Color(0xff92A3FD),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
        ]),
      ),
    );
  }

  Widget _buildMealItem(MealItemData item) {
    // If it's a placeholder, display a special UI with no dismissible
    if (item.isPlaceholder) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            item.name,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Regular food item with dismissible
    return Dismissible(
      key: UniqueKey(),
      background: Container(
          color: Colors.red.withOpacity(0.2),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.red)),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remover Alimento'),
            content: Text('Deseja remover ${item.name} do registro?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Remover')),
            ],
          ),
        );
        return confirm;
      },
      onDismissed: (_) {
        final mi = meals.indexWhere((m) => m.items.contains(item));
        if (mi != -1) {
          removeFoodFromMeal(meals[mi].title, meals[mi].items.indexOf(item));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade50,
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _buildNutrientBadge('P: ${item.protein}g', Colors.green),
                      const SizedBox(width: 6),
                      _buildNutrientBadge('C: ${item.carbs}g', Colors.blue),
                      const SizedBox(width: 6),
                      _buildNutrientBadge(
                          'G: ${item.fat}g', Colors.orangeAccent),
                    ]),
                  ),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xff92A3FD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_fire_department,
                      color: Color(0xff92A3FD), size: 16),
                  const SizedBox(width: 4),
                  Text('${item.calories}',
                      style: const TextStyle(
                          color: Color(0xff92A3FD),
                          fontWeight: FontWeight.bold))
                ])),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remover Alimento'),
                      content: Text('Deseja remover ${item.name} do registro?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar')),
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Remover')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final mi = meals.indexWhere((m) => m.items.contains(item));
                    if (mi != -1) {
                      removeFoodFromMeal(
                          meals[mi].title, meals[mi].items.indexOf(item));
                    }
                  }
                },
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18)),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return Dialog(
                        backgroundColor: Colors.white,
                        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título e ícone de lixeira
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.purple),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      final mi = meals.indexWhere((m) => m.items.contains(item));
                                      if (mi != -1) {
                                        removeFoodFromMeal(meals[mi].title, meals[mi].items.indexOf(item));
                                      }
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tabela TACO',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Campo quantidade e unidade (visual)
                              Row(
                                children: [
                                  Container(
                                    width: 85,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "50",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF7B6F72),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 85,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "G",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFF7B6F72),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF7B6F72)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              const Text(
                                'Informação Nutricional',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),

                              // Calorias
                              _buildInfoCard(
                                iconPath: 'assets/icons/protein.svg',
                                label: 'Calorias',
                                value: '${item.calories} cal',
                              ),
                              const SizedBox(height: 10),

                              // Proteínas
                              _buildInfoCard(
                                iconPath: 'assets/icons/protein.svg',
                                label: 'Proteínas',
                                value: '${item.protein}g',
                              ),
                              const SizedBox(height: 10),

                              // Gordura
                              _buildInfoCard(
                                iconPath: 'assets/icons/protein.svg',
                                label: 'Gordura',
                                value: '${item.fat}g',
                              ),
                              const SizedBox(height: 10),

                              // Carboidrato
                              _buildInfoCard(
                                iconPath: 'assets/icons/protein.svg',
                                label: 'Carbo',
                                value: '${item.carbs}g',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }

Widget _buildInfoCard({
  required String iconPath,
  required String label,
  required String value,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Texto + Ícone (esquerda)
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: Color(0xFF1D1617), // ← cor dos nomes
                ),
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(iconPath, width: 18, height: 18),
            ],
          ),
        ),

        // Valor à direita (ex: 500 cal)
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: Color(0xFF7B6F72), // ← cor dos valores
          ),
        ),
      ],
    ),
  );
}

  Widget _buildNutrientBadge(String text, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)));
  }

  Widget _buildMacrosOverview() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.pie_chart_rounded, color: Color(0xff92A3FD), size: 24),
        const SizedBox(width: 8),
        const Expanded(
            child: Text('Macros Totais',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xff92A3FD).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xff92A3FD).withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ]),
          child: const Row(children: [
            Icon(Icons.insights_rounded,
                color: Color(0xff92A3FD), size: 16),
            SizedBox(width: 5),
            Text('Progresso diário',
                style: TextStyle(
                    color: Color(0xff92A3FD),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      _buildMacroBar(
          label: "Calorias",
          emoji: "🔥",
          current: totalDailyCalories.toDouble(),
          total: caloriesGoal.toDouble()),
      _buildMacroBar(
          label: "Proteínas",
          svgPath: 'assets/icons/protein.svg',
          current: proteinTotal.toDouble(),
          total: proteinGoal.toDouble()),
      _buildMacroBar(
          label: "Gordura",
          emoji: "🥜",
          current: fatTotal.toDouble(),
          total: fatGoal.toDouble()),
      _buildMacroBar(
          label: "Carbo",
          emoji: "🌾",
          current: carbsTotal.toDouble(),
          total: carbsGoal.toDouble()),
    ]);
  }

  Widget _buildMacroBar({
    required String label,
    String? emoji,
    String? svgPath,
    required double current,
    required double total,
  }) {
    assert(emoji != null || svgPath != null,
        "Either emoji or svgPath must be provided");
    final progress = (current / total).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    Color progressColor;
    if (percent < 30) {
      progressColor = Colors.redAccent;
    } else if (percent < 70) {
      progressColor = const Color(0xFF9DCEFF);
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
                color: Colors.grey.shade100,
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: progressColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]),
              child: svgPath != null
                  ? SvgPicture.asset(svgPath,
                      color: progressColor, width: 20, height: 20)
                  : Text(emoji!, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$percent%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: progressColor))),
            const SizedBox(height: 4),
            Text(
                '${current.toInt()} / ${total.toInt()}${label == 'Calorias' ? ' kCal' : 'g'}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: progressColor)),
          ]),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10))),
          LayoutBuilder(builder: (context, constraints) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              height: 12,
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                    colors: [progressColor.withOpacity(0.7), progressColor]),
                boxShadow: [
                  BoxShadow(
                      color: progressColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
            );
          }),
        ]),
      ]),
    );
  }

  Widget _buildRecordingModal() {
    return GestureDetector(
      onTap: hideAddFoodModal,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevents tap from dismissing
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  "Adicionar alimento para $selectedMealTitle",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xff1D1617).withOpacity(0.11),
                            blurRadius: 40)
                      ]),
                  child: Row(children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Row(children: [
                          Listener(
                            onPointerDown: !hasRecordedAudio &&
                                    !isRecording &&
                                    !isPlayingAudio
                                ? (_) {
                                    setState(() {
                                      micButtonOffset = -5;
                                    });
                                    recordingDelayTimer = Timer(
                                        const Duration(milliseconds: 50), () {
                                      if (mounted) {
                                        setState(() {
                                          isLongPress = true;
                                          isRecording = true;
                                          startRecordingTimer();
                                        });
                                      }
                                    });
                                  }
                                : null,
                            onPointerUp: (_) {
                              if (!isLongPress) {
                                recordingDelayTimer?.cancel();
                                setState(() {
                                  micButtonOffset = 0;
                                });
                              } else {
                                setState(() {
                                  micButtonOffset = 0;
                                  isRecording = false;
                                  hasRecordedAudio = true;
                                  stopRecordingTimer();
                                  isLongPress = false;
                                });
                              }
                            },
                            child: GestureDetector(
                              onTap: hasRecordedAudio &&
                                      !isRecording &&
                                      !isPlayingAudio
                                  ? playRecordedAudio
                                  : null,
                              child: AnimatedContainer(
                                height: 28,
                                width: 28,
                                duration: const Duration(milliseconds: 150),
                                transform: Matrix4.translationValues(
                                    0, micButtonOffset, 0),
                                child: hasRecordedAudio
                                    ? Icon(
                                        isPlayingAudio
                                            ? Icons.pause_circle_filled
                                            : Icons.play_arrow,
                                        color: const Color(0xff92A3FD),
                                        size: 28)
                                    : SvgPicture.asset('assets/icons/mic.svg',
                                        color: isRecording
                                            ? const Color(0xff92A3FD)
                                            : null),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: isRecording || isPlayingAudio
                                ? Row(children: [
                                    Text(formattedRecordingTime,
                                        style: const TextStyle(
                                            color: Color(0xff92A3FD),
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        isRecording
                                            ? 'Gravando...'
                                            : 'Reproduzindo...',
                                        style: const TextStyle(
                                            color: Color(0xff92A3FD),
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ])
                                : Text(
                                    hasRecordedAudio
                                        ? 'Áudio gravado'
                                        : 'Pressione e segure para falar',
                                    style: TextStyle(
                                        color: hasRecordedAudio
                                            ? const Color(0xff92A3FD)
                                            : const Color(0xffDDDADA),
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          if (hasRecordedAudio &&
                              !isRecording &&
                              !isPlayingAudio)
                            GestureDetector(
                              onTap: deleteRecordedAudio,
                              child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.red, size: 20)),
                            ),
                        ]),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(5),
                      width: 50,
                      child: Row(children: [
                        Container(
                            width: 1,
                            height: 30,
                            color: const Color(0xFFEEEEEE)),
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: hasRecordedAudio &&
                                      !isRecording &&
                                      !isPlayingAudio
                                  ? submitRecordedAudio
                                  : null,
                              child: SvgPicture.asset('assets/icons/enviar.svg',
                                  color: hasRecordedAudio &&
                                          !isRecording &&
                                          !isPlayingAudio
                                      ? null
                                      : Colors.grey),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: hideAddFoodModal,
                      child: const Text("Cancelar",
                          style: TextStyle(color: Colors.grey))),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _getWeekdayAbbr(int w) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days[w - 1];
  }

  String _getMonthName(int m) {
    const months = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro"
    ];
    return months[m - 1];
  }

  Widget _getMealIcon(String title) {
    switch (title) {
      case "Café da Manhã":
        return const Icon(Icons.free_breakfast, color: Colors.white);
      case "Almoço":
        return const Icon(Icons.restaurant, color: Colors.white);
      case "Lanches":
        return const Icon(Icons.cookie, color: Colors.white);
      case "Janta":
        return const Icon(Icons.dinner_dining, color: Colors.white);
      default:
        return const Icon(Icons.restaurant_menu, color: Colors.white);
    }
  }
}

// Classes para os dados de refeição
class MealData {
  final String title;
  int totalCalories;
  List<MealItemData> items;

  MealData({
    required this.title,
    required this.totalCalories,
    required this.items,
  });
}

class MealItemData {
  final String name;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final bool isPlaceholder;

  MealItemData({
    required this.name,
    required this.calories,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.isPlaceholder = false,
  });
}

// Comportamento para remover efeito de glow azul nas listas e permitir scrolling com toque
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _MonthYearPickerDialog({required this.initialDate});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialDate.month;
    selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecione mês e ano'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mês
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text(getMonthName(i + 1)),
              );
            }),
            onChanged: (v) => setState(() => selectedMonth = v!),
          ),
          const SizedBox(width: 16),
          // Ano
          DropdownButton<int>(
            value: selectedYear,
            items: List.generate(10, (i) {
              final year = DateTime.now().year - 5 + i;
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }),
            onChanged: (v) => setState(() => selectedYear = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(DateTime(selectedYear, selectedMonth, 1));
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

String getMonthName(int m) {
  const months = [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ];
  return months[m - 1];
}