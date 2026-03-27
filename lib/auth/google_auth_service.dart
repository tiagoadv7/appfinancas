import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'auth_config.dart';
import 'auth_service.dart';

class GoogleAuthService implements AuthService {
  // Para a web, é necessário fornecer o clientId.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? googleSignInWebAppClientId : null,
    scopes: ['email', 'profile'],
  );
  User? _user;

  @override
  User? get currentUser => _user;

  @override
  Future<User?> signInWithBiometric(String email) async {
    // GoogleAuthService não gerencia sessões locais — delega para FirebaseAuthService
    throw UnimplementedError('Use FirebaseAuthService para login biométrico');
  }

  @override
  Future<User?> signIn({String? email, String? password}) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      _user = User(
        id: account.id,
        email: account.email,
        name: account.displayName ?? 'Usuário',
        photoUrl: account.photoUrl,
        role: 'collaborator',
      );
      return _user;
    } catch (e) {
      // Propaga a exceção para o chamador lidar
      rethrow;
    }
  }

  @override
  Future<User?> signInWithGoogle() => signIn();

  @override
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // Google Sign-In não suporta criação via email/senha — delega ao mock
    throw UnimplementedError('Use MockAuthService para cadastro com email/senha');
  }

  @override
  Future<bool> resetPassword({required String email}) async {
    throw UnimplementedError('Use MockAuthService para redefinição de senha');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw UnimplementedError('Use FirebaseAuthService para troca de senha');
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _user = null;
  }
}
