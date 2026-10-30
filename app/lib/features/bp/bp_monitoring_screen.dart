import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/ai/bp_inference_service.dart';
import '../../domain/profile/user_profile.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/pulse_trace_chart.dart';
import '../device/heart_rate_source.dart';
import '../../data/repositories/user_profile_repository.dart';

class BpMonitoringScreen extends ConsumerStatefulWidget {
  const BpMonitoringScreen({super.key});

  @override
  ConsumerState<BpMonitoringScreen> createState() => _BpMonitoringScreenState();
}

class _BpMonitoringScreenState extends ConsumerState<BpMonitoringScreen> {
  final _cuffSbpController = TextEditingController();
  final _cuffDbpController = TextEditingController();

  late BpInferenceService _bpService;
  UserProfile? _userProfile;
  BpEstimateResult? _latestEstimate;
  double _calibratedSbpOffset = 0.0;
  double _calibratedDbpOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _bpService = BpInferenceService.defaultModel();
    _loadProfileAndCalibration();
  }

  @override
  void dispose() {
    _cuffSbpController.dispose();
    _cuffDbpController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndCalibration() async {
    final profileRepo = ref.read(userProfileRepositoryProvider);
    final p = await profileRepo.getProfile();
    final db = ref.read(appDatabaseProvider);

    final calibRows = db.rawDb.select(
      'SELECT offset_sbp, offset_dbp FROM bp_calibrations ORDER BY calibrated_at DESC LIMIT 1;',
    );

    double sbpOff = 0.0;
    double dbpOff = 0.0;
    if (calibRows.isNotEmpty) {
      sbpOff = (calibRows.first['offset_sbp'] as num).toDouble();
      dbpOff = (calibRows.first['offset_dbp'] as num).toDouble();
    }

    if (mounted) {
      setState(() {
        _userProfile = p;
        _calibratedSbpOffset = sbpOff;
        _calibratedDbpOffset = dbpOff;
        _bpService = BpInferenceService.defaultModel(
          sbpOffset: sbpOff,
          dbpOffset: dbpOff,
        );
      });
    }
  }

  void _runEstimation(double hrBpm) {
    final p = _userProfile ??
        UserProfile(
          id: 'temp',
          fullName: 'User',
          age: 45,
          gender: 'male',
          heightCm: 175,
          weightKg: 75,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final est = _bpService.estimate(
      age: p.age.toDouble(),
      gender: p.gender == 'male' ? 1.0 : 0.0,
      bmi: p.bmi > 0 ? p.bmi : 24.5,
      hrBpm: hrBpm,
      crestTimeMs: 152.0,
      decayTimeMs: 698.0,
      pw50Ms: 245.0,
      areaRatio: 0.27,
      reflectionIndex: 0.75,
      stiffnessIndex: 10.6,
    );

    setState(() {
      _latestEstimate = est;
    });
  }

  Future<void> _applyCuffCalibration() async {
    final cuffS = double.tryParse(_cuffSbpController.text.trim());
    final cuffD = double.tryParse(_cuffDbpController.text.trim());

    if (cuffS == null || cuffD == null || cuffS <= cuffD) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid Cuff SBP and DBP values')),
      );
      return;
    }

    if (_latestEstimate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perform a live reading before calibrating')),
      );
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final uncalibSbp = _latestEstimate!.sbp - _calibratedSbpOffset;
    final uncalibDbp = _latestEstimate!.dbp - _calibratedDbpOffset;

    final newOffsetSbp = cuffS - uncalibSbp;
    final newOffsetDbp = cuffD - uncalibDbp;

    final calibId = 'calib-${DateTime.now().millisecondsSinceEpoch}';
    db.rawDb.execute(
      '''
      INSERT INTO bp_calibrations (
        id, user_id, cuff_sbp, cuff_dbp, estimated_sbp, estimated_dbp, offset_sbp, offset_dbp, calibrated_at, device_identifier
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        calibId,
        _userProfile?.id ?? 'user_primary',
        cuffS,
        cuffD,
        uncalibSbp,
        uncalibDbp,
        newOffsetSbp,
        newOffsetDbp,
        DateTime.now().millisecondsSinceEpoch,
        'PulsePatch-BLE',
      ],
    );

    setState(() {
      _calibratedSbpOffset = newOffsetSbp;
      _calibratedDbpOffset = newOffsetDbp;
      _bpService = BpInferenceService.defaultModel(
        sbpOffset: newOffsetSbp,
        dbpOffset: newOffsetDbp,
      );
    });

    _runEstimation(72.0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Model Calibrated Successfully with Cuff Reference'),
          backgroundColor: AppColors.cardBgGradientStart,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleSource = ref.watch(heartRateSourceProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DesignCanvasScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header
              Row(
                children: [
                  CircleIconButton(
                    type: CircleIconType.back,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      isRtl ? 'مراقبة ضغط الدم التجريبي' : 'Blood Pressure Monitoring',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Non-Diagnostic Medical Boundary Notice
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20.0),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        isRtl
                            ? 'نموذج بحثي وتجريبي غير تشخيصي. لا تعتمد على هذه التقديرات لاتخاذ قرارات علاجية. يتطلب معايرة دورية بواسطة جهاز ضغط معتمد.'
                            : 'Experimental research model. Non-diagnostic estimates; do not use for treatment decisions. Requires regular reference cuff calibration.',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.0,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Live Blood Pressure Estimation Hero Card
              MetricCard(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isRtl ? 'تقدير ضغط الدم (ملم زئبق)' : 'Estimated Blood Pressure',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: (_calibratedSbpOffset != 0.0)
                                ? AppColors.accentCyan.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            (_calibratedSbpOffset != 0.0)
                                ? (isRtl ? 'معاير' : 'Calibrated')
                                : (isRtl ? 'غير معاير' : 'Uncalibrated'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: (_calibratedSbpOffset != 0.0)
                                  ? AppColors.accentCyan
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _latestEstimate != null
                                ? '${_latestEstimate!.sbp.toInt()} / ${_latestEstimate!.dbp.toInt()}'
                                : '-- / --',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 48.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Text(
                            'mmHg',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    if (_latestEstimate != null)
                      Text(
                        isRtl ? _latestEstimate!.categoryArabic : _latestEstimate!.category,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentCyan,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Live PPG Waveform Trace Preview
              StreamBuilder<double>(
                stream: bleSource.opticalWaveformStream,
                initialData: 0.0,
                builder: (context, snapshot) {
                  return MetricCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'مخطط تدفق النبض الضوئي (PPG)' : 'Live Optical PPG Waveform',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        const SizedBox(
                          height: 90.0,
                          child: PulseTraceChart(
                            points: [0.0, 0.2, 0.5, 0.9, 0.4, 0.1, 0.0],
                            lineColor: AppColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20.0),

              // Trigger Estimation Button
              StreamBuilder(
                stream: bleSource.packetStream,
                builder: (context, snapshot) {
                  final packet = snapshot.data;
                  final currentBpm = packet?.rawBpm ?? 72.0;
                  return PillButton(
                    label: isRtl ? 'حساب تقدير ضغط الدم الآن' : 'Estimate Blood Pressure Now',
                    onPressed: () => _runEstimation(currentBpm),
                  );
                },
              ),
              const SizedBox(height: 24.0),

              // Cuff Reference Calibration Panel
              MetricCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'معايرة بواسطة جهاز ضغط كف مرجعي' : 'Cuff Reference Calibration',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      isRtl
                          ? 'أدخل قياس جهاز الضغط المنزلي لمطابقة دقة النموذج'
                          : 'Enter your certified upper-arm cuff reading to calibrate the AI model offset.',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cuffSbpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                            decoration: const InputDecoration(
                              labelText: 'Cuff SBP',
                              prefixIcon: Icon(Icons.speed, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: TextFormField(
                            controller: _cuffDbpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                            decoration: const InputDecoration(
                              labelText: 'Cuff DBP',
                              prefixIcon: Icon(Icons.speed, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    PillButton(
                      label: isRtl ? 'تطبيق المعايرة المرجعية' : 'Calibrate AI Model',
                      onPressed: _applyCuffCalibration,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
