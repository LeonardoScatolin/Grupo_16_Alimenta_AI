import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controlador para a animação do logo (chatLogo)
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;

  // Controlador separado para a animação do texto (escritoAlimenta)
  late AnimationController _textController;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation; // Corrigido o tipo para Offset

  @override
  void initState() {
    super.initState();

    // Controlador para animação do chatLogo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animações para o chatLogo - efeito popup
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Controlador para animação do texto
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Animações para o texto
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Iniciando as animações em sequência
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward().then((_) {
        // Após o logo aparecer, inicia a animação do texto
        Future.delayed(const Duration(milliseconds: 200), () {
          _textController.forward().then((_) {
            // Após completar as animações, navega para a próxima tela
            Future.delayed(const Duration(milliseconds: 800), () {
              Navigator.pushReplacementNamed(context, '/welcome');
            });
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo totalmente branco, sem decoração
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Espaço para centralizar o conteúdo verticalmente
            const Spacer(flex: 4),

            // Logo animado (chatLogo) - efeito popup
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: SvgPicture.asset(
                      'assets/icons/chatLogo.svg', // Corrigido para .svg
                      height: 180,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Texto animado (escritoAlimenta)
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: SvgPicture.asset(
                      'assets/icons/escritoAlimenta.svg',
                      height: 60,
                    ),
                  ),
                );
              },
            ),

            // Espaço para centralizar o conteúdo verticalmente
            const Spacer(flex: 5),
          ],
        ),
      ),
    );
  }
}
