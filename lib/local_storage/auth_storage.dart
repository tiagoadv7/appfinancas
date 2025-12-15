import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Simple storage for Google login info using SharedPreferences.
/// Stores a JSON object under key `google_user`.
class AuthStorage {
  static const _key = 'google_user';

  /// Save a user map: { 'id', 'name', 'email', 'photoUrl', 'token' }
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user);
    await prefs.setString(_key, jsonString);
  }

  /// Read stored user or null
  static Future<Map<String, dynamic>?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return null;
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Remove stored user
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
