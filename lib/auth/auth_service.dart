import '../models/user.dart';

abstract class AuthService {
  /// Faz login com email/senha. Retorna o [User] autenticado ou null.
  Future<User?> signIn({String? email, String? password});

  /// Cria uma conta com nome, email e senha. Retorna o [User] criado ou null.
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Redefine a senha do usuário com o email informado.
  /// Retorna true se encontrou o usuário e atualizou a senha.
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  });

  /// Faz logout do usuário atual.
  Future<void> signOut();

  /// Retorna o usuário atualmente autenticado, se houver.
  User? get currentUser;
}
