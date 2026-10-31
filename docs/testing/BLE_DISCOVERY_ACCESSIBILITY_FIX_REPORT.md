# PULSEPATCH NEXT GENERATION — BLE DISCOVERY ACCESSIBILITY FIX REPORT

**Date:** 2026-10-31  
**Target Package:** `com.pulsepatch.lite.app`  
**Application Version:** `1.0.0+1`  
**Physical Validation Device:** `HONOR NIC-LX2` (Honor X8b)  
**Android OS:** Android 15 (API level 35)  
**ADB Serial:** `A9VUCP5A08407069`  
**Test Suite Status:** 402 passing tests (0 failures)  
**Flutter Static Analysis:** 0 issues found  

---

## 1. Executive Summary & Root Cause Analysis

A critical user discovery failure was investigated: users were unable to find any visible screen or navigation entry point to initiate Bluetooth Low Energy (BLE) scanning and peripheral pairing.

### Root Cause Diagnosis
1. **Isolated Widget Route:** `ConnectDeviceScreen` was previously rendered exclusively when `AppView.device` was activated in `AppShell`. However, no visible button or primary navigation entry point existed in the main user journey.
2. **Obscure Home Trigger:** The only trigger on the Home dashboard was a minuscule text chip (`StatusChip`) labeled "Not connected", which lacked a Bluetooth icon, button affordance, or call-to-action indication.
3. **Missing Monitoring Trigger:** The Monitoring / History screen (`MeasurementHistoryScreen`) had **no connection mechanism whatsoever**. If a user navigated to history to take or view measurements, there was zero indication of how to pair a sensor.
4. **Overly Restrictive BLE Filter:** In `ConnectDeviceScreen`, `_filterOnlyHeartRate` was initialized to `true` by default (`bool _filterOnlyHeartRate = true;`). Most surrounding BLE peripherals (smartwatches, ESP32 prototypes not broadcasting 0x180D in primary advert) were filtered out immediately, presenting an empty list and misleading users into believing the scanner was broken.
5. **No System Back Interception:** When `ConnectDeviceScreen` was shown via `AppView.device`, pressing the Android hardware/gesture back button did not transition back to `AppView.home`, causing unexpected app exits.

---

## 2. Engineering Modifications & Implementation

