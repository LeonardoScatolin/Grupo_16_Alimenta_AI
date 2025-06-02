import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:alimenta_ai/theme/theme_provider.dart';
import '../services/weight_service.dart';
import '../services/nutricao_service.dart';
import '../services/user_service.dart'; // Nova importação
import 'package:alimenta_ai/pages/weight_history.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  String _userName = 'Usuário'; // Nome padrão caso não carregue

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Carregar o nome do usuário logado
    _loadUserName();

    // Carregar dados do dia atual quando o dashboard inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosDiarios();
    });
  }

  // Método para carregar o nome do usuário
  void _loadUserName() async {
    try {
      final userName = await UserService.getUserName();
      if (userName != null) {
        setState(() {
          _userName = userName;
        });
      }
    } catch (e) {
      print('Erro ao carregar nome do usuário: $e');
    }
  }

  void _carregarDadosDiarios() async {
    final nutricaoService =
        Provider.of<NutricaoService>(context, listen: false);

    // 🔧 Garantir que os IDs estão configurados antes de carregar dados
    await _configurarUsuariosSeNecessario(nutricaoService);

    // 📅 Garantir que estamos carregando dados do dia atual
    final String dataAtual = DateTime.now().toString().split(' ')[0];
    debugPrint('📅 Dashboard carregando dados para: $dataAtual');
    debugPrint(
        '🔧 IDs configurados - Paciente: ${nutricaoService.pacienteId}, Nutri: ${nutricaoService.nutriId}');

    try {
      // 🎯 Carregar metas diárias primeiro
      debugPrint('🎯 Iniciando carregamento de metas...');
      await nutricaoService.carregarMetas(dataAtual);
      debugPrint('🎯 Metas carregadas');

      // 📊 Depois carregar o resumo diário completo
      debugPrint('📊 Iniciando carregamento do resumo diário...');
      await nutricaoService.atualizarResumoDiario(dataAtual);
      debugPrint('📊 Resumo diário carregado');

      // 🔄 Verificar se os dados foram carregados corretamente
      final resumo = nutricaoService.resumoAtual;
      if (resumo != null) {
        debugPrint('✅ Dashboard: Dados carregados com sucesso');
        debugPrint(
            '✅ Dashboard: Meta calorias = ${resumo.metaDiaria.calorias}');
        debugPrint(
            '✅ Dashboard: Consumo calorias = ${resumo.consumoAtual.calorias}');
      } else {
        debugPrint('❌ Dashboard: Nenhum resumo disponível após carregamento');
      }
    } catch (e) {
      debugPrint('❌ Dashboard: Erro ao carregar dados: $e');
    }
  }

  // Método para configurar IDs de usuário se ainda não estiverem configurados
  Future<void> _configurarUsuariosSeNecessario(
      NutricaoService nutricaoService) async {
    // Primeiro, verificar se o usuário está logado
    final isLoggedIn = await UserService.isUserLoggedIn();
    if (!isLoggedIn) {
      debugPrint('❌ Usuário não está logado - redirecionando para login');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
    }

    // Verificar se os dados do usuário estão completos
    final hasCompleteData = await UserService.hasCompleteUserData();
    if (!hasCompleteData) {
      debugPrint('❌ Dados do usuário incompletos - redirecionando para login');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
    }

    // Se IDs já estão configurados, não precisa fazer nada
    if (nutricaoService.pacienteId != null && nutricaoService.nutriId != null) {
      debugPrint(
          '🔧 IDs já configurados - Paciente: ${nutricaoService.pacienteId}, Nutri: ${nutricaoService.nutriId}');
      return;
    }

    try {
      debugPrint('🔧 Obtendo IDs dinamicamente do usuário logado...');

      // Debug detalhado dos dados do usuário
      final userDataDebug = await UserService.getUserDataDebug();
      debugPrint('🔍 Dados completos do usuário: $userDataDebug');

      // Obter IDs dinamicamente baseado no usuário logado
      final apiIds = await UserService.getApiIds();
      final pacienteId = apiIds['paciente_id'];
      final nutriId = apiIds['nutri_id'];
      final userType = await UserService.getUserType();

      debugPrint(
          '🔧 Dados obtidos - Tipo: $userType, Paciente: $pacienteId, Nutri: $nutriId');

      if (pacienteId != null && nutriId != null) {
        nutricaoService.configurarUsuarios(pacienteId, nutriId);
        debugPrint(
            '🔧 ✅ IDs configurados dinamicamente: paciente=$pacienteId, nutri=$nutriId');
      } else {
        debugPrint(
            '⚠️ IDs incompletos - Paciente: $pacienteId, Nutri: $nutriId');
        throw Exception(
            'IDs do usuário incompletos após verificação. Paciente: $pacienteId, Nutri: $nutriId');
      }
    } catch (e) {
      debugPrint('❌ Erro ao obter IDs do usuário: $e');

      // Em caso de erro crítico, redirecionar para login
      debugPrint('❌ Erro crítico na configuração - redirecionando para login');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Recarregar dados sempre que a página se tornar visível
    // Isso garante que dados sejam atualizados quando o usuário volta de outras telas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint(
            '🔄 Dashboard: Página se tornou visível, recarregando dados...');
        _carregarDadosDiarios();
      }
    });
  }  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            toolbarHeight: 50,
            automaticallyImplyLeading: false, // <-- Adicione esta linha!
            actions: [
              IconButton(
                onPressed: () {
                  debugPrint('🔄 Botão de refresh pressionado');
                  _carregarDadosDiarios();
                },
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
                tooltip: 'Atualizar dados',
              ),
            ],
          ),
          body: Container(
            color: Theme.of(context).colorScheme.surface,
            child: ListView(
              children: [
                _buildCard(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 60.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreetingSection(),
                        const SizedBox(height: 25),
                        _buildWeightTrackingCard(),
                        const SizedBox(height: 25),
                        _buildDailyGoalsCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }
  Widget _buildCard({required Widget child}) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          color: themeProvider.isDarkMode 
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
          elevation: themeProvider.isDarkMode ? 8 : 2,
          shadowColor: themeProvider.isDarkMode 
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: themeProvider.isDarkMode 
              ? BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                )
              : BorderSide.none,
          ),
          child: child,
        );
      },
    );
  }
  Widget _buildGreetingSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo de volta!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode 
                  ? Colors.white
                  : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _userName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: themeProvider.isDarkMode 
                  ? Colors.grey[300]
                  : Colors.grey[700],
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildWeightTrackingCard() {
    final weightService = WeightService();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Usar AnimatedBuilder para reconstruir quando houver mudanças no serviço
        return AnimatedBuilder(
          animation: weightService,
          builder: (context, child) {
            final double lastWeight = weightService.lastWeight;
            final String weightText = lastWeight > 0
                ? '${lastWeight.toStringAsFixed(1)} kg'
                : 'Sem registro';

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: themeProvider.isDarkMode 
                  ? const LinearGradient(
                      colors: [Color(0xff4A5568), Color(0xff2D3748)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : const Color(0xff9DCEFF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: themeProvider.isDarkMode 
                  ? Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registro dos Pesos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'acompanhe seu peso',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: CircleProgressPainter(
                            progress: _progressAnimation.value,
                            color: Colors.white,
                          ),
                          child: Center(                            child: Container(
                              padding: const EdgeInsets.all(12),
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7A66EC),
                                    Color(0xFF5D42D9)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                  // Borda luminosa
                                  BoxShadow(
                                    color: const Color(0xFF7A66EC).withOpacity(0.6),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF5D42D9).withOpacity(0.4),
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  weightText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7A66EC),
                      Color(0xFF5D42D9)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    // Borda luminosa para o botão
                    BoxShadow(
                      color: const Color(0xFF7A66EC).withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: const Color(0xFF5D42D9).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WeightHistoryPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    minimumSize: const Size(120, 35),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Ver histórico',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }
  Widget _buildDailyGoalsCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<NutricaoService>(
          builder: (context, nutricaoService, child) {
            final resumo = nutricaoService.resumoAtual;
            final isLoading = nutricaoService.isLoading;
            final error = nutricaoService.error;

            // 📊 Debug logging para verificar os dados
            debugPrint('🏠 Dashboard - Resumo disponível: ${resumo != null}');
            if (resumo != null) {
              debugPrint(
                  '🏠 Dashboard - Meta calorias: ${resumo.metaDiaria.calorias}');
              debugPrint(
                  '🏠 Dashboard - Consumo calorias: ${resumo.consumoAtual.calorias}');
              debugPrint(
                  '🏠 Dashboard - Consumo proteína: ${resumo.consumoAtual.proteina}');
              debugPrint(
                  '🏠 Dashboard - Consumo carbo: ${resumo.consumoAtual.carbo}');
              debugPrint(
                  '🏠 Dashboard - Consumo gordura: ${resumo.consumoAtual.gordura}');
            }
            debugPrint('🏠 Dashboard - Loading: $isLoading');
            debugPrint('🏠 Dashboard - Error: $error');

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode 
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: themeProvider.isDarkMode 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metas Diárias',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode 
                        ? Colors.white
                        : Colors.black,
                    ),
                  ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Erro: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (resumo != null)
                Column(
                  children: [
                    _buildNutritionGoalItem(
                      icon: 'assets/icons/protein.svg',
                      title: 'Proteínas',
                      current: resumo.consumoAtual.proteina,
                      goal: resumo.metaDiaria.proteina,
                      unit: 'g',
                    ),
                    const SizedBox(height: 15),
                    _buildNutritionGoalItem(
                      icon: 'assets/icons/protein.svg',
                      title: 'Carboidratos',
                      current: resumo.consumoAtual.carbo,
                      goal: resumo.metaDiaria.carbo,
                      unit: 'g',
                    ),
                    const SizedBox(height: 15),
                    _buildNutritionGoalItem(
                      icon: 'assets/icons/janta.svg',
                      title: 'Gorduras',
                      current: resumo.consumoAtual.gordura,
                      goal: resumo.metaDiaria.gordura,
                      unit: 'g',
                    ),
                    const SizedBox(height: 15),
                    _buildNutritionGoalItem(
                      icon: 'assets/icons/janta.svg',
                      title: 'Calorias',
                      current: resumo.consumoAtual.calorias,
                      goal: resumo.metaDiaria.calorias,
                      unit: 'kcal',
                    ),
                  ],
                )
              else
                const Text(
                  'Carregue seus dados fazendo login',
                  style: TextStyle(color: Colors.grey),
                ),            ],
          ),
        );
          },
        );
      },
    );
  }
  Widget _buildNutritionGoalItem({
    required String icon,
    required String title,
    required double current,
    required double goal,
    required String unit,
  }) {
    // Defina o emoji de acordo com o título
    String emoji = '';
    if (title.contains('Proteína')) emoji = '🥩';
    else if (title.contains('Carboidrato')) emoji = '🌾';
    else if (title.contains('Gordura')) emoji = '🥜';
    else if (title.contains('Caloria')) emoji = '🔥';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : const Color(0xFFEEEEFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode 
                        ? Colors.white
                        : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Meta: ${goal.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 13,
                      color: themeProvider.isDarkMode 
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }  Widget _buildBottomNavigationBar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode 
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            border: themeProvider.isDarkMode 
              ? Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                )
              : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: 'assets/icons_bar/Home-Active.svg',
                isActive: true,
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: _buildAddButton(),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: _buildNavItem(
                    icon: 'assets/icons_bar/Profile.svg',
                    isActive: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildNavItem({required String icon, required bool isActive}) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              height: 24,
              // Remova o colorFilter para manter as cores originais do SVG
            ),
          ],
        );
      },
    );
  }
  Widget _buildAddButton() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/registra-alimento'),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: themeProvider.isDarkMode
                ? const LinearGradient(
                    colors: [Color(0xFF7A66EC), Color(0xFF5D42D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode
                    ? const Color(0xFF7A66EC).withOpacity(0.3)
                    : const Color(0xff92A3FD).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons_bar/plus.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Classe para desenhar o círculo de progresso
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  CircleProgressPainter({
    required this.progress,
    required this.color,
    this.backgroundColor = Colors.transparent,
    this.strokeWidth = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Desenha o círculo de fundo
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, backgroundPaint);
    }

    // Desenha o progresso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Começa no topo
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
