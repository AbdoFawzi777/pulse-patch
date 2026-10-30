# PulsePatch Lite v2.0 — ESP32-C3 Firmware Flash & Device Setup Guide

**Target Hardware:** ESP32-C3 DevKitM-1 (RISC-V 32-bit single-core) + MAX30102 Optical Biomonitoring Sensor  
**Firmware Version:** 2.0.0-esp32c3  
**Communication:** BLE GATT Peripheral (Custom 128-bit UUID, 12-byte Little-Endian Packet)  

---

## 1. Hardware Bill of Materials (BOM)

| Item | Component | Quantity | Description / Notes |
|:---:|:---|:---:|:---|
| 1 | **ESP32-C3 DevKitM-1** | 1 | RISC-V SoC with integrated 2.4 GHz Wi-Fi and Bluetooth 5 (LE) |
| 2 | **MAX30102 Breakout Board** | 1 | Integrated pulse oximetry and heart-rate sensor (3.3 V only) |
| 3 | **Micro-USB / USB-C Cable** | 1 | High-quality data cable for flashing and serial telemetry |
| 4 | **DuPont Jumper Wires** | 4 | Female-to-Female or Male-to-Female jumper wires |
| 5 | **Elastic Wrist Strap / Clip** | 1 | For stabilizing optical contact on the finger pad |

---

## 2. Electrical Wiring & Pinout Diagram

> [!CAUTION]
> **Voltage Warning:** The MAX30102 sensor operates at **3.3 V logic and supply levels**. Supplying 5 V from the ESP32-C3 VIN pin can permanently damage the sensor photodiode and LED drivers.

```
       ESP32-C3 DevKitM-1                     MAX30102 Breakout
   ┌────────────────────────┐              ┌────────────────────┐
   │                        │              │                    │
   │                   3V3  ├──────────────┤ VIN / VCC (3.3V)   │
   │                   GND  ├──────────────┤ GND                │
   │                        │              │                    │
   │        GPIO 4 (SDA)    ├──────────────┤ SDA                │
   │        GPIO 5 (SCL)    ├──────────────┤ SCL                │
   │                        │              │                    │
   │        GPIO 9 (BOOT)   │              │ INT (Optional)     │
   │                        │              │                    │
   └────────────────────────┘              └────────────────────┘
```

### Pin Assignment Table:
- **`3V3` $\to$ `VIN`:** Regulated 3.3 V DC Power Supply.
- **`GND` $\to$ `GND`:** Common System Ground.
- **`GPIO 4` $\to$ `SDA`:** I2C Serial Data line (400 kHz Fast-Mode).
- **`GPIO 5` $\to$ `SCL`:** I2C Serial Clock line (400 kHz Fast-Mode).
- *Note:* If using a bare breakout without internal pull-ups, install two $4.7\text{ k}\Omega$ pull-up resistors from SDA and SCL to 3.3 V.

---

## 3. Pre-Compiled Binary Artifacts

The repository contains pre-compiled, verified production binaries at `firmware/.pio/build/esp32-c3-devkitm-1/`:

| Artifact | Offset Address | Size (bytes) | SHA-256 Checksum |
|:---|:---:|:---:|:---|
| `bootloader.bin` | `0x0000` | 13,248 | `30D47AB1F344CFA69F6B2F718FFA72FC7BAEA6DB047EAABEFEA162DB29E6821C` |
| `partitions.bin` | `0x8000` | 3,072 | `148B959CBFF1C38AA8E1D5C0BA9D612C54997B945E56A63F41223EEF650653A1` |
| `firmware.bin` | `0x10000` | 572,352 | `5DCC42A3C1A4870705C212EEB26AA7584534099EB74B02F8668B4D5FA42A4080` |

---

## 4. Flashing Instructions via esptool.py

Ensure Python with `esptool` is installed:
```bash
pip install esptool
```

