import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches with themed shell smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PulsePatchApp()));
    await tester.pumpAndSettle();

    expect(find.text('PulsePatch Lite'), findsOneWidget);
    expect(find.text('Hi, there!'), findsOneWidget);
  });

  testWidgets('Themed shell renders correctly in Arabic RTL locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(locale: Locale('ar'), home: ThemedShellScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ThemedShellScreen), findsOneWidget);
  });
}
