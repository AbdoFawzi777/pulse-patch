# PulsePatch Lite — Phone to ESP32-C3 Physical BLE Integration & Validation Guide

**Document Identification:** GDE-BLE-INTEG-V2.1  
**App Version:** 2.1.0  
**Target Mobile Hardware:** Physical Android Phone (`HONOR NIC-LX2`, Android 15, API 35)  
**Target Sensor Peripheral:** Espressif ESP32-C3 RISC-V SoC + Maxim Integrated MAX30102  
**Validation Status:** **APP READY ON PHYSICAL PHONE · HARDWARE INTEGRATION PENDING PHYSICAL BREADBOARD CONNECTION**  
**Date:** 2026-10-31  

---

## 1. Physical BLE Validation Boundary

To maintain complete scientific and engineering integrity:

> [!IMPORTANT]
> **PHYSICAL HARDWARE INTEGRATION BOUNDARY:**  
> The PulsePatch mobile app is fully installed, executing, and validated on a physical Android phone (`HONOR NIC-LX2`).  
> **Physical BLE telemetry testing cannot be claimed as passed until the physical ESP32-C3 + MAX30102 breadboard is powered on and advertising the custom PulsePatch GATT service.**  
> Commercial wearables (such as Xiaomi Smart Band, Apple Watch, or generic heart rate straps) advertise standard Bluetooth SIG profiles (`0x180D` 16-bit UUID with 2-byte flags/BPM payloads) and **CANNOT** be substituted for the custom 12-byte little-endian dual-wavelength protocol (`180D0000-7243-4E64-8843-50554C534531`).

---

## 2. End-to-End BLE Communication Contract

```
+-------------------------------------------------------------------------------+
|                      PHYSICAL BLE COMMUNICATION CONTRACT                      |
+-------------------------------------------------------------------------------+
|                                                                               |
|   [ Physical Phone: HONOR NIC-LX2 ]            [ Hardware: ESP32-C3 + MAX ]   |
|   - Android 15 (API 35) BLE Central            - BLE 5.0 GATT Peripheral      |
|   - FlutterBluePlus 2.3.14                     - NimBLE Arduino Stack         |
|   - Filters by Service:                        - Advertises Local Name:       |
|     180D0000-7243-4E64-8843-50554C534531         "PulsePatch Lite"            |
|                                                                               |
|   1. BLE GAP Scan -----------------------------> Detects Adv (RSSI > -85dBm)  |
|   2. Connect Request --------------------------> Accepts Connection           |
|   3. Discover Services ------------------------> Exposes 128-bit Custom GATT  |
|   4. Enable CCCD Notifications (0x2902) -------> Streams 12-byte Packets      |
|                                                                               |
|   [ CHAR_RAW_SAMPLES: 180D0002-... ] <--------- 25 Hz IR + Red (12 Bytes)     |
|   [ CHAR_HR_MEASUREMENT: 180D0001-... ] <------- 1 Hz Processed BPM (12 Bytes) |
+-------------------------------------------------------------------------------+
```

---

## 3. Step-by-Step Benchtop Hardware Integration Procedure

When the hardware team has completed assembling the ESP32-C3 and MAX30102 on the breadboard:

### Step 1: Bench Power & Firmware Verification
1. Connect ESP32-C3 to PC USB port.
2. Confirm MAX30102 power rail is strictly **3.3V DC** (measure with multimeter across VDD and GND).
3. Open serial monitor at 115200 baud:
   ```
   [INFO] PulsePatch Lite Firmware v2.0.0-esp32c3 starting...
   [INFO] I2C initialized on SDA: GPIO4, SCL: GPIO5
   [INFO] MAX30102 detected at 0x57 (Part ID: 0x15)
   [INFO] BLE Advertising started as 'PulsePatch Lite'
   ```

### Step 2: Discovery from Physical Android Phone
1. Ensure Bluetooth and Location are toggled `ON` in the phone's Quick Settings.
2. Launch `com.pulsepatch.lite.app` on the phone.
3. On the Home screen, tap **"No device connected"** or open the **Connect Device** screen.
4. Tap **"Start Scan"**.
5. Verify that `"PulsePatch Lite"` appears in the discovered peripheral list with RSSI indicator.

### Step 3: Pairing & Telemetry Streaming
1. Tap **"Connect"** on the discovered device tile.
2. Verify status badge updates to **"Connected"** (accent cyan).
3. Navigate to **Monitoring** > tap **"Record"** to enter **Live Measurement**.
4. Place clean finger on MAX30102 optical sensor:
   - Verify Red & IR LEDs illuminate.
   - Observe live real-time PPG waveform rendering on the phone screen.
   - Observe Heart Pulse indicator pulsing synchronously with cardiac cycles.
   - Verify SpO2 percentage reading stabilizes between 96% and 99%.

### Step 4: Drop Detection & Disconnect Handling
1. Remove finger from sensor:
   - Confirm app transitions to "Finger Contact Lost" prompt.
2. Power off ESP32-C3:
   - Verify phone displays "Connection Lost / Reconnecting" banner.
   - Re-power ESP32-C3; verify auto-reconnect succeeds within 5 seconds.

---

## 4. Current State & Handoff Declaration

- **Physical Android Phone Software:** **100% READY & VERIFIED**
- **ESP32-C3 Firmware Binary:** **100% READY IN REPOSITORY**
- **Physical Sensor Hardware Telemetry:** **PENDING PHYSICAL BREADBOARD POWER-ON**
