import 'dart:async';
import '../models/user.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  User? _user;

  @override
  User? get currentUser => _user;

  @override
  Future<User?> signIn() async {
    // Simula autenticação rápida
    await Future.delayed(const Duration(milliseconds: 300));
    _user = User(
      id: 'mock-user-001',
      email: 'tiago@appfinancas.com',
      name: 'Tiago Neves',
      photoUrl: null,
      role: 'owner',
    );
    return _user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _user = null;
  }
}
