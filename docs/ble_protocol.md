# PulsePatch Lite — BLE GATT Protocol Specification

**Version:** 1.0.0  
**Target Hardware:** ESP32-C3 + MAX30102  
**Transport:** Bluetooth Low Energy (BLE 5.0)  
**Byte Order:** Little-Endian for all multi-byte fields

---

## 1. GATT Architecture & Service UUIDs

All PulsePatch Lite GATT interactions are hosted under a custom 128-bit Primary Service.

| Descriptor | UUID | Type | Properties |
|---|---|---|---|
| **Primary Service** | `180D0000-7243-4E64-8843-50554C534531` | Service | N/A |
| **Heart Rate Measurement** | `180D0001-7243-4E64-8843-50554C534531` | Characteristic | Notify |
| **Raw Optical Samples** | `180D0002-7243-4E64-8843-50554C534531` | Characteristic | Notify (Optional) |
| **Device & Sensor Status** | `180D0003-7243-4E64-8843-50554C534531` | Characteristic | Read |

---

## 2. Heart Rate Measurement Characteristic (`180D0001...`)

- **Notification Rate:** 1 Hz (1 packet per second).
- **Payload Length:** Exactly 12 bytes.
- **Endianness:** Little-Endian.

### Binary Layout
```
+---------------+---------------+--------------------+---------------+-------------------------+--------------------+---------------+
| Offset: 0     | Offset: 1     | Offset: 2-3        | Offset: 4     | Offset: 5-8             | Offset: 9-10       | Offset: 11    |
| uint8_t       | uint8_t       | uint16_t (LE)      | uint8_t       | uint32_t (LE)           | uint16_t (LE)      | uint8_t       |
| protocolVer   | flags         | bpmTimes10         | quality       | deviceTimestampMs       | sequenceNumber     | reserved      |
+---------------+---------------+--------------------+---------------+-------------------------+--------------------+---------------+
```

### Field Definitions
1. **`protocolVersion` (uint8, Offset 0):**
   - Current protocol version is `1` (`0x01`). Packets with unrecognized versions are rejected.
2. **`flags` (uint8, Offset 1):**
   - `bit 0`: `contactDetected` (1 = finger detected on MAX30102 sensor, 0 = no contact).
   - `bit 1`: `motionSuspected` (1 = optical signal corrupted by motion, 0 = clean signal).
   - `bits 2-7`: Reserved for future hardware revisions (must be 0).
3. **`bpmTimes10` (uint16, Offset 2–3):**
   - Raw BPM multiplied by 10 (e.g. `742` = 74.2 BPM).
   - Special value `0xFFFF` indicates calculating or invalid BPM.
   - Valid range: 300 to 2200 (corresponding to 30.0 to 220.0 BPM).
4. **`quality` (uint8, Offset 4):**
   - Optical photoplethysmogram signal quality index ranging from `0` (unusable / noise) to `100` (optimal perfusion).
   - Recommended minimum threshold for valid session inclusion: `60`.
5. **`deviceTimestampMs` (uint32, Offset 5–8):**
   - Free-running millisecond timer on the ESP32-C3 microcontroller since boot.
6. **`sequenceNumber` (uint16, Offset 9–10):**
   - Monotonically increasing packet counter (`0` to `65535`, wraps to `0`). Used by the client to calculate packet dropout and network latency.
7. **`reserved` (uint8, Offset 11):**
   - Padding byte, fixed to `0x00`. The hardware is powered by a small rechargeable battery (or USB-C while charging), but lacks battery-level telemetry (no fuel gauge or voltage divider circuit). The app does not receive battery level, so no battery percentage is displayed, and this byte remains reserved padding.

---

## 3. Raw Optical Samples Characteristic (`180D0002...` - Optional)

- **Notification Rate:** 25 Hz / 50 Hz batches.
- **Payload:** Batches of 16-bit unsigned ADC samples from the MAX30102 IR / Red photodiode.
- **App Behavior:** If this characteristic is omitted by firmware, the client smoothly falls back to displaying the optical trend trace.

---

## 4. Device & Sensor Status Characteristic (`180D0003...`)

- **Access:** Read-only.
- **Payload:** UTF-8 JSON or formatted string:
  ```json
  {
    "fw": "1.0.0-esp32c3",
    "sensor": "MAX30102_OK",
    "battery_mv": null
  }
  ```
- **Rule:** The hardware is powered by a small rechargeable battery (or USB-C while charging), but lacks battery-level telemetry circuitry (no fuel gauge or ADC voltage divider), so `battery_mv` is null and the app does not display a battery percentage.

---

## 5. Defensive Handling in Client App

1. **Length Validation:** Discards any payload where `bytes.length != 12`.
2. **Sequence Tracking:** Computes lost packets when `seq_current != (seq_previous + 1) % 65536`.
3. **Dropout Alarm:** If no packet arrives within 4.0 seconds during an active connection, the UI enters `noSensorData` state.
4. **Reconnection:** Disconnections trigger automatic reconnect attempts with exponential backoff (1s, 2s, 4s, 8s, up to 16s).
