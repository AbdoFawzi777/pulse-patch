import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/features/reports/pdf_report_generator.dart';
import 'package:app/features/reports/reports_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  group('PdfReportGenerator Tests', () {
    test('Generates valid PDF with empty session history without crashing', () async {
      final now = DateTime.now();
      final bytes = await PdfReportGenerator.generate(
        userName: 'Test User',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
        items: [],
      );

      expect(bytes, isNotEmpty);
      // Check PDF header magic bytes %PDF-
      expect(bytes[0], equals(0x25)); // %
      expect(bytes[1], equals(0x50)); // P
      expect(bytes[2], equals(0x44)); // D
      expect(bytes[3], equals(0x46)); // F
    });

    test('Generates valid PDF with sessions including HR, SpO2, and AI pattern', () async {
      final now = DateTime.now();
      final session = SessionRecord(
        id: 'sess-pdf-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );
      final stats = SessionStatsRecord(
        sessionId: 'sess-pdf-1',
        meanHr: 72.0,
        stdHr: 2.1,
        minHr: 68.0,
        maxHr: 76.0,
        startHr: 74.0,
        endHr: 70.0,
        validSampleCount: 120,
        totalDurationSeconds: 120,
        avgSpo2: 98.0,
      );

      final items = [
        SessionReportData(
          session: session,
          stats: stats,
          aiPattern: 'Typical pattern',
        ),
      ];

      final bytes = await PdfReportGenerator.generate(
        userName: 'Ahmed Ali',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
        items: items,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      expect(bytes[0], equals(0x25)); // %
      expect(bytes[1], equals(0x50)); // P
      expect(bytes[2], equals(0x44)); // D
      expect(bytes[3], equals(0x46)); // F
    });
  });

  group('ReportsScreen Widget Tests', () {
    testWidgets('Renders all multi-period date range filters', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: ReportsScreen(onBack: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biomonitoring Reports'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      // Verify Generate & Share button exists
      expect(find.text('Export & Share PDF Report', skipOffstage: false), findsOneWidget);
    });
  });
}
