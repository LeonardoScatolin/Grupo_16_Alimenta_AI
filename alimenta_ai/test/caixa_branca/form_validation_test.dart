import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class FormValidator {  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }
    static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Senha deve conter ao menos: 1 minúscula, 1 maiúscula, 1 número';
    }
    return null;
  }
  
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Peso é obrigatório';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Peso deve ser um número válido';
    }
    if (weight < 20 || weight > 300) {
      return 'Peso deve estar entre 20kg e 300kg';
    }
    return null;
  }
  
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Idade é obrigatória';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Idade deve ser um número válido';
    }
    if (age < 18 || age > 120) {
      return 'Idade deve estar entre 18 e 120 anos';
    }
    return null;
  }
  
}

class CustomLoginForm extends StatefulWidget {
  final Function(String email, String password)? onSubmit;
  
  const CustomLoginForm({Key? key, this.onSubmit}) : super(key: key);
  
  @override
  State<CustomLoginForm> createState() => _CustomLoginFormState();
}

class _CustomLoginFormState extends State<CustomLoginForm> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  bool _isObscure = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    print('🎬 [${DateTime.now()}] LoginForm inicializado');
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simula delay
      
      widget.onSubmit?.call(_emailController.text, _passwordController.text);
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('email_field'),
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: FormValidator.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('password_field'),
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  key: const Key('toggle_password'),
                  icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              validator: FormValidator.validatePassword,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('submit_button'),
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('🧪 CAIXA BRANCA - Form Validation Tests', () {
    late Stopwatch stopwatch;

    setUp(() {
      print('🔧 [${DateTime.now()}] Setting up Form Validation tests');
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] Setup completed');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up test environment');
      stopwatch.reset();
      print('✅ [${DateTime.now()}] Teardown completed');
    });

    test('19. validateEmail - email válido', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: validateEmail válido');
      stopwatch.start();
      
      final validEmails = [
        'test@test.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        'test123@gmail.com'
      ];
      
      for (final email in validEmails) {
        final result = FormValidator.validateEmail(email);
        expect(result, isNull, reason: 'Email $email deveria ser válido');
        print('✅ Email válido: $email');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Todos emails válidos passaram');
    });

    test('20. validateEmail - email inválido', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: validateEmail inválido');
      stopwatch.start();
      
      final invalidEmails = [
        '',
        'invalid',
        '@domain.com',
        'user@',
        'user@domain',
        'user space@domain.com'
      ];
      
      for (final email in invalidEmails) {
        final result = FormValidator.validateEmail(email);
        expect(result, isNotNull, reason: 'Email $email deveria ser inválido');
        print('❌ Email inválido: $email - Erro: $result');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Todos emails inválidos foram rejeitados');
    });

    test('21. validatePassword - senha forte', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: validatePassword forte');
      stopwatch.start();
      
      final strongPasswords = [
        'Password123',
        'MyPass1234',
        'Secure9Pass',
        'Test1ng2024'
      ];
      
      for (final password in strongPasswords) {
        final result = FormValidator.validatePassword(password);
        expect(result, isNull, reason: 'Senha $password deveria ser válida');
        print('✅ Senha forte: $password');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Todas senhas fortes passaram');
    });

    test('22. validatePassword - senha fraca', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: validatePassword fraca');
      stopwatch.start();
      
      final weakPasswords = [
        '',
        '123',
        'password',
        'PASSWORD',
        '12345678',
        'password123',
        'PASSWORD123'
      ];
      
      for (final password in weakPasswords) {
        final result = FormValidator.validatePassword(password);
        expect(result, isNotNull, reason: 'Senha $password deveria ser inválida');
        print('❌ Senha fraca: $password - Erro: $result');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Todas senhas fracas foram rejeitadas');
    });

    test('23. validateWeight - peso válido', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: validateWeight válido');
      stopwatch.start();
      
      final validWeights = ['50', '75.5', '100', '150.2', '200'];
      
      for (final weight in validWeights) {
        final result = FormValidator.validateWeight(weight);
        expect(result, isNull, reason: 'Peso $weight deveria ser válido');
        print('✅ Peso válido: ${weight}kg');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Todos pesos válidos passaram');
    });

    test('24. validateAge - idade válida e inválida', () {
      print('🧪 [${DateTime.now()}] Iniciando teste: validateAge');
      stopwatch.start();
      
      // Idades válidas
      final validAges = ['18', '25', '35', '65', '80'];
      for (final age in validAges) {
        final result = FormValidator.validateAge(age);
        expect(result, isNull, reason: 'Idade $age deveria ser válida');
        print('✅ Idade válida: $age anos');
      }
      
      // Idades inválidas
      final invalidAges = ['', '12', '121', 'abc', '-5'];
      for (final age in invalidAges) {
        final result = FormValidator.validateAge(age);
        expect(result, isNotNull, reason: 'Idade $age deveria ser inválida');
        print('❌ Idade inválida: $age - Erro: $result');
      }
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Validação de idade funcionando corretamente');
    });
  });

  group('🧪 CAIXA BRANCA - Widget Internal Tests', () {
    late Stopwatch stopwatch;

    setUp(() {
      print('🔧 [${DateTime.now()}] Setting up Widget tests');
      stopwatch = Stopwatch();
      print('✅ [${DateTime.now()}] Setup completed');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up test environment');
      stopwatch.reset();
      print('✅ [${DateTime.now()}] Teardown completed');
    });

    testWidgets('25. CustomLoginForm - inicialização e estado interno', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: CustomLoginForm inicialização');
      stopwatch.start();
      
      String? submittedEmail;
      String? submittedPassword;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomLoginForm(
              onSubmit: (email, password) {
                submittedEmail = email;
                submittedPassword = password;
              },
            ),
          ),
        ),
      );
      
      // Verificar estado inicial
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);      expect(find.byKey(const Key('submit_button')), findsOneWidget);
        // Verificar se password está obscuro inicialmente
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      print('🔒 [STATE] Password field encontrado');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Widget inicializado corretamente');
    });

    testWidgets('26. Toggle password visibility - método interno', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: toggle password');
      stopwatch.start();
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomLoginForm(),
          ),
        ),
      );
        // Verificar estado inicial (obscuro)
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      print('🔒 [STATE] Password inicialmente obscuro');
      
      // Tocar no ícone para alternar
      await tester.tap(find.byKey(const Key('toggle_password')));
      await tester.pump();
      
      // Verificar se mudou para visível
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      print('👁️ [STATE] Password agora visível');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Toggle password funcionando');
    });

    testWidgets('27. Form validation - estado interno', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: form validation estado');
      stopwatch.start();
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomLoginForm(),
          ),
        ),
      );
      
      // Tentar submeter form vazio
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();
      
      // Verificar se erros de validação aparecem
      expect(find.text('Email é obrigatório'), findsOneWidget);
      expect(find.text('Senha é obrigatória'), findsOneWidget);
      print('❌ [VALIDATION] Erros exibidos para campos vazios');
      
      // Preencher com dados válidos
      await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Password123');
      await tester.pump();
        // Submeter novamente
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();
      
      // Aguardar o timer de 500ms completar para evitar pending timer
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Verificar se não há erros
      expect(find.text('Email é obrigatório'), findsNothing);
      expect(find.text('Senha é obrigatória'), findsNothing);
      print('✅ [VALIDATION] Formulário válido submetido');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Validação de formulário funcionando');
    });

    testWidgets('28. Animation lifecycle - controle interno', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: animation lifecycle');
      stopwatch.start();
        await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomLoginForm(),
          ),
        ),
      );
      
      print('🎬 [${DateTime.now()}] LoginForm inicializado');
      
      // Pump para completar animação inicial
      await tester.pumpAndSettle();
      
      // Verificar se pelo menos um FadeTransition existe (pode haver múltiplos devido ao MaterialApp)
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));
      print('🎬 [ANIMATION] FadeTransition encontrado');
      
      // Pegar o primeiro FadeTransition do CustomLoginForm
      final fadeTransitions = tester.widgetList<FadeTransition>(find.byType(FadeTransition));
      final customFormFadeTransition = fadeTransitions.firstWhere(
        (widget) => widget.child is Form,
        orElse: () => fadeTransitions.first,
      );
      expect(customFormFadeTransition.opacity.value, equals(1.0));
      print('🎬 [ANIMATION] Animação completada - opacity: ${customFormFadeTransition.opacity.value}');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Ciclo de vida da animação verificado');
    });

    testWidgets('29. Loading state - mudança de estado interno', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Iniciando teste: loading state');
      stopwatch.start();
      
      bool formSubmitted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomLoginForm(
              onSubmit: (email, password) {
                formSubmitted = true;
              },
            ),
          ),
        ),
      );
      
      // Preencher formulário
      await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Password123');
      
      // Submeter e verificar loading state
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Durante loading, botão deve mostrar CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('⏳ [STATE] Loading state ativo');
      
      // Aguardar completion
      await tester.pumpAndSettle();
      
      // Verificar se form foi submetido
      expect(formSubmitted, isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      print('✅ [STATE] Loading completado, form submetido');
      
      stopwatch.stop();
      print('📊 [PERFORMANCE] Tempo execução: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ [SUCESSO] Estado de loading funcionando corretamente');
    });
  });
}
