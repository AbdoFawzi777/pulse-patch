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

/// Live measurement screen matching Live.dc.html and Measuring.png exactly.
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

  final List<double> _waveformPoints = [];
  late RecorderSnapshot _snapshot;

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
      widget.recorder.processPacket(pkt);
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
  }

  @override
  void dispose() {
    _packetSub?.cancel();
    _waveformSub?.cancel();
    _snapshotSub?.cancel();
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching_rounded,
              color: AppColors.accentCyan,
              size: 28.0,
            ),
            SizedBox(height: 8.0),
            Text(
              'Awaiting BLE packets from ESP32-C3...',
              textAlign: TextAlign.center,
              style: TextStyle(
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
    final displayBpm = _snapshot.currentDisplayBpm ?? 74;

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

          // Hero BPM Number & Subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$displayBpm',
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

          // Optical Pulse Trace Waveform
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

          // Trace Subtitle
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
