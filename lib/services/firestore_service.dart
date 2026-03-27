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
  // Getter lazy: acessa FirebaseFirestore.instance somente no primeiro uso,
  // não durante a construção da classe. Evita FirebaseException([core/no-app])
  // quando o app roda em modo mock (debug) e Firebase não foi inicializado.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

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

  /// Stream em tempo real no formato raw compatível com Transaction.fromMap do app.
  /// Normaliza os campos Timestamp → String e garante que todos os campos
  /// extras (isPaid, isRecurring, paidByMonth, etc.) sejam incluídos.
  Stream<List<Map<String, dynamic>>> transactionsAppStream(String uid) {
    return _txCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              // Normaliza date: pode ser Timestamp (legado) ou String
              if (data['date'] is Timestamp) {
                data['date'] = (data['date'] as Timestamp)
                    .toDate()
                    .toIso8601String()
                    .substring(0, 10);
              }
              // Normaliza paidByMonth
              if (data['paidByMonth'] is Map) {
                data['paidByMonth'] = Map<String, bool>.from(
                  (data['paidByMonth'] as Map).map(
                    (k, v) => MapEntry(k.toString(), v == true),
                  ),
                );
              } else {
                data['paidByMonth'] = <String, bool>{};
              }
              return data;
            }).toList());
  }

  /// Nomes das categorias padrão do app. Usados para normalizar `isDefault`
  /// em contas antigas que não tinham esse campo no Firestore.
  static const _defaultCategoryNames = {
    'Salário', 'Freelancer', 'Investimentos', 'Presente', 'Reembolso',
    'Alimentação', 'Assinaturas', 'Compras', 'Educação', 'Lazer',
    'Moradia', 'Odonto', 'Outros', 'Saúde', 'Transporte',
  };

  /// Stream em tempo real de categorias no formato raw compatível com Category.fromMap do app.
  Stream<List<Map<String, dynamic>>> categoriesAppStream(String uid) {
    return _catCol(uid)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              // Garante que iconName seja preenchido (Firestore usa 'icon')
              data['iconName'] = data['iconName'] ?? data['icon'] ?? 'Porquinho';
              // Normaliza isDefault: se ausente no Firestore, infere pelo nome
              data['isDefault'] = data['isDefault'] ??
                  _defaultCategoryNames.contains(data['name']);
              return data;
            }).toList());
  }

  /// Busca todas as transações uma única vez.
  Future<List<Transaction>> fetchTransactions(String uid) async {
    final snap = await _txCol(uid).orderBy('date', descending: true).get();
    return snap.docs.map(Transaction.fromDoc).toList();
  }

  /// Verifica se o usuário já possui transações salvas no Firestore.
  Future<bool> hasExistingTransactions(String uid) async {
    final snap = await _txCol(uid).limit(1).get();
    return snap.docs.isNotEmpty;
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

  /// Salva (cria ou atualiza) uma transação com ID fixo.
  /// Usa merge para preservar campos como `createdAt` em atualizações.
  Future<void> saveTransactionRaw(
    String uid,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _txCol(uid).doc(id).set(data, SetOptions(merge: true));
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

  /// Salva (cria ou atualiza) uma categoria com ID fixo.
  Future<void> saveCategoryRaw(
    String uid,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _catCol(uid).doc(id).set(data, SetOptions(merge: true));
  }

  // ─── Seed de categorias padrão ────────────────────────────────────────────

  /// Cria as categorias padrão para um novo usuário, somente se ainda não
  /// existirem categorias cadastradas.
  Future<void> seedDefaultCategories(String uid) async {
    final existing = await _catCol(uid).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final defaults = [
      // ── Saídas ──────────────────────────────────────────────────────
      _cat('Alimentação',  'Talheres',         0xFFEF5350, 'expense'),
      _cat('Transporte',   'Carro',            0xFF42A5F5, 'expense'),
      _cat('Moradia',      'Casa',             0xFF66BB6A, 'expense'),
      _cat('Saúde',        'Saude',            0xFFEC407A, 'expense'),
      _cat('Educação',     'Escola',           0xFFAB47BC, 'expense'),
      _cat('Lazer',        'Controle',         0xFFFF7043, 'expense'),
      _cat('Compras',      'CarrinhoCompras',  0xFF26C6DA, 'expense'),
      _cat('Assinaturas',  'CartaoCredito',    0xFF8D6E63, 'expense'),
      _cat('Odonto',       'Odonto',           0xFF29B6F6, 'expense'),
      _cat('Outros',       'Cifrão',           0xFF9E9E9E, 'expense'),
      // ── Entradas ────────────────────────────────────────────────────
      _cat('Salário',      'Maleta',           0xFF26A69A, 'income'),
      _cat('Freelancer',   'Computador',       0xFF7E57C2, 'income'),
      _cat('Investimentos','SetaCimaTendencia',0xFFFFCA28, 'income'),
      _cat('Presente',     'Presente',         0xFFFF8A65, 'income'),
      _cat('Reembolso',    'Recibo',           0xFF29B6F6, 'income'),
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

  // ─── Colaboradores ────────────────────────────────────────────────────────

  /// Adiciona um colaborador ao usuário dono (owner).
  /// Salva o email em `collaboratorEmails` (para query rápida) e em
  /// `collaborators` (para exibir nome/role na UI).
  Future<void> addCollaborator(
    String ownerUid,
    String email,
    String role,
  ) async {
    final ref = _db.collection('users').doc(ownerUid);
    await ref.update({
      'collaboratorEmails': FieldValue.arrayUnion([email]),
      'collaborators': FieldValue.arrayUnion([
        {'email': email, 'role': role},
      ]),
    });
  }

  /// Remove um colaborador do usuário dono.
  Future<void> removeCollaborator(
    String ownerUid,
    String email,
    String role,
  ) async {
    final ref = _db.collection('users').doc(ownerUid);
    await ref.update({
      'collaboratorEmails': FieldValue.arrayRemove([email]),
      'collaborators': FieldValue.arrayRemove([
        {'email': email, 'role': role},
      ]),
    });
  }

  /// Busca o UID e role do dono cujo `collaboratorEmails` contém [email].
  /// Retorna null se o usuário não for colaborador de ninguém.
  Future<Map<String, dynamic>?> findOwnerByCollaboratorEmail(
    String email,
  ) async {
    final snap = await _db
        .collection('users')
        .where('collaboratorEmails', arrayContains: email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final data = doc.data();

    // Determina a role do colaborador dentro da lista
    final collaborators =
        (data['collaborators'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    final entry = collaborators.firstWhere(
      (c) => c['email'] == email,
      orElse: () => {'email': email, 'role': 'viewer'},
    );

    return {
      'ownerUid': doc.id,
      'ownerName': data['name'] ?? 'Proprietário',
      'role': entry['role'] ?? 'viewer',
      'collaborators': collaborators,
    };
  }

  /// Retorna lista de colaboradores de um dono (como Map com email e role).
  Future<List<Map<String, dynamic>>> getCollaborators(String ownerUid) async {
    final snap = await _db.collection('users').doc(ownerUid).get();
    final data = snap.data();
    if (data == null) return [];
    return (data['collaborators'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }
}
