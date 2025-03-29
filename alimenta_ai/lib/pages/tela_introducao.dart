import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:math';

class TelaIntroducao extends StatefulWidget {
  const TelaIntroducao({Key? key}) : super(key: key);

  @override
  _TelaIntroducaoState createState() => _TelaIntroducaoState();
}

class _TelaIntroducaoState extends State<TelaIntroducao> with TickerProviderStateMixin {
  // Controladores para animação das bolinhas
  late AnimationController _bubble1Controller;
  late AnimationController _bubble2Controller;
  late AnimationController _bubble3Controller;
  late AnimationController _bubble4Controller;
  late AnimationController _bubble5Controller;
  late AnimationController _bubble6Controller;

  // Posições das bolinhas
  double _bubble1X = 0;
  double _bubble1Y = 0;
  double _bubble2X = 0;
  double _bubble2Y = 0;
  double _bubble3X = 0;
  double _bubble3Y = 0;
  double _bubble4X = 0;
  double _bubble4Y = 0;
  double _bubble5X = 0;
  double _bubble5Y = 0;
  double _bubble6X = 0;
  double _bubble6Y = 0;

  // Direções de movimento
  double _bubble1DirX = 1;
  double _bubble1DirY = 1;
  double _bubble2DirX = -1;
  double _bubble2DirY = 1;
  double _bubble3DirX = 1;
  double _bubble3DirY = -1;
  double _bubble4DirX = -1;
  double _bubble4DirY = -1;
  double _bubble5DirX = 0.7;
  double _bubble5DirY = -1.2;
  double _bubble6DirX = -0.8;
  double _bubble6DirY = 0.9;

  @override
  void initState() {
    super.initState();
    
    // Posições iniciais aleatórias
    final random = Random();
    _bubble1X = random.nextDouble() * 0.8;
    _bubble1Y = random.nextDouble() * 0.3;
    _bubble2X = random.nextDouble() * 0.8;
    _bubble2Y = random.nextDouble() * 0.3 + 0.3;
    _bubble3X = random.nextDouble() * 0.8;
    _bubble3Y = random.nextDouble() * 0.3 + 0.6;
    _bubble4X = random.nextDouble() * 0.4 + 0.5;
    _bubble5X = random.nextDouble() * 0.3 + 0.1;
    _bubble6X = random.nextDouble() * 0.4 + 0.4;
    _bubble6Y = random.nextDouble() * 0.2 + 0.7;

    // Inicialização dos controladores
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
  }

  // Funções de movimento das bolinhas
  void _moveBubble1() {
    setState(() {
      final speed = 0.001;
      _bubble1X += _bubble1DirX * speed;
      _bubble1Y += _bubble1DirY * speed;
      if (_bubble1X <= 0 || _bubble1X >= 1) _bubble1DirX *= -1;
      if (_bubble1Y <= 0 || _bubble1Y >= 1) _bubble1DirY *= -1;
    });
  }

  void _moveBubble2() {
    setState(() {
      final speed = 0.001;
      _bubble2X += _bubble2DirX * speed;
      _bubble2Y += _bubble2DirY * speed;
      if (_bubble2X <= 0 || _bubble2X >= 1) _bubble2DirX *= -1;
      if (_bubble2Y <= 0 || _bubble2Y >= 1) _bubble2DirY *= -1;
    });
  }

  void _moveBubble3() {
    setState(() {
      final speed = 0.001;
      _bubble3X += _bubble3DirX * speed;
      _bubble3Y += _bubble3DirY * speed;
      if (_bubble3X <= 0 || _bubble3X >= 1) _bubble3DirX *= -1;
      if (_bubble3Y <= 0 || _bubble3Y >= 1) _bubble3DirY *= -1;
    });
  }

  void _moveBubble4() {
    setState(() {
      final speed = 0.001;
      _bubble4X += _bubble4DirX * speed;
      _bubble4Y += _bubble4DirY * speed;
      if (_bubble4X <= 0 || _bubble4X >= 1) _bubble4DirX *= -1;
      if (_bubble4Y <= 0 || _bubble4Y >= 1) _bubble4DirY *= -1;
    });
  }

  void _moveBubble5() {
    setState(() {
      final speed = 0.001;
      _bubble5X += _bubble5DirX * speed;
      _bubble5Y += _bubble5DirY * speed;
      if (_bubble5X <= 0 || _bubble5X >= 1) _bubble5DirX *= -1;
      if (_bubble5Y <= 0 || _bubble5Y >= 1) _bubble5DirY *= -1;
    });
  }

  void _moveBubble6() {
    setState(() {
      final speed = 0.001;
      _bubble6X += _bubble6DirX * speed;
      _bubble6Y += _bubble6DirY * speed;
      if (_bubble6X <= 0 || _bubble6X >= 1) _bubble6DirX *= -1;
      if (_bubble6Y <= 0 || _bubble6Y >= 1) _bubble6DirY *= -1;
    });
  }

  @override
  void dispose() {
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    _bubble3Controller.dispose();
    _bubble4Controller.dispose();
    _bubble5Controller.dispose();
    _bubble6Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated bubbles
          Positioned(
            left: _bubble1X * screenWidth,
            top: _bubble1Y * screenHeight,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7661EC).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: _bubble2X * screenWidth,
            top: _bubble2Y * screenHeight,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7661EC).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: _bubble3X * screenWidth,
            top: _bubble3Y * screenHeight,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7661EC).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: _bubble4X * screenWidth,
            top: _bubble4Y * screenHeight,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7661EC).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: _bubble5X * screenWidth,
            top: _bubble5Y * screenHeight,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7661EC).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: _bubble6X * screenWidth,
            top: _bubble6Y * screenHeight,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7661EC).withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xff9DCEFF),
                        Color(0xff92A3FD),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 40.0,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Alimenta',
                                speed: const Duration(milliseconds: 200),
                              ),
                            ],
                            repeatForever: false,
                            totalRepeatCount: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 40.0,
                            fontFamily: 'Poppins', // Changed from 'stanley' to 'Poppins'
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'AI',
                                speed: const Duration(milliseconds: 200),
                              ),
                            ],
                            repeatForever: false,
                            totalRepeatCount: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80), // Increased bottom padding
                child: Container(
                  width: 150,
                  height: 45, // Increased height for better touch target
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xff9DCEFF),
                        Color(0xff92A3FD),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Começar',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
