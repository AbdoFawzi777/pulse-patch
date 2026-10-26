import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/features/reports/pdf_report_generator.dart';

void main() {
  test(
    'PdfReportGenerator produces offline PDF from real phone recorded sessions',
    () async {
      final now = DateTime.now();
      final items = [
        SessionReportData(
          session: SessionRecord(
            id: 'sess-1792996240842',
            startedAt: DateTime.fromMillisecondsSinceEpoch(1792996240842),
            endedAt: DateTime.fromMillisecondsSinceEpoch(1792996240842 + 60000),
            type: SessionType.rest,
            qualitySummary: QualitySummary.good,
            appVersion: '1.0.0',
            source: SessionSource.standardBle,
          ),
          stats: const SessionStatsRecord(
            sessionId: 'sess-1792996240842',
            meanHr: 71.8308,
            stdHr: 1.3059,
            minHr: 70.0,
            maxHr: 74.0,
            startHr: 72.0,
            endHr: 73.0,
            recoveryDrop: -1.0,
            pulseIntervalMs: 835.3,
            variabilityEstMs: 20.4,
            validSampleCount: 65,
            totalDurationSeconds: 60,
          ),
          aiPattern: 'Typical pattern',
        ),
        SessionReportData(
          session: SessionRecord(
            id: 'sess-1793000580974',
            startedAt: DateTime.fromMillisecondsSinceEpoch(1793000580974),
            endedAt: DateTime.fromMillisecondsSinceEpoch(1793000580974 + 90000),
            type: SessionType.postActivity,
            qualitySummary: QualitySummary.good,
            appVersion: '1.0.0',
            source: SessionSource.standardBle,
          ),
          stats: const SessionStatsRecord(
            sessionId: 'sess-1793000580974',
            meanHr: 74.0316,
            stdHr: 0.8049,
            minHr: 73.0,
            maxHr: 75.0,
            startHr: 75.0,
            endHr: 74.0,
            recoveryDrop: 0.0,
            pulseIntervalMs: 810.465,
            variabilityEstMs: 4.3726,
            validSampleCount: 95,
            totalDurationSeconds: 90,
          ),
          aiPattern: 'Typical pattern',
        ),
        SessionReportData(
          session: SessionRecord(
            id: 'sess-1793010133841',
            startedAt: DateTime.fromMillisecondsSinceEpoch(1793010133841),
            endedAt: DateTime.fromMillisecondsSinceEpoch(1793010133841 + 90000),
            type: SessionType.postActivity,
            qualitySummary: QualitySummary.good,
            appVersion: '1.0.0',
            source: SessionSource.standardBle,
          ),
          stats: const SessionStatsRecord(
            sessionId: 'sess-1793010133841',
            meanHr: 76.4421,
            stdHr: 3.5097,
            minHr: 71.0,
            maxHr: 84.0,
            startHr: 84.0,
            endHr: 74.0,
            recoveryDrop: 9.0,
            pulseIntervalMs: 784.908,
            variabilityEstMs: 14.156,
            validSampleCount: 95,
            totalDurationSeconds: 90,
          ),
          aiPattern: 'Different pattern',
        ),
      ];

      final pdfBytes = await PdfReportGenerator.generate(
        userName: 'Volunteer VOL_REAL_01',
        startDate: DateTime.fromMillisecondsSinceEpoch(1792996240842),
        endDate: now,
        items: items,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));

      // Write to docs/field_test/reports/
      final reportDir = Directory('../docs/field_test/reports');
      if (!reportDir.existsSync()) {
        reportDir.createSync(recursive: true);
      }
      final reportFile = File(
        '../docs/field_test/reports/pulse_patch_biomonitoring_report.pdf',
      );
      reportFile.writeAsBytesSync(pdfBytes);

      expect(reportFile.existsSync(), isTrue);
      expect(reportFile.lengthSync(), equals(pdfBytes.length));
    },
  );
}
