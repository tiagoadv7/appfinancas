import 'dart:async';
import '../models/user.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  User? _user;

  @override
  User? get currentUser => _user;

  @override
  Future<User?> signIn({String? email, String? password}) async {
    // Simula autenticação rápida
    await Future.delayed(const Duration(milliseconds: 300));

    // Usar email preenchido ou padrão
    final userEmail = email?.isNotEmpty == true
        ? email
        : 'tiago@appfinancas.com';
    final userName = userEmail?.split('@').first ?? 'Usuário';

    _user = User(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: userEmail!,
      name: userName[0].toUpperCase() + userName.substring(1),
      photoUrl: null,
      role: 'owner',
      salary: 0.0,
    );
    return _user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _user = null;
  }
}
