---
name: esp32c3-max30102-ble
description: ESP32-C3 RISC-V firmware development, MAX30102 dual-wavelength I2C register management, BLE GATT service contracts, raw PPG batching, and serial debugging telemetry.
---

# ESP32-C3, MAX30102, and BLE Skill

## 1. Purpose
Governs embedded firmware implementation for the Espressif ESP32-C3 microcontroller paired with the Maxim Integrated MAX30102 optical sensor. Manages I2C sensor initialization, FIFO polling, optical sample buffering, and Bluetooth Low Energy (BLE) GATT streaming contracts.

## 2. When to Use
- Writing or refactoring C++ firmware in `firmware/src/main.cpp` using PlatformIO and Arduino/NimBLE cores.
- Configuring MAX30102 hardware registers (sample rate, LED pulse width, ADC range, LED current).
- Implementing dual-channel Red + IR sample batching and 12-byte / 20-byte BLE characteristic notifications.
- Establishing serial calibration environments (`DEBUG_RAW`, `I2C_SCANNER_ONLY`).

## 3. Required Inputs
- Target hardware specs: ESP32-C3 DevKitM-1, MAX30102 breakout board.
- I2C pinout: SDA=GPIO4, SCL=GPIO5, 3.3V logic (strictly no 5V).
- BLE GATT UUID specifications and packet byte layout.

## 4. Expected Outputs
- Compilable PlatformIO binary (`firmware.bin`) within flash and RAM budgets ($Flash < 60\%, RAM < 20\%$).
- BLE GATT service advertising:
  - 1 Hz Heart Rate & SQI notification characteristic.
  - Raw optical waveform streaming characteristic (batched Red/IR samples).
  - Device status and configuration read/write characteristic.
- Serial telemetry output at 115200 baud.

## 5. Practical Workflow
1. **I2C Bus Initialization:** Set up I2C on GPIO4/5 at $400\text{ kHz}$ Fast Mode. Verify MAX30102 part ID register ($0xFF = 0x15$).
2. **Sensor Setup:** Configure Mode 2 (Red + IR mode), sample rate $100\text{ Hz}$, pulse width $411\text{ }\mu\text{s}$ ($18$-bit resolution), LED currents $\approx 6.4\text{ mA}$.
3. **FIFO Batching:** Read 32-sample hardware FIFO into memory buffer. Avoid missing samples due to BLE blocking calls.
4. **BLE Transport:** Use NimBLE stack for low-overhead GATT notifications. Pack data into little-endian binary structures with fixed alignment (`#pragma pack(push, 1)`).

## 6. Verification Criteria
- `sizeof(PulsePacket)` must equal the defined GATT byte contract (verified via `static_assert`).
- PlatformIO compilation must exit with code 0.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never power MAX30102 from 5V rails (damages optical sensor and ESP32 GPIOs).
- **Prohibited:** Never block FreeRTOS execution in I2C polling loops without yielding (`delay(1)` or vTaskDelay).
- **Limitation:** High-rate raw PPG streaming ($100\text{ Hz} \times 2\text{ channels} = 200\text{ samples/s}$) requires packet batching to stay within BLE MTU and connection intervals.
