import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';

// Serviço de criptografia para testes internos
class EncryptionService {
  final String _secretKey;
  late Random _random;
  
  EncryptionService(this._secretKey) {
    _random = Random.secure();
  }
  
  // Método interno para gerar salt
  String _generateSalt() {
    final bytes = List<int>.generate(16, (i) => _random.nextInt(256));
    return base64.encode(bytes);
  }
  
  // Método interno para hash com salt
  String _hashWithSalt(String data, String salt) {
    final combined = data + salt + _secretKey;
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Método interno para encriptação simples
  String _encryptData(String data) {
    final salt = _generateSalt();
    final hash = _hashWithSalt(data, salt);
    return '$salt:$hash';
  }
  
  // Método interno para validação de força de senha
  bool _validatePasswordStrength(String password) {
    if (password.length < 8) return false;
    
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      return hasUpper && hasLower && hasDigit && hasSpecial;
  }
  
  // Método interno para detecção de padrões suspeitos
  bool _detectSuspiciousPatterns(String input) {
    final sqlPatterns = [
      RegExp(r"(select|insert|update|delete|drop|union|exec)", caseSensitive: false),
      RegExp(r"(--|;|\/\*|\*\/|xp_)", caseSensitive: false),
      RegExp(r"(\b\d+\s+(or|and)\s+\d+\s*=\s*\d+)", caseSensitive: false), // Para "1 OR 1=1"
    ];
    
    final xssPatterns = [
      RegExp(r"(<script|javascript:|on\w+\s*=)", caseSensitive: false),
      RegExp(r"(alert\(|confirm\(|prompt\()", caseSensitive: false),
    ];
    
    for (final pattern in [...sqlPatterns, ...xssPatterns]) {
      if (pattern.hasMatch(input)) return true;
    }
    
    return false;
  }
  
  // Métodos públicos
  String encryptPassword(String password) {
    return _encryptData(password);
  }
    bool validatePassword(String password) {
    return _validatePasswordStrength(password);
  }
  
  String sanitizeInput(String input) {
    if (_detectSuspiciousPatterns(input)) {
      throw SecurityException('Input contém padrões suspeitos');
    }
    return input.replaceAll(RegExp(r'[<>&"' "'" + r'/]'), '');
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

void main() {
  group('🔒 Encryption & Security White-box Tests', () {
    late EncryptionService encryptionService;
    
    setUp(() {
      print('🧪 [${DateTime.now().toIso8601String()}] Setting up encryption tests');
      encryptionService = EncryptionService('test-secret-key-123');
    });
    
    tearDown(() {
      print('🧹 [${DateTime.now().toIso8601String()}] Cleaning up encryption tests');
    });
    
    group('Geração de Salt Interno', () {
      test('deve gerar salt único a cada chamada', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing salt generation uniqueness');
        
        final salt1 = encryptionService._generateSalt();
        final salt2 = encryptionService._generateSalt();
        final salt3 = encryptionService._generateSalt();
        
        expect(salt1, isNot(equals(salt2)));
        expect(salt2, isNot(equals(salt3)));
        expect(salt1, isNot(equals(salt3)));
        
        print('✅ Salt generation produces unique values');
      });
      
      test('deve gerar salt com tamanho adequado', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing salt size validation');
        
        final salt = encryptionService._generateSalt();
        final decodedBytes = base64.decode(salt);
        
        expect(decodedBytes.length, equals(16));
        expect(salt.isNotEmpty, isTrue);
        
        print('✅ Salt has correct size (16 bytes)');
      });
    });
    
    group('Hash com Salt Interno', () {
      test('deve produzir hash consistente para mesmos inputs', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing hash consistency');
        
        const data = 'test-data';
        const salt = 'test-salt';
        
        final hash1 = encryptionService._hashWithSalt(data, salt);
        final hash2 = encryptionService._hashWithSalt(data, salt);
        
        expect(hash1, equals(hash2));
        expect(hash1.length, equals(64)); // SHA-256 length
        
        print('✅ Hash produces consistent results');
      });
      
      test('deve produzir hashes diferentes para dados diferentes', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing hash uniqueness for different data');
        
        const salt = 'test-salt';
        
        final hash1 = encryptionService._hashWithSalt('data1', salt);
        final hash2 = encryptionService._hashWithSalt('data2', salt);
        final hash3 = encryptionService._hashWithSalt('data3', salt);
        
        expect(hash1, isNot(equals(hash2)));
        expect(hash2, isNot(equals(hash3)));
        expect(hash1, isNot(equals(hash3)));
        
        print('✅ Different data produces different hashes');
      });
      
      test('deve produzir hashes diferentes para salts diferentes', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing hash uniqueness for different salts');
        
        const data = 'test-data';
        
        final hash1 = encryptionService._hashWithSalt(data, 'salt1');
        final hash2 = encryptionService._hashWithSalt(data, 'salt2');
        final hash3 = encryptionService._hashWithSalt(data, 'salt3');
        
        expect(hash1, isNot(equals(hash2)));
        expect(hash2, isNot(equals(hash3)));
        expect(hash1, isNot(equals(hash3)));
        
        print('✅ Different salts produce different hashes');
      });
    });
    
