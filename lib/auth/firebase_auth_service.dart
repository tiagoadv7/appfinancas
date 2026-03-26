import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
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

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        // Envia apenas o hash SHA-256, nunca a senha em texto puro
        password: _hashPassword(password),
      );
      _user = await _buildUser(cred.user!);
      return _user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_translateError(e.code));
    } catch (e) {
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
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    // Firebase recomenda o fluxo de e-mail de redefinição de senha.
    // O método abaixo envia um e-mail ao usuário com o link de reset.
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_translateError(e.code));
    } catch (e) {
      throw Exception('Erro ao enviar e-mail de redefinição. Verifique sua conexão.');
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
        // Fluxo nativo: exibe o seletor de contas do dispositivo
        // Não passar clientId no mobile — vem do google-services.json / GoogleService-Info.plist
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
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
    } catch (e) {
      // Captura erros genéricos do web (ex: popup bloqueado, domínio não autorizado)
      // e exceções de JS interop que escapam do handler FirebaseAuthException
      if (e.toString().contains('popup-closed') ||
          e.toString().contains('popup_closed')) {
        return null; // usuário fechou o popup — comportamento normal
      }
      throw Exception('Erro ao entrar com Google. Verifique sua conexão e tente novamente.');
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
        return 'Usuário não encontrado. Verifique o e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca. Use ao menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        return 'Erro de autenticação ($code).';
    }
  }
}
