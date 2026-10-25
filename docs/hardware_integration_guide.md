# PulsePatch Lite — Hardware Integration & Real Chip Calibration Guide

This guide fulfills the Section 8 physical hardware checklist of the Master Build Plan. It provides step-by-step instructions for the hardware owner to connect, flash, validate, and calibrate the physical **ESP32-C3 + MAX30102** sensor patch with the PulsePatch Lite mobile client.

---

## 1. Hardware Assembly & Inspection Checklist

Before connecting USB power to the ESP32-C3, verify physical pin continuity and voltage levels:

- [ ] **Power Line (3.3V):** Confirm the MAX30102 `VIN` is connected to the ESP32-C3 **3.3V** pin.
  > [!CAUTION]
  > Never connect MAX30102 to 5.0V USB bus power. Excessive voltage will permanently damage the photodiode array.
- [ ] **Ground (GND):** Common ground between ESP32-C3 `GND` and MAX30102 `GND`.
- [ ] **I2C SDA:** MAX30102 `SDA` to ESP32-C3 **GPIO 4**.
- [ ] **I2C SCL:** MAX30102 `SCL` to ESP32-C3 **GPIO 5**.
- [ ] **Pull-Up Resistors:** Verify 4.7kΩ pull-up resistors are installed between 3.3V and SDA, and between 3.3V and SCL (many commercial breakout modules include these on-board).
- [ ] **Optical Enclosure / Strap:** Ensure sensor is secured in a clip or elastic strap that holds the optical window against the finger pad without constricting capillary blood flow.

---

## 2. Firmware Flashing & Serial Validation

1. **Connect ESP32-C3 to Computer via USB-C.**
2. **Flash Firmware:**
   Using PlatformIO in `firmware/`:
   ```bash
   cd firmware
   pio run --target upload
   ```
   Or using Arduino IDE with the `firmware/src/main.cpp` sketch (Board: ESP32C3 Dev Module, Flash Mode: DIO, USB CDC On Boot: Enabled).
3. **Open Serial Monitor (115200 baud):**
   ```bash
   pio device monitor -b 115200
   ```
4. **Confirm Initialization Output:**
   ```
   [SENSOR] SUCCESS: MAX30102 detected.
   [BLE] Advertising started. Waiting for PulsePatch mobile client...
   ```
   *If you see `[SENSOR] ERROR: MAX30102 not found`, check SDA/SCL wiring and verify I2C address `0x57`.*
5. **Finger Placement Test:**
   - Rest finger on optical sensor pad with light pressure.
   - Confirm Serial begins streaming 1 Hz heart rate packets:
     ```
     [PulsePatch] Seq: 1 | Contact:YES | Motion: NO | BPM: 72.4 | Quality: 88% | TS: 34102ms
     ```

---

## 3. End-to-End BLE Client Validation

1. Launch **PulsePatch Lite** on the test Android device or emulator with Bluetooth enabled.
2. In the app, navigate to **Connect Device** screen.
3. Tap **Scan for Devices**:
   - Verify `PulsePatch Lite` appears in the discovered peripherals list with strong RSSI.
4. Tap **Connect**:
   - Confirm state transitions cleanly from `Connecting...` to `Connected`.
   - Verify Device Information card reads:
     - Firmware: `1.0.0-esp32c3`
     - Sensor: `MAX30102_OK`
     - Battery: `Rechargeable battery powered (no level telemetry; percentage not received)`
5. Start a **Measurement Session (Rest, 60s)**:
   - Observe live heart rate number updating every 1.0s.
   - Verify circular timer counts down smoothly from 60s to 0s.
   - Verify Signal Quality indicator displays `Good` ($SQI \ge 60$).

---

## 4. Hardware Stress & Fault Recovery Tests

Execute the following physical stress tests to verify client fault tolerance:

| Test Case | Physical Action | Expected Client Behavior |
|---|---|---|
| **Finger Removed** | Lift finger off sensor mid-measurement | UI displays `Weak signal / Adjust sensor`, pauses countdown, BPM masked to `--` |
| **Finger Replaced** | Place finger back on sensor | Signal resumes, quality recovers to $>60$, countdown resumes |
| **Sudden Motion** | Vigorously shake finger or tap sensor | Sensor flags `motionSuspected = 1`, quality drops, jump gate rejects outlier BPM |
| **BLE Disconnect** | Power down ESP32-C3 mid-session | UI presents `Reconnecting...`, triggers exponential backoff (1s, 2s, 4s, 8s) |
| **Power Restore** | Power ESP32-C3 back on | App auto-reconnects, synchronizes sequence counter, resumes telemetry |
| **App Backgrounding** | Switch to another app or lock phone | Bluetooth connection remains alive; data buffered upon foreground return |

---

## 5. Threshold Calibration from Real Recordings

If physical optical characteristics differ from synthetic norms, calibrate thresholds in `app/lib/domain/signal/signal_constants.dart`:

```dart
// app/lib/domain/signal/signal_constants.dart
static const int minSignalQuality = 60;        // Minimum SQI (0–100) for valid sample
static const double maxBpmJumpPerSecond = 15.0; // Physiological jump threshold
static const Duration invalidDataHoldDelay = Duration(seconds: 4); // Dropout alarm
```

---

## 6. Real Volunteer Dataset Recording & Retraining

1. Collect baseline recordings across 8+ volunteers using the app's **Export for training** button on the Privacy & Data Management screen.
2. Place exported CSV files into `ml/data/volunteer_recordings/`.
3. Retrain the on-device model with one documented command:
   ```bash
   py ml/src/train.py
   ```
4. Run parity verification to guarantee agreement:
   ```bash
   py ml/src/verify_parity.py
   ```
5. Commit and re-build the app!
