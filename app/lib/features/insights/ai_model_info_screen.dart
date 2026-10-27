import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/circle_icon_button.dart';

import '../../shared/widgets/design_canvas_scaffold.dart';

/// Screen displaying transparency metadata for the AI model.
/// Derived screen #13 adhering strictly to design tokens.
class AiModelInfoScreen extends StatefulWidget {
  const AiModelInfoScreen({super.key});

  @override
  State<AiModelInfoScreen> createState() => _AiModelInfoScreenState();
}

class _AiModelInfoScreenState extends State<AiModelInfoScreen> {
  bool _isTechnicalPanelExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'AI Model Information',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56.0), // Balance top bar
            ],
          ),
          const SizedBox(height: 12.0),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Model Hero Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF451A8B), Color(0xFF112061)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: AppColors.accentCyan,
                                size: 28.0,
                              ),
                            ),
                            const SizedBox(width: 14.0),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PulsePatch AI Insights',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.0),
                                  Text(
                                    'On-device Dart Background Isolate Engine',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        const Divider(color: Color(0xFF26336D), height: 1.0),
                        const SizedBox(height: 12.0),
                        const Wrap(
                          spacing: 12.0,
                          runSpacing: 6.0,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              'Trained: Oct 2026',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              '241 Parameters (<0.15ms)',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                color: AppColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Privacy & Offline Guarantee Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgNavy,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: AppColors.accentCyan,
                          size: 22.0,
                        ),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100% Offline & Private',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                'The model runs entirely inside a background isolate on your phone. No pulse samples, features, or inferences are transmitted off this device.',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.0,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Validation Status & Synthetic Metrics Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgNavy,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: AppColors.accentCyan.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: const Text(
                                'SYNTHETIC PIPELINE TEST',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentCyan,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Expanded(
                              child: Text(
                                'Not real validation',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.0,
                                  color: Color(0xFF94A3B8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        const Text(
                          'Pipeline Simulation Metrics',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          'Evaluated across 160 modeled synthetic volunteer sessions to verify numerical pipeline stability. Not measured on physical human subjects.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        _buildMetricRow(
                          'Cross-Validation Accuracy',
                          '99.38% (±0.9%)',
                          'Synthetic test',
                        ),
                        _buildMetricRow(
                          'ROC-AUC Score',
                          '1.0000',
                          'Synthetic test',
                        ),
                        _buildMetricRow(
                          'Synthetic Cohort Size',
                          '160 sessions (10 profiles)',
                          'Synthetic test',
                        ),
                        _buildMetricRow(
                          'Resting MAE',
                          '1.21 BPM (MAPE 1.77%)',
                          'Synthetic test',
                        ),
                        _buildMetricRow(
                          'Mean Recovery Drop',
                          '21.6 ± 10.3 BPM',
                          'Synthetic test',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Real Data & Sensor Transparency Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgNavy,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: AppColors.accentCyan.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: const Text(
                                'SINGLE-SUBJECT DATA PROTOCOL',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentCyan,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        const Text(
                          'Session Type Pattern Classification',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          'When training on single-subject recordings, labels (Typical vs Different pattern) are derived programmatically from the session protocol: resting stability vs post-activity rate recovery drop. The model learns session type dynamics and recovery trajectory, NOT health, wellness, or fitness. Physical over-the-air pairing with a Mi Band 5 is not yet tested on a real band.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        _buildMetricRow(
                          'Learning Target',
                          'Session type & recovery trajectory',
                          'Not health rating',
                        ),
                        _buildMetricRow(
                          'Label Derivation',
                          'Rest stability vs recovery drop',
                          'Programmatic protocol',
                        ),
                        _buildMetricRow(
                          'Physical Band Status',
                          'Not yet tested on a real band',
                          'Awaits pairing',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Input Features Transparency Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgNavy,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Model Input Features',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Computed over valid pulse samples (30–220 BPM, quality >= 60).',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        _buildFeatureRow(
                          'mean_hr',
                          'Mean heart rate across valid samples.',
                        ),
                        _buildFeatureRow(
                          'std_hr',
                          'Sample standard deviation (N-1) of heart rate.',
                        ),
                        _buildFeatureRow(
                          'start_hr',
                          'Median heart rate in the first 10 valid seconds.',
                        ),
                        _buildFeatureRow(
                          'end_hr',
                          'Median heart rate in the last 10 valid seconds.',
                        ),
                        _buildFeatureRow(
                          'recovery_drop',
                          'Drop from initial 10s to 60s recovery window.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Educational Compliance & Non-Diagnostic Disclaimer
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgNavy,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: AppColors.accentPurple.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.accentPurple,
                              size: 22.0,
                            ),
                            SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Non-Diagnostic Educational Scope',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'PulsePatch Lite is an educational prototype. The labels "Typical pattern" and "Different pattern" denote statistical clusters derived from synthetic training protocols. They do not constitute an evaluation of cardiovascular health, normalcy, or pathology.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Technical Evaluators Panel (Expandable)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBgNavy,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: const Text(
                        'Technical Evaluator Panel',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Architecture, execution mode & parameters',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      initiallyExpanded: _isTechnicalPanelExpanded,
                      onExpansionChanged: (val) {
                        setState(() {
                          _isTechnicalPanelExpanded = val;
                        });
                      },
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 18.0,
                        vertical: 10.0,
                      ),
                      children: [
                        _buildTechRow(
                          'Network Architecture',
                          'MLP (5 -> 16 -> 8 -> 1)',
                        ),
                        _buildTechRow('Input Tensor Shape', '[1, 5] (Float32)'),
                        _buildTechRow(
                          'Output Tensor Shape',
                          '[1, 1] (Sigmoid Logits)',
                        ),
                        _buildTechRow(
                          'On-Device Execution',
                          'Dart Isolate (Isolate.run)',
                        ),
                        _buildTechRow(
                          'Model Parameter Count',
                          '241 weights & biases',
                        ),
                        _buildTechRow(
                          'Inference Latency',
                          '< 0.15 ms on device',
                        ),
                        _buildTechRow(
                          'Local Inference Engine',
                          'small neural network running locally in the app',
                        ),
                        _buildTechRow(
                          'Scaler Mean Vector',
                          '[88.38, 7.18, 95.26, 81.47, 10.85]',
                        ),
                        _buildTechRow(
                          'Scaler Scale Vector',
                          '[21.27, 3.90, 27.64, 17.07, 13.07]',
                        ),
                        _buildTechRow(
                          'Training Dataset',
                          'trained on Mi Band 5 wrist data (wrist optical sensor, not MAX30102)',
                        ),
                        _buildTechRow(
                          'Validation Status',
                          'Real wrist optical: single-subject time-ordered split; Synthetic baseline: pipeline simulation only',
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
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

  Widget _buildMetricRow(String label, String value, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.0,
                    color: AppColors.accentCyan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String key, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1947),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: AppColors.accentCyan,
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
