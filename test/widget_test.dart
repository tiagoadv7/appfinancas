// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for all timers and animations to complete
    await tester.pumpAndSettle();

    // Wait for the watchdog timer to complete
    await Future.delayed(const Duration(seconds: 6));

    // Verify that the app builds successfully by checking for a basic widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
