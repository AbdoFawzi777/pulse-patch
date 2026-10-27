# PulsePatch Lite — Hardware Bring-Up Checklist

> [!WARNING]
> This checklist is for physical hardware bring-up of the **ESP32-C3 DevKitM-1 + MAX30102** sensor patch.
> The software stack is verified end-to-end on a physical phone with simulated BLE transport.
> Physical ESP32-C3 + MAX30102 breadboard testing has **NOT** been performed yet.

---

## 1. Parts & Prerequisites

| Item | Specification / Requirement | Notes |
|---|---|---|
| **Microcontroller** | Espressif ESP32-C3 DevKitM-1 (RISC-V single-core @ 160 MHz) | Any ESP32-C3 board with exposed I2C GPIOs |
| **PPG Sensor** | Maxim Integrated MAX30102 Optical Heart Rate & Pulse Oximeter Module | **3.3 V supply ONLY — 5 V damages module** |
| **Cabling** | 4-pin Female-to-Female or Female-to-Male DuPont jumper wires | SDA, SCL, 3.3V, GND |
| **Host PC** | Windows / Linux / macOS with PlatformIO Core (`pio`) installed | USB-C data cable connected to ESP32-C3 |
| **Mobile Client** | Android phone (API 26+) with `app-release.apk` installed | Bluetooth and Location/Nearby permissions enabled |

---

## 2. Breadboard Wiring Diagram

> [!CAUTION]
> **VCC MUST BE CONNECTED TO 3.3 V ONLY.** Connecting MAX30102 VCC to 5 V (VIN) can destroy the optical sensor and the ESP32-C3 I2C pins.

```
MAX30102 Sensor Module             ESP32-C3 DevKitM-1
┌───────────────────────┐          ┌───────────────────────┐
│                   VIN │──────────│ 3V3 (Pin 3.3V)        │  <-- 3.3V ONLY!
│                   GND │──────────│ GND (Ground)          │
│                   SDA │──────────│ GPIO4 (I2C SDA)       │
│                   SCL │──────────│ GPIO5 (I2C SCL)       │
│                   INT │   N/C    │ (Unused in Firmware)  │
│                   IRD │   N/C    │ (Unused in Firmware)  │
│                    RD │   N/C    │ (Unused in Firmware)  │
└───────────────────────┘          └───────────────────────┘
```

---

## 3. Step-by-Step Bring-Up Procedure

### Step 1 — I2C Bus Address Scan
- **Command:**
  ```bash
  cd firmware
  pio run -e esp32-c3-devkitm-1-i2c-scanner -t upload
  pio device monitor --baud 115200
  ```
- **Expected Serial Output:**
  ```
  [I2C SCANNER] Starting scan on SDA=GPIO4, SCL=GPIO5...
  [I2C SCANNER] Found device at 0x57
  [I2C SCANNER] Scan complete. Found 1 device(s).
  ```
- **Pass Criteria:** Device found at address `0x57` (MAX30102 standard 7-bit address).
- **Fail Action:** If 0 devices found, disconnect USB immediately and inspect SDA (GPIO4), SCL (GPIO5), and 3.3V power rails.

### Step 2 — Optical Sensor Raw Stream Calibration (`DEBUG_RAW`)
- **Command:**
  ```bash
  pio run -e esp32-c3-devkitm-1-debug-raw -t upload
  pio device monitor --baud 115200
  ```
- **Expected Serial Output (CSV Format):**
  ```
  # millis,ir,red,filtered_bpm,bpm,sqi,flags
  1000,68450,54210,72.40,72.4,85,1
  2000,69120,54890,72.10,72.1,88,1
  ```
- **Pass Criteria:** IR readings increase above `50,000` when a finger is placed on the lens; flags show `1` (contact detected); SQI > 60.
- **Fail Action:** If IR remains near 0, verify LED current in `firmware/include/pulse_config.h` (`LED_CURRENT_MA 6`).

### Step 3 — Standard Firmware Flash & BLE Advertising
- **Command:**
  ```bash
  pio run -e esp32-c3-devkitm-1 -t upload
  pio device monitor --baud 115200
  ```
- **Expected Serial Output:**
  ```
  ==================================================
  PulsePatch Lite — ESP32-C3 Firmware v1.0.0-esp32c3
  Strictly Educational Biomonitoring Device
  ==================================================
  [SENSOR] SUCCESS: MAX30102 detected.
  [BLE] Advertising started. Waiting for PulsePatch mobile client...
  ```
- **Pass Criteria:** Firmware boots without panic; advertising begins on service UUID `180D0000-7243-4E64-8843-50554C534531`.

### Step 4 — Mobile App Discovery & Pairing
1. Launch `PulsePatch Lite` on Android phone.
2. Tap **Connect Device** from the bottom navigation bar.
3. Verify that `PulsePatch Lite` appears in the scanned device list with RSSI > -80 dBm.
4. Tap the device card to establish GATT connection.
- **Pass Criteria:** App shows "Connected" status; device detail sheet displays firmware version `1.0.0-esp32c3`.

### Step 5 — Live Measurement & Telemetry Diagnostics
1. In the app, navigate to **Settings > About**.
2. Tap the version label **7 times** to open the **BLE Diagnostics** screen.
3. Verify incoming packet rate: `~1.0 pkts/sec`.
4. Check that sequence gaps = 0 and parse rejections = 0.
5. Place finger gently on sensor: verify raw 12-byte hex updates every second and decoded BPM is within physiological range (40–180 BPM).

---

## 4. Hardware Troubleshooting Matrix

| Symptom | Probable Cause | Corrective Action |
|---|---|---|
| I2C Scanner reports 0 devices | Inverted SDA/SCL or bad jumper wire | Swap GPIO4 and GPIO5 connections; test continuity with multimeter |
| MAX30102 module gets hot | 5V supply connected instead of 3.3V | **Disconnect immediately.** MAX30102 requires 3.3V or 1.8V logic |
| `0xFFFF` BPM reported continuously | Insufficient perfusion or finger not detected | IR count < 50,000; ensure finger is centered directly over the optical aperture |
| SQI consistently < 60% | Motion artifacts or excessive ambient light | Shield sensor from direct sunlight; keep hand relaxed on a flat surface |
| Packet parse rejected in app | Firmware/app packet protocol version mismatch | Verify `BLE_PROTOCOL_VERSION 1` in `pulse_config.h` and `ble_packet.dart` |
| Dropped BLE packets (gaps > 0) | 2.4 GHz RF congestion or distance | Bring ESP32-C3 within 1 meter of phone; ensure 2.4 GHz Wi-Fi router is > 2m away |

---

## 5. Scope & Current Verification Boundary

- **Software Stack:** Fully verified and defense-ready (Flutter app, Drift SQLite database, on-device MLP classifier, offline PDF generator).
- **Physical BLE OTA:** Verified on `HONOR NIC-LX2` using `PulsePatch-SimHR` peripheral (real BLE transport, simulated physiology).
- **Physical ESP32-C3 + MAX30102:** Hardware integration is **PENDING** physical breadboard testing following the checklist above.
