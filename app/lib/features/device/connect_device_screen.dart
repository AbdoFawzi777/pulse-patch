import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'heart_rate_source.dart';

/// Connect Device screen matching Device.dc.html and Connect device.png exactly.
class ConnectDeviceScreen extends ConsumerWidget {
  const ConnectDeviceScreen({
    super.key,
    this.onBack,
    this.onSelectTab,
    this.currentNavIndex = 3,
    this.showBottomNav = true,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onSelectTab;
  final int currentNavIndex;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleSource = ref.watch(heartRateSourceProvider);

    return DesignCanvasScaffold(
      bottomNavigationBar: showBottomNav
          ? BottomCircleNav(
              currentIndex: currentNavIndex,
              onTap: onSelectTab ?? (_) {},
            )
          : null,
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
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const Text(
                'Connect device',
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

          // Radar Scanner Illustration (width: 320, height: 250)
          const Center(
            child: SizedBox(
              width: 320.0,
              height: 250.0,
              child: CustomPaint(
                size: Size(320.0, 250.0),
                painter: _RadarScannerPainter(),
              ),
            ),
          ),

          // Scanning Subtitle
          const Text(
            'Scanning · keep the patch within 1 m',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 12.0),

          // Device Card 1: PulsePatch-C3
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PulsePatch-C3',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'Signal strong · −52 dBm',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                PillButton(
                  label: 'Connect',
                  style: PillButtonStyle.white,
                  onPressed: () {
                    bleSource.startScan();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10.0),

          // Device Card 2: PulsePatch-C3 (2)
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PulsePatch-C3 (2)',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'Signal weak · −85 dBm',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                PillButton(
                  label: 'Connect',
                  style: PillButtonStyle.dark,
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12.0),

          // Hardware Footnote
          const Text(
            'Sensor: MAX30102 · Battery and firmware shown only if reported',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarScannerPainter extends CustomPainter {
  const _RadarScannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 320.0;
    final scaleY = size.height / 250.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    const center = Offset(160.0, 125.0);

    // Outer ring: r=115, stroke #3A2A8F opacity .4
    final outerPaint = Paint()
      ..color = const Color(0x663A2A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 115.0, outerPaint);

    // Middle ring: r=80, stroke #3A2A8F opacity .6
    final midPaint = Paint()
      ..color = const Color(0x993A2A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 80.0, midPaint);

    // Inner ring: r=45, stroke #4C8DF5
    final innerPaint = Paint()
      ..color = const Color(0xFF4C8DF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 45.0, innerPaint);

    // Center beacon: r=14, fill #C0148F
    final beaconPaint = Paint()
      ..color = const Color(0xFFC0148F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14.0, beaconPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
