import 'package:flutter/foundation.dart';
import 'alimenta_api_service.dart';

class AuthService {
  // Usar uma instância singleton do AlimentaAPIService
  static final AlimentaAPIService _apiService = AlimentaAPIService();
  // Simplified base URL - will be used for future implementation
  String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3333';
    } else {
      return 'http://127.0.0.1:3333';
    }
  }

  // Login integrado com a API real
  Future<Map<String, dynamic>> login(String email, String password,
      {String tipo = 'paciente'}) async {
    debugPrint('🔐 Fazendo login como $tipo com email: $email');

    try {
      Map<String, dynamic> result;

      if (tipo == 'nutricionista' || tipo == 'nutri') {
        result = await _apiService.loginNutri(email, password);
      } else {
        result = await _apiService.loginPaciente(email, password);
      }

      debugPrint('📤 Resposta da API: $result'); // VERIFICAÇÃO MAIS RIGOROSA
      if (result['success'] == true && result.containsKey('data')) {
        final userData = result['data'];

        // Verificar se a resposta do backend tem status true
        if (userData['status'] == true) {
          final token = userData['token'];

          // Para paciente: dados estão em userData['paciente']
          // Para nutri: dados estão em userData['nutri']
          final userInfo = userData['paciente'] ?? userData['nutri'];
          if (token != null && userInfo != null) {
            final userId = userInfo['paciente_id'] ?? userInfo['nutri_id'];
            final userName = userInfo['nome'] ?? 'Usuário';
            final nutriId = userInfo[
                'nutri_id']; // Para pacientes, já existe; para nutris, será o próprio ID

            debugPrint(
                '✅ Login bem-sucedido! Token: ${token.substring(0, 20)}...');

            // Definir token no AlimentaAPIService para futuras requisições autenticadas
            _apiService.setAuthToken(token);

            return {
              'success': true,
              'message': 'Login realizado com sucesso!',
              'user': {
                'id': userId,
                'name': userName,
                'email': email,
                'tipo': tipo,
                'token': token,
                'nutri_id': nutriId,
              },
            };
          } else {
            debugPrint('❌ Login falhou: Token ou dados do usuário ausentes');
            return {
              'success': false,
              'message': 'Erro na autenticação - dados incompletos',
            };
          }
        } else {
          debugPrint('❌ Login falhou: Status false do backend');
          return {
            'success': false,
            'message': userData['message'] ??
                userData['error'] ??
                'Erro na autenticação',
          };
        }
      } else {
        debugPrint(
            '❌ Login falhou: ${result['error'] ?? 'Credenciais inválidas'}');
        return {
          'success': false,
          'message': result['error'] ?? 'Credenciais inválidas',
        };
      }
    } catch (e) {
      debugPrint('💥 Erro no login: $e');
      return {
        'success': false,
        'message': 'Erro de conexão com o servidor.',
      };
    }
  }

  // Login específico para paciente
  Future<Map<String, dynamic>> loginPaciente(
      String email, String password) async {
    return login(email, password, tipo: 'paciente');
  }

  // Login específico para nutricionista
  Future<Map<String, dynamic>> loginNutri(String email, String password) async {
    return login(email, password, tipo: 'nutricionista');
  }
}