### A. Prominent Device Connection Card on Home (`HomeScreen`)
- File: [home_screen.dart](file:///e:/pulse%20patch/app/lib/features/home/home_screen.dart)
- Widget: `MetricCard(key: Key('home_device_connection_card'))`
- Positioned immediately beneath the header row and above the quick status chips.
- Dynamic States:
  - **Not Connected:** Gray Bluetooth icon, "Not Connected" badge, subtitle *"Tap to discover and pair your sensor"*, prominent "Pair" pill button.
  - **Scanning:** Pulsing cyan Bluetooth search icon, "Scanning..." badge, subtitle *"Scanning nearby BLE sensors..."*.
  - **Connecting:** Cyan audio icon, "Connecting" badge.
  - **Connected:** Emerald green icon, "Connected" badge, green checkmark indicator.
- Bilingual Support: Automatically respects RTL Arabic (`'اتصال بجهاز PulsePatch'`, `'اقتران'`) and LTR English.

### B. Persistent Connection Banner on Monitoring Screen (`MeasurementHistoryScreen`)
- File: [measurement_history_screen.dart](file:///e:/pulse%20patch/app/lib/features/history/measurement_history_screen.dart)
- Widget: `MetricCard(key: Key('monitoring_connect_device_card'))`
- Displays whenever `bleSource.currentState != BleConnectionState.connected && bleSource.currentState != BleConnectionState.streaming`.
- Features Bluetooth radar icon, clear explanation *"PulsePatch Sensor Not Connected — Pair with hardware sensor for live PPG telemetry"*, and a white "Connect" (`'ربط الجهاز'`) pill button directly opening `ConnectDeviceScreen`.

### C. Standard Android Navigation & PopScope (`AppShell` & `ConnectDeviceScreen`)
- Files: [app_shell.dart](file:///e:/pulse%20patch/app/lib/features/home/app_shell.dart), [connect_device_screen.dart](file:///e:/pulse%20patch/app/lib/features/device/connect_device_screen.dart)
- Wrapped in `PopScope(canPop: true, onPopInvokedWithResult: ...)` to guarantee that Android hardware back button and edge swipe gestures return seamlessly to the Home dashboard (`_currentView = AppView.home; _navIndex = 0;`) rather than exiting the application.
- Top-left `CircleIconButton` correctly pops or invokes `onBack` callback.

### D. Universal BLE Discovery & Adapter Governance (`ConnectDeviceScreen`)
- File: [connect_device_screen.dart](file:///e:/pulse%20patch/app/lib/features/device/connect_device_screen.dart)
- Default filter changed to `bool _filterOnlyHeartRate = false;`, immediately displaying all surrounding BLE peripherals while sorting compatible devices to the top.
- **Dedicated Start/Stop Scan Button:** Added `PillButton(key: Key('ble_scan_toggle_button'))` allowing users to explicitly start or stop scanning without having to guess that the radar illustration is interactive.
- **Bluetooth Adapter State Listener:** Monitored via `FlutterBluePlus.adapterState`. If Bluetooth is disabled, a red warning banner appears (`Key('ble_bluetooth_off_banner')`) with a one-touch **"Turn On"** action calling `FlutterBluePlus.turnOn()`.
- **Runtime Permissions Safeguard:** Requests `Permission.bluetoothScan`, `Permission.bluetoothConnect`, and fallback `Permission.locationWhenInUse` for legacy Android compatibility.

### E. Precise GATT Contract Subscription (`PulsePatchSource`)
- File: [pulse_patch_source.dart](file:///e:/pulse%20patch/app/lib/features/device/pulse_patch_source.dart)
- Subscribes to custom GATT UUIDs:
  - Custom Service: `180D0000-7243-4E64-8843-50554C534531`
  - Heart Rate Characteristic: `180D0001-7243-4E64-8843-50554C534531`
  - Optical PPG Characteristic: `180D0002-7243-4E64-8843-50554C534531` (now subscribed with separate `_opticalSubscription` and parsed into `opticalWaveformStream`).
  - Device Info Characteristic: `180D0003-7243-4E64-8843-50554C534531`
- Clean teardown in `_handleDisconnect()` and `disconnect()`.

---

## 3. Verification & Quality Gate Results

### Automated Regression Tests
- Created new test file: [ble_discovery_navigation_test.dart](file:///e:/pulse%20patch/app/test/ble_discovery_navigation_test.dart)
  - `HomeScreen renders prominent device connection card and triggers onOpenDevice`: **PASSED**
  - `MeasurementHistoryScreen renders prominent connection banner when disconnected`: **PASSED**
  - `ConnectDeviceScreen renders prominent BLE scan toggle button and scanner header`: **PASSED**
- Full test suite: **402 passed**, **0 failed**.
- Flutter Analyzer: **0 issues found**.

### Release Artifact Information
- **Output Path:** `app/build/app/outputs/flutter-apk/app-release.apk`
- **File Size:** `68,310,820 bytes` (65.1 MB)
- **SHA-256 Checksum:** `DA108D9A7155FAECF5A85DB22E37100BAB7A4178A9394835825AE601EE592ACA`
- **Streamed Installation on `A9VUCP5A08407069`:** `Success` (data and database preserved).

---

## 4. Evidence Artifacts

The following photographic proof was captured directly from the physical HONOR NIC-LX2:
1. `docs/phone_test/evidence/phone_10_home_connection_card.png` (936 KB) — Home screen showing prominent "Connect PulsePatch Device" card with "Not Connected" status badge.
2. `docs/phone_test/evidence/phone_11_monitoring_connection_banner.png` (1.18 MB) — Monitoring screen showing prominent "PulsePatch Sensor Not Connected" banner with action button.
3. `docs/phone_test/evidence/phone_12_ble_discovery_scanning.png` (744 KB) — Connect Device screen showing active radar scanner and explicit "Start/Stop BLE Scan" controls.