    group('Encriptação de Dados Interna', () {
      test('deve encriptar dados com formato salt:hash', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing data encryption format');
        
        const data = 'sensitive-data';
        final encrypted = encryptionService._encryptData(data);
        
        expect(encrypted.contains(':'), isTrue);
        
        final parts = encrypted.split(':');
        expect(parts.length, equals(2));
        expect(parts[0].isNotEmpty, isTrue); // salt
        expect(parts[1].isNotEmpty, isTrue); // hash
        expect(parts[1].length, equals(64)); // SHA-256 length
        
        print('✅ Encryption follows salt:hash format');
      });
      
      test('deve produzir encriptações diferentes para mesmo dado', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing encryption uniqueness');
        
        const data = 'same-data';
        
        final encrypted1 = encryptionService._encryptData(data);
        final encrypted2 = encryptionService._encryptData(data);
        final encrypted3 = encryptionService._encryptData(data);
        
        expect(encrypted1, isNot(equals(encrypted2)));
        expect(encrypted2, isNot(equals(encrypted3)));
        expect(encrypted1, isNot(equals(encrypted3)));
        
        print('✅ Same data produces different encryptions (due to salt)');
      });
    });
    
    group('Validação de Força de Senha Interna', () {
      test('deve rejeitar senhas fracas', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing weak password rejection');
        
        final weakPasswords = [
          '123456',
          'password',
          'abc',
          'PASSWORD',
          '12345678',
          'abcdefgh',
          'ABCDEFGH',
          'Abcdefgh',
          'Password',
          '123Pass',
        ];
        
        for (final password in weakPasswords) {
          final isValid = encryptionService._validatePasswordStrength(password);
          expect(isValid, isFalse, reason: 'Password "$password" should be invalid');
        }
        
        print('✅ Weak passwords properly rejected');
      });
      
      test('deve aceitar senhas fortes', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing strong password acceptance');
          final strongPasswords = [
          'Password123!',
          'MyStr0ng@Pass',
          'S3cur3#P4ssw0rd',
          'C0mpl3x\$Passw0rd',
          'V3ry\$tr0ng&P@ss',
        ];
        
        for (final password in strongPasswords) {
          final isValid = encryptionService._validatePasswordStrength(password);
          expect(isValid, isTrue, reason: 'Password "$password" should be valid');
        }
        
        print('✅ Strong passwords properly accepted');
      });
        test('deve verificar requisitos específicos de senha', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing specific password requirements');
          // Teste individual de cada requisito
        expect(encryptionService._validatePasswordStrength('Password123!'), isTrue); // tem tudo
        expect(encryptionService._validatePasswordStrength('MyPass123!'), isTrue); // tem minúscula, maiúscula, número e especial
        expect(encryptionService._validatePasswordStrength('Strong1!'), isTrue); // tem tudo 
        expect(encryptionService._validatePasswordStrength('Valid123!'), isTrue); // tem maiúscula, minúscula, número e especial
        expect(encryptionService._validatePasswordStrength('Test123!'), isTrue); // tem maiúscula, minúscula, número e especial
        expect(encryptionService._validatePasswordStrength('Pass1!'), isFalse); // muito curta
        
        print('✅ Individual password requirements properly validated');
      });
    });
    
    group('Detecção de Padrões Suspeitos Interna', () {
      test('deve detectar padrões de SQL injection', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing SQL injection pattern detection');
        
        final sqlInputs = [
          "'; DROP TABLE users; --",
          "1 OR 1=1",
          "UNION SELECT * FROM passwords",
          "exec xp_cmdshell",
          "INSERT INTO users VALUES",
          "DELETE FROM table",
        ];
        
        for (final input in sqlInputs) {
          final isSuspicious = encryptionService._detectSuspiciousPatterns(input);
          expect(isSuspicious, isTrue, reason: 'SQL injection "$input" should be detected');
        }
        
        print('✅ SQL injection patterns properly detected');
      });
      
      test('deve detectar padrões de XSS', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing XSS pattern detection');
        
        final xssInputs = [
          '<script>alert("xss")</script>',
          'javascript:alert(1)',
          'onclick="alert(1)"',
          'onmouseover="alert(1)"',
          'alert("hack")',
          'confirm("test")',
          'prompt("enter")',
        ];
        
        for (final input in xssInputs) {
          final isSuspicious = encryptionService._detectSuspiciousPatterns(input);
          expect(isSuspicious, isTrue, reason: 'XSS "$input" should be detected');
        }
        
        print('✅ XSS patterns properly detected');
      });
      
      test('deve permitir entradas legítimas', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing legitimate input acceptance');
        
        final legitimateInputs = [
          'João da Silva',
          'email@example.com',
          'Minha refeição favorita',
          'Receita: 2 ovos, 1 xícara de leite',
          'Comentário sobre nutrição',
          'Telefone: (11) 99999-9999',
        ];
        
        for (final input in legitimateInputs) {
          final isSuspicious = encryptionService._detectSuspiciousPatterns(input);
          expect(isSuspicious, isFalse, reason: 'Legitimate input "$input" should be allowed');
        }
        
        print('✅ Legitimate inputs properly allowed');
      });
    });
    
    group('Métodos Públicos de Segurança', () {
      test('deve encriptar senhas com método público', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing public password encryption');
        
        const password = 'MyPassword123!';
        final encrypted = encryptionService.encryptPassword(password);
        
        expect(encrypted.contains(':'), isTrue);
        expect(encrypted.isNotEmpty, isTrue);
        
        final parts = encrypted.split(':');
        expect(parts.length, equals(2));
        
        print('✅ Public password encryption works correctly');
      });
      
      test('deve validar senhas com método público', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing public password validation');
        
        expect(encryptionService.validatePassword('StrongPass123!'), isTrue);
        expect(encryptionService.validatePassword('weak'), isFalse);
        expect(encryptionService.validatePassword(''), isFalse);
        
        print('✅ Public password validation works correctly');
      });
      
      test('deve sanitizar entradas com método público', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing public input sanitization');
        
        const legitimateInput = 'Nome do usuário';
        final sanitized = encryptionService.sanitizeInput(legitimateInput);
        expect(sanitized, equals(legitimateInput));
        
        const inputWithHtml = 'Nome<script>alert(1)</script>';
        expect(() => encryptionService.sanitizeInput(inputWithHtml), 
               throwsA(isA<SecurityException>()));
        
        const inputWithSpecialChars = 'Nome & Sobrenome';
        final sanitizedSpecial = encryptionService.sanitizeInput(inputWithSpecialChars);
        expect(sanitizedSpecial, equals('Nome  Sobrenome'));
        
        print('✅ Public input sanitization works correctly');
      });
    });
    
    group('Testes de Performance e Segurança', () {
      test('deve ter performance adequada para operações de hash', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing hash performance');
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          encryptionService._hashWithSalt('data$i', 'salt$i');
        }
        
        stopwatch.stop();
        final avgTime = stopwatch.elapsedMicroseconds / 100;
        
        expect(avgTime, lessThan(10000)); // Menos de 10ms por hash
        print('📊 Average hash time: ${avgTime.toStringAsFixed(2)} microseconds');
        print('✅ Hash performance is adequate');
      });
      
      test('deve ter performance adequada para validação de senhas', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing password validation performance');
        
        final passwords = List.generate(50, (i) => 'Password$i!');
        final stopwatch = Stopwatch()..start();
        
        for (final password in passwords) {
          encryptionService._validatePasswordStrength(password);
        }
        
        stopwatch.stop();
        final avgTime = stopwatch.elapsedMicroseconds / passwords.length;
        
        expect(avgTime, lessThan(1000)); // Menos de 1ms por validação
        print('📊 Average validation time: ${avgTime.toStringAsFixed(2)} microseconds');
        print('✅ Password validation performance is adequate');
      });
      
      test('deve ter performance adequada para detecção de padrões', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing pattern detection performance');
        
        final inputs = List.generate(50, (i) => 'Input normal $i para teste');
        final stopwatch = Stopwatch()..start();
        
        for (final input in inputs) {
          encryptionService._detectSuspiciousPatterns(input);
        }
        
        stopwatch.stop();
        final avgTime = stopwatch.elapsedMicroseconds / inputs.length;
        
        expect(avgTime, lessThan(5000)); // Menos de 5ms por detecção
        print('📊 Average detection time: ${avgTime.toStringAsFixed(2)} microseconds');
        print('✅ Pattern detection performance is adequate');
      });
    });
  });
}
