import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'auth_config.dart';
import 'auth_service.dart';

/// Chave usada para persistir o mapa de usuários cadastrados.
const _kUsersKey = 'auth_users';

class MockAuthService implements AuthService {
  User? _user;

  @override
  User? get currentUser => _user;

  // ---------- helpers ----------

  Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsersKey, jsonEncode(users));
  }

  /// Garante que o usuário de teste DEV existe no mapa de usuários.
  Future<void> _ensureDevUser(Map<String, dynamic> users) async {
    final key = devTestEmail.toLowerCase();
    if (!users.containsKey(key)) {
      users[key] = {
        'id': 'dev-user',
        'name': 'Dev Tester',
        'password': devTestPassword,
      };
      await _saveUsers(users);
    }
  }

  // ---------- AuthService ----------

  @override
  Future<User?> signIn({String? email, String? password}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final users = await _loadUsers();
    await _ensureDevUser(users);

    // Atalho para biometria / login sem senha (ex: biometria)
    if (email != null && (password == null || password.isEmpty)) {
      final key = email.toLowerCase();
      if (users.containsKey(key)) {
        final data = Map<String, dynamic>.from(users[key]);
        _user = User(
          id: data['id'],
          email: email,
          name: data['name'],
          photoUrl: null,
          role: 'owner',
          salary: 0.0,
        );
        return _user;
      }
      // Fallback legacy
      final userName = email.split('@').first;
      _user = User(
        id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: userName[0].toUpperCase() + userName.substring(1),
        photoUrl: null,
        role: 'owner',
        salary: 0.0,
      );
      return _user;
    }

    if (email == null || email.isEmpty) {
      throw Exception('E-mail não informado');
    }
    if (password == null || password.isEmpty) {
      throw Exception('Senha não informada');
    }

    final key = email.toLowerCase();

    if (!users.containsKey(key)) {
      throw Exception('Usuário não encontrado. Verifique o e-mail.');
    }

    final data = Map<String, dynamic>.from(users[key]);
    if (data['password'] != password) {
      throw Exception('Senha incorreta.');
    }

    _user = User(
      id: data['id'],
      email: email,
      name: data['name'],
      photoUrl: null,
      role: 'owner',
      salary: 0.0,
    );
    return _user;
  }

  @override
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final users = await _loadUsers();
    await _ensureDevUser(users);
    final key = email.toLowerCase();

    if (users.containsKey(key)) {
      throw Exception('Este e-mail já está cadastrado.');
    }

    final id = 'user-${DateTime.now().millisecondsSinceEpoch}';
    users[key] = {'id': id, 'name': name, 'password': password};
    await _saveUsers(users);

    _user = User(
      id: id,
      email: email,
      name: name,
      photoUrl: null,
      role: 'owner',
      salary: 0.0,
    );
    return _user;
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final users = await _loadUsers();
    await _ensureDevUser(users);
    final key = email.toLowerCase();

    if (!users.containsKey(key)) return false;

    final data = Map<String, dynamic>.from(users[key]);
    data['password'] = newPassword;
    users[key] = data;
    await _saveUsers(users);
    return true;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _user = null;
  }
}
