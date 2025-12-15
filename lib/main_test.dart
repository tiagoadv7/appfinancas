import 'package:flutter/material.dart';
import 'local_storage/test_storage_screen.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppFinancas - Test Storage',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestStorageScreen(),
    );
  }
}
