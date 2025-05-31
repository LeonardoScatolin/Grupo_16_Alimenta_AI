import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';

// Mock classes for testing validation and security
@GenerateMocks([])
void main() {
  group('🧪 Validation and Security White-box Tests', () {
    setUp(() {
      print('🧪 [${DateTime.now()}] Setting up validation and security test environment');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up validation and security test environment');
    });

    test('Should validate email formats correctly', () {
      print('🧪 [${DateTime.now()}] Testing email validation');
      final stopwatch = Stopwatch()..start();

      final validator = _EmailValidator();

      // Test valid emails
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        'user123@test-domain.com',
      ];

      for (final email in validEmails) {
        expect(validator.isValid(email), isTrue, reason: 'Email $email should be valid');
        print('📊 [${DateTime.now()}] Valid email tested: $email');
      }

      // Test invalid emails
      final invalidEmails = [
        'invalid-email',
        '@example.com',
        'user@',
        'user@.com',
        'user..double@example.com',
        'user@example.',
      ];

      for (final email in invalidEmails) {
        expect(validator.isValid(email), isFalse, reason: 'Email $email should be invalid');
        print('📊 [${DateTime.now()}] Invalid email tested: $email');
      }

      print('✅ [${DateTime.now()}] Email validation verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Email validation test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should validate password strength correctly', () {
      print('🧪 [${DateTime.now()}] Testing password validation');
      final stopwatch = Stopwatch()..start();

      final validator = _PasswordValidator();

      // Test strong passwords
      final strongPasswords = [
        'StrongP@ssw0rd123',
        'MySecure#Pass1',
        'Complex&Strong9',
        'A1b2C3d4@#',
      ];

      for (final password in strongPasswords) {
        final result = validator.validate(password);
        expect(result.isValid, isTrue, reason: 'Password $password should be strong');
        expect(result.strength, equals(PasswordStrength.strong));
        print('📊 [${DateTime.now()}] Strong password tested: ${password.replaceAll(RegExp(r'.'), '*')}');
      }      // Test medium passwords
      final mediumPasswords = [
        'Password123',
        'MyPassw0rd', 
        'TestPass123',
      ];

      for (final password in mediumPasswords) {
        final result = validator.validate(password);
        expect(result.strength, isIn([PasswordStrength.medium, PasswordStrength.strong]));
        print('📊 [${DateTime.now()}] Medium password tested: ${password.replaceAll(RegExp(r'.'), '*')}');
      }

      // Test weak passwords
      final weakPasswords = [
        'password',
        '123456',
        'abc',
        'simple',
      ];

      for (final password in weakPasswords) {
        final result = validator.validate(password);
        expect(result.isValid, isFalse);
        expect(result.strength, equals(PasswordStrength.weak));
        print('📊 [${DateTime.now()}] Weak password tested: ${password.replaceAll(RegExp(r'.'), '*')}');
      }

      print('✅ [${DateTime.now()}] Password validation verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Password validation test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should sanitize input data correctly', () {
      print('🧪 [${DateTime.now()}] Testing input sanitization');
      final stopwatch = Stopwatch()..start();

      final sanitizer = _InputSanitizer();

      // Test HTML injection prevention
      final htmlInput = '<script>alert("xss")</script>Hello World';
      final sanitizedHtml = sanitizer.sanitizeHtml(htmlInput);
      expect(sanitizedHtml, equals('Hello World'));
      expect(sanitizedHtml, isNot(contains('<script>')));
      print('📊 [${DateTime.now()}] HTML sanitization: "$htmlInput" → "$sanitizedHtml"');

      // Test SQL injection prevention
      final sqlInput = "'; DROP TABLE users; --";
      final sanitizedSql = sanitizer.sanitizeSql(sqlInput);
      expect(sanitizedSql, isNot(contains('DROP TABLE')));
      expect(sanitizedSql, isNot(contains(';')));
      print('📊 [${DateTime.now()}] SQL sanitization: "$sqlInput" → "$sanitizedSql"');

      // Test whitespace normalization
      final whitespaceInput = '  Multiple   Spaces   Here  ';
      final normalizedWhitespace = sanitizer.normalizeWhitespace(whitespaceInput);
      expect(normalizedWhitespace, equals('Multiple Spaces Here'));
      print('📊 [${DateTime.now()}] Whitespace normalization: "$whitespaceInput" → "$normalizedWhitespace"');

      // Test special character handling
      final specialCharsInput = 'Test@#\$%^&*(){}[]|\\:";\'<>?,./`~';
      final sanitizedSpecial = sanitizer.sanitizeSpecialChars(specialCharsInput);
      expect(sanitizedSpecial.length, lessThan(specialCharsInput.length));
      print('📊 [${DateTime.now()}] Special chars sanitization: "${specialCharsInput.substring(0, 10)}..." → "$sanitizedSpecial"');

      print('✅ [${DateTime.now()}] Input sanitization verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Input sanitization test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle data encryption and decryption', () {
      print('🧪 [${DateTime.now()}] Testing data encryption');
      final stopwatch = Stopwatch()..start();

      final encryptor = _DataEncryptor();

      // Test string encryption
      final originalText = 'Sensitive user data that needs protection';
      final encryptedText = encryptor.encrypt(originalText);
      expect(encryptedText, isNot(equals(originalText)));
      expect(encryptedText.length, greaterThan(originalText.length));
      print('📊 [${DateTime.now()}] Text encrypted: "${originalText.substring(0, 10)}..." → "${encryptedText.substring(0, 10)}..."');

      // Test decryption
      final decryptedText = encryptor.decrypt(encryptedText);
      expect(decryptedText, equals(originalText));
      print('📊 [${DateTime.now()}] Text decrypted successfully');

      // Test JSON encryption
      final originalJson = {'username': 'testuser', 'password': 'secret123'};
      final encryptedJson = encryptor.encryptJson(originalJson);
      expect(encryptedJson, isNot(equals(jsonEncode(originalJson))));
      print('📊 [${DateTime.now()}] JSON encrypted successfully');

      // Test JSON decryption
      final decryptedJson = encryptor.decryptJson(encryptedJson);
      expect(decryptedJson['username'], equals('testuser'));
      expect(decryptedJson['password'], equals('secret123'));
      print('📊 [${DateTime.now()}] JSON decrypted successfully');

      print('✅ [${DateTime.now()}] Data encryption verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Data encryption test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should validate form inputs comprehensively', () {
      print('🧪 [${DateTime.now()}] Testing form validation');
      final stopwatch = Stopwatch()..start();

      final formValidator = _FormValidator();

      // Test user registration form
      final validForm = {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'password': 'SecureP@ssw0rd123',
        'confirmPassword': 'SecureP@ssw0rd123',
        'age': '25',
        'phone': '+1234567890',
      };

      final validResult = formValidator.validateRegistrationForm(validForm);
      expect(validResult.isValid, isTrue);
      expect(validResult.errors, isEmpty);
      print('📊 [${DateTime.now()}] Valid registration form passed validation');

      // Test invalid form
      final invalidForm = {
        'name': '',
        'email': 'invalid-email',
        'password': 'weak',
        'confirmPassword': 'different',
        'age': 'not-a-number',
        'phone': '123',
      };

      final invalidResult = formValidator.validateRegistrationForm(invalidForm);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors.length, greaterThan(0));
      print('📊 [${DateTime.now()}] Invalid registration form caught ${invalidResult.errors.length} errors');

      // Test specific field validations
      expect(formValidator.validateName(''), isFalse);
      expect(formValidator.validateName('John Doe'), isTrue);
      expect(formValidator.validateAge('25'), isTrue);
      expect(formValidator.validateAge('not-a-number'), isFalse);
      expect(formValidator.validatePhone('+1234567890'), isTrue);
      expect(formValidator.validatePhone('123'), isFalse);

      print('✅ [${DateTime.now()}] Form validation verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Form validation test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle security tokens and authentication', () {
      print('🧪 [${DateTime.now()}] Testing security tokens');
      final stopwatch = Stopwatch()..start();

      final tokenManager = _SecurityTokenManager();

      // Test token generation
      final token = tokenManager.generateToken('user123');
      expect(token.length, greaterThan(20));
      expect(token, contains('.'));
      print('📊 [${DateTime.now()}] Token generated: "${token.substring(0, 10)}..."');

      // Test token validation
      final isValid = tokenManager.validateToken(token);
      expect(isValid, isTrue);
      print('📊 [${DateTime.now()}] Token validation successful');

      // Test token expiration
      final expiredToken = tokenManager.generateExpiredToken('user123');
      final isExpiredValid = tokenManager.validateToken(expiredToken);
      expect(isExpiredValid, isFalse);
      print('📊 [${DateTime.now()}] Expired token correctly rejected');

      // Test token payload extraction
      final payload = tokenManager.extractPayload(token);
      expect(payload['userId'], equals('user123'));
      expect(payload['timestamp'], isNotNull);
      print('📊 [${DateTime.now()}] Token payload extracted successfully');

      print('✅ [${DateTime.now()}] Security tokens verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Security tokens test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle rate limiting and abuse prevention', () {
      print('🧪 [${DateTime.now()}] Testing rate limiting');
      final stopwatch = Stopwatch()..start();

      final rateLimiter = _RateLimiter();

      // Test normal usage
      for (int i = 0; i < 5; i++) {
        final allowed = rateLimiter.isAllowed('user123');
        expect(allowed, isTrue);
        print('📊 [${DateTime.now()}] Request ${i + 1} allowed for user123');
      }

      // Test rate limit exceeded
      for (int i = 0; i < 10; i++) {
        rateLimiter.isAllowed('user456'); // Exhaust rate limit
      }

      final rateLimitExceeded = rateLimiter.isAllowed('user456');
      expect(rateLimitExceeded, isFalse);
      print('📊 [${DateTime.now()}] Rate limit correctly enforced for user456');

      // Test different users have separate limits
      final anotherUserAllowed = rateLimiter.isAllowed('user789');
      expect(anotherUserAllowed, isTrue);
      print('📊 [${DateTime.now()}] Separate rate limits for different users verified');

      print('✅ [${DateTime.now()}] Rate limiting verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Rate limiting test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should validate file uploads securely', () {
      print('🧪 [${DateTime.now()}] Testing file upload validation');
      final stopwatch = Stopwatch()..start();

      final fileValidator = _FileUploadValidator();

      // Test valid image files
      final validImages = [
        {'name': 'photo.jpg', 'size': 1024000, 'type': 'image/jpeg'},
        {'name': 'avatar.png', 'size': 512000, 'type': 'image/png'},
        {'name': 'icon.gif', 'size': 256000, 'type': 'image/gif'},
      ];

      for (final file in validImages) {
        final result = fileValidator.validateImageUpload(
          file['name'] as String,
          file['size'] as int,
          file['type'] as String,
        );
        expect(result.isValid, isTrue);
        print('📊 [${DateTime.now()}] Valid image file: ${file['name']}');
      }

      // Test invalid files
      final invalidFiles = [
        {'name': 'script.exe', 'size': 1024, 'type': 'application/exe'},
        {'name': 'large.jpg', 'size': 10485760, 'type': 'image/jpeg'}, // Too large
        {'name': 'no-extension', 'size': 1024, 'type': 'application/octet-stream'},
      ];

      for (final file in invalidFiles) {
        final result = fileValidator.validateImageUpload(
          file['name'] as String,
          file['size'] as int,
          file['type'] as String,
        );
        expect(result.isValid, isFalse);
        print('📊 [${DateTime.now()}] Invalid file rejected: ${file['name']} - ${result.error}');
      }

      print('✅ [${DateTime.now()}] File upload validation verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] File upload validation test completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

// Helper classes for validation and security testing

class _EmailValidator {
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9+]+([._-]?[a-zA-Z0-9+]+)*@[a-zA-Z0-9]+([.-]?[a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$',
  );

  bool isValid(String email) {
    // Additional check for consecutive dots
    if (email.contains('..')) return false;
    return _emailRegex.hasMatch(email);
  }
}

enum PasswordStrength { weak, medium, strong }

class PasswordValidationResult {
  final bool isValid;
  final PasswordStrength strength;
  final List<String> issues;

  PasswordValidationResult(this.isValid, this.strength, this.issues);
}

class _PasswordValidator {
  PasswordValidationResult validate(String password) {
    final issues = <String>[];
    
    if (password.length < 8) issues.add('Too short');
    if (!password.contains(RegExp(r'[A-Z]'))) issues.add('No uppercase');
    if (!password.contains(RegExp(r'[a-z]'))) issues.add('No lowercase');
    if (!password.contains(RegExp(r'[0-9]'))) issues.add('No numbers');
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) issues.add('No special chars');

    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    // Password is only valid if it meets minimum requirements
    final isValid = password.length >= 8 && hasUpper && hasLower && hasNumber;
    PasswordStrength strength;

    if (password.length >= 10 && hasUpper && hasLower && hasNumber && hasSpecial) {
      strength = PasswordStrength.strong;
    } else if (password.length >= 8 && hasUpper && hasLower && hasNumber) {
      strength = PasswordStrength.medium;
    } else {
      strength = PasswordStrength.weak;
    }

    return PasswordValidationResult(isValid, strength, issues);
  }
}

class _InputSanitizer {
  String sanitizeHtml(String input) {
    // Remove script tags and their content
    String sanitized = input.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
    // Remove all other HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove remaining < and > characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>]'), '');
    return sanitized;
  }

  String sanitizeSql(String input) {
    return input
        .replaceAll(RegExp(r'''[;'"\\]'''), '')
        .replaceAll(RegExp(r'\b(DROP|DELETE|INSERT|UPDATE|SELECT)\b', caseSensitive: false), '');
  }

  String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String sanitizeSpecialChars(String input) {
    return input.replaceAll(RegExp(r'[^\w\s@.-]'), '');
  }
}

class _DataEncryptor {
  String encrypt(String data) {
    // Simple base64 encoding for testing purposes
    final bytes = utf8.encode(data);
    return base64.encode(bytes);
  }

  String decrypt(String encryptedData) {
    final bytes = base64.decode(encryptedData);
    return utf8.decode(bytes);
  }

  String encryptJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString);
  }

  Map<String, dynamic> decryptJson(String encryptedJson) {
    final jsonString = decrypt(encryptedJson);
    return jsonDecode(jsonString);
  }
}

class FormValidationResult {
  final bool isValid;
  final List<String> errors;

  FormValidationResult(this.isValid, this.errors);
}

class _FormValidator {
  FormValidationResult validateRegistrationForm(Map<String, String> form) {
    final errors = <String>[];

    if (!validateName(form['name'] ?? '')) {
      errors.add('Invalid name');
    }

    if (!_EmailValidator().isValid(form['email'] ?? '')) {
      errors.add('Invalid email');
    }

    final password = form['password'] ?? '';
    final confirmPassword = form['confirmPassword'] ?? '';
    
    if (!_PasswordValidator().validate(password).isValid) {
      errors.add('Weak password');
    }

    if (password != confirmPassword) {
      errors.add('Passwords do not match');
    }

    if (!validateAge(form['age'] ?? '')) {
      errors.add('Invalid age');
    }

    if (!validatePhone(form['phone'] ?? '')) {
      errors.add('Invalid phone');
    }

    return FormValidationResult(errors.isEmpty, errors);
  }

  bool validateName(String name) {
    return name.trim().isNotEmpty && name.length >= 2;
  }
  bool validateAge(String age) {
    final ageInt = int.tryParse(age);
    return ageInt != null && ageInt >= 18 && ageInt <= 120;
  }
  bool validatePhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s'), ''));
  }
}

class _SecurityTokenManager {
  String generateToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = base64.encode(utf8.encode('{"userId":"$userId","timestamp":$timestamp}'));
    final signature = base64.encode(utf8.encode('signature_$userId$timestamp'));
    return '$payload.$signature';
  }

  String generateExpiredToken(String userId) {
    final expiredTimestamp = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
    final payload = base64.encode(utf8.encode('{"userId":"$userId","timestamp":$expiredTimestamp}'));
    final signature = base64.encode(utf8.encode('signature_$userId$expiredTimestamp'));
    return '$payload.$signature';
  }

  bool validateToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return false;

      final payloadJson = utf8.decode(base64.decode(parts[0]));
      final payload = jsonDecode(payloadJson);
      final timestamp = payload['timestamp'] as int;
      
      // Check if token is expired (1 hour validity)
      final isExpired = DateTime.now().millisecondsSinceEpoch - timestamp > 3600000;
      return !isExpired;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> extractPayload(String token) {
    final parts = token.split('.');
    final payloadJson = utf8.decode(base64.decode(parts[0]));
    return jsonDecode(payloadJson);
  }
}

class _RateLimiter {
  final Map<String, List<int>> _userRequests = {};
  final int _maxRequests = 10;
  final int _timeWindowMs = 60000; // 1 minute

  bool isAllowed(String userId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (!_userRequests.containsKey(userId)) {
      _userRequests[userId] = [];
    }

    final userRequests = _userRequests[userId]!;
    
    // Remove old requests outside time window
    userRequests.removeWhere((timestamp) => now - timestamp > _timeWindowMs);
    
    // Check if under limit
    if (userRequests.length < _maxRequests) {
      userRequests.add(now);
      return true;
    }
    
    return false;
  }
}

class FileValidationResult {
  final bool isValid;
  final String? error;

  FileValidationResult(this.isValid, this.error);
}

class _FileUploadValidator {
  final List<String> _allowedImageTypes = ['image/jpeg', 'image/png', 'image/gif'];
  final List<String> _allowedImageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
  final int _maxImageSize = 5242880; // 5MB

  FileValidationResult validateImageUpload(String fileName, int fileSize, String mimeType) {
    // Check file extension
    final hasValidExtension = _allowedImageExtensions.any(
      (ext) => fileName.toLowerCase().endsWith(ext),
    );
    
    if (!hasValidExtension) {
      return FileValidationResult(false, 'Invalid file extension');
    }

    // Check MIME type
    if (!_allowedImageTypes.contains(mimeType)) {
      return FileValidationResult(false, 'Invalid file type');
    }

    // Check file size
    if (fileSize > _maxImageSize) {
      return FileValidationResult(false, 'File too large');
    }

    return FileValidationResult(true, null);
  }
}
