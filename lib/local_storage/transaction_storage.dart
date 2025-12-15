import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Simple temporary storage for test transactions using SharedPreferences.
/// Stores a JSON-encoded list under key `test_transactions`.
class TransactionStorage {
  static const _key = 'test_transactions';

  /// Save list of transaction maps. Each map should contain
  /// { 'id', 'description', 'amount', 'categoryId', 'date' }
  static Future<void> saveTransactions(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list);
    await prefs.setString(_key, jsonString);
  }

  /// Read stored transactions. Returns empty list if none.
  static Future<List<Map<String, dynamic>>> readTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    try {
      final data = jsonDecode(jsonString) as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Append a transaction map to storage
  static Future<void> addTransaction(Map<String, dynamic> txn) async {
    final list = await readTransactions();
    list.insert(0, txn);
    await saveTransactions(list);
  }

  /// Remove by id
  static Future<void> removeById(String id) async {
    final list = await readTransactions();
    list.removeWhere((m) => m['id'] == id);
    await saveTransactions(list);
  }

  /// Clear all
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
