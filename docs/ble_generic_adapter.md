# BLE Generic Adapter Specification & Hardware Guide

PulsePatch Lite includes a universal **Generic BLE Chip Adapter** designed to interface with custom electronics, microcontrollers (ESP32, ESP32-C3, nRF52, Arduino BLE), and third-party peripherals that transmit heart-rate data over Bluetooth Low Energy.

---

## 1. Architecture & Protocol Routing

When scanning for Bluetooth Low Energy devices, PulsePatch Lite routes peripherals according to the following priority:

1. **Standard Heart Rate Profile (0x180D / 0x2A37):** Subscribes to standard Bluetooth SIG notifications or indications with automatic 8-bit/16-bit BPM detection, contact flags, and RR intervals.
2. **PulsePatch Custom Protocol:** 12-byte binary packet with sync byte and MAX30102 raw AC/DC optical metrics.
3. **Generic BLE Chip Adapter (Nordic UART Service or Custom Mapped Characteristic):** Automatically detects the Nordic UART Service (`6E400001-B5A3-F393-E0A9-E50E24DCCA9E` with TX `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`) or allows user-defined characteristic mapping stored in device preferences.

---

## 2. Supported Wire Formats

The Generic BLE adapter parses incoming notification or indication payloads using one of four selectable wire formats:

| Format Name | Code | Wire Encoding | Example Payload | Decoded BPM |
| :--- | :--- | :--- | :--- | :--- |
| **uint8 BPM** | `uint8` | Single unsigned 8-bit byte | `[0x48]` | 72.0 BPM |
| **uint16 little-endian BPM** | `uint16_le` | 2 bytes, little-endian unsigned integer | `[0x48, 0x00]` | 72.0 BPM |
| **uint16 BPM x10** | `uint16_x10` | 2 bytes little-endian, scaled by 10 (0.1 BPM resolution) | `[0xD0, 0x02]` (720) | 72.0 BPM |
| **ASCII text line** | `ascii_regex` | UTF-8 plain string with optional regex pattern | `"BPM:72\n"` | 72.0 BPM |

### Validity Gate (30 – 220 BPM)
Every received packet is strictly evaluated against a physiological validity gate:
$$\text{Valid} \iff 30.0 \le \text{BPM} \le 220.0$$
Any readings outside this range are rejected, preventing corrupted bytes or noise from entering downstream session statistics or the AI classifier.

---

## 3. Nordic UART Service (NUS) Default UUIDs

When a peripheral advertises the Nordic Semiconductor UART service, PulsePatch Lite automatically tags it with the **Nordic UART** badge and pre-fills the configuration:

- **Service UUID:** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- **TX Characteristic (Notify):** `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- **RX Characteristic (Write):** `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`

---

## 4. Hardware Implementation Examples

### A. ESP32-C3 / Arduino (Nordic UART Service - ASCII Text Format)

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    }
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      BLEDevice::startAdvertising();
    }
};

void setup() {
  Serial.begin(115200);
  BLEDevice::init("ESP32_PulsePatch");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pTxCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID_TX,
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
  pTxCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
}

void loop() {
  if (deviceConnected) {
    uint8_t simulatedBpm = 72; // Replace with sensor calculation
    char payload[16];
    snprintf(payload, sizeof(payload), "BPM:%d\n", simulatedBpm);

    pTxCharacteristic->setValue((uint8_t*)payload, strlen(payload));
    pTxCharacteristic->notify();
    delay(1000);
  }
}
```

### B. ESP32 / Arduino (uint8 Direct Byte Format)

```cpp
// Within loop when connected:
uint8_t bpmValue = 75; // 30 - 220 BPM
pTxCharacteristic->setValue(&bpmValue, 1);
pTxCharacteristic->notify();
delay(1000);
```

---

## 5. User Mapping & Device Persistence

1. In the **Connect Device** screen, tap on any discovered device row.
2. In the bottom sheet, tap **Advanced: map this characteristic**.
3. Confirm the **Service UUID**, **Characteristic UUID**, and **Data Wire Format**.
4. Tap **Save Mapping & Connect**. The configuration is saved locally in `SharedPreferences` for that device MAC and restored automatically on subsequent scans.
