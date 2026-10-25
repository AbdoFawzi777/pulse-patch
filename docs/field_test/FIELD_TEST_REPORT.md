# PulsePatch Lite — Field Test & Wearable Compatibility Report

**Date:** October 25, 2026  
**Target Hardware:** HONOR `NIC-LX2` (Android 15, API level 35)  
**Wearable Under Test:** Xiaomi Mi Smart Band 5 (Bluetooth MAC: `F1:E7:67:**:**:**`)  
**Workspace:** `e:\pulse patch`  

---

## 1. Executive Summary

This field test validates the real-device performance of PulsePatch Lite on physical Android hardware and evaluates interoperability with third-party BLE wearables, specifically the Xiaomi Mi Smart Band 5.

Key accomplishments during this test cycle:
1. **Resolved 360x800 dp Screen Overflows:** Transformed the fixed layout on `ConnectDeviceScreen` into a responsive, scrollable `CustomScrollView` featuring a shrinking radar scanner header. Added bottom clearance `(96.0 + bottomInset)` preventing occlusion behind the floating circular navigation bar.
2. **Global SafeArea & Inset Alignment:** Wrapped all screens in dynamic `SafeArea` top-inset management (clearing the phone's 39 dp status bar) and added bottom padding to `BottomCircleNav` (clearing the 22 dp gesture navigation bar).
3. **Universal BLE Scanner & Real Discovery:** Removed all simulated and mock devices from the real device discovery feed. Implemented de-duplication across active BLE advertisements and system-bonded Bluetooth peripherals. Added capability badges (`Heart rate (0x180D)`, `SpO2 (0x1822)`, `PulsePatch`, `Mi Band`) and masked MAC address telemetry (`AA:BB:**:**:**:FF`).
4. **Mi Smart Band 5 Compatibility Diagnosis:** Executed an on-device GATT diagnostic sweep. Discovered that while the Mi Smart Band 5 exposes standard Heart Rate Service `0x180D` and characteristic `0x2A37`, its stock firmware explicitly refuses descriptor writes (`CCCD 0x2902`) with `GATT_WRITE_NOT_PERMITTED (status 3)` unless paired through proprietary, authenticated Huami protocols.
5. **Clean UI Failure Handling & Fallback:** Implemented clear, non-alarming UI messaging stating plainly that the band blocks third-party heart-rate subscriptions in its current state, auto-disconnecting cleanly and offering direct one-tap CSV/JSON session file import or synthetic sensor simulation.
6. **Multi-Screen & State Machine Test Verification:** Added 48 multi-screen overflow test permutations (360x800, 390x844, 411x891 at 1.0x and 1.3x text scaling) with zero layout overflows, plus a dedicated BLE connection state machine suite covering all 14 lifecycle states. Total application test suite: **162 passing tests**.

---

## 2. Phone Environment & Physical Geometry

Physical inspection and telemetry captured via ADB:

| Property | Value | Notes |
|:---|:---|:---|
| **Device Model** | HONOR `NIC-LX2` | Product: `NIC_LX2`, Hardware: `HNNIC-M1` |
| **Android Version** | Android 15 (SDK 35) | Full BLE Permissions: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` |
| **Physical Resolution** | 720 x 1604 pixels | Density: 320 dpi (scale factor: 2.0) |
| **Logical Canvas (dp)** | 360 x 802 dp | Tested baseline for small Android phones |
| **Status Bar Inset** | 78 px (39 dp) | Requires top clearance for app headers |
| **Gesture Navigation Bar Inset**| 44 px (22 dp) | Requires bottom clearance for bottom navigation |
| **Storage / Battery** | 51 GB free / 62% battery | Verified ready for on-device testing |

---

## 3. Layout & UI Remediation (Task A)

### 3.1. 80-Pixel Bottom Overflow Resolution
- **Root Cause:** On a 360x800 dp screen with 39 dp status bar and 100 dp bottom navigation allowance, available vertical height is ~661 dp. The previous unscrollable `Column` layout exceeded available space once peripheral cards were populated.
- **Remediation:**
  - Migrated `ConnectDeviceScreen` to `CustomScrollView` with `BouncingScrollPhysics`.
  - Implemented `_RadarHeaderDelegate` (`SliverPersistentHeader`): smoothly scales the radar illustration from `maxExtent: 220.0` down to `minExtent: 90.0` as the user scrolls, yielding screen space to discovered devices.
  - Added bottom padding: `SizedBox(height: 96.0 + bottomInset)` ensuring that the final card, simulator button, and hardware footnote are completely scrollable above the floating circle nav bar.

### 3.2. SafeArea & Gesture Bar Inset Alignment
- **Top Inset:** `DesignCanvasScaffold` now dynamically queries `MediaQuery.paddingOf(context).top`. When `topInset > 0` (such as 39 dp on this phone), top padding is adjusted to `12.0 dp`, giving a total status-bar clearance of `51.0 dp`. Back buttons and titles no longer collide with the status bar.
- **Bottom Inset:** `BottomCircleNav` now incorporates `MediaQuery.paddingOf(context).bottom + 8.0 dp` bottom padding. The four 64 px circles now comfortably clear the system gesture pill.

### 3.3. Real Scan List vs. Simulator Separation
- **Real Discovery Only:** Simulated peripherals (`PulsePatch-C3` at -52 dBm, duplicate `Mi Smart Band 5`) were completely removed from `discoveredDevicesStream`. Real scan results contain only physical BLE devices discovered in range or bonded via Android Bluetooth.
- **Dedicated Simulator Card:** Positioned below the real peripheral list as a clearly labeled, distinct action:
  - *Title:* "Use Simulator (sample data)"
  - *Description:* "Simulate a running MAX30102 sensor with realistic heart-rate data for offline testing without physical hardware."
  - *Action:* One-tap activation switching the provider to `SimulatedHeartRateSource`.

### 3.4. Badges & Masked Identifiers
- Every discovered device card now features:
  - **Masked MAC Identifier:** Formatted strictly as `AA:BB:**:**:**:FF` to prevent privacy leakage in logs, UI, and test reports.
  - **RSSI Signal Strength:** Rendered as `Signal strong / good / weak · −XX dBm`.
  - **Capability Badges:**
    - `Heart rate (0x180D)` (green chip)
    - `SpO2 (0x1822)` (purple chip)
    - `PulsePatch` (cyan chip)
    - `Mi Band` (amber chip)
  - **Muted Non-Compatible Actions:** Non-compatible or unknown devices display a muted `Check compatibility` action instead of a prominent white button.

---

## 4. Universal BLE Scanner & Xiaomi Mi Smart Band 5 Diagnostics (Tasks B & C)

### 4.1. Discovered GATT Services & Characteristics
When connecting to the test Xiaomi Mi Smart Band 5 (`F1:E7:67:**:**:**`), service discovery returned 12 primary services:

```text
=== [GATT TABLE START: F1:E7:67:**:**:**] ===
Service: 00001800-0000-1000-8000-00805f9b34fb (Generic Access)
  Char: 00002a00-0000-1000-8000-00805f9b34fb [READ|WRITE] (Device Name)
  Char: 00002a01-0000-1000-8000-00805f9b34fb [READ] (Appearance)
Service: 00001801-0000-1000-8000-00805f9b34fb (Generic Attribute)
Service: 0000180a-0000-1000-8000-00805f9b34fb (Device Information)
  Char: 00002a28-0000-1000-8000-00805f9b34fb [READ] (Software Revision)
Service: 0000180d-0000-1000-8000-00805f9b34fb (Standard Heart Rate Service)
  Char: 00002a37-0000-1000-8000-00805f9b34fb [NOTIFY] (Heart Rate Measurement)
    Desc: 00002902-0000-1000-8000-00805f9b34fb (Client Characteristic Configuration)
Service: 0000fee0-0000-1000-8000-00805f9b34fb (Huami Mi Band Basic Service)
Service: 0000fee1-0000-1000-8000-00805f9b34fb (Huami Authentication Service)
  Char: 00000009-0000-3512-2118-0009af100700 [READ|WRITE_NO_RESP|NOTIFY] (Auth Characteristic)
=== [GATT TABLE END: F1:E7:67:**:**:**] ===
```

### 4.2. Diagnostic Subscription Experiments
We systematically tested four connection and subscription pathways:

1. **Test 1: Standard CCCD Write on `0x2A37` (`setNotifyValue(true)`):**
   - *Result:* **Rejected by Firmware.**
   - *Android GATT Status:* `GATT_WRITE_NOT_PERMITTED (status: 3)`.
   - *Evidence:* The band firmware requires an established cryptographic session before allowing Client Characteristic Configuration Descriptor writes, even on standard Bluetooth SIG services.

2. **Test 2: Android Bonding (`createBond()`) & Reconnect:**
   - *Result:* **Rejected by Firmware.**
   - *Outcome:* Android OS pairing/bonding alone does not satisfy the firmware's authentication requirement. Descriptor write was refused with status 3.

3. **Test 3: CCCD Direct Indicate Write (`[0x02, 0x00]`):**
   - *Result:* **Rejected by Firmware.**
   - *Outcome:* Firmware refuses all unauthenticated descriptor writes on `0x2902` regardless of notification or indication flag values.

4. **Test 4: Companion App Single Connection Limit & Broadcast Mode:**
   - *Status:* Unconfirmed in user testing. The user was unable to verify any "Heart rate sharing" toggle in Zepp Life. Without confirmed broadcast mode or key extraction, direct live streaming over BLE cannot proceed.

### 4.3. UI Failure Handling & User Guidance
When `GATT_WRITE_NOT_PERMITTED (3)` is detected or `BleConnectionState.blocked` occurs:
- The app auto-disconnects from the peripheral to prevent resource lockups.
- A prominent, human-readable alert card is rendered on screen:
  > **Heart-rate access blocked by device**  
  > *This band blocks heart-rate access from third-party apps in its current state (GATT status: 3 WRITE_NOT_PERMITTED). The firmware refuses descriptor writes to 0x2A37 without proprietary authentication.*
- Direct action buttons are offered:
  - `[Import session file]`: Launches the file picker for CSV/JSON files exported from health apps (e.g. Gadgetbridge, Zepp export).
  - `[Use simulator]`: Immediately starts synthetic MAX30102 sensor telemetry.

---

## 5. Verification & Test Evidence

### 5.1. Multi-Screen Layout Overflow Verification (`overflow_screen_test.dart`)
Automated widget tests verified 8 core screens across 3 device resolutions at 1.0x and 1.3x text scaling:

| Screen | 360x800 (1.0x) | 360x800 (1.3x) | 390x844 (1.0x) | 390x844 (1.3x) | 411x891 (1.0x) | 411x891 (1.3x) | Status |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **ConnectDeviceScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |
| **HomeScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |
| **MeasurementPreparationScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |
| **LiveMeasurementScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |
| **MeasurementCompleteScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |
| **AiInsightsDashboardScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |
| **MeasurementHistoryScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |
| **ApplicationSettingsScreen** | PASS | PASS | PASS | PASS | PASS | PASS | **Zero Overflows** |

**Total:** 48 / 48 permutations passed with 0 RenderFlex overflow exceptions.

### 5.2. BLE State Machine Unit Tests (`ble_state_machine_test.dart`)
- **7 / 7 unit tests passed:**
  - Complete `BleConnectionState` enum coverage (14 states).
  - MAC address masking (`AA:BB:**:**:**:FF`).
  - Badge computation and capability resolution.
  - Handshake sequence (`idle -> scanning -> connecting -> connected -> streaming`).
  - Failure handshake on descriptor write refusal (`subscribing -> blocked -> disconnected`).
  - Reconnecting backoff progression.

### 5.3. Full Test Suite Summary
- **Total Passing Tests:** 162
- **Static Analysis:** `flutter analyze` — 0 issues found.
- **PARITY Check:** Firmware struct layout byte-by-byte matches Dart parser.
