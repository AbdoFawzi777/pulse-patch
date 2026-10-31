# PulsePatch Next Generation — Hardware Engineering Team Handoff

**Project Name:** PulsePatch Lite Next Generation  
**Target Mobile Package:** `com.pulsepatch.lite.app`  
**Software Verification Status:** **APP SOFTWARE: READY FOR HARDWARE INTEGRATION**  
**Physical BLE Validation Status:** **PENDING PHYSICAL HARDWARE CONNECTION**  
**Firmware Architecture:** ESP32-C3 RISC-V SoC + Maxim Integrated MAX30102 High-Sensitivity Pulse Oximeter & Heart Rate Sensor  
**Document Version:** 2.1.0  
**Date:** 2026-10-31  

---

## 1. Executive Summary & Integration Boundary

The PulsePatch mobile application software engineering team has completed 100% of the mobile application architecture, UI/UX implementation, offline data persistence, local biomedical processing, AI safety escalation, and OpenStreetMap healthcare discovery services.

All automated Flutter test suites pass completely (**398/398 tests passed**, **0 analyzer issues**), and the production release APK has been built, cryptographically signed, and verified on the Android emulator (`Pixel_API34`).

The remaining physical validation responsibility is handed over to the **Hardware Engineering Team**. This document specifies the electrical wiring, firmware flashing, BLE protocol contract, and physical breadboard test procedure.

---

## 2. Hardware Bill of Materials (BOM) & Electrical Constraints

| Component | Specification | Vendor / Reference | Operating Voltage |
|---|---|---|---|
| **Microcontroller** | ESP32-C3 SuperMini / DevKit (RISC-V single-core 160MHz) | Espressif Systems | 3.3V logic (USB 5V to onboard LDO) |
| **Optical Biomonitor** | MAX30102 Photoplethysmography Sensor (Red 660nm + IR 880nm) | Maxim Integrated (Analog Devices) | **3.3V ONLY (DO NOT CONNECT TO 5V)** |
| **I2C Pull-up Resistors** | 4.7 kΩ pull-ups on SDA and SCL to 3.3V | Standard SMD/Through-hole | 3.3V bus rail |
| **Decoupling Capacitors** | 0.1 µF ceramic + 4.7 µF tantalum across VDD and GND | Decoupling adjacent to MAX30102 | - |
| **Wiring** | 4-wire silicone flexible cable (VDD, GND, SDA, SCL) | AWG 28–30 | Flexible for wearable patch |

> [!CAUTION]
> **ELECTRICAL HAZARD NOTICE (3.3V vs 5V):**  
> MAX30102 is rated for a maximum VDD of 3.6V (recommended 1.8V / 3.3V for internal LEDs). Supplying 5V directly to the sensor VDD or I2C pull-ups will cause catastrophic electrical breakdown of the photodiode ADC and LED drivers. Ensure the ESP32-C3 3.3V LDO pin is used.

---

## 3. Pinout & Interconnection Map

```
  +--------------------------------------------------------+
  |              ESP32-C3 Microcontroller                  |
  |                                                        |
  |   [ 3V3 ] ------------------------- VDD (3.3V)         |
  |   [ GND ] ------------------------- GND                |
  |   [ GPIO4 ] ----------------------- SDA (I2C Data)     |
  |   [ GPIO5 ] ----------------------- SCL (I2C Clock)    |
  +--------------------------------------------------------+
                             |
                             v
  +--------------------------------------------------------+
  |               MAX30102 Sensor Module                   |
  |                                                        |
  |   VDD : 3.3V DC Power Rail                             |
  |   GND : Common Ground                                  |
  |   SDA : Serial Data (I2C Addr: 0x57)                   |
  |   SCL : Serial Clock (400 kHz Fast-Mode)               |
  |   INT : Optional active-low interrupt (Not connected)  |
  +--------------------------------------------------------+
```

