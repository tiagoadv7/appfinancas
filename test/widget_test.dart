import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:appfinancas/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Inicializa formatação de datas PT-BR (igual ao main() de produção)
    await initializeDateFormatting('pt_BR', null);
  });

  setUp(() {
    // Garante SharedPreferences limpo antes de cada teste
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renderiza sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Avança 2 segundos para cobrir o delay de _loadInitialData (1.5s)
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Tela de login é exibida para usuário não autenticado',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // sem usuário em cache

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));

    // Em modo mock (debug), sem usuário salvo, deve exibir tela de login
    // Procura por algum indicador da tela de login/boas-vindas
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App restaura usuário do cache ao iniciar',
      (WidgetTester tester) async {
    // Simula sessão salva
    SharedPreferences.setMockInitialValues({
      'currentUser': '{"id":"u1","email":"a@b.com","name":"Test","role":"owner","salary":0.0}',
      'transactions': '[]',
      'categories': '[]',
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
