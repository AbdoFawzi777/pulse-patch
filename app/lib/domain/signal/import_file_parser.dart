import 'dart:convert';
import '../entities/pulse_sample.dart';
import '../entities/session_record.dart';
import '../entities/session_stats_record.dart';

class ImportedSessionResult {
  const ImportedSessionResult({
    required this.session,
    required this.samples,
    required this.stats,
    required this.sourceDescription,
  });

  final SessionRecord session;
  final List<PulseSample> samples;
  final SessionStatsRecord stats;
  final String sourceDescription;
}

/// Robust parser for importing heart rate recordings from CSV, JSON,
/// Gadgetbridge exports, and Health Connect data exports.
class ImportFileParser {
  const ImportFileParser._();

  /// Automatically detects file format (JSON or CSV) and parses into a session.
  static ImportedSessionResult parseFileContent(
    String content, {
    String? preferredSessionId,
    String? fileName,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Imported file is empty.');
    }

    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return _parseJson(trimmed, preferredSessionId, fileName);
    } else {
      return _parseCsv(trimmed, preferredSessionId, fileName);
    }
  }

  static ImportedSessionResult _parseJson(
    String jsonStr,
    String? preferredSessionId,
    String? fileName,
  ) {
    final dynamic decoded = jsonDecode(jsonStr);
    final String sessionId =
        preferredSessionId ?? 'import-${DateTime.now().millisecondsSinceEpoch}';
    final List<dynamic> sampleList;
    DateTime startTime = DateTime.now();
    SessionType sessionType = SessionType.rest;

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('sessions') &&
          (decoded['sessions'] as List).isNotEmpty) {
        // Native PulsePatch JSON export format
        final firstSession = decoded['sessions'][0] as Map<String, dynamic>;
        return ImportedSessionResult(
          session: SessionRecord.fromJson({
            ...firstSession,
            'id': sessionId,
            'source': SessionSource.importSource.code,
          }),
          samples: (firstSession['samples'] as List? ?? [])
              .map((s) => PulseSample.fromJson(s as Map<String, dynamic>))
              .toList(),
          stats: firstSession['stats'] != null
              ? SessionStatsRecord.fromJson(
                  firstSession['stats'] as Map<String, dynamic>,
                )
              : _computeStatsFromSamples(sessionId, []),
          sourceDescription: 'PulsePatch JSON Export (${fileName ?? "File"})',
        );
      }

      if (decoded.containsKey('samples') && decoded['samples'] is List) {
        sampleList = decoded['samples'] as List<dynamic>;
      } else {
        sampleList = [decoded];
      }

      if (decoded.containsKey('startedAt')) {
        startTime =
            DateTime.tryParse(decoded['startedAt'].toString()) ?? startTime;
      }
      if (decoded.containsKey('type') && decoded['type'] == 'postActivity') {
        sessionType = SessionType.postActivity;
      }
    } else if (decoded is List) {
      sampleList = decoded;
    } else {
      throw const FormatException(
        'Unrecognized JSON structure for heart rate import.',
      );
    }

    final samples = <PulseSample>[];
    int tMsCounter = 0;

    for (final item in sampleList) {
      if (item is! Map<String, dynamic>) continue;
      final bpmVal =
          item['bpm'] ?? item['heart_rate'] ?? item['hr'] ?? item['value'];
      if (bpmVal == null) continue;
      final double bpm = (bpmVal as num).toDouble();
      final int tMs = item['t_ms'] is num
          ? (item['t_ms'] as num).toInt()
          : (item['timestamp'] is num
                ? (item['timestamp'] as num).toInt()
                : tMsCounter);
      tMsCounter += 1000;

      final int quality = (item['quality'] as num?)?.toInt() ?? 85;
      final double? spo2 = (item['spo2'] as num?)?.toDouble();

      samples.add(
        PulseSample(
          sessionId: sessionId,
          tMs: tMs,
          bpm: bpm,
          quality: quality,
          isValid: bpm >= 40 && bpm <= 220,
          spo2: spo2,
        ),
      );
    }

    if (samples.isEmpty) {
      throw const FormatException(
        'No valid heart rate samples found in JSON file.',
      );
    }

    final stats = _computeStatsFromSamples(sessionId, samples);
    final session = SessionRecord(
      id: sessionId,
      startedAt: startTime,
      endedAt: startTime.add(Duration(seconds: stats.totalDurationSeconds)),
      type: sessionType,
      qualitySummary: stats.validSampleCount > 10
          ? QualitySummary.good
          : QualitySummary.fair,
      appVersion: '1.0.0',
      source: SessionSource.importSource,
    );

    return ImportedSessionResult(
      session: session,
      samples: samples,
      stats: stats,
      sourceDescription: 'JSON Import (${fileName ?? "File"})',
    );
  }

  static ImportedSessionResult _parseCsv(
    String csvStr,
    String? preferredSessionId,
    String? fileName,
  ) {
    final lines = LineSplitter.split(
      csvStr,
    ).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) {
      throw const FormatException('CSV file has no data lines.');
    }

    // Determine delimiter (, or ;)
    final delimiter = lines.first.contains(';') ? ';' : ',';
    final headerTokens = lines.first
        .toLowerCase()
        .split(delimiter)
        .map((h) => h.trim())
        .toList();

    int bpmIdx = -1;
    int timeIdx = -1;
    int qualityIdx = -1;
    int spo2Idx = -1;

    for (int i = 0; i < headerTokens.length; i++) {
      final h = headerTokens[i];
      if (h == 'bpm' ||
          h == 'heart_rate' ||
          h == 'heartrate' ||
          h == 'hr' ||
          h == 'value') {
        bpmIdx = i;
      } else if (h == 't_ms' ||
          h == 'timestamp' ||
          h == 'time' ||
          h == 'date' ||
          h == 'datetime') {
        timeIdx = i;
      } else if (h == 'quality' || h == 'sqi') {
        qualityIdx = i;
      } else if (h == 'spo2' || h == 'oxygen' || h == 'o2') {
        spo2Idx = i;
      }
    }

    final bool hasHeader = bpmIdx != -1;
    final int startLine = hasHeader ? 1 : 0;
    if (!hasHeader) {
      // Default guess: column 0 = time, column 1 = bpm
      timeIdx = 0;
      bpmIdx = 1;
    }

    final String sessionId =
        preferredSessionId ?? 'import-${DateTime.now().millisecondsSinceEpoch}';
    final samples = <PulseSample>[];
    int relativeMs = 0;
    DateTime startTime = DateTime.now();

    for (int lineNum = startLine; lineNum < lines.length; lineNum++) {
      final cols = lines[lineNum]
          .split(delimiter)
          .map((c) => c.trim())
          .toList();
      if (cols.length <= bpmIdx) continue;

      final bpm = double.tryParse(cols[bpmIdx]);
      if (bpm == null || bpm <= 0) continue;

      int tMs = relativeMs;
      if (timeIdx != -1 && cols.length > timeIdx) {
        final parsedTime = double.tryParse(cols[timeIdx]);
        if (parsedTime != null) {
          tMs = parsedTime > 1000000000
              ? (parsedTime * 1000).toInt()
              : parsedTime.toInt();
        } else {
          final dt = DateTime.tryParse(cols[timeIdx]);
          if (dt != null) {
            if (samples.isEmpty) startTime = dt;
            tMs = dt.difference(startTime).inMilliseconds.abs();
          }
        }
      }
      relativeMs += 1000;

      int quality = 85;
      if (qualityIdx != -1 && cols.length > qualityIdx) {
        quality = int.tryParse(cols[qualityIdx]) ?? 85;
      }

      double? spo2;
      if (spo2Idx != -1 && cols.length > spo2Idx) {
        spo2 = double.tryParse(cols[spo2Idx]);
      }

      samples.add(
        PulseSample(
          sessionId: sessionId,
          tMs: tMs,
          bpm: bpm,
          quality: quality,
          isValid: bpm >= 40 && bpm <= 220,
          spo2: spo2,
        ),
      );
    }

    if (samples.isEmpty) {
      throw const FormatException(
        'Could not parse any valid heart rate records from CSV.',
      );
    }

    final stats = _computeStatsFromSamples(sessionId, samples);
    final session = SessionRecord(
      id: sessionId,
      startedAt: startTime,
      endedAt: startTime.add(Duration(seconds: stats.totalDurationSeconds)),
      type: SessionType.rest,
      qualitySummary: stats.validSampleCount >= 10
          ? QualitySummary.good
          : QualitySummary.weak,
      appVersion: '1.0.0',
      source: SessionSource.importSource,
    );

    return ImportedSessionResult(
      session: session,
      samples: samples,
      stats: stats,
      sourceDescription: 'CSV / Gadgetbridge Import (${fileName ?? "File"})',
    );
  }

  static SessionStatsRecord _computeStatsFromSamples(
    String sessionId,
    List<PulseSample> samples,
  ) {
    final valid = samples.where((s) => s.isValid && s.bpm != null).toList();
    if (valid.isEmpty) {
      return SessionStatsRecord(
        sessionId: sessionId,
        meanHr: 0.0,
        stdHr: 0.0,
        minHr: 0.0,
        maxHr: 0.0,
        startHr: 0.0,
        endHr: 0.0,
        validSampleCount: 0,
        totalDurationSeconds: 0,
      );
    }

    final bpms = valid.map((s) => s.bpm!).toList();
    final mean = bpms.reduce((a, b) => a + b) / bpms.length;

    double std = 0.0;
    if (bpms.length > 1) {
      double varianceSum = 0.0;
      for (final b in bpms) {
        varianceSum += (b - mean) * (b - mean);
      }
      std = varianceSum / (bpms.length - 1);
    }

    final minHr = bpms.reduce((a, b) => a < b ? a : b);
    final maxHr = bpms.reduce((a, b) => a > b ? a : b);
    final startHr = bpms.first;
    final endHr = bpms.last;
    final recoveryDrop = startHr - endHr;

    final spo2Vals = valid
        .where((s) => s.spo2 != null)
        .map((s) => s.spo2!)
        .toList();
    final avgSpo2 = spo2Vals.isNotEmpty
        ? (spo2Vals.reduce((a, b) => a + b) / spo2Vals.length)
        : null;

    final durationSec = samples.isNotEmpty
        ? ((samples.last.tMs - samples.first.tMs) / 1000).round().clamp(
            1,
            86400,
          )
        : 0;

    return SessionStatsRecord(
      sessionId: sessionId,
      meanHr: double.parse(mean.toStringAsFixed(1)),
      stdHr: double.parse(std.toStringAsFixed(1)),
      minHr: minHr,
      maxHr: maxHr,
      startHr: startHr,
      endHr: endHr,
      recoveryDrop: double.parse(recoveryDrop.toStringAsFixed(1)),
      pulseIntervalMs: double.parse((60000.0 / mean).toStringAsFixed(1)),
      variabilityEstMs: double.parse((std * 5.0).toStringAsFixed(1)),
      validSampleCount: valid.length,
      totalDurationSeconds: durationSec,
      avgSpo2: avgSpo2,
    );
  }
}
