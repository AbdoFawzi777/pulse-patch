import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/signal/ble_packet.dart';

/// In-memory & on-disk recorder for raw 12-byte BLE telemetry packets.
/// Used for offline firmware filter tuning, DSP analysis, and algorithm verification.
class RawSessionRecorder {
  RawSessionRecorder();

  final List<String> _rows = [];
  bool _isRecording = false;
  DateTime? _sessionStartTime;
  File? _activeFile;

  bool get isRecording => _isRecording;
  int get packetCount => _rows.length;
  List<String> get rows => List.unmodifiable(_rows);

  /// Starts a new recording session and initializes the CSV header.
  Future<void> start() async {
    _rows.clear();
    _sessionStartTime = DateTime.now();
    _isRecording = true;

    const header = 'hex,receivedAt,deviceTimestampMs,seq,bpm,sqi,flags';
    _rows.add(header);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'raw_session_${_sessionStartTime!.toIso8601String().replaceAll(':', '-')}.csv';
      _activeFile = File('${dir.path}/$filename');
      await _activeFile!.writeAsString('$header\n');
    } catch (_) {
      // In test environments or when path_provider is unavailable, keep in memory
      _activeFile = null;
    }
  }

  /// Appends a raw packet to the recording stream.
  void recordPacket({
    required List<int> rawBytes,
    required BlePacket? parsed,
    required DateTime receivedAt,
  }) {
    if (!_isRecording) return;

    final hexStr = rawBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join('');
    final tsMs = parsed?.deviceTimestampMs ?? -1;
    final seq = parsed?.sequenceNumber ?? -1;
    final bpm = parsed?.rawBpm?.toStringAsFixed(1) ?? 'NaN';
    final sqi = parsed?.quality ?? 0;
    final flags = rawBytes.length > 1 ? rawBytes[1] : 0;

    final row =
        '$hexStr,${receivedAt.toIso8601String()},$tsMs,$seq,$bpm,$sqi,$flags';
    _rows.add(row);

    if (_activeFile != null) {
      _activeFile!.writeAsStringSync('$row\n', mode: FileMode.append);
    }
  }

  /// Stops recording and returns the full CSV content string.
  Future<String> stop() async {
    _isRecording = false;
    return _rows.join('\n');
  }

  /// Shares the recorded CSV file via system share sheet.
  Future<bool> exportCsv() async {
    if (_rows.isEmpty) return false;

    if (_activeFile != null && await _activeFile!.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(_activeFile!.path)],
          subject: 'PulsePatch Lite Raw BLE Session Telemetry',
        ),
      );
      return true;
    }

    try {
      final dir = await getTemporaryDirectory();
      final tempFile = File(
        '${dir.path}/raw_session_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await tempFile.writeAsString(_rows.join('\n'));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          subject: 'PulsePatch Lite Raw BLE Session Telemetry',
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
