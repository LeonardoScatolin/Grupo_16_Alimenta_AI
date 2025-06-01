import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alimenta_ai/models/modelo_categoria.dart';
import 'package:alimenta_ai/models/ver_dietanutri.dart';
import 'package:alimenta_ai/services/audio_service.dart';
import 'package:alimenta_ai/services/nutricao_service.dart';
import 'package:alimenta_ai/widgets/audio_debug_widget.dart';

class RegistroUnificadoPage extends StatefulWidget {
  const RegistroUnificadoPage({Key? key}) : super(key: key);

  @override
  State<RegistroUnificadoPage> createState() => _RegistroUnificadoPageState();
}

class _RegistroUnificadoPageState extends State<RegistroUnificadoPage> {
  // Constants for default user IDs
  static const int DEFAULT_PACIENTE_ID = 1;
  static const int DEFAULT_NUTRI_ID = 1;

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
  // Meta diária dinâmica (carregada da API)
  int caloriesGoal = 2000;
  int proteinGoal = 150;
  int fatGoal = 80;
  int carbsGoal = 250;
  // Modelo de dados para refeições
  late List<MealData> meals;

  // Cache em memória das refeições por data
  Map<String, List<MealData>> _mealsByDate = {};

  // Getter para obter refeições da data atual
  List<MealData> get _currentDisplayMeals =>
      _mealsByDate[_formatDateForBackend(selectedDate)] ??
      _initializeEmptyMealsForDate();

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
    // Não calcular totais aqui pois ainda não há dados carregados

    // Carregar dados do NutricaoService
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('🚀 Iniciando carregamento de dados no initState...');

      await _inicializarServicos();

      debugPrint('📅 Carregando dados para data: $selectedDate');
      // Carregar dados para a data atual (prioriza SharedPreferences)
      _loadMealsForDate(selectedDate);

      // Carregar metas explicitamente para garantir que são carregadas
      final dateString = _formatDateForBackend(selectedDate);
      debugPrint('📊 Carregando metas para data: $dateString');
      _carregarMetasParaData(dateString);

      // Aguardar um pouco para as operações assíncronas
      await Future.delayed(Duration(milliseconds: 500));

      debugPrint(
          '📊 Estado atual das metas: $caloriesGoal cal, $proteinGoal prot');
      debugPrint('📊 Estado atual das calorias: $totalDailyCalories cal');

