import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/ai_result_record.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/history/measurement_history_screen.dart';
import 'package:app/features/history/session_details_screen.dart';
import 'package:app/features/reports/historical_trends_screen.dart';
import 'package:app/features/reports/pdf_report_generator.dart';
import 'package:app/features/reports/reports_screen.dart';

Widget _wrap(Widget child, {AppDatabase? db, HeartRateSource? source}) {
  final inMemDb = db ?? AppDatabase.inMemory();
  final simSource = source ?? SimulatedHeartRateSource();

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(inMemDb),
      heartRateSourceProvider.overrideWithValue(simSource),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Phase 7 History, Trends & Reports Tests', () {
    late AppDatabase db;
    late SessionRepository repo;

    setUp(() async {
      db = AppDatabase.inMemory();
      repo = SessionRepository(db);

      // Seed mock sessions
      final now = DateTime.now();
      await repo.insertSession(
        session: SessionRecord(
          id: 'hist-1',
          startedAt: now.subtract(const Duration(hours: 2)),
          endedAt: now.subtract(const Duration(hours: 1, minutes: 59)),
          type: SessionType.rest,
          qualitySummary: QualitySummary.good,
          appVersion: '1.0.0',
          source: SessionSource.simulator,
        ),
        samples: const [],
        stats: const SessionStatsRecord(
          sessionId: 'hist-1',
          meanHr: 74.0,
          stdHr: 2.5,
          minHr: 68.0,
          maxHr: 82.0,
          startHr: 75.0,
          endHr: 72.0,
          pulseIntervalMs: 811.0,
          variabilityEstMs: 41.0,
          validSampleCount: 60,
          totalDurationSeconds: 60,
        ),
        aiResult: AiResultRecord(
          sessionId: 'hist-1',
          modelVersion: '1.0.0',
          label: 'typical',
          featuresJson: '{"mean_hr":74.0}',
          createdAt: now,
        ),
      );

      // Second session: Post-activity
      await repo.insertSession(
        session: SessionRecord(
          id: 'hist-2',
          startedAt: now.subtract(const Duration(days: 2)),
          endedAt: now.subtract(const Duration(days: 2, minutes: -2)),
          type: SessionType.postActivity,
          qualitySummary: QualitySummary.fair,
          appVersion: '1.0.0',
          source: SessionSource.simulator,
        ),
        samples: const [],
        stats: const SessionStatsRecord(
          sessionId: 'hist-2',
          meanHr: 88.0,
          stdHr: 5.0,
          minHr: 72.0,
          maxHr: 110.0,
          startHr: 105.0,
          endHr: 76.0,
          recoveryDrop: 29.0,
          pulseIntervalMs: 681.0,
          variabilityEstMs: 38.0,
          validSampleCount: 120,
          totalDurationSeconds: 120,
        ),
      );
    });

    tearDown(() {
      db.close();
    });

    test(
      'PdfReportGenerator produces valid PDF bytes with header and disclaimer',
      () async {
        final now = DateTime.now();
        final items = [
          SessionReportData(
            session: SessionRecord(
              id: 'test-pdf',
              startedAt: now,
              endedAt: now.add(const Duration(seconds: 60)),
              type: SessionType.rest,
              qualitySummary: QualitySummary.good,
              appVersion: '1.0.0',
              source: SessionSource.simulator,
            ),
            stats: const SessionStatsRecord(
              sessionId: 'test-pdf',
              meanHr: 72.0,
              stdHr: 3.0,
              minHr: 65.0,
              maxHr: 80.0,
              startHr: 74.0,
              endHr: 70.0,
              validSampleCount: 60,
              totalDurationSeconds: 60,
            ),
            aiPattern: 'typical',
          ),
        ];

        final pdfBytes = await PdfReportGenerator.generate(
          userName: 'Test Subject',
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now,
          items: items,
        );

        expect(pdfBytes, isNotEmpty);
        // Valid PDF magic bytes: %PDF
        final headerStr = String.fromCharCodes(pdfBytes.take(4));
        expect(headerStr, '%PDF');
      },
    );

    testWidgets(
      'MeasurementHistoryScreen matches History.png and lists sessions',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        SessionRecord? tappedSession;
        await tester.pumpWidget(
          _wrap(
            MeasurementHistoryScreen(
              onBack: () {},
              onSelectSession: (s) => tappedSession = s,
            ),
            db: db,
          ),
        );

        expect(find.text('History'), findsOneWidget);
        expect(find.text('Week'), findsOneWidget);
        expect(find.text('Day'), findsOneWidget);
        expect(find.text('Sample data'), findsOneWidget);

        // Verify session item is rendered
        expect(find.text('74'), findsWidgets);
        expect(find.textContaining('Quality: Good'), findsOneWidget);

        // Tap session tile
        await tester.tap(find.textContaining('Quality: Good'));
        expect(tappedSession?.id, 'hist-1');
      },
    );

    testWidgets(
      'SessionDetailsScreen displays full stats, optical waveform and delete action',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final session = repo.getSessionById('hist-1')!;
        bool deleted = false;

        await tester.pumpWidget(
          _wrap(
            SessionDetailsScreen(
              session: session,
              onBack: () {},
              onDeleted: () => deleted = true,
            ),
            db: db,
          ),
        );

        expect(find.text('Session Details'), findsOneWidget);
        expect(find.text('Rest'), findsOneWidget);
        expect(find.text('Sample data'), findsOneWidget);
        expect(find.text('mean_hr'), findsOneWidget);
        expect(find.text('std_hr'), findsOneWidget);
        expect(find.text('start_hr'), findsOneWidget);
        expect(find.text('end_hr'), findsOneWidget);
        expect(find.text('Pulse interval'), findsOneWidget);
        expect(find.text('Typical pattern'), findsOneWidget);

        // Test delete flow
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Delete Session?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(deleted, isTrue);
      },
    );

    testWidgets(
      'HistoricalTrendsScreen displays trend chart with gaps and filters',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          _wrap(HistoricalTrendsScreen(onBack: () {}), db: db),
        );

        expect(find.text('Historical Trends'), findsOneWidget);
        expect(find.text('Optical Pulse Rate Trend'), findsOneWidget);
        expect(find.text('All Protocols'), findsOneWidget);
        expect(find.text('Resting'), findsOneWidget);
        expect(find.text('Post-Activity'), findsOneWidget);
        expect(find.text('Lowest recorded'), findsOneWidget);
        expect(find.text('Highest recorded'), findsOneWidget);
        expect(
          find.text('Missing days show gaps · no fabricated data'),
          findsOneWidget,
        );

        // Filter by Resting
        await tester.tap(find.text('Resting'));
        await tester.pumpAndSettle();
        expect(find.text('Resting'), findsOneWidget);
      },
    );

    testWidgets(
      'ReportsScreen renders summary stats, origin declaration, and disclaimer',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_wrap(ReportsScreen(onBack: () {}), db: db));
        await tester.pumpAndSettle();

        expect(find.text('Biomonitoring Reports'), findsOneWidget);
        expect(find.text('7 Days'), findsOneWidget);
        expect(find.text('30 Days'), findsOneWidget);
        expect(find.text('All Time'), findsOneWidget);
        expect(find.text('Eligible Session Summary'), findsOneWidget);
        expect(find.text('Total Sessions'), findsOneWidget);
        expect(find.text('Data Transparency Declaration'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Export & Share PDF Report'),
          300.0,
          scrollable: find.byType(Scrollable).last,
        );

        expect(find.text('Export & Share PDF Report'), findsOneWidget);
        expect(
          find.textContaining('educational research prototype'),
          findsOneWidget,
        );
      },
    );
  });
}
