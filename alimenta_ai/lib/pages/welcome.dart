import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Controladores para as animações
  late AnimationController _slideController;
  late AnimationController _loadingController;

  // Animações
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador para deslizar e escalar o logo
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Controlador para animação da barra de carregamento
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animação para deslizar o logo de baixo para cima
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Animação para escalar o logo (começa pequeno e cresce)
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Iniciar animações sequencialmente
    _slideController.forward().then((_) {
      _loadingController.repeat();

      // Navegar para a tela de login após 3 segundos
      Future.delayed(Duration(milliseconds: 3000), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // Logo animado (deslizando de baixo para cima)
            SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SvgPicture.asset(
                  'assets/icons/logo.svg',
                  width: 180,
                  height: 180,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Apenas a barra de carregamento elegante
            AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Container(
                  width: 160,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    children: [
                      // Efeito de sliding dot
                      Positioned(
                        left: 160 * _loadingController.value - 20,
                        top: 0,
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6E55E3),
                                Color(0xFF9980FF),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6E55E3).withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
