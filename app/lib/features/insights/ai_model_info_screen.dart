import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/circle_icon_button.dart';

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
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'AI Model Information',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 56.0), // Balance top bar
                ],
              ),
            ),

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
                                      'On-device TensorFlow Lite Engine',
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
                                'Local Isolate',
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
                              Text(
                                'Non-Diagnostic Scope',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'PulsePatch Lite is an educational prototype. The labels "Typical pattern" and "Different pattern" denote statistical clusters derived from volunteer protocol data. They do not constitute an evaluation of cardiovascular health, normalcy, or abnormality.',
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
                          'Architecture, weights & standardization vectors',
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
                            'MLP (5 -> 16 -> 8 -> 2)',
                          ),
                          _buildTechRow(
                            'Inference Engine',
                            'TensorFlow Lite C++ / Dart Isolate',
                          ),
                          _buildTechRow(
                            'Input Tensor Shape',
                            '[1, 5] (Float32)',
                          ),
                          _buildTechRow(
                            'Output Tensor Shape',
                            '[1, 2] (Logits / Softmax)',
                          ),
                          _buildTechRow(
                            'Scaler Mean Vector',
                            '[72.5, 4.2, 75.0, 71.0, -4.0]',
                          ),
                          _buildTechRow(
                            'Scaler Scale Vector',
                            '[12.0, 2.5, 12.0, 11.5, 6.0]',
                          ),
                          _buildTechRow(
                            'Decision Boundary',
                            'Euclidean z-distance threshold = 2.8',
                          ),
                          _buildTechRow(
                            'Asset Checksum Status',
                            'Valid TFL3 flatbuffer header',
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
