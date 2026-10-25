import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/signal/ble_packet.dart';
import '../../domain/signal/session_recorder.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/circular_timer.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/pulse_trace_chart.dart';
import '../../shared/widgets/trend_chart.dart';
import '../device/heart_rate_source.dart';

/// Live measurement screen matching Live.dc.html and Measuring.png.
/// Displays real-time heart rate telemetry, validity gating, and watchdog timeout.
class LiveMeasurementScreen extends StatefulWidget {
  const LiveMeasurementScreen({
    super.key,
    required this.recorder,
    required this.source,
    required this.onComplete,
    required this.onBack,
  });

  final SessionRecorder recorder;
  final HeartRateSource source;
  final void Function(SessionRecorder recorder) onComplete;
  final VoidCallback onBack;

  @override
  State<LiveMeasurementScreen> createState() => _LiveMeasurementScreenState();
}

class _LiveMeasurementScreenState extends State<LiveMeasurementScreen> {
  StreamSubscription<BlePacket>? _packetSub;
  StreamSubscription<double>? _waveformSub;
  StreamSubscription<RecorderSnapshot>? _snapshotSub;
  StreamSubscription<PacketDiagnostics>? _diagnosticsSub;

  final List<double> _waveformPoints = [];
  late RecorderSnapshot _snapshot;
  PacketDiagnostics _diagnostics = const PacketDiagnostics();

  Timer? _watchdogTimer;
  DateTime? _lastPacketReceivedAt;
  bool _watchdogTriggered = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.recorder.currentSnapshot;

    if (widget.recorder.state == SessionRecorderState.preparing) {
      widget.recorder.start();
    }

    _snapshotSub = widget.recorder.snapshotStream.listen((snap) {
      if (!mounted) return;
      setState(() => _snapshot = snap);
      if (snap.state == SessionRecorderState.completed) {
        widget.onComplete(widget.recorder);
      }
    });

    _packetSub = widget.source.packetStream.listen((pkt) {
      _lastPacketReceivedAt = DateTime.now();
      if (_watchdogTriggered) {
        setState(() => _watchdogTriggered = false);
      }
      widget.recorder.processPacket(pkt);
    });

    _diagnosticsSub = widget.source.diagnosticsStream.listen((diag) {
      if (!mounted) return;
      setState(() => _diagnostics = diag);
    });

    _waveformSub = widget.source.opticalWaveformStream.listen((point) {
      if (!mounted) return;
      setState(() {
        _waveformPoints.add(point);
        if (_waveformPoints.length > 60) {
          _waveformPoints.removeAt(0);
        }
      });
    });

    _startWatchdog();
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      final last = _lastPacketReceivedAt;
      if (last == null) {
        if (_snapshot.elapsed.inSeconds >= 10 && !_watchdogTriggered) {
          setState(() => _watchdogTriggered = true);
        }
      } else if (now.difference(last).inSeconds >= 10 && !_watchdogTriggered) {
        setState(() => _watchdogTriggered = true);
      }
    });
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _packetSub?.cancel();
    _waveformSub?.cancel();
    _snapshotSub?.cancel();
    _diagnosticsSub?.cancel();
    super.dispose();
  }

  void _togglePause() {
    if (_snapshot.state == SessionRecorderState.measuring) {
      widget.recorder.pause();
    } else if (_snapshot.state == SessionRecorderState.paused) {
      widget.recorder.resume();
    }
  }

  void _stopAndSave() {
    widget.recorder.stopAndSave();
  }

  Widget _buildRealDeviceBpmTrend() {
    final validSamples = widget.recorder.samples
        .where((s) => s.isValid && s.bpm != null)
        .map((s) => s.bpm!.toDouble())
        .toList();

    if (validSamples.length < 2) {
      return Container(
        height: 130.0,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: AppColors.cardBgNavy,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bluetooth_searching_rounded,
              color: AppColors.accentCyan,
              size: 28.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Awaiting heart rate packets from ${widget.source.sourceLabel}...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return TrendChart(
      values: validSamples.length > 50
          ? validSamples.sublist(validSamples.length - 50)
          : validSamples,
      height: 130.0,
      minY: 40.0,
      maxY: 160.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = _snapshot.state == SessionRecorderState.paused;
    final int? currentBpm = _snapshot.currentDisplayBpm;
    final String displayBpmStr;
    if (currentBpm != null && currentBpm >= 30 && currentBpm <= 220) {
      displayBpmStr = '$currentBpm';
    } else if (widget.source.isSimulator) {
      displayBpmStr = '74';
    } else {
      displayBpmStr = '--';
    }

    final sourceCode = widget.source.source.code;
    final packetRate = _diagnostics.packetRateHz.toStringAsFixed(1);
    final qualityStr = _snapshot.currentQuality > 0
        ? '${_snapshot.currentQuality}%'
        : 'Assessing...';

    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row (.r)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: widget.onBack,
              ),
              const Text(
                'Measuring',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),

          const SizedBox(height: 20.0),

          // 10-Second Watchdog Alert Banner
          if (_watchdogTriggered)
            Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFEF4444), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  const Expanded(
                    child: Text(
                      'No heart-rate data from this device yet',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFCA5A5),
                      ),
                    ),
                  ),
                  PillButton(
                    label: 'Troubleshoot',
                    style: PillButtonStyle.dark,
                    onPressed: widget.onBack,
                  ),
                ],
              ),
            ),

          // Hero BPM Number & Subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayBpmStr,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 96.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.0,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4.0),
              const Text(
                'BPM',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40.0),

          // Optical Pulse Trace Waveform / Trend
          Center(
            child: widget.source.isSimulator
                ? const PulseTraceChart(
                    useDesignPath: true,
                    width: 350.0,
                    height: 130.0,
                  )
                : _buildRealDeviceBpmTrend(),
          ),

          const SizedBox(height: 8.0),

          // Trace Subtitle matching Live.dc.html
          const Text(
            'Optical pulse trace · Signal: Good',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),

          if (!widget.source.isSimulator) ...[
            const SizedBox(height: 4.0),
            Text(
              'Source: $sourceCode · $packetRate Hz · Quality: $qualityStr',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.0,
                fontWeight: FontWeight.w300,
                color: AppColors.textMuted,
              ),
            ),
          ],

          const Spacer(),

          // Circular Countdown Timer
          Center(
            child: CircularTimer(
              duration: _snapshot.targetDuration,
              elapsed: _snapshot.elapsed,
              isPaused: isPaused,
              onTogglePause: _togglePause,
            ),
          ),

          const SizedBox(height: 20.0),

          // Action Button: Stop and save
          Center(
            child: PillButton(
              label: 'Stop and save',
              style: PillButtonStyle.dark,
              onPressed: _stopAndSave,
            ),
          ),
        ],
      ),
    );
  }
}
