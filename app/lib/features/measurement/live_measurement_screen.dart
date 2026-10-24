import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/signal/ble_packet.dart';
import '../../domain/signal/session_recorder.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/circular_timer.dart';
import '../../shared/widgets/heart_rate_hero_number.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/pulse_trace_chart.dart';
import '../../shared/widgets/trend_chart.dart';
import '../device/heart_rate_source.dart';

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

  final List<double> _waveformPoints = List.filled(50, 0.5);
  late RecorderSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.recorder.currentSnapshot;

    // Start recording if not started
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

  String get _signalLabel {
    if (!_snapshot.isContactDetected) return 'No contact';
    if (_snapshot.currentQuality >= 80) return 'Signal: Good';
    if (_snapshot.currentQuality >= 60) return 'Signal: Fair';
    return 'Signal: Weak';
  }

  Widget _buildRealDeviceBpmTrend() {
    final validSamples = widget.recorder.samples
        .where((s) => s.isValid && s.bpm != null)
        .map((s) => s.bpm!.toDouble())
        .toList();

    if (validSamples.length < 2) {
      return Container(
        height: 110.0,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: AppColors.cardBgNavy.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.accentCyan.withValues(alpha: 0.2),
            width: 1.0,
          ),
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
              'Awaiting 12-byte BLE packets from ESP32-C3...',
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
      height: 110.0,
      minY: 40.0,
      maxY: 160.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = _snapshot.state == SessionRecorderState.paused;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Background corner glows
          Positioned(
            top: -120,
            left: -120,
            width: 360,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowTopLeft.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            width: 360,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowBottomRight.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 12.0),
                  // Top Bar
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        semanticLabel: 'Back',
                        onPressed: widget.onBack,
                      ),
                      const Expanded(
                        child: Text(
                          'Measuring',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 56.0), // Symmetry spacer
                    ],
                  ),
                  const Spacer(flex: 1),
                  // Hero Number
                  HeartRateHeroNumber(
                    bpm: _snapshot.currentDisplayBpm,
                    stacked: true,
                    size: HeroNumberSize.large,
                  ),
                  const Spacer(flex: 1),
                  // Waveform or BPM Trend based on source
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: widget.source.isSimulator
                        ? PulseTraceChart(
                            points: _waveformPoints,
                            height: 110.0,
                            strokeWidth: 2.5,
                          )
                        : _buildRealDeviceBpmTrend(),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    widget.source.isSimulator
                        ? 'Optical pulse trace · Simulator · $_signalLabel'
                        : 'Heart rate trend (BPM) · Real device · $_signalLabel',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Circular Countdown Timer
                  CircularTimer(
                    duration: _snapshot.targetDuration,
                    elapsed: _snapshot.elapsed,
                    isPaused: isPaused,
                    onTogglePause: _togglePause,
                  ),
                  const SizedBox(height: 36.0),
                  // Primary Action: Stop and save pill
                  PillButton(
                    label: 'Stop and save',
                    style: PillButtonStyle.stopSave,
                    width: 165.0,
                    height: 50.0,
                    onPressed: _stopAndSave,
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
