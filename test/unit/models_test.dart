import 'package:flutter_test/flutter_test.dart';
import 'package:appfinancas/main.dart';

void main() {
  // ── Transaction ────────────────────────────────────────────────────────────

  group('Transaction.fromMap', () {
    test('parse completo', () {
      final tx = Transaction.fromMap({
        'id': 'tx1',
        'description': 'Salário',
        'amount': 5000.0,
        'categoryId': 'cat-1',
        'date': '2024-11-01',
        'isPaid': true,
        'isRecurring': false,
        'recurringStartMonth': null,
        'recurringEndMonth': null,
        'paidByMonth': <String, dynamic>{},
      });

      expect(tx.id, 'tx1');
      expect(tx.description, 'Salário');
      expect(tx.amount, 5000.0);
      expect(tx.categoryId, 'cat-1');
      expect(tx.date, DateTime(2024, 11, 1));
      expect(tx.isPaid, isTrue);
      expect(tx.isRecurring, isFalse);
      expect(tx.paidByMonth, isEmpty);
    });

    test('amount inteiro é convertido para double', () {
      final tx = Transaction.fromMap({
        'id': 'tx2',
        'description': 'X',
        'amount': 1500, // int, não double
        'categoryId': 'cat-1',
        'date': '2024-01-15',
        'isPaid': false,
        'isRecurring': false,
        'paidByMonth': {},
      });
      expect(tx.amount, 1500.0);
    });

    test('campos nulos recebem valores padrão', () {
      final tx = Transaction.fromMap({
        'id': null,
        'description': null,
        'amount': null,
        'categoryId': null,
        'date': null,
        'isPaid': null,
        'isRecurring': null,
        'paidByMonth': null,
      });

      expect(tx.id, '');
      expect(tx.description, '');
      expect(tx.amount, 0.0);
      expect(tx.categoryId, '');
      expect(tx.isPaid, isFalse);
      expect(tx.isRecurring, isFalse);
      expect(tx.paidByMonth, isEmpty);
    });

    test('date inválida usa DateTime.now sem crash', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final tx = Transaction.fromMap({
        'id': 'x',
        'description': '',
        'amount': 0,
        'categoryId': '',
        'date': 'data-invalida',
        'isPaid': false,
        'isRecurring': false,
        'paidByMonth': {},
      });
      expect(tx.date.isAfter(before), isTrue);
    });

    test('paidByMonth é carregado corretamente', () {
      final tx = Transaction.fromMap({
        'id': 'r1',
        'description': 'Aluguel',
        'amount': 1200.0,
        'categoryId': 'cat-3',
        'date': '2024-03-01',
        'isPaid': false,
        'isRecurring': true,
        'recurringStartMonth': '2024-03',
        'recurringEndMonth': '2024-12',
        'paidByMonth': {'2024-03': true, '2024-04': false},
      });

      expect(tx.isRecurring, isTrue);
      expect(tx.paidByMonth['2024-03'], isTrue);
      expect(tx.paidByMonth['2024-04'], isFalse);
    });
  });

  group('Transaction.toMap / round-trip', () {
    test('toMap preserva todos os campos', () {
      final tx = Transaction.fromMap({
        'id': 'tx3',
        'description': 'Mercado',
        'amount': 350.75,
        'categoryId': 'cat-2',
        'date': '2024-10-10',
        'isPaid': true,
        'isRecurring': false,
        'paidByMonth': {'2024-10': true},
      });

      final map = tx.toMap();
      expect(map['id'], 'tx3');
      expect(map['description'], 'Mercado');
      expect(map['amount'], 350.75);
      expect(map['categoryId'], 'cat-2');
      expect(map['date'], '2024-10-10');
      expect(map['isPaid'], isTrue);
    });

    test('round-trip fromMap → toMap → fromMap mantém dados', () {
      final original = {
        'id': 'rt1',
        'description': 'Teste',
        'amount': 99.9,
        'categoryId': 'cat-5',
        'date': '2024-06-15',
        'isPaid': false,
        'isRecurring': true,
        'recurringStartMonth': '2024-06',
        'recurringEndMonth': '2024-12',
        'paidByMonth': {'2024-06': true},
      };

      final restored = Transaction.fromMap(Transaction.fromMap(original).toMap());
      expect(restored.id, original['id']);
      expect(restored.amount, original['amount']);
      expect(restored.date, DateTime(2024, 6, 15));
      expect(restored.recurringStartMonth, '2024-06');
    });
  });

  group('Transaction.copyWith', () {
    test('copyWith isPaid altera apenas isPaid', () {
      final tx = Transaction.fromMap({
        'id': 'cp1',
        'description': 'Original',
        'amount': 100.0,
        'categoryId': 'cat-1',
        'date': '2024-05-01',
        'isPaid': false,
        'isRecurring': false,
        'paidByMonth': {},
      });

      final updated = tx.copyWith(isPaid: true);
      expect(updated.isPaid, isTrue);
      expect(updated.description, 'Original');
      expect(updated.amount, 100.0);
    });

    test('copyWith paidByMonth substitui o mapa', () {
      final tx = Transaction.fromMap({
        'id': 'cp2',
        'description': 'Recorrente',
        'amount': 500.0,
        'categoryId': 'cat-1',
        'date': '2024-01-01',
        'isPaid': false,
        'isRecurring': true,
        'paidByMonth': {},
      });

      final updated = tx.copyWith(paidByMonth: {'2024-01': true});
      expect(updated.paidByMonth['2024-01'], isTrue);
    });
  });

  // ── Category ───────────────────────────────────────────────────────────────

  group('Category.fromMap', () {
    test('parse completo', () {
      final cat = Category.fromMap({
        'id': 'cat-1',
        'name': 'Salário',
        'type': 'income',
        'iconName': 'Maleta',
      });

      expect(cat.id, 'cat-1');
      expect(cat.name, 'Salário');
      expect(cat.type, 'income');
      expect(cat.iconName, 'Maleta');
    });

    test('iconName usa fallback para campo icon', () {
      final cat = Category.fromMap({
        'id': 'c2',
        'name': 'Alimentação',
        'type': 'expense',
        'icon': 'faUtensils', // campo legado do Firebase
      });

      expect(cat.iconName, 'faUtensils');
    });

    test('iconName usa fallback Porquinho quando ambos ausentes', () {
      final cat = Category.fromMap({
        'id': 'c3',
        'name': 'Outros',
        'type': 'expense',
      });

      expect(cat.iconName, 'Porquinho');
    });

    test('campos nulos recebem valores padrão sem crash', () {
      final cat = Category.fromMap({
        'id': null,
        'name': null,
        'type': null,
      });

      expect(cat.id, '');
      expect(cat.name, 'Sem nome');
      expect(cat.type, 'expense');
      expect(cat.iconName, 'Porquinho');
    });
  });

  group('Category.toMap / round-trip', () {
    test('toMap contém todos os campos', () {
      final cat = Category.fromMap({
        'id': 'cat-5',
        'name': 'Educação',
        'type': 'expense',
        'iconName': 'Escola',
      });

      final map = cat.toMap();
      expect(map['id'], 'cat-5');
      expect(map['name'], 'Educação');
      expect(map['type'], 'expense');
      expect(map['iconName'], 'Escola');
    });

    test('round-trip preserva dados', () {
      final original = {
        'id': 'cat-x',
        'name': 'Investimentos',
        'type': 'income',
        'iconName': 'Porquinho',
      };

      final restored = Category.fromMap(Category.fromMap(original).toMap());
      expect(restored.id, 'cat-x');
      expect(restored.name, 'Investimentos');
      expect(restored.type, 'income');
    });
  });
}
