# PulsePatch Lite — ESP32-C3 Firmware Guide

This directory contains the production firmware for the **PulsePatch Lite** biomonitoring sensor patch, targeting an **Espressif ESP32-C3 RISC-V Microcontroller** paired with a **Maxim Integrated MAX30102 High-Sensitivity Pulse Oximeter and Heart-Rate Sensor**.

> [!IMPORTANT]
> **Strictly Non-Diagnostic Educational Biomonitoring Device**  
> PulsePatch Lite is an educational research and engineering capstone platform. It does not provide medical-grade ECG diagnostics, medical screening, or disease detection.

---

## 1. Hardware Bill of Materials (BOM)

| Component | Part / Model | Operating Voltage | Interface | Description |
|---|---|---|---|---|
| **MCU** | ESP32-C3 SuperMini / DevKitM-1 | 3.3V DC (5V USB in) | BLE 5.0 / USB-C | 160MHz RISC-V Single-Core, 400KB SRAM |
| **Battery** | Small Rechargeable LiPo/Li-ion | 3.7V nom (regulated to 3.3V) | Untethered Power / USB-C charging | Powers patch untethered; board lacks fuel gauge / voltage divider telemetry so level is not reported to app |
| **Sensor** | Maxim MAX30102 Breakout Board | 3.3V DC VDD / 1.8V Core | I2C (0x57 address) | High-sensitivity Red (660nm) & IR (880nm) Photoplethysmography |
| **Resistors** | 4.7kΩ Resistors (x2) | N/A | I2C Pull-Up | Pull-up resistors between 3.3V and SDA/SCL lines |
| **Enclosure** | 3D-Printed Finger Clip / Band | N/A | Mechanical | Keeps optical sensor aligned against finger pad without excessive pressure |

---

## 2. Electrical Wiring & Pinout Diagram

The PulsePatch hardware is powered by an onboard small rechargeable battery (or 5V USB-C while charging). Note that the board does not contain a battery level sensing circuit (no fuel gauge or ADC voltage divider), so battery percentage is not reported to the app.

```
+------------------------------------+           +-------------------------------+
|       ESP32-C3 DevKit / Mini       |           |   MAX30102 Breakout Board     |
|                                    |           |                               |
|                     [3.3V Pin] ----+-----------+--> [VIN / 3.3V] (NEVER 5V!)   |
|                      [GND Pin] ----+-----------+--> [GND]                      |
|                                    |           |                               |
|        [GPIO 4] (I2C SDA) ---------+-----+-----+--> [SDA]                      |
|                                    |     |     |                               |
|        [GPIO 5] (I2C SCL) ---------+--+  |     |--> [SCL]                      |
|                                    |  |  |     |                               |
|                                    | [4.7k Pullups to 3.3V]                    |
|                                    |  |  |     |                               |
|        [GPIO 6] (Optional INT) ----+--+--+-----+--> [INT] (Optional)           |
+------------------------------------+           +-------------------------------+
```

> [!CAUTION]
> **Power Supply Rule:** Always connect MAX30102 `VIN` strictly to the ESP32-C3 board's **3.3V** pin, **NEVER to 5V**. Supplying 5.0V directly to the sensor without a level converter will permanently destroy the MAX30102 optical photodiode array.

---

## 3. Signal Processing & Algorithm Overview

### A. Optical Photoplethysmography (PPG) Sampling
The MAX30102 is configured via I2C at **100 Hz** sampling frequency:
- **LED Mode:** Dual-wavelength (Red + Infrared).
- **LED Current:** 6.4 mA (prevents photodiode saturation across diverse skin tones).
- **ADC Resolution:** 18-bit (411 μs pulse width).
- **Sample Averaging:** 4 samples per FIFO read.

### B. DC Baseline Cancellation (IIR High-Pass Filter)
Skin tissue, venous blood, and bone reflect a substantial static DC optical component that varies slowly with respiration. An on-chip 1st-order digital Infinite Impulse Response (IIR) filter removes DC drift while preserving dynamic pulsatile AC fluctuations:
$$y[n] = x[n] - x[n-1] + \alpha \cdot y[n-1] \quad (\alpha = 0.95)$$

### C. Peak Detection & Physiological Refractory Window
Zero-crossing detection with an adaptive positive threshold monitors cardiac systole:
1. **Refractory Window:** Inter-Beat Intervals (IBI) below **272 ms** (> 220 BPM) or above **2000 ms** (< 30 BPM) are rejected as physiological outliers or motion noise.
2. **Smoothing:** Instantaneous IBIs are buffered across a 4-beat rolling window to filter erratic ectopic beats.

