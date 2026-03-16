// import 'dart:convert';

// import 'package:shared_preferences/shared_preferences.dart';

// class LocalStorage {
//   static const String tokenKey = 'token';
//   static const String userKey = 'authUser';
//   static const String regNameKey = 'reg_name';
//   static const String regEmailKey = 'reg_email';

//   static Future<void> saveToken(String token) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(tokenKey, token);
//   }

//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(tokenKey);
//   }

//   static Future<void> saveUser(Map<String, dynamic> user) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(userKey, jsonEncode(user));
//   }

//   static Future<Map<String, dynamic>?> getUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userString = prefs.getString(userKey);

//     if (userString == null || userString.isEmpty) return null;

//     return Map<String, dynamic>.from(jsonDecode(userString));
//   }

//   static Future<void> saveRegisterName(String name) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(regNameKey, name);
//   }

//   static Future<void> saveRegisterEmail(String email) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(regEmailKey, email);
//   }

//   static Future<String?> getRegisterName() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(regNameKey);
//   }

//   static Future<String?> getRegisterEmail() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(regEmailKey);
//   }

//   static Future<void> clearRegisterData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(regNameKey);
//     await prefs.remove(regEmailKey);
//   }

//   static Future<void> clearToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(tokenKey);
//   }

//   static Future<void> clearUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(userKey);
//   }

//   static Future<void> clearAuth() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(tokenKey);
//     await prefs.remove(userKey);
//   }
// }







import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String tokenKey = 'token';
  static const String userKey = 'authUser';
  static const String regNameKey = 'reg_name';
  static const String regEmailKey = 'reg_email';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(userKey);

    if (userString == null || userString.isEmpty) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(userString));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveRegisterName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(regNameKey, name);
  }

  static Future<void> saveRegisterEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(regEmailKey, email);
  }

  static Future<String?> getRegisterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(regNameKey);
  }

  static Future<String?> getRegisterEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(regEmailKey);
  }

  static Future<void> clearRegisterData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(regNameKey);
    await prefs.remove(regEmailKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
    await prefs.remove(regNameKey);
    await prefs.remove(regEmailKey);
  }
}
