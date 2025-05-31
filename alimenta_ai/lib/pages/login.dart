import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/nutricao_service.dart';
import '../services/user_service.dart';  // Nova importação

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Controladores para animação das bolinhas
  late AnimationController _bubble1Controller;
  late AnimationController _bubble2Controller;
  late AnimationController _bubble3Controller;
  late AnimationController _bubble4Controller; // Nova bolinha
  late AnimationController _bubble5Controller; // Nova bolinha
  late AnimationController _bubble6Controller; // Nova bolinha

  // Posições e movimentos das bolinhas
  double _bubble1X = 0;
  double _bubble1Y = 0;
  double _bubble2X = 0;
  double _bubble2Y = 0;
  double _bubble3X = 0;
  double _bubble3Y = 0;
  double _bubble4X = 0; // Nova bolinha
  double _bubble4Y = 0; // Nova bolinha
  double _bubble5X = 0; // Nova bolinha
  double _bubble5Y = 0; // Nova bolinha
  double _bubble6X = 0; // Nova bolinha
  double _bubble6Y = 0; // Nova bolinha

  // Direções de movimento para cada bolinha
  double _bubble1DirX = 1;
  double _bubble1DirY = 1;
  double _bubble2DirX = -1;
  double _bubble2DirY = 1;
  double _bubble3DirX = 1;
  double _bubble3DirY = -1;
  double _bubble4DirX = -1; // Nova bolinha
  double _bubble4DirY = -1; // Nova bolinha
  double _bubble5DirX = 0.7; // Nova bolinha
  double _bubble5DirY = -1.2; // Nova bolinha
  double _bubble6DirX = -0.8; // Nova bolinha
  double _bubble6DirY = 0.9; // Nova bolinha
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Auth service instance
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimation = Tween<double>(begin: 0, end: 3).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Posições iniciais aleatórias para as bolinhas
    final random = Random();
    _bubble1X = random.nextDouble() * 0.8;
    _bubble1Y = random.nextDouble() * 0.3;
    _bubble2X = random.nextDouble() * 0.8;
    _bubble2Y = random.nextDouble() * 0.3 + 0.3;
    _bubble3X = random.nextDouble() * 0.8;
    _bubble3Y = random.nextDouble() * 0.3 + 0.6;

    // Novas bolinhas com posições iniciais diferentes
    _bubble4X = random.nextDouble() * 0.4 + 0.5; // Mais para a direita
    _bubble4Y = random.nextDouble() * 0.2 + 0.1;
    _bubble5X = random.nextDouble() * 0.3 + 0.1;
    _bubble5Y = random.nextDouble() * 0.2 + 0.4;
    _bubble6X = random.nextDouble() * 0.4 + 0.4;
    _bubble6Y = random.nextDouble() * 0.2 + 0.7;

    // Inicialização dos controladores para movimentação das bolinhas existentes
    _bubble1Controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_moveBubble1);

    _bubble2Controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_moveBubble2);

    _bubble3Controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_moveBubble3);

    // Controladores para as novas bolinhas
    _bubble4Controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_moveBubble4);

    _bubble5Controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_moveBubble5);

    _bubble6Controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_moveBubble6);

    // Inicia as animações
    _bubble1Controller.repeat();
    _bubble2Controller.repeat();
    _bubble3Controller.repeat();
    _bubble4Controller.repeat();
    _bubble5Controller.repeat();
    _bubble6Controller.repeat();

    // Inicia a animação de fade-in quando a tela é carregada
    _fadeController.forward();

    // Configura a barra de status para clara
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));
  }

  // Função para mover a bolinha 1
  void _moveBubble1() {
    setState(() {
      // Velocidade de movimento
      const speed = 0.001;

      // Atualiza a posição
      _bubble1X += _bubble1DirX * speed;
      _bubble1Y += _bubble1DirY * speed;

      // Inverte a direção ao atingir os limites
      if (_bubble1X <= 0 || _bubble1X >= 1) {
        _bubble1DirX *= -1;
      }
      if (_bubble1Y <= 0 || _bubble1Y >= 1) {
        _bubble1DirY *= -1;
      }
    });
  }

  // Função para mover a bolinha 2
  void _moveBubble2() {
    setState(() {
      // Velocidade de movimento (diferente para cada bolinha)
      const speed = 0.0008;

      _bubble2X += _bubble2DirX * speed;
      _bubble2Y += _bubble2DirY * speed;

      if (_bubble2X <= 0 || _bubble2X >= 1) {
        _bubble2DirX *= -1;
      }
      if (_bubble2Y <= 0 || _bubble2Y >= 1) {
        _bubble2DirY *= -1;
      }
    });
  }

  // Função para mover a bolinha 3
  void _moveBubble3() {
    setState(() {
      // Velocidade de movimento
      const speed = 0.0012;

      _bubble3X += _bubble3DirX * speed;
      _bubble3Y += _bubble3DirY * speed;

      if (_bubble3X <= 0 || _bubble3X >= 1) {
        _bubble3DirX *= -1;
      }
      if (_bubble3Y <= 0 || _bubble3Y >= 1) {
        _bubble3DirY *= -1;
      }
    });
  }

  // Funções adicionais para mover as novas bolinhas
  void _moveBubble4() {
    setState(() {
      // Velocidade mais lenta
      const speed = 0.0007;

      _bubble4X += _bubble4DirX * speed;
      _bubble4Y += _bubble4DirY * speed;

      if (_bubble4X <= 0 || _bubble4X >= 1) {
        _bubble4DirX *= -1;
      }
      if (_bubble4Y <= 0 || _bubble4Y >= 1) {
        _bubble4DirY *= -1;
      }
    });
  }

  void _moveBubble5() {
    setState(() {
      // Velocidade muito lenta
      const speed = 0.0005;

      _bubble5X += _bubble5DirX * speed;
      _bubble5Y += _bubble5DirY * speed;

      if (_bubble5X <= 0 || _bubble5X >= 1) {
        _bubble5DirX *= -1;
      }
      if (_bubble5Y <= 0 || _bubble5Y >= 1) {
        _bubble5DirY *= -1;
      }
    });
  }

  void _moveBubble6() {
    setState(() {
      // Velocidade média
      const speed = 0.0009;

      _bubble6X += _bubble6DirX * speed;
      _bubble6Y += _bubble6DirY * speed;

      if (_bubble6X <= 0 || _bubble6X >= 1) {
        _bubble6DirX *= -1;
      }
      if (_bubble6Y <= 0 || _bubble6Y >= 1) {
        _bubble6DirY *= -1;
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _buttonController.dispose();
    _fadeController.dispose();
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    _bubble3Controller.dispose();
    _bubble4Controller.dispose();
    _bubble5Controller.dispose();
    _bubble6Controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removido o AppBar que continha o título de login e o botão de voltar
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background - branco
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),

            // Bolinhas decorativas em roxo - já existentes
            Positioned(
              left: _bubble1X * MediaQuery.of(context).size.width,
              top: _bubble1Y * MediaQuery.of(context).size.height,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7661EC).withOpacity(0.1),
                ),
              ),
            ),

            Positioned(
              left: _bubble2X * MediaQuery.of(context).size.width,
              top: _bubble2Y * MediaQuery.of(context).size.height,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7661EC).withOpacity(0.07),
                ),
              ),
            ),

            Positioned(
              left: _bubble3X * MediaQuery.of(context).size.width,
              top: _bubble3Y * MediaQuery.of(context).size.height,
              child: Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6E55E3).withOpacity(0.1),
                ),
              ),
            ),

            // Novas bolinhas decorativas
            Positioned(
              left: _bubble4X * MediaQuery.of(context).size.width,
              top: _bubble4Y * MediaQuery.of(context).size.height,
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6E55E3).withOpacity(0.06),
                ),
              ),
            ),

            Positioned(
              left: _bubble5X * MediaQuery.of(context).size.width,
              top: _bubble5Y * MediaQuery.of(context).size.height,
              child: Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9980FF).withOpacity(0.05),
                ),
              ),
            ),

            Positioned(
              left: _bubble6X * MediaQuery.of(context).size.width,
              top: _bubble6Y * MediaQuery.of(context).size.height,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5D42D9).withOpacity(0.08),
                ),
              ),
            ), // Conteúdo principal
            SafeArea(
              child: SingleChildScrollView(
                // Add ScrollView
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        28, 40, 28, 28), // Aumentado o padding do topo
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo maior e centralizada
                        Center(
                          child: SvgPicture.asset(
                            'assets/icons/logo.svg',
                            height: 200, // Tamanho ajustado
                          ),
                        ),

                        const SizedBox(height: 30), // Espaço reduzido

                        // Email field
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Senha',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text(
                                'Esqueceu a senha?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6E55E3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Login button with animation
                        AnimatedBuilder(
                          animation: _buttonAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _buttonAnimation.value),
                              child: _buildGradientButton(
                                text: 'ENTRAR',
                                isLoading: _isLoading,
                                onPressed: _handleLogin,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6E55E3),
                                    Color(0xFF5D42D9)
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Sign up text
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: 'Não tem uma conta? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Cadastre-se',
                                    style: TextStyle(
                                      color: Color(0xFF6E55E3),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1617).withOpacity(0.07),
            blurRadius: 40,
            spreadRadius: 0.0,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(
              prefixIcon,
              color: const Color(0xFF6E55E3),
              size: 22,
            ),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF6E55E3),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    required LinearGradient gradient,
    bool isLoading = false,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E55E3).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.2),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Method to handle login with API
  Future<void> _handleLogin() async {
    // Validação básica
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Por favor, preencha todos os campos', isError: true);
      return;
    }

    // Mostrar loading
    setState(() {
      _isLoading = true;
    });

    // Animação do botão
    _buttonController.forward().then((_) => _buttonController.reverse());

    try {
      debugPrint('🚀 Iniciando processo de login...');

      // Fazer login via AuthService
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        tipo: 'paciente',
      );

      debugPrint('📋 Resultado do login: $result');      if (result['success'] == true) {
        debugPrint('✅ Login bem-sucedido!');

        final user = result['user'];
        
        // Salvar dados do usuário
        await UserService.saveUserData(
          userId: user['id'],
          userName: user['name'] ?? 'Usuário',
          userEmail: user['email'] ?? '',
          additionalData: user,
        );
        
        // Configurar o NutricaoService com os IDs
        if (mounted) {
          final nutricaoService =
              Provider.of<NutricaoService>(context, listen: false);
          nutricaoService.configurarUsuarios(user['id'], user['nutri_id'] ?? 1);

          // Atualizar dados imediatamente após configurar
          await nutricaoService.atualizarResumoDiario();

          // Navegar para o dashboard - ROTA CORRETA
          Navigator.pushReplacementNamed(
              context, '/dashboard'); // Mudança aqui!

          _showSnackBar('Bem-vindo, ${user['name']}!');
        }
      } else {
        debugPrint('❌ Login falhou: ${result['message']}');
        _showSnackBar(result['message'] ?? 'Erro no login', isError: true);
      }
    } catch (e) {
      debugPrint('💥 Erro inesperado no login: $e');
      _showSnackBar('Erro inesperado. Tente novamente.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to show snackbar messages
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
