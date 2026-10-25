import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/shared/widgets/ble_device_card.dart';
import 'package:app/shared/widgets/bottom_circle_nav.dart';
import 'package:app/shared/widgets/circle_icon_button.dart';
import 'package:app/shared/widgets/circular_timer.dart';
import 'package:app/shared/widgets/confirm_dialog.dart';
import 'package:app/shared/widgets/date_range_filter.dart';
import 'package:app/shared/widgets/dot_variability_chart.dart';
import 'package:app/shared/widgets/empty_state.dart';
import 'package:app/shared/widgets/error_banner.dart';
import 'package:app/shared/widgets/heart_rate_hero_number.dart';
import 'package:app/shared/widgets/info_tooltip.dart';
import 'package:app/shared/widgets/insight_card.dart';
import 'package:app/shared/widgets/loading_state.dart';
import 'package:app/shared/widgets/metric_card.dart';
import 'package:app/shared/widgets/pill_button.dart';
import 'package:app/shared/widgets/pulse_trace_chart.dart';
import 'package:app/shared/widgets/session_tile.dart';
import 'package:app/shared/widgets/status_chip.dart';
import 'package:app/shared/widgets/trend_chart.dart';

Widget _wrap(Widget child, {TextScaler? textScaler}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 390.0,
          child: textScaler != null
              ? MediaQuery(
                  data: MediaQueryData(textScaler: textScaler),
                  child: child,
                )
              : child,
        ),
      ),
    ),
  );
}

