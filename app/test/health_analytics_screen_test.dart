import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/features/reports/health_analytics_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('HealthAnalyticsScreen Widget Tests', () {
    testWidgets('Renders health analytics screen, tabs, and default empty state', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const HealthAnalyticsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Health Analytics & Baseline'), findsOneWidget);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Oxygen (SpO₂)'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Personal Baseline'), findsOneWidget);

      // Verify heart rate average card renders
      expect(find.text('7-Day Heart Rate Average'), findsOneWidget);
      expect(find.text('-- BPM'), findsOneWidget);
    });

    testWidgets('Can switch tabs to Blood Pressure and view segregated sections', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const HealthAnalyticsScreen()));
      await tester.pumpAndSettle();

      // Tap Blood Pressure tab
      await tester.tap(find.text('Blood Pressure'));
      await tester.pumpAndSettle();

      expect(find.text('Reference Cuff Blood Pressure'), findsOneWidget);
      expect(find.text('Experimental AI Estimates (PPG)'), findsOneWidget);
      expect(find.text('RESEARCH ONLY'), findsOneWidget);
    });
  });
}
