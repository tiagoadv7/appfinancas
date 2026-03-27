import '../models/user.dart';

abstract class AuthService {
  /// Faz login com email/senha. Retorna o [User] autenticado ou null.
  Future<User?> signIn({String? email, String? password});

  /// Faz login via Google (OAuth). Retorna o [User] autenticado ou null.
  Future<User?> signInWithGoogle();

  /// Restaura sessão pelo email sem exigir senha (usado após autenticação biométrica).
  Future<User?> signInWithBiometric(String email);

  /// Cria uma conta com nome, email e senha. Retorna o [User] criado ou null.
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Envia e-mail de redefinição de senha (fluxo "Esqueci a senha").
  /// O usuário clica no link recebido por e-mail para redefinir a senha.
  Future<bool> resetPassword({required String email});

  /// Troca a senha do usuário autenticado.
  /// Reautentica com [currentPassword] antes de aplicar [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Faz logout do usuário atual.
  Future<void> signOut();

  /// Retorna o usuário atualmente autenticado, se houver.
  User? get currentUser;
}