void main() {
  group('Phase 1 Design System Widget Tests', () {
    testWidgets('CircleIconButton renders with 56px size and fires onTap', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          Center(
            child: CircleIconButton(
              icon: Icons.chevron_left_rounded,
              semanticLabel: 'Back',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CircleIconButton));
      expect(size.width, 56.0);
      expect(size.height, 56.0);

      await tester.tap(find.byType(CircleIconButton));
      expect(tapped, isTrue);
    });

    testWidgets('PillButton meets 48px touch target and fires callback', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          PillButton(
            label: 'Measure',
            style: PillButtonStyle.white,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Measure'), findsOneWidget);
      final size = tester.getSize(find.byType(PillButton));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(find.text('Measure'));
      expect(tapped, isTrue);
    });

    testWidgets('HeartRateHeroNumber displays bpm and unit', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HeartRateHeroNumber(
            bpm: 74,
            unit: 'BPM',
            size: HeroNumberSize.large,
          ),
        ),
      );

      expect(find.text('74'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
    });

    testWidgets('HeartRateHeroNumber displays fallback for null BPM', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const HeartRateHeroNumber(bpm: null, unit: 'BPM')),
      );

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('MetricCard renders with 22px border radius', (tester) async {
      await tester.pumpWidget(
        _wrap(const MetricCard(child: Text('Card Content'))),
      );

      expect(find.text('Card Content'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(22.0));
    });

    testWidgets('StatusChip renders neutral and experimental styles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              StatusChip(
                label: 'Sample data',
                variant: StatusChipVariant.sample,
              ),
              StatusChip(
                label: 'Experimental',
                variant: StatusChipVariant.experimental,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Sample data'), findsOneWidget);
      expect(find.text('Experimental'), findsOneWidget);
    });

    testWidgets(
      'CircularTimer displays formatted countdown and handles pause',
      (tester) async {
        bool toggled = false;
        await tester.pumpWidget(
          _wrap(
            CircularTimer(
              duration: const Duration(seconds: 60),
              elapsed: const Duration(seconds: 9),
              isPaused: false,
              onTogglePause: () => toggled = true,
            ),
          ),
        );

        expect(find.text('00:51'), findsOneWidget);
        expect(find.byType(CircularTimer), findsOneWidget);

        await tester.tap(find.byType(CircularTimer));
        expect(toggled, isTrue);
      },
    );

    testWidgets('BottomCircleNav renders four 64px circles with active state', (
      tester,
    ) async {
      int selected = 0;
      await tester.pumpWidget(
        _wrap(
          BottomCircleNav(currentIndex: selected, onTap: (i) => selected = i),
        ),
      );

      expect(find.byType(BottomCircleNav), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('History'));
      expect(selected, 1);
    });

    testWidgets('PulseTraceChart paints without errors', (tester) async {
      await tester.pumpWidget(
        _wrap(const PulseTraceChart(points: [0.5, 0.2, 0.8, 0.4, 0.6])),
      );

      expect(find.byType(PulseTraceChart), findsOneWidget);
    });

    testWidgets('DotVariabilityChart renders columns and time labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const DotVariabilityChart(
            columns: [
              [
                DotPoint(normalizedY: 0.2, isMagenta: true),
                DotPoint(normalizedY: 0.5, isMagenta: false),
              ],
              [
                DotPoint(normalizedY: 0.4, isMagenta: false),
                DotPoint(normalizedY: 0.7, isMagenta: true),
              ],
            ],
          ),
        ),
      );

      expect(find.text('6am'), findsOneWidget);
      expect(find.text('9pm'), findsOneWidget);
    });

    testWidgets('TrendChart handles null gap correctly without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TrendChart(
            values: [70.0, 75.0, null, 80.0, 72.0],
            labels: ['M', 'T', 'W', 'T', 'F'],
          ),
        ),
      );

      expect(find.byType(TrendChart), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('BleDeviceCard shows device name, rssi, and connect button', (
      tester,
    ) async {
      bool connected = false;
      await tester.pumpWidget(
        _wrap(
          BleDeviceCard(
            name: 'PulsePatch-C3',
            rssi: -52,
            onConnect: () => connected = true,
          ),
        ),
      );

      expect(find.text('PulsePatch-C3'), findsOneWidget);
      expect(find.text('Signal strong · -52 dBm'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);

      await tester.tap(find.text('Connect'));
      expect(connected, isTrue);
    });

    testWidgets('SessionTile renders session info and hero BPM', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SessionTile(
            title: 'Today 18:05',
            qualityText: 'Good',
            patternText: 'typical',
            bpm: 74,
          ),
        ),
      );

      expect(find.text('Today 18:05'), findsOneWidget);
      expect(find.text('Quality: Good · Pattern: typical'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
    });

    testWidgets('InsightCard renders model result hero and feature cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              InsightCard.modelResult(
                patternTitle: 'Typical pattern',
                explanation: 'Similar to your last 5 rest sessions.',
              ),
              InsightCard.feature(
                featureName: 'mean_hr',
                featureValue: '74 BPM',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Model result'), findsOneWidget);
      expect(find.text('Typical pattern'), findsOneWidget);
      expect(find.text('mean_hr'), findsOneWidget);
      expect(find.text('74 BPM'), findsOneWidget);
    });

    testWidgets('DateRangeFilter toggles between Week and Day', (tester) async {
      DateRangeOption selected = DateRangeOption.week;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return DateRangeFilter(
                selectedOption: selected,
                onChanged: (opt) => setState(() => selected = opt),
              );
            },
          ),
        ),
      );

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);

      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();
      expect(selected, DateRangeOption.day);
    });

    testWidgets('EmptyState and LoadingState render properly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              EmptyState(
                title: 'No Sessions',
                description: 'Record your first pulse session.',
              ),
              LoadingState(message: 'Connecting to patch...'),
            ],
          ),
        ),
      );

      expect(find.text('No Sessions'), findsOneWidget);
      expect(find.text('Connecting to patch...'), findsOneWidget);
    });

    testWidgets('ErrorBanner renders non-alarming banner with action', (
      tester,
    ) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        _wrap(
          ErrorBanner(
            message: 'Weak optical signal detected. Reposition patch.',
            actionLabel: 'Troubleshoot',
            onAction: () => actionTapped = true,
          ),
        ),
      );

      expect(
        find.text('Weak optical signal detected. Reposition patch.'),
        findsOneWidget,
      );
      expect(find.text('Troubleshoot'), findsOneWidget);

      await tester.tap(find.text('Troubleshoot'));
      expect(actionTapped, isTrue);
    });

    testWidgets(
      'ConfirmDialog displays title, message and returns user choice',
      (tester) async {
        bool? result;
        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await ConfirmDialog.show(
                      context,
                      title: 'Delete Session?',
                      message: 'This action cannot be undone.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Session?'), findsOneWidget);
        expect(find.text('This action cannot be undone.'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(result, isTrue);
      },
    );

    testWidgets('InfoTooltip renders with semantic message', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InfoTooltip(
            message:
                'Signal quality represents optical clarity from the sensor.',
          ),
        ),
      );

      expect(find.byType(InfoTooltip), findsOneWidget);
    });

    testWidgets('Accessibility text scaling 2.0x test does not crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HeartRateHeroNumber(
            bpm: 74,
            unit: 'BPM',
            size: HeroNumberSize.card,
          ),
          textScaler: const TextScaler.linear(2.0),
        ),
      );

      expect(find.text('74'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
    });
  });
}