### D. Signal Quality Index (SQI 0–100) Formulation
- **Finger Contact:** Evaluated via DC baseline threshold ($IR > 50,000$). If no finger is present, packet flags set `contactDetected = 0` and BPM output transmits `0xFFFF` (calculating / invalid).
- **Motion Detection:** Evaluated via 1st derivative magnitude ($\Delta AC > 12,000$). When abrupt finger shear occurs, `motionSuspected = 1` and SQI is penalized.
- **SQI Score:** Evaluated from normalized AC pulse amplitude and rhythm regularity, scaled from `0` (unusable) to `100` (optimal perfusion).

---

## 4. BLE GATT Architecture

PulsePatch Lite implements a custom 128-bit Primary GATT Service:
- **Service UUID:** `180D0000-7243-4E64-8843-50554C534531`
- **Heart Rate Measurement (Notify):** `180D0001-7243-4E64-8843-50554C534531`
  - 12-byte little-endian binary packet broadcast every 1.0 second:
    ```
    Offset 0:   uint8_t  protocolVersion (0x01)
    Offset 1:   uint8_t  flags (bit 0: contactDetected, bit 1: motionSuspected)
    Offset 2-3: uint16_t bpmTimes10 (LE, 0xFFFF = invalid / calculating)
    Offset 4:   uint8_t  quality (0–100)
    Offset 5-8: uint32_t deviceTimestampMs (LE)
    Offset 9-10:uint16_t sequenceNumber (LE, wraps at 65535)
    Offset 11:  uint8_t  reserved (0x00 padding; patch is battery-powered, but lacks level telemetry so no percentage is sent)
    ```
- **Raw Optical Trace (Notify, Optional):** `180D0002-7243-4E64-8843-50554C534531`
- **Device Info (Read):** `180D0003-7243-4E64-8843-50554C534531`
  - Returns JSON: `{"fw":"1.0.0-esp32c3","sensor":"MAX30102_OK","battery_mv":null}` (battery_mv is null because board lacks fuel gauge / voltage divider telemetry)

---

## 5. Build & Flash Instructions

### Method 1: Using PlatformIO (Recommended)
1. Install PlatformIO Core (`pip install platformio`) or PlatformIO for VS Code.
2. Connect your ESP32-C3 board via USB.
3. Open a terminal in the `firmware/` directory:
   ```bash
   pio run --target upload
   ```
4. Open the Serial Monitor at 115200 baud:
   ```bash
   pio device monitor -b 115200
   ```

### Method 2: Using Arduino IDE
1. Install Arduino IDE (v2.x).
2. Add ESP32 board support via Boards Manager: `esp32 by Espressif Systems`.
3. Install required libraries via Library Manager:
   - `NimBLE-Arduino` by h2zero
   - `SparkFun MAX3010x Pulse and Proximity Sensor Library` by SparkFun
4. Select Board: `ESP32C3 Dev Module`.
5. Open `firmware/src/main.cpp`, configure USB CDC on Boot = Enabled (if using ESP32-C3 USB), and click **Upload**.

---

## 6. Serial Monitor Diagnostics Sample Output

When running, the firmware logs formatted telemetry to Serial:
```
[BLE] Advertising started. Waiting for PulsePatch mobile client...
[BLE] Central client connected.
[PulsePatch] Seq:    1 | Contact:YES | Motion: NO | BPM: 71.4 | Quality: 88% | TS: 34102ms
[PulsePatch] Seq:    2 | Contact:YES | Motion: NO | BPM: 72.0 | Quality: 90% | TS: 35104ms
[PulsePatch] Seq:    3 | Contact:YES | Motion:YES | BPM: 72.8 | Quality: 42% | TS: 36108ms
[PulsePatch] Seq:    4 | Contact: NO | Motion: NO | BPM: ---.- | Quality:  0% | TS: 37110ms
```

---

## 7. Physical Limitations & Calibration Advice

1. **Finger Pressure:** Excessive pressure restricts capillary blood flow and flattens the optical pulse waveform. Light, steady contact is required.
2. **Cold Extremities:** Vasoconstriction reduces peripheral perfusion, lowering the SQI score. Warming the hands restores signal amplitude.
3. **Ambient Light Shielding:** High ambient light (sunlight, fluorescent lighting) can saturate the photodiode. Use a dark silicone strap or enclosure over the sensor pad.
