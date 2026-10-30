// test/medical_knowledge_assistant_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/knowledge/medical_knowledge_engine.dart';
import 'package:app/features/knowledge/medical_knowledge_assistant_screen.dart';

void main() {
  late MedicalKnowledgeEngine engine;

  setUp(() async {
    engine = MedicalKnowledgeEngine();
    await engine.initialize();
  });

  testWidgets('MedicalKnowledgeAssistantScreen renders empty state with topic chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicalKnowledgeEngineProvider.overrideWithValue(engine),
        ],
        child: const MaterialApp(
          home: MedicalKnowledgeAssistantScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Medical Reference Assistant'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Authoritative Medical Knowledge Base'), findsOneWidget);
    expect(find.text('Normal resting heart rate ranges'), findsWidgets);
  });

  testWidgets('Submitting a question renders user bubble and assistant answer card with citations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicalKnowledgeEngineProvider.overrideWithValue(engine),
        ],
        child: const MaterialApp(
          home: MedicalKnowledgeAssistantScreen(),
        ),
      ),
    );
    await tester.pump();

    // Enter question in TextField
    final inputFinder = find.byType(TextField);
    await tester.enterText(inputFinder, 'What is a normal resting heart rate?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    
    // Process frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify assistant answer card appeared with citations
    expect(find.text('Authoritative Medical Sources:'), findsOneWidget);
    expect(find.textContaining('60'), findsWidgets);
  });

  testWidgets('Submitting an emergency symptom triggers the emergency warning banner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicalKnowledgeEngineProvider.overrideWithValue(engine),
        ],
        child: const MaterialApp(
          home: MedicalKnowledgeAssistantScreen(),
        ),
      ),
    );
    await tester.pump();

    final inputFinder = find.byType(TextField);
    await tester.enterText(inputFinder, 'I feel severe chest pain and cannot breathe');
    await tester.tap(find.byIcon(Icons.send_rounded));
    
    // Process frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify emergency warning banner appears with 123 prompt
    expect(find.textContaining('EMERGENCY WARNING'), findsOneWidget);
    expect(find.textContaining('Egyptian Ambulance 123'), findsOneWidget);
  });
}
