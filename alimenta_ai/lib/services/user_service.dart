import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class UserService {
  static const String _userDataKey = 'user_data';
  static const String _userNameKey = 'user_name';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Salvar dados do usuário após login
  static Future<void> saveUserData({
    required int userId,
    required String userName,
    required String userEmail,
    Map<String, dynamic>? additionalData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Salvar dados individuais para acesso rápido
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);

    // Salvar dados completos se fornecidos
    if (additionalData != null) {
      final userData = {
        'id': userId,
        'name': userName,
        'email': userEmail,
        ...additionalData,
      };
      await prefs.setString(_userDataKey, jsonEncode(userData));
    }
  }

  // Obter nome do usuário
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Obter ID do usuário
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Obter email do usuário
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Obter dados completos do usuário
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);

    if (userDataString != null) {
      return jsonDecode(userDataString);
    }

    // Fallback: construir dados básicos se existirem
    final name = prefs.getString(_userNameKey);
    final id = prefs.getInt(_userIdKey);
    final email = prefs.getString(_userEmailKey);

    if (name != null && id != null && email != null) {
      return {
        'id': id,
        'name': name,
        'email': email,
      };
    }

    return null;
  }

  // Limpar dados do usuário (logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  // Verificar se o usuário está logado
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userNameKey) && prefs.containsKey(_userIdKey);
  }

  // Obter ID do nutricionista associado ao paciente
  static Future<int?> getNutriId() async {
    final userData = await getUserData();
    if (userData != null && userData.containsKey('nutri_id')) {
      return userData['nutri_id'] as int?;
    }
    return null;
  }

  // Obter tipo de usuário (paciente ou nutri)
  static Future<String?> getUserType() async {
    final userData = await getUserData();
    if (userData != null && userData.containsKey('tipo')) {
      return userData['tipo'] as String?;
    }
    return null;
  }

  // Método auxiliar para obter os IDs necessários para a API
  static Future<Map<String, int?>> getApiIds() async {
    final userData = await getUserData();
    int? pacienteId;
    int? nutriId;

    if (userData != null) {
      final userType = userData['tipo'] as String?;
      final userId = userData['id'] as int?;

      debugPrint('🔧 UserService.getApiIds - Tipo: $userType, UserID: $userId');
      debugPrint('🔧 UserService.getApiIds - UserData completo: $userData');

      if (userType == 'paciente') {
        pacienteId = userId;
        nutriId = userData['nutri_id'] as int?;
        debugPrint(
            '🔧 Configuração para PACIENTE - PacienteID: $pacienteId, NutriID: $nutriId');
      } else if (userType == 'nutricionista' || userType == 'nutri') {
        nutriId = userId;
        // Para nutricionista, ele pode visualizar vários pacientes,
        // mas para o dashboard dele, usaremos seu próprio ID como paciente temporariamente
        pacienteId = userId;
        debugPrint(
            '🔧 Configuração para NUTRICIONISTA - NutriID: $nutriId, PacienteID (próprio): $pacienteId');
      } else {
        debugPrint(
            '⚠️ Tipo de usuário não reconhecido: $userType - Tentando usar como paciente');
        pacienteId = userId;
        nutriId =
            userData['nutri_id'] as int? ?? 1; // Fallback para nutri_id = 1
      }
    } else {
      debugPrint('❌ UserService.getApiIds - Nenhum userData encontrado');
    }

    debugPrint(
        '🔧 IDs finais retornados - PacienteID: $pacienteId, NutriID: $nutriId');

    return {
      'paciente_id': pacienteId,
      'nutri_id': nutriId,
    };
  }

  // Método para verificar se os dados do usuário estão completos
  static Future<bool> hasCompleteUserData() async {
    final userData = await getUserData();
    if (userData == null) return false;

    final userId = userData['id'] as int?;
    final userType = userData['tipo'] as String?;

    if (userId == null || userType == null) return false;

    // Para pacientes, verificar se tem nutri_id
    if (userType == 'paciente') {
      final nutriId = userData['nutri_id'] as int?;
      return nutriId != null;
    }

    // Para nutricionistas, os dados básicos são suficientes
    return true;
  }

  // Método para obter dados do usuário com debug detalhado
  static Future<Map<String, dynamic>?> getUserDataDebug() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);

    debugPrint('🔍 getUserDataDebug - userDataString: $userDataString');

    if (userDataString != null) {
      final decoded = jsonDecode(userDataString);
      debugPrint('🔍 getUserDataDebug - dados decodificados: $decoded');
      return decoded;
    }

    // Fallback: construir dados básicos se existirem
    final name = prefs.getString(_userNameKey);
    final id = prefs.getInt(_userIdKey);
    final email = prefs.getString(_userEmailKey);

    debugPrint(
        '🔍 getUserDataDebug - fallback - name: $name, id: $id, email: $email');

    if (name != null && id != null && email != null) {
      final basicData = {
        'id': id,
        'name': name,
        'email': email,
      };
      debugPrint('🔍 getUserDataDebug - dados básicos construídos: $basicData');
      return basicData;
    }

    debugPrint('🔍 getUserDataDebug - nenhum dado encontrado');
    return null;
  }
}
