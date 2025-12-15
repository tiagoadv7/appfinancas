import 'package:flutter/material.dart';
import 'dart:math';

import 'package:intl/intl.dart';
import 'transaction_storage.dart';
import 'auth_storage.dart';

class TestStorageScreen extends StatefulWidget {
  const TestStorageScreen({super.key});

  @override
  State<TestStorageScreen> createState() => _TestStorageScreenState();
}

class _TestStorageScreenState extends State<TestStorageScreen> {
  List<Map<String, dynamic>> _txns = [];
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final txns = await TransactionStorage.readTransactions();
    final user = await AuthStorage.readUser();
    setState(() {
      _txns = txns;
      _user = user;
    });
  }

  Future<void> _addSampleTxn() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random();
    final amount = (random.nextDouble() * 500).roundToDouble();
    final now = DateTime.now();
    final map = {
      'id': id,
      'description': 'Teste $id',
      'amount': amount,
      'categoryId': 'cat_${random.nextInt(5)}',
      'date': DateFormat('yyyy-MM-dd').format(now),
    };
    await TransactionStorage.addTransaction(map);
    await _loadAll();
  }

  Future<void> _saveMockUser() async {
    final user = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Usuário Teste',
      'email': 'teste@example.com',
      'photoUrl': null,
      'token': 'mock-token-123',
    };
    await AuthStorage.saveUser(user);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Storage')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addSampleTxn,
                    child: const Text('Adicionar transação de teste'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await TransactionStorage.clear();
                    await _loadAll();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveMockUser,
              child: const Text('Salvar mock user Google'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuário salvo:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_user == null) const Text('- nenhum usuário salvo'),
                    if (_user != null) ...[
                      Text('ID: ${_user!['id']}'),
                      Text('Nome: ${_user!['name']}'),
                      Text('Email: ${_user!['email']}'),
                      const SizedBox(height: 12),
                    ],
                    const Divider(),
                    Text(
                      'Transações armazenadas:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (var t in _txns)
                      Card(
                        child: ListTile(
                          title: Text(t['description'] ?? ''),
                          subtitle: Text('${t['date']} • ${t['categoryId']}'),
                          trailing: Text('R\$ ${t['amount'].toString()}'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
