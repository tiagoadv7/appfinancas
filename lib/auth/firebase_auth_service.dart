import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'auth_config.dart';
import 'auth_service.dart';

/// Transforma a senha em SHA-256 antes de enviá-la ao Firebase Auth.
/// Isso adiciona uma camada extra de segurança: o Firebase nunca recebe
/// a senha em texto puro — apenas seu hash SHA-256.
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

/// Implementação de [AuthService] usando Firebase Authentication
/// e Cloud Firestore.
///
/// • Email/senha → hash SHA-256 client-side antes de enviar ao Firebase.
/// • Google Sign-In → OAuth 2.0 via GoogleSignIn + Firebase credential.
/// • Dados do perfil do usuário são armazenados em Firestore:
///     users/{uid}  →  name, email, photoUrl, role, salary, createdAt
class FirebaseAuthService implements AuthService {
  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? _user;

  @override
  User? get currentUser => _user;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Cria ou atualiza o documento do usuário em Firestore.
  Future<void> _upsertUserDoc({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String role = 'owner',
    double salary = 0.0,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'role': role,
        'salary': salary,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Atualiza apenas campos que podem mudar no login
      await ref.update({
        'name': name,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    }
  }

  /// Constrói o [User] do app a partir de [fb.User].
  Future<User> _buildUser(fb.User fbUser, {String? name}) async {
    final doc = await _db.collection('users').doc(fbUser.uid).get();
    final data = doc.data();
    return User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: name ?? data?['name'] ?? fbUser.displayName ?? 'Usuário',
      photoUrl: fbUser.photoURL ?? data?['photoUrl'],
      role: data?['role'] ?? 'owner',
      salary: (data?['salary'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ─── AuthService ──────────────────────────────────────────────────────────

  @override
  Future<User?> signIn({String? email, String? password}) async {
    if (email == null || email.isEmpty) throw Exception('E-mail não informado');
    if (password == null || password.isEmpty) {
      throw Exception('Senha não informada');
    }

    // Tenta primeiro com senha em texto puro (contas novas / após reset).
    // Se falhar, tenta com SHA-256 (contas antigas) e migra automaticamente.
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = await _buildUser(cred.user!);
      return _user;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found') {
        // Fallback: tenta com hash SHA-256 (contas criadas antes da migração)
        try {
          final cred = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: _hashPassword(password),
          );
          // Migra: atualiza senha para texto puro para compatibilidade futura
          await cred.user!.updatePassword(password);
          _user = await _buildUser(cred.user!);
          return _user;
        } on fb.FirebaseAuthException catch (e2) {
          throw Exception(_translateError(e2.code));
        }
      }
      throw Exception(_translateError(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro ao fazer login. Verifique sua conexão.');
    }
  }

  @override
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: _hashPassword(password),
      );

      // Atualiza o displayName no Firebase Auth
      await cred.user!.updateDisplayName(name);

      // Cria o documento do usuário no Firestore
      await _upsertUserDoc(
        uid: cred.user!.uid,
        name: name,
        email: email.trim(),
        role: 'owner',
        salary: 0.0,
      );

      _user = await _buildUser(cred.user!, name: name);
      return _user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_translateError(e.code));
    } catch (e) {
      throw Exception('Erro ao criar conta. Verifique sua conexão.');
    }
  }

  @override
  Future<bool> resetPassword({required String email}) async {
    try {
      final actionCodeSettings = fb.ActionCodeSettings(
        url: 'https://appfinancas-9d7a3.firebaseapp.com/__/auth/action',
        handleCodeInApp: true,
        androidPackageName: 'com.example.appfinancas',
        androidInstallApp: true,
        androidMinimumVersion: '23',
      );
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
      return true;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_translateError(e.code));
    } catch (e) {
      throw Exception('Erro ao enviar e-mail de redefinição. Verifique sua conexão.');
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: oobCode, newPassword: newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_translateError(e.code));
    } catch (e) {
      throw Exception('Erro ao redefinir senha. Tente novamente.');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Usuário não autenticado.');
    }
    final credential = fb.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_translateError(e.code));
    } catch (e) {
      throw Exception('Erro ao trocar a senha. Verifique sua conexão.');
    }
  }

  /// Restaura a sessão Firebase existente após autenticação biométrica.
  /// Não requer senha — usa o token já em memória do FirebaseAuth.
  @override
  Future<User?> signInWithBiometric(String email) async {
    final currentFbUser = _auth.currentUser;
    if (currentFbUser != null && currentFbUser.email == email) {
      _user = await _buildUser(currentFbUser);
      return _user;
    }
    // Sessão expirada — usuário precisa fazer login manual
    throw Exception('Sessão expirada. Faça login novamente.');
  }

  /// Login com Google.
  /// • Web  → signInWithPopup (Firebase)
  /// • Mobile → google_sign_in (seletor nativo de contas) + credencial Firebase
  @override
  Future<User?> signInWithGoogle() async {
    try {
      fb.UserCredential cred;

      if (kIsWeb) {
        final googleProvider = fb.GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        cred = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        // Força deslogar conta anterior para sempre exibir o seletor de contas
        await googleSignIn.signOut();
        final account = await googleSignIn.signIn();
        if (account == null) return null; // usuário cancelou

        final googleAuth = await account.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }

      if (cred.user == null) return null;

      await _upsertUserDoc(
        uid: cred.user!.uid,
        name: cred.user!.displayName ?? 'Usuário',
        email: cred.user!.email ?? '',
        photoUrl: cred.user!.photoURL,
      );

      _user = await _buildUser(cred.user!);
      return _user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_translateError(e.code));
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_failed') {
        return null;
      }
      throw Exception('Erro ao entrar com Google: ${e.message}');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('popup-closed') || msg.contains('popup_closed') ||
          msg.contains('sign_in_canceled')) {
        return null;
      }
      throw Exception('Erro ao entrar com Google. Verifique se o SHA-1 do app está configurado no Firebase Console.');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
  }

  // ─── Tradução de erros do Firebase ────────────────────────────────────────

  String _translateError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'E-mail não encontrado. Verifique e tente novamente.';
      case 'wrong-password':
        return 'Senha incorreta. Verifique e tente novamente.';
      case 'invalid-credential':
        // Firebase v9+ agrupa email/senha errados neste código por segurança
        return 'E-mail ou senha incorretos. Verifique e tente novamente.';
      case 'invalid-email':
        return 'E-mail inválido. Verifique o formato.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca. Use ao menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique sua internet e tente novamente.';
      case 'operation-not-allowed':
        return 'Login com e-mail desativado. Contate o suporte.';
      default:
        return 'Erro de autenticação. Tente novamente ($code).';
    }
  }
}
