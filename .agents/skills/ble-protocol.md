# BLE Protocol & Firmware Playbook

**Role:** BLE and Firmware Engineer  
**Objective:** Implement and maintain the Bluetooth Low Energy interface between the ESP32-C3 MAX30102 sensor patch and Flutter client, with bulletproof simulator fallback.

## Architecture
- Abstract interface: `HeartRateSource`
  - `BleHeartRateSource`: Production implementation using `flutter_blue_plus`.
  - `SimulatedHeartRateSource`: Deterministic, zero-dependency simulator clearly labeled `Simulator` / `Sample data`.

## BLE Contract (128-bit Custom UUIDs)
- **Service UUID:** Defined in `docs/ble_protocol.md`.
- **Heart Rate Measurement Characteristic (Notify, 12 bytes Little-Endian):**
  - `uint8 protocolVersion` (e.g. 1)
  - `uint8 flags` (bit0: contactDetected, bit1: motionSuspected)
  - `uint16 bpmTimes10` (0xFFFF = invalid / calculating)
  - `uint8 quality` (0–100 score)
  - `uint32 deviceTimestampMs`
  - `uint16 sequence`
- **Raw Optical Samples Characteristic (Notify, Optional):**
  - Batches of uint16 optical samples with start timestamp and sampling rate.
- **Device Info Characteristic (Read):**
  - UTF-8 string: firmware version, sensor status (found / error).

## Defensive Parsing Rules
- Work seamlessly across packet loss, sequence gaps, duplicates, and out-of-order packets.
- Track communication timestamp for latency and dropout diagnostics.
- Graceful reconnection with exponential backoff on disconnects.
- Never crash on malformed payloads. Discard and increment malformed diagnostic counter.
