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
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _user = null;
  }
}