      // Verificar permissões do microfone
      _verificarPermissoesMicrofone();
    });
  }

  // Inicializar serviços com dados do usuário
  Future<void> _inicializarServicos() async {
    // Configurações de teste - CORRIGIDO: usar ID do usuário logado
    debugPrint('⚙️ Inicializando serviços...');

    final nutricaoService =
        Provider.of<NutricaoService>(context, listen: false);

    // Obter IDs do usuário logado dinamicamente
    final userIdString =
        await _getStoredUserId() ?? DEFAULT_PACIENTE_ID.toString();
    final userId = int.tryParse(userIdString) ?? DEFAULT_PACIENTE_ID;

    debugPrint('👤 Configurando serviços para usuário ID: $userId');

    // Configurar usuários dinamicamente
    nutricaoService.configurarUsuarios(userId, DEFAULT_NUTRI_ID);

    // Carregar metas da API
    _carregarMetasPublicas();
  }

  // Verifica permissões para gravação de áudio
  Future<void> _verificarPermissoesMicrofone() async {
    final audioService = Provider.of<AudioService>(context, listen: false);
    final permissionGranted = await audioService.checkAndRequestPermissions();
    if (!permissionGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Permissão de microfone necessária para gravação de áudio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Carregar metas definidas pela nutricionista (sem autenticação)
  void _carregarMetasPublicas() async {
    final nutricaoService =
        Provider.of<NutricaoService>(context, listen: false);

    try {
      // CORRIGIDO: usar ID do usuário logado dinamicamente
      final userIdString =
          await _getStoredUserId() ?? DEFAULT_PACIENTE_ID.toString();
      final userId = int.tryParse(userIdString) ?? DEFAULT_PACIENTE_ID;

      debugPrint('👤 Carregando metas para usuário ID: $userId');

      final meta = await nutricaoService.buscarMetasPublicas(
        pacienteIdOverride: userId, // ID do paciente logado
        nutriIdOverride: DEFAULT_NUTRI_ID, // ID da nutricionista
      );

      if (meta != null) {
        setState(() {
          caloriesGoal = meta.caloriesGoal;
          proteinGoal = meta.proteinGoal;
          fatGoal = meta.fatGoal;
          carbsGoal = meta.carbsGoal;
        });
        debugPrint(
            '✅ Metas carregadas: ${meta.calorias} cal, ${meta.proteina}g prot');
      } else {
        debugPrint(
            '⚠️ Usando metas padrão - nenhuma meta personalizada encontrada');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar metas: $e');
      // Manter valores padrão em caso de erro
    }
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

  // Inicializa refeições padrão (vazias - dados virão da API)
  void initializeMeals() {
    meals = [
      MealData(
        title: "Café da Manhã",
        totalCalories: 0,
        items: [],
      ),
      MealData(
        title: "Almoço",
        totalCalories: 0,
        items: [],
      ),
      MealData(
        title: "Lanches",
        totalCalories: 0,
        items: [],
      ),
      MealData(
        title: "Janta",
        totalCalories: 0,
        items: [],
      ),
    ];
  } // Carrega refeições de acordo com a data (dados do cache local ou API)

  void _loadMealsForDate(DateTime date) async {
    // Atualizar selectedDate
    selectedDate = date;

    // Carregar dados para a data selecionada
    final dateString = _formatDateForBackend(date);
    debugPrint('🗓️ Carregando dados para a data: $dateString');

    // Primeiro: tentar carregar do SharedPreferences
    final cachedMeals = await _loadMealsFromPrefs(dateString);

    if (cachedMeals != null) {
      debugPrint('💾 Dados encontrados no cache local para $dateString');

      // Atualizar cache em memória
      _mealsByDate[dateString] = cachedMeals;

      // Atualizar variável meals para compatibilidade com código existente
      setState(() {
        meals = List.from(cachedMeals);
      });

      // Calcular totais de macronutrientes APÓS carregar os dados
      calculateTotalCalories();

      // Carregar metas para a data
      _carregarMetasParaData(dateString);

      debugPrint('✅ Dados carregados do cache local para $dateString');
      return;
    }

    // Se não há dados no cache, buscar do backend
    debugPrint('🌐 Buscando dados do backend para $dateString');
    await _fetchAndSetMealsForDate(dateString);
  }

  // Carrega alimentos detalhados salvos no backend para a data específica
  Future<void> _loadDetailedFoodsForDate(String dateString) async {
    final nutricaoService =
        Provider.of<NutricaoService>(context, listen: false);

    try {
      debugPrint('🔍 Iniciando carregamento de alimentos para $dateString...');
      debugPrint('🏥 Paciente ID configurado: ${nutricaoService.pacienteId}');

      // Buscar alimentos detalhados para a data agrupados por refeição
      final alimentosAgrupados =
          await nutricaoService.obterAlimentosPorData(dateString);

      debugPrint('📊 Resultado da busca:');
      debugPrint(
          '- Tipos de refeição encontrados: ${alimentosAgrupados.keys.toList()}');
      debugPrint(
          '- Total de alimentos: ${alimentosAgrupados.values.expand((x) => x).length}');

      // Debug detalhado por refeição
      alimentosAgrupados.forEach((tipo, alimentos) {
        debugPrint('  📝 $tipo: ${alimentos.length} alimentos');
        for (var alimento in alimentos) {
          debugPrint(
              '    🍎 ${alimento.nomeAlimento} - ${alimento.quantidade}g');
        }
      });
      if (alimentosAgrupados.isNotEmpty) {
        debugPrint(
            '✅ Carregados alimentos para $dateString: ${alimentosAgrupados.keys}');

        // Atualizar as meals com os alimentos carregados
        setState(() {
          // Só limpar se realmente existem dados para carregar do backend
          // Isso evita limpar dados locais recém-adicionados quando o backend está vazio
          if (alimentosAgrupados.isNotEmpty) {
            // Primeiro, limpar todos os itens das refeições
            for (var meal in meals) {
              meal.items.clear();
              meal.totalCalories = 0;
            }
          }

          // Adicionar alimentos carregados
          alimentosAgrupados.forEach((tipoRefeicaoOriginal, alimentos) {
            final tipoRefeicaoMapeado =
                _mapearTipoRefeicaoParaUI(tipoRefeicaoOriginal);

            debugPrint(
                '🍽️ Processando: $tipoRefeicaoOriginal -> $tipoRefeicaoMapeado (${alimentos.length} alimentos)');

            // Encontrar a meal correspondente
            final mealIndex =
                meals.indexWhere((meal) => meal.title == tipoRefeicaoMapeado);

            debugPrint(
                '📍 Meal encontrada no índice: $mealIndex para "$tipoRefeicaoMapeado"');

            if (mealIndex != -1) {
              // Converter RegistroAlimentoDetalhado para MealItemData
              final itensConvertidos = alimentos.map((alimento) {
                return MealItemData(
                  name:
                      '${alimento.nomeAlimento} (${alimento.quantidade.toStringAsFixed(0)}g)',
                  calories: alimento.calorias.round(),
                  protein: alimento.proteinas.round(),
                  fat: alimento.gorduras.round(),
                  carbs: alimento.carboidratos.round(),
                  registroId: alimento.id, // Salvar ID para permitir remoção
                );
              }).toList();
              meals[mealIndex].items.addAll(itensConvertidos);

              debugPrint(
                  '✅ Adicionados ${itensConvertidos.length} itens à "${meals[mealIndex].title}"');

              // Recalcular total de calorias da refeição
              meals[mealIndex].totalCalories = meals[mealIndex]
                  .items
                  .fold(0, (sum, item) => sum + item.calories);

              debugPrint(
                  '📊 "${meals[mealIndex].title}" agora tem ${meals[mealIndex].items.length} itens e ${meals[mealIndex].totalCalories} kcal');
            } else {
              debugPrint('❌ ERRO: Meal "$tipoRefeicaoMapeado" não encontrada!');
            }
          }); // Recalcular totais gerais
          calculateTotalCalories();

          // Debug: Verificar estado final das meals
          debugPrint('📊 Estado final das refeições:');
          for (var meal in meals) {
            debugPrint(
                '  ${meal.title}: ${meal.items.length} itens, ${meal.totalCalories} cal');
            for (var item in meal.items) {
              debugPrint('    - ${item.name} (${item.calories} cal)');
            }
          }
        }); // Salvar dados carregados do backend no cache local
        await _saveMealsToPrefs(dateString, meals);

        debugPrint(
            '✅ Carregados ${alimentosAgrupados.values.expand((x) => x).length} alimentos para $dateString e salvos no cache');
      } else {
        debugPrint(
            'ℹ️ Nenhum alimento encontrado para $dateString - mantendo dados zerados');
        // Garantir que os dados ficam zerados quando não há alimentos
        setState(() {
          for (var meal in meals) {
            meal.items.clear();
            meal.totalCalories = 0;
          }
          totalDailyCalories = 0;
          proteinTotal = 0;
          fatTotal = 0;
          carbsTotal = 0;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar alimentos detalhados: $e');
      // Em caso de erro, garantir que dados ficam zerados
      setState(() {
        for (var meal in meals) {
          meal.items.clear();
          meal.totalCalories = 0;
        }
        totalDailyCalories = 0;
        proteinTotal = 0;
        fatTotal = 0;
        carbsTotal = 0;
      });
    }
  }

  /// Carregar metas para uma data específica
  void _carregarMetasParaData(String data) async {
    final nutricaoService =
        Provider.of<NutricaoService>(context, listen: false);

    try {
      // Obter ID do usuário logado corretamente
      final userId = await _getStoredUserId();
      final pacienteId = int.tryParse(userId ?? '') ?? DEFAULT_PACIENTE_ID;

      debugPrint(
          '🔍 Buscando metas para paciente ID: $pacienteId, data: $data');

      final meta = await nutricaoService.buscarMetasPublicas(
        pacienteIdOverride: pacienteId, // ID do paciente logado
        nutriIdOverride:
            1, // ID da nutricionista (pode ser configurável depois)
        data: data,
      );

      if (meta != null) {
        debugPrint(
            '✅ Metas encontradas: ${meta.caloriesGoal} cal, ${meta.proteinGoal} prot, ${meta.fatGoal} fat, ${meta.carbsGoal} carbs');

        setState(() {
          caloriesGoal = meta.caloriesGoal;
          proteinGoal = meta.proteinGoal;
          fatGoal = meta.fatGoal;
          carbsGoal = meta.carbsGoal;
        });

        debugPrint(
            '✅ Metas carregadas e aplicadas para paciente $pacienteId: ${meta.caloriesGoal} cal');
      } else {
        debugPrint(
            '⚠️ Nenhuma meta encontrada para paciente $pacienteId na data $data');
        debugPrint(
            '🔄 Mantendo metas padrão: $caloriesGoal cal, $proteinGoal prot');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar metas para data $data: $e');
      debugPrint(
          '🔄 Mantendo metas padrão: $caloriesGoal cal, $proteinGoal prot');
    }
  }

  // Cálculo de calorias e macros totais do dia
  void calculateTotalCalories() {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalFat = 0;
    int totalCarbs = 0;

    // Usar _currentDisplayMeals ao invés de meals para garantir que usamos os dados corretos
    final currentMeals = _currentDisplayMeals;

    for (var meal in currentMeals) {
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

    debugPrint(
        '🧮 Cálculo realizado - Total: $totalDailyCalories cal, Protein: $totalProtein, Fat: $totalFat, Carbs: $totalCarbs');
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
  void removeFoodFromMeal(String mealTitle, int itemIndex) async {
    final mealIndex = meals.indexWhere((m) => m.title == mealTitle);
    if (mealIndex != -1 &&
        itemIndex >= 0 &&
        itemIndex < meals[mealIndex].items.length) {
      final itemToRemove = meals[mealIndex].items[itemIndex];

      // Se o item tem um registroId, remover do backend também
      if (itemToRemove.registroId != null) {
        final nutricaoService =
            Provider.of<NutricaoService>(context, listen: false);

        try {
          // Armazenar os macros do item antes de remover
          final currentDateString = _formatDateForBackend(selectedDate);
          final caloriasParaRemover = itemToRemove.calories.toDouble();
          final proteinaParaRemover = itemToRemove.protein.toDouble();
          final carboidratoParaRemover = itemToRemove.carbs.toDouble();
          final gorduraParaRemover = itemToRemove.fat.toDouble();

          debugPrint('🗑️ Iniciando remoção do item: ${itemToRemove.name}');
          debugPrint(
              '📊 Macros a remover - Cal: $caloriasParaRemover, Prot: $proteinaParaRemover, Carb: $carboidratoParaRemover, Gord: $gorduraParaRemover');

          // 1. Primeiro, remover o item específico do backend
          final deleteSuccess = await nutricaoService
              .removerAlimentoDetalhado(itemToRemove.registroId!);

          if (!deleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao remover alimento do servidor'),
                backgroundColor: Colors.red,
              ),
            );
            return; // Não prosseguir se a deleção falhou
          }

          debugPrint(
              '✅ Item removido do backend com sucesso'); // 2. Subtrair os macros do resumo diário
          final subtrairSuccess = await nutricaoService.removerAlimento(
            proteina: proteinaParaRemover,
            carboidrato: carboidratoParaRemover,
            gordura: gorduraParaRemover,
            calorias: caloriasParaRemover,
            data: currentDateString,
          );

          if (subtrairSuccess) {
            debugPrint('✅ Macros subtraídos com sucesso do resumo diário');

            // 3. Atualizar a UI local apenas se tudo ocorreu bem
            setState(() {
              // Remove o item
              final removedItem = meals[mealIndex].items[itemIndex];
              meals[mealIndex].items.removeAt(itemIndex);

              debugPrint(
                  '🗑️ Removendo item da UI: ${removedItem.name} (${removedItem.calories} cal)');
              debugPrint('📊 Total antes da remoção: $totalDailyCalories cal');

              // Recalcula as calorias da refeição
              if (meals[mealIndex].items.isNotEmpty) {
                meals[mealIndex].totalCalories = meals[mealIndex]
                    .items
                    .fold(0, (sum, i) => sum + i.calories);
              } else {
                meals[mealIndex].totalCalories = 0;
              }

              // Recalcula os totais diários
              calculateTotalCalories();

              debugPrint('📊 Total após remoção: $totalDailyCalories cal');
            });

            // 4. Salvar no cache local após remoção bem-sucedida
            _mealsByDate[currentDateString] = List.from(meals);
            await _saveMealsToPrefs(currentDateString, meals);
            debugPrint('💾 Cache atualizado após remoção de alimento');

            // 5. Mostrar feedback de sucesso
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Alimento "${itemToRemove.name}" removido com sucesso'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Se subtrairMacros falhou, mostrar aviso mas manter UI consistente
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Item removido, mas houve problema ao atualizar totais no servidor'),
                backgroundColor: Colors.orange,
              ),
            );
            // Ainda assim, atualizar a UI local para consistência visual
            setState(() {
              meals[mealIndex].items.removeAt(itemIndex);

              // Recalcula as calorias da refeição
              if (meals[mealIndex].items.isNotEmpty) {
                meals[mealIndex].totalCalories = meals[mealIndex]
                    .items
                    .fold(0, (sum, i) => sum + i.calories);
              } else {
                meals[mealIndex].totalCalories = 0;
              }

              calculateTotalCalories();
            });

            // Atualizar cache local
            _mealsByDate[currentDateString] = List.from(meals);
            await _saveMealsToPrefs(currentDateString, meals);
          }
        } catch (e) {
          debugPrint('❌ Erro durante remoção: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover alimento: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return; // Não prosseguir se houve erro
        }
      } else {
        // Item sem registroId - apenas remoção local
        setState(() {
          final removedItem = meals[mealIndex].items[itemIndex];
          meals[mealIndex].items.removeAt(itemIndex);

          debugPrint(
              '🗑️ Removendo item local: ${removedItem.name} (${removedItem.calories} cal)');

          // Recalcula as calorias da refeição
          if (meals[mealIndex].items.isNotEmpty) {
            meals[mealIndex].totalCalories =
                meals[mealIndex].items.fold(0, (sum, i) => sum + i.calories);
          } else {
            meals[mealIndex].totalCalories = 0;
          }

          calculateTotalCalories();
        });

        // Salvar no cache local
        final currentDateString = _formatDateForBackend(selectedDate);
        _mealsByDate[currentDateString] = List.from(meals);
        await _saveMealsToPrefs(currentDateString, meals);
      }
    }
  }

  // Controle de timers de gravação  // Iniciar gravação de áudio real
  Future<void> startRecordingTimer() async {
    final audioService = Provider.of<AudioService>(context, listen: false);

    // Iniciar gravação real
    bool started = await audioService.startRecording();

    if (!started) {
      setState(() {
        isRecording = false;
        isLongPress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível iniciar a gravação'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Atualizar UI com duração da gravação
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            recordingDuration = audioService.recordingDuration.inSeconds;
          });
        }
      });
    }
  }

  // Parar gravação de áudio real
  Future<void> stopRecordingTimer() async {
    final audioService = Provider.of<AudioService>(context, listen: false);

    // Parar timer e gravação
    recordingTimer?.cancel();
    recordingTimer = null;

    final audioPath = await audioService.stopRecording();

    if (audioPath != null) {
      setState(() {
        hasRecordedAudio = true;
      });
    }
  }

  String get formattedRecordingTime {
    final audioService = Provider.of<AudioService>(context, listen: false);
    return audioService.formattedDuration;
  }

  void showAddFoodModal(String mealTitle) {
    final audioService = Provider.of<AudioService>(context, listen: false);

    // Configurar o tipo de refeição no AudioService
    audioService.setCurrentMealType(mealTitle);

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
  Future<void> playRecordedAudio() async {
    final audioService = Provider.of<AudioService>(context, listen: false);

    // Reproduzir áudio real
    setState(() => isPlayingAudio = true);
    await audioService.playRecording();

    // A mudança de estado é controlada pelo listener do audioService
    audioService.addListener(() {
      if (!audioService.isPlaying && mounted) {
        setState(() => isPlayingAudio = false);
      }
    });
  }

  Future<void> deleteRecordedAudio() async {
    final audioService = Provider.of<AudioService>(context, listen: false);

    // Deletar arquivo de áudio
    await audioService.deleteCurrentRecording();

    setState(() {
      hasRecordedAudio = false;
      recordingDuration = 0;
      isRecording = false;
      isLongPress = false;
    });
  }

  Future<void> submitRecordedAudio() async {
    final audioService = Provider.of<AudioService>(context, listen: false);

    if (hasRecordedAudio && audioService.currentRecordingPath != null) {
      setState(() => showRecordingModal = false);

      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      try {
        // 🔄 PRIMEIRO: Aguardar a transcrição ser concluída (se ainda não foi)
        if (audioService.isTranscribing) {
          debugPrint('⏳ Aguardando transcrição ser concluída...');
          // Aguardar até que a transcrição termine
          while (audioService.isTranscribing) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          debugPrint('✅ Transcrição concluída!');
        } // 🔄 SEGUNDO: Se não há resultado de busca, tentar realizar a busca agora
        if (audioService.lastFoodSearchResult == null &&
            audioService.lastTranscription != null) {
          debugPrint('🔍 Realizando busca adicional...');
          await audioService.searchFoodFromExistingTranscription();
        }

        // 🎯 TERCEIRO: Usar dados já obtidos pelo AudioService
        final foodData = audioService.getPrimaryFoodData();

        // 🐛 DEBUG: Verificar estado dos dados
        debugPrint('🔍 DEBUG: foodData = $foodData');
        debugPrint(
            '🔍 DEBUG: lastFoodSearchResult = ${audioService.lastFoodSearchResult}');
        debugPrint(
            '🔍 DEBUG: lastTranscription = ${audioService.lastTranscription}');

        if (foodData != null) {
          debugPrint(
              '🍎 Alimento encontrado pelo AudioService: ${foodData['nome']}');

          // Criar item de refeição com dados reais do backend
          final novoItem = MealItemData(
            name: '${foodData['nome']} (${foodData['quantidade_sugerida']}g)',
            calories: (foodData['calorias'] as num).round(),
            protein: (foodData['proteinas'] as num).round(),
            fat: (foodData['gordura'] as num).round(),
            carbs: (foodData['carboidratos'] as num).round(),
            isPlaceholder: false,
          );

          // Encontrar a refeição correspondente e adicionar o item
          final mealIndex = meals.indexWhere((meal) =>
              meal.title.toLowerCase() == selectedMealTitle.toLowerCase());
          if (mealIndex != -1) {
            setState(() {
              meals[mealIndex].items.add(novoItem);

              // Recalcular totais da refeição
              meals[mealIndex].totalCalories = meals[mealIndex]
                  .items
                  .fold(0, (sum, item) => sum + item.calories);

              // Atualizar totais diários
              totalDailyCalories += novoItem.calories;
              proteinTotal += novoItem.protein;
              fatTotal += novoItem.fat;
              carbsTotal += novoItem.carbs;
            }); // 🔥 IMPORTANTE: SALVAR NO BACKEND PARA PERSISTÊNCIA
            try {
              await _salvarAlimentoNoBackend(
                nomeAlimento: foodData['nome'],
                quantidade: foodData['quantidade_sugerida'],
                tipoRefeicao: selectedMealTitle,
                calorias: (foodData['calorias'] as num).toDouble(),
                proteinas: (foodData['proteinas'] as num).toDouble(),
                carboidratos: (foodData['carboidratos'] as num).toDouble(),
                gorduras: (foodData['gordura'] as num).toDouble(),
              );
              debugPrint('✅ Alimento salvo no backend com sucesso!');

              // Salvar no cache local após sucesso no backend
              final currentDateString = _formatDateForBackend(selectedDate);
              _mealsByDate[currentDateString] = List.from(meals);
              await _saveMealsToPrefs(currentDateString, meals);
              debugPrint('💾 Dados atualizados no cache local');

              // ⚠️ NÃO RECARREGAR - Os dados já estão na UI e foram salvos no backend
              // O reload pode causar perda de dados se o backend ainda não retornou
              // await _loadDetailedFoodsForDate(dateString);
            } catch (e) {
              debugPrint('⚠️ Erro ao salvar no backend: $e');
              // Se deu erro, remover da UI também
              setState(() {
                meals[mealIndex].items.removeLast();
                meals[mealIndex].totalCalories = meals[mealIndex]
                    .items
                    .fold(0, (sum, item) => sum + item.calories);
                totalDailyCalories -= novoItem.calories;
                proteinTotal -= novoItem.protein;
                fatTotal -= novoItem.fat;
                carbsTotal -= novoItem.carbs;
              });
              rethrow; // Re-throw para mostrar erro ao usuário
            }

            // Limpar dados de gravação
            setState(() {
              hasRecordedAudio = false;
              recordingDuration = 0;
            });

            // Limpar sessão do AudioService
            audioService.clearSession();

            // Remover indicador de carregamento
            if (mounted) Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ ${foodData['nome']} adicionado ao $selectedMealTitle!'),
                backgroundColor: Colors.green,
              ),
            );

            debugPrint(
                '✅ Alimento adicionado com sucesso à refeição $selectedMealTitle');
          } else {
            throw Exception('Refeição não encontrada: $selectedMealTitle');
          }
        } else {
          throw Exception('Nenhum alimento encontrado na busca');
        }
      } catch (e) {
        // Remover indicador de carregamento
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao adicionar alimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('❌ Erro ao processar alimento: $e');
        setState(() => showRecordingModal = true); // Voltar ao modal
      }
    }
  }

  /// 🔥 MÉTODO CRÍTICO: Salva alimento no backend para persistência
  Future<void> _salvarAlimentoNoBackend({
    required String nomeAlimento,
    required int quantidade,
    required String tipoRefeicao,
    required double calorias,
    required double proteinas,
    required double carboidratos,
    required double gorduras,
  }) async {
    try {
      debugPrint('🔄 Salvando alimento no backend...');
      debugPrint('📊 Dados: $nomeAlimento ($quantidade g) - $tipoRefeicao');

      // Pegar o usuário atual
      String? usuarioId = await _getStoredUserId();
      if (usuarioId == null) {
        throw Exception('Usuário não identificado');
      } // Acessar o API service através do NutricaoService
      final nutricaoService =
          Provider.of<NutricaoService>(context, listen: false);

      // Mapear tipo de refeição para formato do backend
      final tipoRefeicaoBackend = _mapearTipoRefeicaoParaBackend(tipoRefeicao);

      // Preparar dados para o backend (formato esperado pela API)
      final alimentoData = {
        'nomeAlimento': nomeAlimento,
        'quantidade': quantidade,
        'tipoRefeicao': tipoRefeicaoBackend,
        'pacienteId': int.parse(usuarioId),
        'nutriId': 1, // Por enquanto usar nutricionista padrão
        'observacoes':
            'Registrado via Flutter - ${_formatDateForBackend(selectedDate)}',
      };

      debugPrint(
          '📤 Enviando para backend: $alimentoData'); // Chamar API para salvar
      final response = await nutricaoService.apiService
          .salvarAlimentoDetalhado(alimentoData);

      if (response['success'] == true) {
        debugPrint('✅ Alimento salvo no backend com sucesso');
      } else {
        throw Exception('Resposta inválida do backend: $response');
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar alimento no backend: $e');
      rethrow; // Re-throw para que o caller possa tratar
    }
  }

  /// Helper para obter ID do usuário armazenado
  Future<String?> _getStoredUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id'); // Mudado para getInt

      // Fallback para usuário padrão se não encontrar
      if (userId == null) {
        debugPrint(
            '⚠️ user_id não encontrado, usando padrão: $DEFAULT_PACIENTE_ID');
        return DEFAULT_PACIENTE_ID.toString();
      }

      debugPrint('✅ user_id encontrado: $userId');
      return userId.toString(); // Converter int para string
    } catch (e) {
      debugPrint('❌ Erro ao obter user_id: $e');
      debugPrint('🔄 Usando user_id padrão: $DEFAULT_PACIENTE_ID');
      return DEFAULT_PACIENTE_ID.toString();
    }
  }

  /// Helper para formatar data para o backend (YYYY-MM-DD)
  String _formatDateForBackend(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Helper para mapear tipos de refeição para o formato do backend
  String _mapearTipoRefeicaoParaBackend(String tipoRefeicaoUI) {
    final Map<String, String> mapeamentoTipoRefeicao = {
      'Café da Manhã': 'cafe_manha',
      'Almoço': 'almoco',
      'Lanches': 'lanches',
      'Janta': 'janta',
    };

    return mapeamentoTipoRefeicao[tipoRefeicaoUI] ?? 'outro';
  }

  /// Helper para mapear tipos de refeição do backend para o formato da UI
  String _mapearTipoRefeicaoParaUI(String tipoRefeicaoBackend) {
    final Map<String, String> mapeamentoRefeicoes = {
      'cafe_manha': 'Café da Manhã',
      'almoco': 'Almoço',
      'lanches': 'Lanches',
      'janta': 'Janta',
      'outro': 'Lanches',
    };

    return mapeamentoRefeicoes[tipoRefeicaoBackend] ?? 'Lanches';
  }

  // Função para inicializar refeições vazias com placeholders
  List<MealData> _initializeEmptyMealsForDate() {
    return [
      MealData(
        title: "Café da Manhã",
        totalCalories: 0,
        items: [
          MealItemData(
            name: "Adicione um alimento",
            calories: 0,
            isPlaceholder: true,
          )
        ],
      ),
      MealData(
        title: "Almoço",
        totalCalories: 0,
        items: [
          MealItemData(
            name: "Adicione um alimento",
            calories: 0,
            isPlaceholder: true,
          )
        ],
      ),
      MealData(
        title: "Lanches",
        totalCalories: 0,
        items: [
          MealItemData(
            name: "Adicione um alimento",
            calories: 0,
            isPlaceholder: true,
          )
        ],
      ),
      MealData(
        title: "Janta",
        totalCalories: 0,
        items: [
          MealItemData(
            name: "Adicione um alimento",
            calories: 0,
            isPlaceholder: true,
          )
        ],
      ),
    ];
  }

  // Função para salvar refeições no SharedPreferences
  Future<void> _saveMealsToPrefs(
      String dateString, List<MealData> mealsForDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar se há dados reais (não apenas placeholders) para salvar
      bool hasRealData = false;
      for (var meal in mealsForDate) {
        if (meal.items.any((item) => !item.isPlaceholder)) {
          hasRealData = true;
          break;
        }
      }

      // CORRIGIDO: Obter ID do usuário logado dinamicamente
      final userIdString =
          await _getStoredUserId() ?? DEFAULT_PACIENTE_ID.toString();
      final key = 'meals_${userIdString}_$dateString';

      if (hasRealData) {
        // Salvar dados como JSON
        final jsonString =
            jsonEncode(mealsForDate.map((meal) => meal.toJson()).toList());
        await prefs.setString(key, jsonString);
        debugPrint(
            '💾 Dados salvos no SharedPreferences para usuário $userIdString na data $dateString');
      } else {
        // Remover chave se não há dados reais
        await prefs.remove(key);
        debugPrint(
            '🗑️ Dados vazios - chave removida do SharedPreferences para usuário $userIdString na data $dateString');
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar no SharedPreferences: $e');
    }
  }

  // Função para carregar refeições do SharedPreferences
  Future<List<MealData>?> _loadMealsFromPrefs(String dateString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // CORRIGIDO: Obter ID do usuário logado dinamicamente
      final userIdString =
          await _getStoredUserId() ?? DEFAULT_PACIENTE_ID.toString();
      final key = 'meals_${userIdString}_$dateString';

      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final meals = jsonList.map((json) => MealData.fromJson(json)).toList();
        debugPrint(
            '📱 Dados carregados do SharedPreferences para usuário $userIdString na data $dateString');
        return meals;
      }

      debugPrint(
          '📱 Nenhum dado encontrado no SharedPreferences para usuário $userIdString na data $dateString');
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao carregar do SharedPreferences: $e');
      return null;
    }
  }

  // Busca dados do backend e salva no cache local
  Future<void> _fetchAndSetMealsForDate(String dateString) async {
    try {
      debugPrint('🌐 Buscando dados do backend para $dateString');

      // Limpar dados locais primeiro
      setState(() {
        totalDailyCalories = 0;
        proteinTotal = 0;
        fatTotal = 0;
        carbsTotal = 0;
        initializeMeals(); // Reinicializar com dados vazios
      });

      // Carregar metas para a data específica primeiro
      _carregarMetasParaData(dateString);

      // Carregar alimentos detalhados do backend
      await _loadDetailedFoodsForDate(dateString);

      // Atualizar cache em memória com os dados carregados
      _mealsByDate[dateString] = List.from(meals);

      // Calcular totais APÓS carregar os dados do backend
      calculateTotalCalories();

      // Salvar no SharedPreferences
      await _saveMealsToPrefs(dateString, meals);

      debugPrint(
          '✅ Dados carregados do backend e salvos no cache para $dateString');
    } catch (e) {
      debugPrint('❌ Erro ao buscar dados do backend: $e');

      // Em caso de erro, criar dados vazios
      final emptyMeals = _initializeEmptyMealsForDate();
      _mealsByDate[dateString] = emptyMeals;

      setState(() {
        meals = emptyMeals;
        totalDailyCalories = 0;
        proteinTotal = 0;
        fatTotal = 0;
        carbsTotal = 0;
      });

      // Calcular totais mesmo com dados vazios para resetar UI
      calculateTotalCalories();

      // Salvar estado "vazio" no cache
      await _saveMealsToPrefs(dateString, emptyMeals);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Registro Unificado',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/seta_esquerda.svg',
              height: 20, width: 20),
          onPressed: () => Navigator.pushNamed(context, '/home'),
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
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                return ScrollConfiguration(
                  behavior: const _NoGlowScrollBehavior(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Widget de debug do sistema de áudio (apenas em debug mode)
                          if (const bool.fromEnvironment('dart.vm.product') ==
                              false)
                            const AudioDebugWidget(),
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
      ),
    );
  }

  Widget _buildDateSelector() {
    // Use selectedDate para definir o mês/ano exibido
    final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    final totalDays =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // Scroll to selected day only on first load
    if (!_initialScrollDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const itemWidth = 60 + 12;
        final screenW = MediaQuery.of(context).size.width;
        final offset = (itemWidth * (selectedDate.day - 1)) -
            (screenW / 2) +
            (itemWidth / 2);
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
                        insetPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título e ícone de lixeira
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    icon: const Icon(Icons.delete,
                                        color: Colors.purple),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      final mi = meals.indexWhere(
                                          (m) => m.items.contains(item));
                                      if (mi != -1) {
                                        removeFoodFromMeal(meals[mi].title,
                                            meals[mi].items.indexOf(item));
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
                                      border: Border.all(
                                          color: Colors.grey.shade100),
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
                                      border: Border.all(
                                          color: Colors.grey.shade100),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        Icon(Icons.keyboard_arrow_down_rounded,
                                            size: 22, color: Color(0xFF7B6F72)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              const Text(
                                'Informação Nutricional',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
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
                child: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
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
            Icon(Icons.insights_rounded, color: Color(0xff92A3FD), size: 16),
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

  // Serialização para JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Desserialização do JSON
  factory MealData.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((item) => MealItemData.fromJson(item))
        .toList();

    // Recalcular totalCalories a partir dos items
    final totalCalories =
        items.fold<int>(0, (sum, item) => sum + item.calories);

    return MealData(
      title: json['title'],
      totalCalories: totalCalories,
      items: items,
    );
  }
}

class MealItemData {
  final String name;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final bool isPlaceholder;
  final int? registroId; // ID do registro no backend para permitir remoção

  MealItemData({
    required this.name,
    required this.calories,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.isPlaceholder = false,
    this.registroId,
  });

  // Serialização para JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'isPlaceholder': isPlaceholder,
      'registroId': registroId,
    };
  }

  // Desserialização do JSON
  factory MealItemData.fromJson(Map<String, dynamic> json) {
    return MealItemData(
      name: json['name'],
      calories: json['calories'],
      protein: json['protein'] ?? 0,
      fat: json['fat'] ?? 0,
      carbs: json['carbs'] ?? 0,
      isPlaceholder: json['isPlaceholder'] ?? false,
      registroId: json['registroId'],
    );
  }
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
