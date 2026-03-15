import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa uma transação financeira (entrada ou saída).
class Transaction {
  final String id;
  final String description;
  final double amount;
  final String type; // 'income' | 'expense'
  final String categoryId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  factory Transaction.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      description: d['description'] ?? '',
      amount: (d['amount'] as num).toDouble(),
      type: d['type'] ?? 'expense',
      categoryId: d['categoryId'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      note: d['note'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'description': description,
    'amount': amount,
    'type': type,
    'categoryId': categoryId,
    'date': Timestamp.fromDate(date),
    'note': note,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// Representa uma categoria (padrão ou personalizada).
class Category {
  final String id;
  final String name;
  final String icon; // nome do ícone FontAwesome, ex: 'faUtensils'
  final int color; // ARGB int, ex: 0xFF2196F3
  final String type; // 'income' | 'expense' | 'both'
  final bool isDefault;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.isDefault,
    required this.createdAt,
  });

  factory Category.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: d['name'] ?? '',
      icon: d['icon'] ?? 'faTag',
      color: (d['color'] as num?)?.toInt() ?? 0xFF9E9E9E,
      type: d['type'] ?? 'both',
      isDefault: d['isDefault'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'icon': icon,
    'color': color,
    'type': type,
    'isDefault': isDefault,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// Serviço de acesso ao Cloud Firestore.
///
/// Estrutura do banco:
/// ```
/// users/{uid}
///   ├── name, email, photoUrl, role, salary, createdAt
///   ├── transactions/{txId}
///   │     description, amount, type, categoryId, date, note, createdAt
///   └── categories/{catId}
///         name, icon, color, type, isDefault, createdAt
/// ```
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Referências ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> _catCol(String uid) =>
      _db.collection('users').doc(uid).collection('categories');

  // ─── Transações ───────────────────────────────────────────────────────────

  /// Stream em tempo real de todas as transações, ordenadas pela data desc.
  Stream<List<Transaction>> transactionsStream(String uid) {
    return _txCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Transaction.fromDoc).toList());
  }

  /// Busca todas as transações uma única vez.
  Future<List<Transaction>> fetchTransactions(String uid) async {
    final snap = await _txCol(uid).orderBy('date', descending: true).get();
    return snap.docs.map(Transaction.fromDoc).toList();
  }

  /// Adiciona uma nova transação.
  Future<String> addTransaction(String uid, Transaction tx) async {
    final ref = await _txCol(uid).add(tx.toMap());
    return ref.id;
  }

  /// Atualiza uma transação existente.
  Future<void> updateTransaction(String uid, Transaction tx) async {
    final map = tx.toMap();
    map.remove('createdAt'); // não sobrescreve a data de criação
    await _txCol(uid).doc(tx.id).update(map);
  }

  /// Remove uma transação.
  Future<void> deleteTransaction(String uid, String txId) async {
    await _txCol(uid).doc(txId).delete();
  }

  // ─── Categorias ───────────────────────────────────────────────────────────

  /// Stream em tempo real de todas as categorias do usuário.
  Stream<List<Category>> categoriesStream(String uid) {
    return _catCol(uid)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(Category.fromDoc).toList());
  }

  /// Busca todas as categorias uma única vez.
  Future<List<Category>> fetchCategories(String uid) async {
    final snap = await _catCol(uid).orderBy('name').get();
    return snap.docs.map(Category.fromDoc).toList();
  }

  /// Cria uma nova categoria personalizada.
  Future<String> addCategory(String uid, Category cat) async {
    final ref = await _catCol(uid).add(cat.toMap());
    return ref.id;
  }

  /// Atualiza uma categoria existente.
  Future<void> updateCategory(String uid, Category cat) async {
    final map = cat.toMap();
    map.remove('createdAt');
    await _catCol(uid).doc(cat.id).update(map);
  }

  /// Remove uma categoria. Use com cuidado: transações que referenciam
  /// esta categoria terão categoryId inválido.
  Future<void> deleteCategory(String uid, String catId) async {
    await _catCol(uid).doc(catId).delete();
  }

  // ─── Seed de categorias padrão ────────────────────────────────────────────

  /// Cria as categorias padrão para um novo usuário, somente se ainda não
  /// existirem categorias cadastradas.
  Future<void> seedDefaultCategories(String uid) async {
    final existing = await _catCol(uid).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final defaults = [
      // ── Saídas ──────────────────────────────────────────────────────
      _cat('Alimentação',  'faUtensils',       0xFFEF5350, 'expense'),
      _cat('Transporte',   'faCar',            0xFF42A5F5, 'expense'),
      _cat('Moradia',      'faHouse',          0xFF66BB6A, 'expense'),
      _cat('Saúde',        'faHeart',          0xFFEC407A, 'expense'),
      _cat('Educação',     'faGraduationCap',  0xFFAB47BC, 'expense'),
      _cat('Lazer',        'faGamepad',        0xFFFF7043, 'expense'),
      _cat('Compras',      'faShoppingCart',   0xFF26C6DA, 'expense'),
      _cat('Assinaturas',  'faRepeat',         0xFF8D6E63, 'expense'),
      _cat('Outros',       'faEllipsis',       0xFF9E9E9E, 'expense'),
      // ── Entradas ────────────────────────────────────────────────────
      _cat('Salário',      'faBriefcase',      0xFF26A69A, 'income'),
      _cat('Freelance',    'faLaptop',         0xFF7E57C2, 'income'),
      _cat('Investimentos','faChartLine',      0xFFFFCA28, 'income'),
      _cat('Presente',     'faGift',           0xFFFF8A65, 'income'),
      _cat('Reembolso',    'faArrowRotateLeft',0xFF29B6F6, 'income'),
    ];

    final batch = _db.batch();
    for (final map in defaults) {
      batch.set(_catCol(uid).doc(), map);
    }
    await batch.commit();
  }

  Map<String, dynamic> _cat(
    String name,
    String icon,
    int color,
    String type,
  ) => {
    'name': name,
    'icon': icon,
    'color': color,
    'type': type,
    'isDefault': true,
    'createdAt': FieldValue.serverTimestamp(),
  };

  // ─── Perfil do usuário ────────────────────────────────────────────────────

  /// Atualiza o salário do usuário.
  Future<void> updateSalary(String uid, double salary) async {
    await _db.collection('users').doc(uid).update({'salary': salary});
  }

  /// Stream do perfil completo do usuário.
  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((s) => s.data());
  }
}
