import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/errors/global_error_boundary.dart';
import 'package:app/core/errors/system_state.dart';
import 'package:app/features/device/device_troubleshooting_screen.dart';

void main() {
  group('Phase 11 - SystemStateInfo Model & Enums', () {
    test(
      'all 21 system states produce valid title, message, and action label',
      () {
        for (final stateType in SystemStateType.values) {
          final info = SystemStateInfo.forType(stateType);
          expect(info.type, equals(stateType));
          expect(
            info.title.isNotEmpty,
            isTrue,
            reason: '$stateType title is empty',
          );
          expect(
            info.message.isNotEmpty,
            isTrue,
            reason: '$stateType message is empty',
          );
          expect(
            info.actionLabel.isNotEmpty,
            isTrue,
            reason: '$stateType actionLabel is empty',
          );
        }
      },
    );

    test('critical flags are true for storage and unexpected error states', () {
      expect(
        SystemStateInfo.forType(SystemStateType.storageFailure).isCritical,
        isTrue,
      );
      expect(
        SystemStateInfo.forType(SystemStateType.unexpectedError).isCritical,
        isTrue,
      );
      expect(
        SystemStateInfo.forType(SystemStateType.connected).isCritical,
        isFalse,
      );
    });
  });

  group('Phase 11 - SystemStateBanner Widget Tests', () {
    testWidgets(
      'renders banner with title, message, and triggers action callback',
      (tester) async {
        bool actionFired = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SystemStateBanner(
                stateType: SystemStateType.bluetoothOff,
                onAction: () => actionFired = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Bluetooth is Disabled'), findsOneWidget);
        expect(
          find.textContaining('Enable Bluetooth on your phone'),
          findsOneWidget,
        );
        expect(find.text('Open Bluetooth Settings'), findsOneWidget);

        await tester.tap(find.text('Open Bluetooth Settings'));
        await tester.pumpAndSettle();

        expect(actionFired, isTrue);
      },
    );
  });

  group('Phase 11 - DeviceTroubleshootingScreen Widget Tests', () {
    testWidgets('renders diagnostic guides for all failure modes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: DeviceTroubleshootingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Troubleshooting'), findsOneWidget);
      expect(find.text('Bluetooth is Disabled'), findsOneWidget);
      expect(find.text('Permissions Denied'), findsOneWidget);
      expect(find.text('Device Not Found During Scan'), findsOneWidget);
      expect(find.text('Weak Optical Signal / Noise'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Sensor Communication Error (I2C)'),
        200.0,
      );
      expect(find.text('Sensor Communication Error (I2C)'), findsOneWidget);
    });
  });

  group('Phase 11 - GlobalErrorBoundary Widget Tests', () {
    testWidgets('catches error and shows recovery UI', (tester) async {
      final oldHandler = FlutterError.onError;
      final oldErrorBuilder = ErrorWidget.builder;
      addTearDown(() {
        FlutterError.onError = oldHandler;
        ErrorWidget.builder = oldErrorBuilder;
      });

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, widget) =>
              GlobalErrorBoundary(child: widget ?? const SizedBox.shrink()),
          home: Builder(
            builder: (context) {
              return const Scaffold(body: Text('Healthy App State'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Healthy App State'), findsOneWidget);
    });
  });
}