Reference Source Code: [`firmware/include/pulse_config.h`](file:///e:/pulse%20patch/firmware/include/pulse_config.h#L8-L13)

---

## 4. BLE GATT Service & Characteristics Contract

The mobile app scans for peripheral devices advertising the service UUID or local name `PulsePatch Lite`.

### 4.1 128-Bit UUID Definitions

| Entity | UUID String | Type | Properties |
|---|---|---|---|
| **Service** | `180D0000-7243-4E64-8843-50554C534531` | GATT Primary Service | - |
| **HR & SpO2 Measurement** | `180D0001-7243-4E64-8843-50554C534531` | Characteristic | Read, Notify |
| **Raw PPG Waveform** | `180D0002-7243-4E64-8843-50554C534531` | Characteristic | Read, Notify |
| **Device Status & Battery** | `180D0003-7243-4E64-8843-50554C534531` | Characteristic | Read, Write, Notify |

Reference Source Code: [`firmware/src/main.cpp`](file:///e:/pulse%20patch/firmware/src/main.cpp#L34-L41)

---

## 5. Binary Packet Formats (Little-Endian)

### 5.1 Heart Rate & SpO2 Packet (`PulsePacket`, 12 Bytes)

| Byte Offset | Field Name | Type | Scaling / Unit | Description |
|---|---|---|---|---|
| **0** | `protocolVersion` | `uint8_t` | Constant `0x01` | Protocol version check |
| **1** | `flags` | `uint8_t` | Bitfield | Bit 0: Finger contact (`1`=contact, `0`=air)<br>Bit 1: Motion detected (`1`=motion, `0`=still) |
| **2–3** | `bpmTimes10` | `uint16_t` (LE) | 0.1 BPM | e.g., `725` = 72.5 BPM. `0xFFFF` = calculating |
| **4** | `quality` | `uint8_t` | 0–100 % | Signal Quality Index (SQI) |
| **5–8** | `deviceTimestampMs` | `uint32_t` (LE) | Milliseconds | Monotonic hardware timestamp (`millis()`) |
| **9–10** | `sequenceNumber` | `uint16_t` (LE) | Counter | Monotonic packet counter for dropped frame detection |
| **11** | `spo2Percent` | `uint8_t` | 0–100 % | Dual-wavelength calibrated SpO2 (0 = calculating) |

### 5.2 Raw Dual-Wavelength Waveform Packet (`RawSamplePacket`, 12 Bytes)

Transmitted at 25 Hz over BLE (downsampled from 100 Hz internal acquisition or decimated):

| Byte Offset | Field Name | Type | Scaling / Unit | Description |
|---|---|---|---|---|
| **0–3** | `timestampMs` | `uint32_t` (LE) | Milliseconds | Monotonic hardware timestamp |
| **4–7** | `irSample` | `uint32_t` (LE) | 18-bit ADC Counts | Raw Infrared AC+DC photodiode counts |
| **8–11** | `redSample` | `uint32_t` (LE) | 18-bit ADC Counts | Raw Red AC+DC photodiode counts |

Reference Source Code: [`firmware/src/main.cpp`](file:///e:/pulse%20patch/firmware/src/main.cpp#L46-L68)

---

## 6. Firmware Build & Flashing Instructions

The firmware project is configured for PlatformIO with the `espressif32` platform and `esp32-c3-devkitm-1` board definition.

### Step 1: Open Terminal in Firmware Directory
```bash
cd "e:\pulse patch\firmware"
```

### Step 2: Build Firmware
```bash
pio run
```

### Step 3: Flash to ESP32-C3 via USB-C
Connect the ESP32-C3 board to the host PC via USB-C. Hold the `BOOT` button if the chip does not automatically enter download mode:
```bash
pio run --target upload
```

### Step 4: Verify Serial Monitor at 115200 Baud
```bash
pio device monitor --baud 115200
```
Expected boot output:
```
[INFO] PulsePatch Lite Firmware v2.0.0-esp32c3 starting...
[INFO] I2C initialized on SDA: GPIO4, SCL: GPIO5
[INFO] MAX30102 detected at 0x57 (Part ID: 0x15)
[INFO] BLE Advertising started as 'PulsePatch Lite'
[INFO] Waiting for mobile app connection...
```

---

## 7. Hardware Team Physical Verification Steps

1. **Benchtop Power Verification:** Check with a digital multimeter that the voltage across MAX30102 VDD and GND is between 3.25V and 3.35V.
2. **I2C Address Sweep:** Verify I2C bus response at `0x57`.
3. **Finger Placed Test:** Place a clean index finger lightly on the optical window without excessive pressure.
   - Confirm red and infrared LEDs illuminate.
   - Verify serial log reports `Finger contact detected: IR counts > 50000`.
4. **Mobile App Pairing:**
   - Launch PulsePatch app on Android device.
   - Tap **"No device connected"** or navigate to **Connect Device Screen**.
   - Tap **"Start Scan"**. The app will detect `"PulsePatch Lite"` advertising `180D0000-7243-4E64-8843-50554C534531`.
   - Tap **"Connect"**.
5. **Real-Time Data Stream Verification:**
   - Verify that Live Measurement displays real incoming PPG waveforms.
   - Confirm Heart Pulse indicator pulses in synchrony with actual cardiac cycles.
   - Observe SpO2 percentage reading stabilizes between 96% and 99% within 15 seconds.
