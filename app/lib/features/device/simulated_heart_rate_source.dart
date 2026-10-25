import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import 'heart_rate_source.dart';

/// Deterministic, zero-dependency sensor simulator clearly labeled as Simulator.
class SimulatedHeartRateSource implements HeartRateSource {
  SimulatedHeartRateSource({
    this.baseBpm = 74.0,
    this.simulateDropouts = false,
  });

  final double baseBpm;
  final bool simulateDropouts;

  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _discoveredDevicesController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _diagnosticsController =
      StreamController<PacketDiagnostics>.broadcast();
  final _waveformController = StreamController<double>.broadcast();

  BleConnectionState _currentState = BleConnectionState.idle;
  PacketDiagnostics _diagnostics = const PacketDiagnostics();

  Timer? _telemetryTimer;
  Timer? _waveformTimer;
  Timer? _scanTimer;

  int _sequence = 0;
  int _deviceTimestampMs = 0;
  double _waveformPhase = 0.0;
  bool _isDisposed = false;

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<List<DiscoveredBleDevice>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;

  @override
  Stream<BlePacket> get packetStream => _packetController.stream;

  @override
  Stream<PacketDiagnostics> get diagnosticsStream =>
      _diagnosticsController.stream;

  @override
  Stream<double> get opticalWaveformStream => _waveformController.stream;

  @override
  BleConnectionState get currentState => _currentState;

  @override
  PacketDiagnostics get currentDiagnostics => _diagnostics;

  @override
  bool get isSimulator => true;

  @override
  String get sourceLabel => 'Simulator';

  @override
  SessionSource get source => SessionSource.simulator;

  void _setState(BleConnectionState state) {
    if (_isDisposed) return;
    _currentState = state;
    _connectionStateController.add(state);
  }

  @override
  Future<void> startScan() async {
    _setState(BleConnectionState.scanning);
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 600), () {
      if (_isDisposed) return;
      _discoveredDevicesController.add([
        const DiscoveredBleDevice(
          id: 'SIM-C3-01',
          name: 'PulsePatch-C3 (Simulator)',
          rssi: -52,
        ),
        const DiscoveredBleDevice(
          id: 'SIM-C3-02',
          name: 'PulsePatch-C3 (2)',
          rssi: -85,
        ),
      ]);
    });
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    if (_currentState == BleConnectionState.scanning) {
      _setState(BleConnectionState.idle);
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    _scanTimer?.cancel();
    _setState(BleConnectionState.connecting);

    await Future.delayed(const Duration(milliseconds: 500));
    if (_isDisposed) return;

    _setState(BleConnectionState.connected);
    _startSimulationStreams();
  }

  @override
  Future<void> disconnect() async {
    _stopSimulationStreams();
    _setState(BleConnectionState.disconnected);
  }

  void _startSimulationStreams() {
    _stopSimulationStreams();

    // 1 Hz Heart rate packet generation
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) return;

      _deviceTimestampMs += 1000;
      _sequence = (_sequence + 1) & 0xFFFF;

      // Realistic subtle heart rate variability oscillation (~ ±2 BPM)
      final timeSec = timer.tick;
      final hrvOffset = 2.0 * math.sin(timeSec * 0.2);
      final currentBpm = (baseBpm + hrvOffset).clamp(30.0, 220.0);

      final packet = BlePacket(
        protocolVersion: BlePacket.currentProtocolVersion,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: currentBpm,
        quality: 92,
        deviceTimestampMs: _deviceTimestampMs,
        sequenceNumber: _sequence,
        receivedAt: DateTime.now(),
      );

      _diagnostics = _diagnostics.copyWith(
        totalPackets: _diagnostics.totalPackets + 1,
        lastReceivedTime: packet.receivedAt,
      );

      _packetController.add(packet);
      _diagnosticsController.add(_diagnostics);
    });

    // 25 Hz Optical pulse PPG waveform generation
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (_isDisposed) return;
      _waveformPhase += 0.25;
      if (_waveformPhase > 2 * math.pi) {
        _waveformPhase -= 2 * math.pi;
      }

      // Smooth photoplethysmogram pulse wave with dicrotic notch
      final primary = math.sin(_waveformPhase);
      final dicrotic = 0.3 * math.sin(2 * _waveformPhase);
      final normalized = ((primary + dicrotic + 1.3) / 2.6).clamp(0.0, 1.0);

      _waveformController.add(normalized);
    });
  }

  void _stopSimulationStreams() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _waveformTimer?.cancel();
    _waveformTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopSimulationStreams();
    _scanTimer?.cancel();
    _connectionStateController.close();
    _discoveredDevicesController.close();
    _packetController.close();
    _diagnosticsController.close();
    _waveformController.close();
  }
}
