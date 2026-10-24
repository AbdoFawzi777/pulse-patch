import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class MeasurementPreparationScreen extends StatefulWidget {
  const MeasurementPreparationScreen({
    super.key,
    required this.onStart,
    required this.onBack,
  });

  final void Function(SessionType type, Duration duration) onStart;
  final VoidCallback onBack;

  @override
  State<MeasurementPreparationScreen> createState() =>
      _MeasurementPreparationScreenState();
}

class _MeasurementPreparationScreenState
    extends State<MeasurementPreparationScreen> {
  SessionType _selectedType = SessionType.rest;
  int _selectedDurationSec = 60;

  static const List<int> _durations = [30, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowTopLeft.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12.0),
                            CircleIconButton(
                              icon: Icons.chevron_left_rounded,
                              semanticLabel: 'Back',
                              onPressed: widget.onBack,
                            ),
                            const SizedBox(height: 20.0),
                            const Text(
                              'Measurement Preparation',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 28.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            const Text(
                              'Select session protocol before recording optical pulse.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            // Session Type Selector Cards
                            const Text(
                              'Session Protocol',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                Expanded(
                                  child: _ProtocolCard(
                                    title: 'Resting',
                                    description: 'Seated, quiet rest',
                                    isSelected:
                                        _selectedType == SessionType.rest,
                                    onTap: () => setState(
                                      () => _selectedType = SessionType.rest,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: _ProtocolCard(
                                    title: 'Post-Activity',
                                    description: 'After brisk effort',
                                    isSelected:
                                        _selectedType ==
                                        SessionType.postActivity,
                                    onTap: () => setState(
                                      () => _selectedType =
                                          SessionType.postActivity,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            // Duration Selector
                            const Text(
                              'Target Duration',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: _durations.map((d) {
                                final isSelected = d == _selectedDurationSec;
                                final isLast = d == _durations.last;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: isLast ? 0.0 : 10.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedDurationSec = d,
                                      ),
                                      child: Container(
                                        height: 48.0,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.cardBgNavy,
                                          borderRadius: BorderRadius.circular(
                                            16.0,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.cardBorder,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          '${d}s',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.0,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? AppColors.bgBase
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24.0),
                            // Fingertip Placement Notice Card
                            MetricCard(
                              padding: const EdgeInsets.all(18.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.touch_app_rounded,
                                    color: AppColors.accentCyan,
                                    size: 24.0,
                                  ),
                                  const SizedBox(width: 14.0),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fingertip Placement',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 4.0),
                                        Text(
                                          'Rest your index or middle fingertip gently on the MAX30102 sensor. Keep your hand completely still on the table.',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w400,
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
                            const Spacer(),
                            PillButton(
                              label: 'Start Measurement',
                              style: PillButtonStyle.white,
                              width: double.infinity,
                              height: 52.0,
                              onPressed: () {
                                widget.onStart(
                                  _selectedType,
                                  Duration(seconds: _selectedDurationSec),
                                );
                              },
                            ),
                            const SizedBox(height: 24.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MetricCard(
        borderColor: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentBlue,
                    size: 18.0,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.0,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
