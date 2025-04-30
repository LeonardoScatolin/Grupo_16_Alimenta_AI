import 'package:flutter/foundation.dart';

class AuthService {
  // Simplified base URL - will be used for future implementation
  String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  // Simplified login method that doesn't actually make a network request
  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('Simplified login with email: $email');

    // Add a small delay to simulate network request
    await Future.delayed(const Duration(milliseconds: 500));

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email e senha são obrigatórios.',
      };
    }

    // For development, always return success
    // Later, you can replace this with actual backend authentication
    return {
      'success': true,
      'message': 'Login realizado com sucesso!',
      'user': {
        'id': '1',
        'name': 'Usuário Teste',
        'email': email,
      },
    };
  }
}
