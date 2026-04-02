import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appfinancas/local_storage/transaction_storage.dart';
import 'package:appfinancas/local_storage/auth_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── TransactionStorage ─────────────────────────────────────────────────────

  group('TransactionStorage', () {
    test('readTransactions retorna lista vazia inicialmente', () async {
      final list = await TransactionStorage.readTransactions();
      expect(list, isEmpty);
    });

    test('saveTransactions e readTransactions fazem round-trip', () async {
      final data = [
        {'id': 'tx1', 'description': 'Salário', 'amount': 5000.0, 'categoryId': 'cat-1', 'date': '2024-11-01'},
        {'id': 'tx2', 'description': 'Aluguel', 'amount': 1500.0, 'categoryId': 'cat-3', 'date': '2024-11-05'},
      ];

      await TransactionStorage.saveTransactions(data);
      final result = await TransactionStorage.readTransactions();

      expect(result.length, 2);
      expect(result[0]['id'], 'tx1');
      expect(result[1]['description'], 'Aluguel');
    });

    test('addTransaction insere no início da lista', () async {
      await TransactionStorage.saveTransactions([
        {'id': 'tx1', 'description': 'Primeiro', 'amount': 100.0, 'categoryId': 'c1', 'date': '2024-01-01'},
      ]);

      await TransactionStorage.addTransaction(
        {'id': 'tx2', 'description': 'Novo', 'amount': 200.0, 'categoryId': 'c1', 'date': '2024-01-02'},
      );

      final list = await TransactionStorage.readTransactions();
      expect(list.length, 2);
      expect(list.first['id'], 'tx2'); // novo fica no início
    });

    test('removeById remove apenas o item correto', () async {
      await TransactionStorage.saveTransactions([
        {'id': 'tx1', 'description': 'A', 'amount': 10.0, 'categoryId': 'c1', 'date': '2024-01-01'},
        {'id': 'tx2', 'description': 'B', 'amount': 20.0, 'categoryId': 'c1', 'date': '2024-01-02'},
        {'id': 'tx3', 'description': 'C', 'amount': 30.0, 'categoryId': 'c1', 'date': '2024-01-03'},
      ]);

      await TransactionStorage.removeById('tx2');
      final list = await TransactionStorage.readTransactions();

      expect(list.length, 2);
      expect(list.any((m) => m['id'] == 'tx2'), isFalse);
      expect(list.any((m) => m['id'] == 'tx1'), isTrue);
      expect(list.any((m) => m['id'] == 'tx3'), isTrue);
    });

    test('removeById com id inexistente não afeta a lista', () async {
      await TransactionStorage.saveTransactions([
        {'id': 'tx1', 'description': 'A', 'amount': 10.0, 'categoryId': 'c1', 'date': '2024-01-01'},
      ]);

      await TransactionStorage.removeById('inexistente');
      final list = await TransactionStorage.readTransactions();

      expect(list.length, 1);
    });

    test('clear remove todos os itens', () async {
      await TransactionStorage.saveTransactions([
        {'id': 'tx1', 'description': 'A', 'amount': 10.0, 'categoryId': 'c1', 'date': '2024-01-01'},
      ]);

      await TransactionStorage.clear();
      final list = await TransactionStorage.readTransactions();

      expect(list, isEmpty);
    });

    test('addTransaction em lista vazia cria lista com 1 item', () async {
      await TransactionStorage.addTransaction(
        {'id': 'tx1', 'description': 'Único', 'amount': 50.0, 'categoryId': 'c1', 'date': '2024-01-01'},
      );

      final list = await TransactionStorage.readTransactions();
      expect(list.length, 1);
      expect(list.first['id'], 'tx1');
    });

    test('saveTransactions substitui dados anteriores', () async {
      await TransactionStorage.saveTransactions([
        {'id': 'old', 'description': 'Antigo', 'amount': 1.0, 'categoryId': 'c1', 'date': '2024-01-01'},
      ]);

      await TransactionStorage.saveTransactions([
        {'id': 'new1', 'description': 'Novo 1', 'amount': 2.0, 'categoryId': 'c1', 'date': '2024-01-02'},
        {'id': 'new2', 'description': 'Novo 2', 'amount': 3.0, 'categoryId': 'c1', 'date': '2024-01-03'},
      ]);

      final list = await TransactionStorage.readTransactions();
      expect(list.length, 2);
      expect(list.any((m) => m['id'] == 'old'), isFalse);
    });
  });

  // ── AuthStorage ────────────────────────────────────────────────────────────

  group('AuthStorage', () {
    test('readUser retorna null inicialmente', () async {
      final user = await AuthStorage.readUser();
      expect(user, isNull);
    });

    test('saveUser e readUser fazem round-trip', () async {
      final userData = {
        'id': 'u123',
        'name': 'Tiago',
        'email': 'tiago@example.com',
        'photoUrl': null,
        'token': 'abc123',
      };

      await AuthStorage.saveUser(userData);
      final result = await AuthStorage.readUser();

      expect(result, isNotNull);
      expect(result!['id'], 'u123');
      expect(result['name'], 'Tiago');
      expect(result['email'], 'tiago@example.com');
    });

    test('saveUser sobrescreve usuário anterior', () async {
      await AuthStorage.saveUser({'id': 'u1', 'name': 'Primeiro', 'email': 'a@b.com'});
      await AuthStorage.saveUser({'id': 'u2', 'name': 'Segundo', 'email': 'c@d.com'});

      final result = await AuthStorage.readUser();
      expect(result!['id'], 'u2');
      expect(result['name'], 'Segundo');
    });

    test('clear remove o usuário salvo', () async {
      await AuthStorage.saveUser({'id': 'u1', 'name': 'Test', 'email': 'x@y.com'});
      await AuthStorage.clear();

      final result = await AuthStorage.readUser();
      expect(result, isNull);
    });

    test('readUser retorna null após dados corrompidos', () async {
      // Simula JSON inválido no SharedPreferences
      SharedPreferences.setMockInitialValues({'google_user': 'NAO_EH_JSON'});

      final result = await AuthStorage.readUser();
      expect(result, isNull);
    });
  });
}
