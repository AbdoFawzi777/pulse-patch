import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/device/mi_band_5_source.dart';

void main() {
  group('BleConnectionState Enum & Machine Tests', () {
    test('All states exist in BleConnectionState', () {
      const expectedStates = [
        BleConnectionState.bluetoothOff,
        BleConnectionState.permissionDenied,
        BleConnectionState.idle,
        BleConnectionState.scanning,
        BleConnectionState.connecting,
        BleConnectionState.discovering,
        BleConnectionState.subscribing,
        BleConnectionState.connected,
        BleConnectionState.streaming,
        BleConnectionState.blocked,
        BleConnectionState.disconnected,
        BleConnectionState.reconnecting,
        BleConnectionState.noSensorData,
        BleConnectionState.timeout,
      ];

      for (final s in expectedStates) {
        expect(BleConnectionState.values.contains(s), isTrue);
      }
    });

    test(
      'DiscoveredBleDevice masks MAC addresses correctly without leaking',
      () {
        const dev1 = DiscoveredBleDevice(
          id: 'F1:E7:67:88:99:6C',
          name: 'Mi Smart Band 5',
          rssi: -50,
        );
        expect(dev1.maskedId, 'F1:E7:**:**:**:6C');
        expect(dev1.maskedId.contains('88'), isFalse);
        expect(dev1.maskedId.contains('99'), isFalse);

        const dev2 = DiscoveredBleDevice(
          id: '00:11:22:33:44:55',
          name: 'PulsePatch-C3',
          rssi: -45,
        );
        expect(dev2.maskedId, '00:11:**:**:**:55');

        expect(MiBand5Source.maskMac('AA:BB:CC:DD:EE:FF'), 'AA:BB:**:**:**:FF');
      },
    );

    test('DiscoveredBleDevice evaluates badges correctly', () {
      const miBand = DiscoveredBleDevice(
        id: 'F1:E7:67:00:00:6C',
        name: 'Mi Smart Band 5',
        rssi: -52,
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb', '180d'],
      );
      expect(miBand.isMiBand, isTrue);
      expect(miBand.hasHeartRate, isTrue);
      expect(miBand.hasPulsePatch, isFalse);
      expect(miBand.isCompatible, isTrue);

      const pulsePatch = DiscoveredBleDevice(
        id: 'AA:BB:CC:00:00:11',
        name: 'PulsePatch-C3',
        rssi: -42,
        advertisedServices: ['180d0000-7243-4e64-8843-50554c534531'],
      );
      expect(pulsePatch.hasPulsePatch, isTrue);
      expect(pulsePatch.isMiBand, isFalse);
      expect(pulsePatch.isCompatible, isTrue);

      const unknownDev = DiscoveredBleDevice(
        id: '11:22:33:00:00:44',
        name: 'Wireless Buds',
        rssi: -70,
        advertisedServices: ['180f'],
      );
      expect(unknownDev.hasHeartRate, isFalse);
      expect(unknownDev.hasPulsePatch, isFalse);
      expect(unknownDev.isMiBand, isFalse);
      expect(unknownDev.isCompatible, isFalse);
    });

    test(
      'SimulatedHeartRateSource executes idle -> scanning -> connecting -> connected/streaming state sequence',
      () async {
        final sim = SimulatedHeartRateSource();
        final states = <BleConnectionState>[];
        final sub = sim.connectionStateStream.listen(states.add);

        expect(sim.currentState, BleConnectionState.idle);

        await sim.startScan();
        expect(sim.currentState, BleConnectionState.scanning);

        await sim.connect('sim-sample');
        expect(sim.currentState, BleConnectionState.connected);

        await sim.disconnect();
        expect(sim.currentState, BleConnectionState.disconnected);

        await Future.delayed(const Duration(milliseconds: 20));
        await sub.cancel();
        sim.dispose();

        expect(
          states,
          containsAllInOrder([
            BleConnectionState.scanning,
            BleConnectionState.connecting,
            BleConnectionState.connected,
            BleConnectionState.disconnected,
          ]),
        );
      },
    );

    test('DiscoveredBleDevice displayName fallback rules', () {
      const dev1 = DiscoveredBleDevice(id: '1', name: '', rssi: -60);
      expect(dev1.displayName, 'Unnamed device');

      const dev2 = DiscoveredBleDevice(id: '2', name: '   ', rssi: -60);
      expect(dev2.displayName, 'Unnamed device');

      const dev3 = DiscoveredBleDevice(
        id: '3',
        name: 'BLE Device ()',
        rssi: -60,
      );
      expect(dev3.displayName, 'Unnamed device');

      const dev4 = DiscoveredBleDevice(id: '4', name: '()', rssi: -60);
      expect(dev4.displayName, 'Unnamed device');

      const dev5 = DiscoveredBleDevice(id: '5', name: 'Polar H10', rssi: -60);
      expect(dev5.displayName, 'Polar H10');
    });

    test('DiscoveredBleDevice detects Nordic UART and compatibility', () {
      const dev = DiscoveredBleDevice(
        id: 'AA:BB:CC:11:22:33',
        name: 'ESP32_HR',
        rssi: -65,
        advertisedServices: ['6e400001-b5a3-f393-e0a9-e50e24dcca9e'],
      );
      expect(dev.hasNordicUart, isTrue);
      expect(dev.isCompatible, isTrue);
    });

    test('Device sorting: compatible first, then descending RSSI', () {
      final devices = [
        const DiscoveredBleDevice(
          id: 'A',
          name: 'Buds',
          rssi: -40, // strong RSSI but incompatible
          advertisedServices: ['180f'],
        ),
        const DiscoveredBleDevice(
          id: 'B',
          name: 'Polar H10',
          rssi: -75, // weak RSSI but compatible
          advertisedServices: ['180d'],
        ),
        const DiscoveredBleDevice(
          id: 'C',
          name: 'PulsePatch-C3',
          rssi: -50, // medium RSSI and compatible
          advertisedServices: ['7243-4e64'],
        ),
      ];

      devices.sort((a, b) {
        if (a.isCompatible != b.isCompatible) {
          return a.isCompatible ? -1 : 1;
        }
        return b.rssi.compareTo(a.rssi);
      });

      expect(devices[0].id, 'C'); // Compatible (-50 dBm)
      expect(devices[1].id, 'B'); // Compatible (-75 dBm)
      expect(devices[2].id, 'A'); // Incompatible (-40 dBm)
    });

    test('Device filtering: HR only filters out non-compatible devices', () {
      final devices = [
        const DiscoveredBleDevice(
          id: 'A',
          name: 'Buds',
          rssi: -40,
          advertisedServices: ['180f'],
        ),
        const DiscoveredBleDevice(
          id: 'B',
          name: 'Polar H10',
          rssi: -75,
          advertisedServices: ['180d'],
        ),
        const DiscoveredBleDevice(
          id: 'C',
          name: 'Nordic UART Sensor',
          rssi: -60,
          advertisedServices: ['6e400001-...'],
        ),
      ];

      final filtered = devices.where((d) => d.isCompatible).toList();
      expect(filtered.length, 2);
      expect(filtered.map((d) => d.id).toList(), ['B', 'C']);
    });

    test('De-duplication by uppercase remote ID', () {
      final map = <String, DiscoveredBleDevice>{};
      final dev1 = const DiscoveredBleDevice(
        id: 'aa:bb:cc:dd:ee:ff',
        name: 'Dev',
        rssi: -60,
      );
      final dev2 = const DiscoveredBleDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'Dev Named',
        rssi: -55,
      );

      map[dev1.id.toUpperCase()] = dev1;
      map[dev2.id.toUpperCase()] = dev2;

      expect(map.length, 1);
      expect(map['AA:BB:CC:DD:EE:FF']?.name, 'Dev Named');
    });

    test(
      'Connection state transition sequence emulates descriptor write refusal (blocked status)',
      () async {
        final stateController =
            StreamController<BleConnectionState>.broadcast();
        final observedStates = <BleConnectionState>[];
        final sub = stateController.stream.listen(observedStates.add);

        // Emulate connection handshake:
        // 1. Scanning
        stateController.add(BleConnectionState.scanning);
        // 2. Connecting
        stateController.add(BleConnectionState.connecting);
        // 3. Connected
        stateController.add(BleConnectionState.connected);
        // 4. Discovering services
        stateController.add(BleConnectionState.discovering);
        // 5. Subscribing to 0x2A37
        stateController.add(BleConnectionState.subscribing);
        // 6. Descriptor write (0x2902) rejected with GATT 3 (WRITE_NOT_PERMITTED) -> Blocked
        stateController.add(BleConnectionState.blocked);
        // 7. Auto-disconnect cleanly
        stateController.add(BleConnectionState.disconnected);

        await Future.delayed(const Duration(milliseconds: 20));

        expect(observedStates, [
          BleConnectionState.scanning,
          BleConnectionState.connecting,
          BleConnectionState.connected,
          BleConnectionState.discovering,
          BleConnectionState.subscribing,
          BleConnectionState.blocked,
          BleConnectionState.disconnected,
        ]);

        await sub.cancel();
        await stateController.close();
      },
    );

    test(
      'Connection state transition sequence emulates successful streaming',
      () async {
        final stateController =
            StreamController<BleConnectionState>.broadcast();
        final observedStates = <BleConnectionState>[];
        final sub = stateController.stream.listen(observedStates.add);

        stateController.add(BleConnectionState.connecting);
        stateController.add(BleConnectionState.connected);
        stateController.add(BleConnectionState.discovering);
        stateController.add(BleConnectionState.subscribing);
        stateController.add(BleConnectionState.streaming);

        await Future.delayed(const Duration(milliseconds: 20));

        expect(observedStates, [
          BleConnectionState.connecting,
          BleConnectionState.connected,
          BleConnectionState.discovering,
          BleConnectionState.subscribing,
          BleConnectionState.streaming,
        ]);

        await sub.cancel();
        await stateController.close();
      },
    );

    test(
      'Connection state transition sequence emulates reconnecting backoff',
      () async {
        final stateController =
            StreamController<BleConnectionState>.broadcast();
        final observedStates = <BleConnectionState>[];
        final sub = stateController.stream.listen(observedStates.add);

        stateController.add(BleConnectionState.streaming);
        stateController.add(BleConnectionState.disconnected);
        stateController.add(BleConnectionState.reconnecting);
        stateController.add(BleConnectionState.connecting);
        stateController.add(BleConnectionState.connected);
        stateController.add(BleConnectionState.streaming);

        await Future.delayed(const Duration(milliseconds: 20));

        expect(observedStates, [
          BleConnectionState.streaming,
          BleConnectionState.disconnected,
          BleConnectionState.reconnecting,
          BleConnectionState.connecting,
          BleConnectionState.connected,
          BleConnectionState.streaming,
        ]);

        await sub.cancel();
        await stateController.close();
      },
    );
  });
}
