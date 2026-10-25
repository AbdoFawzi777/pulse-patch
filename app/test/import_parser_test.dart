import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/signal/import_file_parser.dart';

void main() {
  group('ImportFileParser Tests', () {
    test('Parses standard CSV with bpm, time, quality and SpO2', () {
      const csvData = '''
time,bpm,quality,spo2
0,72,90,98.0
1000,74,92,98.5
2000,73,88,97.5
3000,75,95,98.0
''';
      final result = ImportFileParser.parseFileContent(
        csvData,
        preferredSessionId: 'test-csv-1',
      );

      expect(result.session.id, 'test-csv-1');
      expect(result.session.source, SessionSource.importSource);
      expect(result.samples.length, 4);
      expect(result.samples[0].bpm, 72.0);
      expect(result.samples[0].spo2, 98.0);
      expect(result.stats.meanHr, closeTo(73.5, 0.2));
      expect(result.stats.avgSpo2, closeTo(98.0, 0.2));
    });

    test('Parses Gadgetbridge style CSV with timestamp and heart_rate', () {
      const gbCsv = '''
timestamp,heart_rate
1698230400,68
1698230401,69
1698230402,71
''';
      final result = ImportFileParser.parseFileContent(
        gbCsv,
        fileName: 'gadgetbridge.csv',
      );

      expect(result.session.source, SessionSource.importSource);
      expect(result.samples.length, 3);
      expect(result.samples[0].bpm, 68.0);
      expect(result.samples[2].bpm, 71.0);
      expect(result.sourceDescription.contains('gadgetbridge.csv'), isTrue);
    });

    test('Parses semicolon-delimited CSV accurately', () {
      const semiCsv = '''
t_ms;bpm;quality
0;80;90
1000;82;91
''';
      final result = ImportFileParser.parseFileContent(semiCsv);
      expect(result.samples.length, 2);
      expect(result.samples[0].bpm, 80.0);
      expect(result.samples[1].bpm, 82.0);
    });

    test('Parses simple JSON sample array', () {
      const jsonStr = '''
[
  {"t_ms": 0, "bpm": 65.0, "quality": 95, "spo2": 99.0},
  {"t_ms": 1000, "bpm": 66.5, "quality": 90, "spo2": 98.5}
]
''';
      final result = ImportFileParser.parseFileContent(jsonStr);

      expect(result.session.source, SessionSource.importSource);
      expect(result.samples.length, 2);
      expect(result.samples[0].bpm, 65.0);
      expect(result.samples[0].spo2, 99.0);
      expect(result.stats.avgSpo2, 98.75);
    });

    test(
      'Rejects empty or invalid content with informative FormatException',
      () {
        expect(
          () => ImportFileParser.parseFileContent(''),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => ImportFileParser.parseFileContent('hello,world\nfoo,bar'),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
