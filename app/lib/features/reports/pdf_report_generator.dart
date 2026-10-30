import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/session_record.dart';
import '../../domain/entities/session_stats_record.dart';

class SessionReportData {
  const SessionReportData({required this.session, this.stats, this.aiPattern});

  final SessionRecord session;
  final SessionStatsRecord? stats;
  final String? aiPattern;
}

class PdfReportGenerator {
  static Future<Uint8List> generate({
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
    required List<SessionReportData> items,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final rangeFormat = DateFormat('MMM d, yyyy');

    final validStats = items
        .map((i) => i.stats)
        .whereType<SessionStatsRecord>()
        .toList();
    final meanHrAvg = validStats.isNotEmpty
        ? (validStats.map((s) => s.meanHr).reduce((a, b) => a + b) /
                  validStats.length)
              .round()
        : null;

    final restSessions = items
        .where((i) => i.session.type == SessionType.rest && i.stats != null)
        .toList();
    final postSessions = items
        .where(
          (i) => i.session.type == SessionType.postActivity && i.stats != null,
        )
        .toList();

    final restMeanAvg = restSessions.isNotEmpty
        ? (restSessions.map((i) => i.stats!.meanHr).reduce((a, b) => a + b) /
                  restSessions.length)
              .round()
        : null;

    final postMeanAvg = postSessions.isNotEmpty
        ? (postSessions.map((i) => i.stats!.meanHr).reduce((a, b) => a + b) /
                  postSessions.length)
              .round()
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32.0),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PulsePatch Lite',
                    style: pw.TextStyle(
                      fontSize: 24.0,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.SizedBox(height: 2.0),
                  pw.Text(
                    'Pulse Summary Report',
                    style: const pw.TextStyle(
                      fontSize: 14.0,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Date: ${rangeFormat.format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10.0),
                  ),
                  pw.Text(
                    'User: $userName',
                    style: const pw.TextStyle(fontSize: 10.0),
                  ),
                  pw.Text(
                    'Range: ${rangeFormat.format(startDate)} - ${rangeFormat.format(endDate)}',
                    style: const pw.TextStyle(fontSize: 10.0),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.indigo800),
          pw.SizedBox(height: 8.0),

          // Non-diagnostic Educational Disclaimer Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10.0),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber600, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6.0)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EDUCATIONAL PROTOTYPE - NON-DIAGNOSTIC USE ONLY',
                  style: pw.TextStyle(
                    fontSize: 9.0,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber900,
                  ),
                ),
                pw.SizedBox(height: 2.0),
                pw.Text(
                  'PulsePatch Lite is an educational biomonitoring prototype connecting to an ESP32-C3 + MAX30102 pulse sensor. '
                  'This report contains measured optical pulse rates, rule-based summary statistics, and experimental ML pattern labels. '
                  'It does NOT constitute a medical diagnosis or health evaluation.',
                  style: const pw.TextStyle(
                    fontSize: 8.0,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16.0),

          // Aggregate Summary Metrics
          pw.Text(
            'Aggregate Metrics',
            style: pw.TextStyle(
              fontSize: 14.0,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.SizedBox(height: 6.0),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value', 'Unit', 'Classification'],
            data: [
              ['Total Sessions', '${items.length}', 'sessions', 'Measured'],
              [
                'Eligible Analyzed Sessions',
                '${validStats.length}',
                'sessions',
                'Calculated',
              ],
              [
                'Overall Mean Pulse Rate',
                meanHrAvg != null ? '$meanHrAvg' : 'N/A',
                'BPM',
                'Calculated',
              ],
              [
                'Resting Mean Pulse Rate',
                restMeanAvg != null ? '$restMeanAvg' : 'N/A',
                'BPM',
                'Calculated',
              ],
              [
                'Post-Activity Mean Pulse Rate',
                postMeanAvg != null ? '$postMeanAvg' : 'N/A',
                'BPM',
                'Calculated',
              ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9.0,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.indigo800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
          ),
          pw.SizedBox(height: 16.0),

          // Sessions Table
          pw.Text(
            'Session Records Log',
            style: pw.TextStyle(
              fontSize: 14.0,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.SizedBox(height: 6.0),
          if (items.isEmpty)
            pw.Text(
              'No recorded sessions found in the selected date range.',
              style: const pw.TextStyle(
                fontSize: 9.0,
                color: PdfColors.grey600,
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Timestamp',
                'Protocol',
                'Duration',
                'Mean HR',
                'SpO2',
                'Quality',
                'AI Pattern',
                'Source',
              ],
              data: items.map((item) {
                final s = item.session;
                final st = item.stats;
                final durationSec = s.endedAt != null
                    ? s.endedAt!.difference(s.startedAt).inSeconds
                    : (st?.totalDurationSeconds ?? 0);
                return [
                  dateFormat.format(s.startedAt),
                  s.type == SessionType.rest ? 'Rest' : 'Post-Activity',
                  '${durationSec}s',
                  st != null ? '${st.meanHr.round()} BPM' : 'N/A',
                  st?.avgSpo2 != null ? '${st!.avgSpo2!.toStringAsFixed(0)}%' : 'N/A',
                  s.qualitySummary.name,
                  item.aiPattern ?? 'None',
                  s.source == SessionSource.simulator
                      ? 'Simulator'
                      : 'Hardware',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 8.0,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 3.5,
              ),
            ),
          pw.SizedBox(height: 20.0),

          // Data Classification & Transparency Notice
          pw.Container(
            padding: const pw.EdgeInsets.all(8.0),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4.0)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Data Origin Separation:',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2.0),
                pw.Bullet(
                  text:
                      'Received Data: Real over-the-air BLE packets from test peripheral (PulsePatch-SimHR) streaming simulated physiological profiles; physical MAX30102 sensor integration pending.',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.Bullet(
                  text:
                      'Calculated: Rule-based median, mean, standard deviation, and interval arithmetic.',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.Bullet(
                  text:
                      'Model Output: On-device machine learning pattern classification (Typical / Different). Strictly educational, non-diagnostic.',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.SizedBox(height: 4.0),
                pw.Text(
                  'Authoritative Clinical Evidence Bases:',
                  style: pw.TextStyle(
                    fontSize: 8.0,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '- WHO Guidelines on Hypertension (2023) & Pulse Oximetry (2021)\n- ESH/ESC Guidelines for Arterial Hypertension (2023)\n- AHA/ACC Scientific Consensus on Resting Heart Rate (2022)\n- IEEE 1708 Standard for Cuffless Blood Pressure Measurement Boundaries',
                  style: const pw.TextStyle(fontSize: 7.0, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
