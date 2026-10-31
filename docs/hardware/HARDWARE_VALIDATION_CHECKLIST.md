# PulsePatch Lite — Hardware Validation Checklist

**Document Identification:** CHK-HW-VALID-V1.0  
**Target Hardware:** ESP32-C3 DevKit / SuperMini + MAX30102 Sensor Module  
**Tester:** Hardware Engineering Team  
**Verification Date:** ____________________  
**Device Serial / MAC Address:** ____________________  

---

## 1. Pre-Power Visual & Continuity Inspection

| # | Inspection Item | Acceptance Criteria | Pass/Fail | Notes |
|---|---|---|---|---|
| 1.1 | **Solder Joints** | No solder bridges between SDA (GPIO4), SCL (GPIO5), VDD, and GND. Clean fillets. | [ ] | |
| 1.2 | **Power Rail Voltage** | Sensor VDD is connected exclusively to ESP32-C3 3.3V pin. **5V pin is unconnected.** | [ ] | **MANDATORY** |
| 1.3 | **Pull-Up Resistors** | 4.7 kΩ pull-ups present between SDA to 3.3V, and SCL to 3.3V. | [ ] | |
| 1.4 | **Optical Aperture** | MAX30102 optical glass window is free of flux residue, fingerprint oil, or dust. | [ ] | |

---

## 2. Power-On & I2C Bus Verification

| # | Inspection Item | Acceptance Criteria | Pass/Fail | Notes |
|---|---|---|---|---|
| 2.1 | **Supply Voltage Check** | Multimeter across MAX30102 VDD/GND reads **3.25V to 3.35V**. | [ ] | |
| 2.2 | **Quiescent Current** | Total breadboard idle current draw < 35 mA at 5V USB input. | [ ] | |
| 2.3 | **I2C Scanner** | Firmware boot log detects I2C device responding at address `0x57`. | [ ] | |
| 2.4 | **Part ID Verification** | Firmware reads register `0xFF` and confirms Part ID = `0x15`. | [ ] | |

---

## 3. Optical Perfusion & Sensor Calibration

| # | Inspection Item | Acceptance Criteria | Pass/Fail | Notes |
|---|---|---|---|---|
| 3.1 | **No-Contact State** | With no finger on sensor, IR counts < 10,000 counts. Firmware reports `flags.bit0 = 0` (Contact = False). | [ ] | |
| 3.2 | **Skin Placement** | When clean index finger is placed gently on sensor, IR counts rise > 50,000 counts. Firmware sets `flags.bit0 = 1`. | [ ] | |
| 3.3 | **LED Illumination** | Red (660nm) and Infrared (880nm) LEDs illuminate at 6.0 mA configured current. | [ ] | |
| 3.4 | **Motion Artifact Test** | Tapping or shaking sensor sets `flags.bit1 = 1` (Motion Suspected) and temporarily suppresses BPM calculation. | [ ] | |

---

## 4. BLE GATT Connectivity with Mobile App

| # | Inspection Item | Acceptance Criteria | Pass/Fail | Notes |
|---|---|---|---|---|
| 4.1 | **BLE Advertising** | Board advertises device name `"PulsePatch Lite"` and Service UUID `180D0000-7243-4E64-8843-50554C534531`. | [ ] | |
| 4.2 | **Central App Discovery** | Android app (`com.pulsepatch.lite.app`) detects peripheral within 3 seconds of tapping "Start Scan". | [ ] | |
| 4.3 | **Pairing & MTU** | App connects; connection status chip changes from "Disconnected" to "Connected". | [ ] | |
| 4.4 | **Notification Stream** | Characteristic `180D0001` streams 12-byte packets at 1 Hz without buffer overflows. | [ ] | |
| 4.5 | **Raw Waveform Stream**| Characteristic `180D0002` streams 12-byte raw samples at 25 Hz. Real-time PPG chart renders smooth systolic peaks. | [ ] | |
| 4.6 | **Range Test** | Stable BLE connection maintained at 5 meters line-of-sight without packet loss. | [ ] | |

---

## 5. Physiological Accuracy Verification

| # | Metric | Reference Standard | Tolerance | Measured Value | Pass/Fail |
|---|---|---|---|---|---|
| 5.1 | **Resting Heart Rate** | Manual radial pulse count or commercial pulse oximeter | ± 3 BPM | Ref: ____ / Patch: ____ | [ ] |
| 5.2 | **Resting SpO2** | Clinical fingertip pulse oximeter (e.g. Masimo / Nonin) | ± 2 % | Ref: ____ / Patch: ____ | [ ] |
| 5.3 | **Post-Exercise HR** | Heart rate increase followed by recovery drop tracking | Correct trajectory | Pre: ____ / Peak: ____ | [ ] |

---

## 6. Sign-Off & Handoff Approval

- **Hardware Engineer Name:** ______________________________________
- **Signature:** ______________________________________
- **Date:** ______________________________________
- **Software Architecture Lead:** Verified App Ready (`com.pulsepatch.lite.app`)
