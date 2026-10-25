import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
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
    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: widget.onBack,
              ),
              const Text(
                'Prepare Session',
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
          const SizedBox(height: 16.0),
          const Text(
            'Select measurement protocol and recording duration.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20.0),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Protocol Card
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Protocol',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Rest for baseline tracking, Post-Activity to assess recovery deceleration.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Row(
                        children: [
                          Expanded(
                            child: PillButton(
                              label: 'Rest',
                              style: _selectedType == SessionType.rest
                                  ? PillButtonStyle.white
                                  : PillButtonStyle.dark,
                              onPressed: () => setState(
                                () => _selectedType = SessionType.rest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: PillButton(
                              label: 'Post-Activity',
                              style: _selectedType == SessionType.postActivity
                                  ? PillButtonStyle.white
                                  : PillButtonStyle.dark,
                              onPressed: () => setState(
                                () => _selectedType = SessionType.postActivity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
                // Duration Card
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recording Duration',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'A minimum of 30 seconds is required for statistical metrics.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Row(
                        children: _durations.map((sec) {
                          final isSelected = _selectedDurationSec == sec;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: PillButton(
                                label: '${sec}s',
                                style: isSelected
                                    ? PillButtonStyle.white
                                    : PillButtonStyle.dark,
                                onPressed: () => setState(
                                  () => _selectedDurationSec = sec,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          PillButton(
            label: 'Start Recording',
            style: PillButtonStyle.white,
            width: double.infinity,
            height: 48.0,
            onPressed: () {
              widget.onStart(
                _selectedType,
                Duration(seconds: _selectedDurationSec),
              );
            },
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