### 4.1 Determine Serial COM Port
- **Windows:** Open Device Manager $\to$ *Ports (COM & LPT)*. Identify `USB-Enhanced-SERIAL CH340` or `Silicon Labs CP210x` (e.g., `COM3`, `COM5`).
- **Linux/macOS:** Run `ls /dev/ttyUSB*` or `ls /dev/ttyACM*`.

### 4.2 Flashing Command
Run the following single-line command from the project root:

```bash
esptool.py --chip esp32c3 --port COM5 --baud 921600 \
  --before default_reset --after hard_reset write_flash -z \
  --flash_mode dio --flash_freq 80m --flash_size 4MB \
  0x0000 firmware/.pio/build/esp32-c3-devkitm-1/bootloader.bin \
  0x8000 firmware/.pio/build/esp32-c3-devkitm-1/partitions.bin \
  0x10000 firmware/.pio/build/esp32-c3-devkitm-1/firmware.bin
```

*(Replace `COM5` with your active serial port).*

---

## 5. Alternative Compilation & Flash via PlatformIO

If modifying source code in `firmware/src/main.cpp` or `include/pulse_config.h`:

```bash
cd firmware
pio run --target upload
pio device monitor -b 115200
```

---

## 6. Serial Telemetry & Boot Verification

Open any serial terminal (e.g. PuTTY, Arduino Serial Monitor, or `pio device monitor`) at **115200 baud, 8N1**.

### Expected Boot Telemetry Log:
```text
=====================================================
PulsePatch Lite — ESP32-C3 Firmware v2.0.0
Hardware: ESP32-C3 + MAX30102 Optical Biomonitor
=====================================================
[I2C] Initializing Wire on SDA=GPIO4, SCL=GPIO5...
[SENSOR] Probing MAX30102 at 0x57... FOUND!
[SENSOR] Configuring 100 Hz, 411 us pulse width, 6 mA LED current.
[BLE] Initializing NimBLE stack ("PulsePatch Lite")...
[BLE] Service UUID: 180D0000-7243-4E64-8843-50554C534531
[BLE] Advertising started. Waiting for smartphone connection...
```

### Live Perfusion Gating Log:
- **No finger detected (IR < 50,000 counts):**
  ```text
  [PPG] No skin contact detected (IR=1420). Optical perfusion gated.
  ```
- **Finger placed on sensor (IR >= 50,000 counts):**
  ```text
  [PPG] Contact detected! (IR=184200, Red=145320). AC filter active.
  [PPG] Beat detected! IBI=842 ms, Instantaneous BPM=71.2, SQI=88%
  [BLE] Packet sent: Seq=12, BPM=71.2, SpO2=98%, SQI=88%
  ```

---

## 7. BLE GATT Specification & Contract Reference

| Attribute | UUID | Type | Properties | Description |
|:---|:---|:---:|:---:|:---|
| **Service** | `180D0000-7243-4E64-8843-50554C534531` | Service | Primary | PulsePatch Biomonitoring Service |
| **HR Measurement** | `180D0001-7243-4E64-8843-50554C534531` | Characteristic | Read, Notify | 12-byte structured little-endian packet (1 Hz) |
| **Raw Waveform** | `180D0002-7243-4E64-8843-50554C534531` | Characteristic | Notify | 12-byte raw optical waveform samples (25–50 Hz) |
| **Device Status** | `180D0003-7243-4E64-8843-50554C534531` | Characteristic | Read | JSON hardware status string (firmware, battery, I2C) |

### 12-Byte Binary Packet Layout (`0x0001` Characteristic):
```
Offset   Type      Field Name           Description
---------------------------------------------------------------------------------
0        uint8     protocolVersion      0x01
1        uint8     flags                bit0=contactDetected, bit1=motionSuspected
2..3     uint16    bpmTimes10           Heart Rate * 10 (e.g. 725 = 72.5 BPM; 0xFFFF=calculating)
4        uint8     quality              Signal Quality Index SQI (0–100%)
5..8     uint32    deviceTimestampMs    Firmware millis() tick
9..10    uint16    sequenceNumber       Monotonic rolling packet counter
11       uint8     spo2Percent          Oxygen saturation % (70–100%; 0x00=calculating)
```
