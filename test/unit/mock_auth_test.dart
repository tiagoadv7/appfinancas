import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appfinancas/auth/mock_auth_service.dart';

void main() {
  late MockAuthService auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = MockAuthService();
  });

  // ── signUp ─────────────────────────────────────────────────────────────────

  group('signUp', () {
    test('cria usuário e retorna User com dados corretos', () async {
      final user = await auth.signUp(
        name: 'Maria Silva',
        email: 'maria@example.com',
        password: 'senha123',
      );

      expect(user, isNotNull);
      expect(user!.name, 'Maria Silva');
      expect(user.email, 'maria@example.com');
      expect(user.role, 'owner');
    });

    test('lança exceção ao cadastrar email já existente', () async {
      await auth.signUp(
        name: 'Joao',
        email: 'joao@example.com',
        password: '123',
      );

      expect(
        () => auth.signUp(name: 'Joao2', email: 'joao@example.com', password: '456'),
        throwsA(isA<Exception>()),
      );
    });

    test('atualiza currentUser após signUp', () async {
      expect(auth.currentUser, isNull);

      await auth.signUp(name: 'Ana', email: 'ana@test.com', password: 'abc');

      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, 'ana@test.com');
    });
  });

  // ── signIn ─────────────────────────────────────────────────────────────────

  group('signIn', () {
    setUp(() async {
      await auth.signUp(name: 'Pedro', email: 'pedro@test.com', password: 'pass1');
      await auth.signOut();
    });

    test('login com credenciais corretas retorna User', () async {
      final user = await auth.signIn(email: 'pedro@test.com', password: 'pass1');

      expect(user, isNotNull);
      expect(user!.email, 'pedro@test.com');
    });

    test('login com senha errada lança exceção', () async {
      expect(
        () => auth.signIn(email: 'pedro@test.com', password: 'errada'),
        throwsA(isA<Exception>()),
      );
    });

    test('login com email inexistente lança exceção', () async {
      expect(
        () => auth.signIn(email: 'naoexiste@test.com', password: '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('login sem email lança exceção', () async {
      expect(
        () => auth.signIn(email: '', password: 'pass1'),
        throwsA(isA<Exception>()),
      );
    });

    test('login com senha vazia funciona como atalho biométrico', () async {
      // MockAuthService trata password=='' como login biométrico (sem senha)
      final user = await auth.signIn(email: 'pedro@test.com', password: '');
      expect(user, isNotNull);
    });

    test('login case-insensitive para email', () async {
      final user = await auth.signIn(email: 'PEDRO@TEST.COM', password: 'pass1');
      expect(user, isNotNull);
    });
  });

  // ── signOut ────────────────────────────────────────────────────────────────

  group('signOut', () {
    test('limpa currentUser', () async {
      await auth.signUp(name: 'Lu', email: 'lu@test.com', password: '123');
      expect(auth.currentUser, isNotNull);

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });

  // ── signInWithGoogle ───────────────────────────────────────────────────────

  group('signInWithGoogle', () {
    test('retorna usuário mock de Google', () async {
      final user = await auth.signInWithGoogle();

      expect(user, isNotNull);
      expect(user!.role, 'owner');
      expect(user.email, contains('@'));
    });
  });

  // ── signInWithBiometric ────────────────────────────────────────────────────

  group('signInWithBiometric', () {
    test('login biométrico funciona para usuário cadastrado', () async {
      await auth.signUp(name: 'Bio User', email: 'bio@test.com', password: 'pw');
      await auth.signOut();

      final user = await auth.signInWithBiometric('bio@test.com');
      expect(user, isNotNull);
      expect(user!.email, 'bio@test.com');
    });
  });

  // ── resetPassword ──────────────────────────────────────────────────────────

  group('resetPassword', () {
    test('redefine senha e permite novo login', () async {
      await auth.signUp(name: 'Camila', email: 'camila@test.com', password: 'antiga');
      await auth.signOut();

      final ok = await auth.resetPassword(email: 'camila@test.com', newPassword: 'nova123');
      expect(ok, isTrue);

      final user = await auth.signIn(email: 'camila@test.com', password: 'nova123');
      expect(user, isNotNull);
    });

    test('retorna false para email não cadastrado', () async {
      final ok = await auth.resetPassword(email: 'ghost@test.com', newPassword: 'x');
      expect(ok, isFalse);
    });

    test('senha antiga não funciona após reset', () async {
      await auth.signUp(name: 'Rafael', email: 'rafael@test.com', password: 'velha');
      await auth.signOut();
      await auth.resetPassword(email: 'rafael@test.com', newPassword: 'nova');

      expect(
        () => auth.signIn(email: 'rafael@test.com', password: 'velha'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── usuário de dev padrão ──────────────────────────────────────────────────

  group('usuário dev padrão', () {
    test('login com credenciais dev funciona sem cadastro prévio', () async {
      // O MockAuthService garante que dev@appfinancas.com/dev123 sempre existe
      final user = await auth.signIn(
        email: 'dev@appfinancas.com',
        password: 'dev123',
      );

      expect(user, isNotNull);
    });
  });
}
