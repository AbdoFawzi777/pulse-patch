import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/ml/ai_inference_service.dart';
import '../../domain/ml/ai_providers.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/loading_state.dart';
import 'ai_model_info_screen.dart';

/// Screen displaying pattern analysis for a recorded session.
/// Pixel-matched to `AI Insights.png` canvas design.
class SessionPatternAnalysisScreen extends ConsumerWidget {
  const SessionPatternAnalysisScreen({
    super.key,
    required this.sessionId,
    this.initialResult,
  });

  final String sessionId;
  final AiInferenceResult? initialResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiStateAsync = ref.watch(sessionAiAnalysisProvider(sessionId));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar matching AI Insights.png
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
                        'AI Insights',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.info_outline_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AiModelInfoScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: initialResult != null
                  ? _buildSuccessView(context, initialResult!)
                  : aiStateAsync.when(
                      loading: () => const LoadingState(
                        message: 'Analyzing pulse patterns locally...',
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: ErrorBanner(
                            message: 'Could not complete analysis: $err',
                          ),
                        ),
                      ),
                      data: (state) {
                        switch (state.status) {
                          case AiInferenceStatus.loading:
                          case AiInferenceStatus.analyzing:
                            return const LoadingState(
                              message: 'Analyzing pulse patterns locally...',
                            );
                          case AiInferenceStatus.insufficientData:
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: EmptyState(
                                  title: 'Insufficient Data for AI',
                                  description:
                                      state.insufficientReason ??
                                      'Requires at least 30 seconds of valid pulse data to analyze patterns.',
                                  icon: Icons.analytics_outlined,
                                ),
                              ),
                            );
                          case AiInferenceStatus.invalidInput:
                          case AiInferenceStatus.modelUnavailable:
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: ErrorBanner(
                                  message:
                                      state.errorMessage ??
                                      'AI model is unavailable.',
                                ),
                              ),
                            );
                          case AiInferenceStatus.success:
                            if (state.result != null) {
                              return _buildSuccessView(context, state.result!);
                            }
                            return const Center(
                              child: EmptyState(
                                title: 'No Result',
                                description:
                                    'Analysis did not return an output.',
                              ),
                            );
                          case AiInferenceStatus.idle:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
            ),

            // Bottom Navigation with Circle 3 (Insights) active
            BottomCircleNav(
              currentIndex:
                  2, // 0: Home, 1: History, 2: AI Insights, 3: Settings
              onTap: (index) {
                if (index != 2) {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, AiInferenceResult result) {
    final meanHr = result.features['mean_hr']?.toStringAsFixed(0) ?? '--';
    final stdHr = result.features['std_hr']?.toStringAsFixed(1) ?? '--';
    final startHr = result.features['start_hr']?.toStringAsFixed(0) ?? '--';
    final endHr = result.features['end_hr']?.toStringAsFixed(0) ?? '--';
    final recoveryDropVal = result.features['recovery_drop'];
    final recoveryDrop = recoveryDropVal != null
        ? '${recoveryDropVal > 0 ? "+" : ""}${recoveryDropVal.toStringAsFixed(0)} BPM'
        : '--';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Model Result Card matching AI Insights.png
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF451A8B), // Violet
                  Color(0xFF112061), // Deep navy
                ],
              ),
              borderRadius: BorderRadius.circular(22.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Model result',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2A66),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Text(
                        'Experimental',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  result.label, // 'Typical pattern' or 'Different pattern'
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 32.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  result.explanation,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFCBD5E1),
                    height: 1.4,
                  ),
                ),
                if (result.comparisonText.isNotEmpty) ...[
                  const SizedBox(height: 10.0),
                  Text(
                    result.comparisonText,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20.0),

          // 5 Feature Cards matching AI Insights.png
          _buildFeatureCard('mean_hr', '$meanHr BPM'),
          const SizedBox(height: 8.0),
          _buildFeatureCard('std_hr', stdHr),
          const SizedBox(height: 8.0),
          _buildFeatureCard('start_hr', '$startHr BPM'),
          const SizedBox(height: 8.0),
          _buildFeatureCard('end_hr', '$endHr BPM'),
          const SizedBox(height: 8.0),
          _buildFeatureCard('recovery_drop', recoveryDrop),

          const SizedBox(height: 24.0),

          // Footer Text matching AI Insights.png
          const Center(
            child: Text(
              'Runs on this phone · TensorFlow Lite · 6 sessions available',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String featureKey, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1947),
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            featureKey,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
