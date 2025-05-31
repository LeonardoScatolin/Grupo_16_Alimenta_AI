import 'package:shared_preferences/shared_preferences.dart';
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
}
