/**
 * PulsePatch Lite — ESP32-C3 Firmware
 * Target: ESP32-C3 + MAX30102 Optical Biomonitoring Sensor
 * Framework: Arduino / PlatformIO
 * Protocol: BLE GATT (Custom 128-bit UUID, 12-byte Little-Endian Heart Rate Packet)
 *
 * Strictly Non-Diagnostic Educational Biomonitoring System.
 */

#include <Arduino.h>
#include <Wire.h>
#include <NimBLEDevice.h>
#include "MAX30105.h" // SparkFun MAX3010x library (fully compatible with MAX30102)

// =============================================================================
// Hardware Configuration & Pinout
// =============================================================================
// Default I2C pins for ESP32-C3 DevKitM-1 (adjust for Xiao or custom PCB if needed)
#ifndef I2C_SDA_PIN
#define I2C_SDA_PIN 4
#endif

#ifndef I2C_SCL_PIN
#define I2C_SCL_PIN 5
#endif

// MAX30102 Optical Perfusion Thresholds
#define FINGER_CONTACT_IR_THRESHOLD  50000UL // Minimum IR reading to signify optical skin contact
#define MOTION_CORRUPTION_DELTA_MAX  12000L  // Max AC acceleration before motion flag is raised
#define MIN_PHYSIOLOGICAL_IBI_MS     272     // ~220 BPM max physiological rate
#define MAX_PHYSIOLOGICAL_IBI_MS     2000    // ~30 BPM min physiological rate

// BLE GATT 128-Bit Custom UUID Definitions (matching docs/ble_protocol.md)
#define SERVICE_UUID           "180D0000-7243-4E64-8843-50554C534531"
#define CHAR_HR_MEASUREMENT    "180D0001-7243-4E64-8843-50554C534531"
#define CHAR_RAW_SAMPLES       "180D0002-7243-4E64-8843-50554C534531"
#define CHAR_DEVICE_STATUS     "180D0003-7243-4E64-8843-50554C534531"

#define FIRMWARE_VERSION       "1.0.0-esp32c3"
#define DEVICE_NAME            "PulsePatch Lite"

// =============================================================================
// Binary Packet Structure (12 Bytes Little-Endian)
// =============================================================================
#pragma pack(push, 1)
struct PulsePacket {
    uint8_t  protocolVersion;   // Offset 0: 0x01
    uint8_t  flags;             // Offset 1: bit0=contactDetected, bit1=motionSuspected
    uint16_t bpmTimes10;        // Offset 2-3: BPM * 10 (0xFFFF = calculating / invalid)
    uint8_t  quality;           // Offset 4: 0 to 100 SQI score
    uint32_t deviceTimestampMs; // Offset 5-8: millis()
    uint16_t sequenceNumber;    // Offset 9-10: Monotonic packet counter
    uint8_t  reserved;          // Offset 11: 0x00 reserved padding
};
#pragma pack(pop)
static_assert(sizeof(PulsePacket) == 12, "PulsePacket size must be exactly 12 bytes");

// =============================================================================
// Global State
// =============================================================================
MAX30105 particleSensor;
bool sensorFound = false;

NimBLEServer* pServer = nullptr;
NimBLECharacteristic* pHrCharacteristic = nullptr;
NimBLECharacteristic* pRawCharacteristic = nullptr;
NimBLECharacteristic* pStatusCharacteristic = nullptr;

bool deviceConnected = false;
bool oldDeviceConnected = false;
uint16_t currentSequence = 0;

// Signal Processing State
float dcFilterIR = 0.0f;
float acFilteredIR = 0.0f;
float prevAcFilteredIR = 0.0f;
unsigned long lastBeatTime = 0;
float currentBpm = 0.0f;
float rateHistory[4] = {0, 0, 0, 0};
uint8_t rateSpot = 0;
bool beatDetected = false;
uint8_t currentQuality = 0;
bool motionFlag = false;

// 1 Hz Notification Dispatch Timer
unsigned long lastPacketSendTime = 0;

// =============================================================================
// BLE Server Callbacks
// =============================================================================
class ServerCallbacks : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) override {
        deviceConnected = true;
        Serial.println(F("[BLE] Central client connected."));
    }

    void onDisconnect(NimBLEServer* pServer) override {
        deviceConnected = false;
        Serial.println(F("[BLE] Central client disconnected. Restarting advertising..."));
    }
};

// =============================================================================
// Algorithmic Filtering & Peak Detection (PPG Signal Processing)
// =============================================================================

/**
 * 1st-order IIR DC removal filter:
 * y[n] = x[n] - x[n-1] + alpha * y[n-1]
 * Keeps dynamic AC optical pulse while removing static tissue DC component.
 */
float filterDcComponent(uint32_t rawSample) {
    const float alpha = 0.95f;
    float prevInput = dcFilterIR;
    dcFilterIR = (float)rawSample;
    float currentAc = (dcFilterIR - prevInput) + (alpha * acFilteredIR);
    acFilteredIR = currentAc;
    return currentAc;
}

/**
 * Evaluates finger contact, checks peak transition, and computes instantaneous BPM.
 */
void processOpticalSample(uint32_t irValue, unsigned long sampleTime) {
    // 1. Contact Detection via DC threshold
    if (irValue < FINGER_CONTACT_IR_THRESHOLD) {
        currentBpm = 0.0f;
        currentQuality = 0;
        motionFlag = false;
        return;
    }

    // 2. High-pass DC baseline removal
    float ac = filterDcComponent(irValue);

    // 3. Motion Artifact Detection (abrupt optical amplitude jump)
    float deltaAc = abs(ac - prevAcFilteredIR);
    if (deltaAc > MOTION_CORRUPTION_DELTA_MAX) {
        motionFlag = true;
    } else {
        motionFlag = false;
    }

    // 4. Peak / Valley Zero-Crossing Detection with Physiological Refractory Window
    // Peak occurs when derivative transitions from positive to negative
    if (prevAcFilteredIR > 150.0f && ac <= 150.0f) {
        unsigned long deltaMs = sampleTime - lastBeatTime;
        if (deltaMs >= MIN_PHYSIOLOGICAL_IBI_MS && deltaMs <= MAX_PHYSIOLOGICAL_IBI_MS) {
            float instantBpm = 60000.0f / (float)deltaMs;

            // Store in 4-sample median / smoothing buffer
            rateHistory[rateSpot++] = instantBpm;
            rateSpot %= 4;

            // Compute running mean
            float sumBpm = 0.0f;
            uint8_t count = 0;
            for (uint8_t i = 0; i < 4; i++) {
                if (rateHistory[i] > 30.0f && rateHistory[i] < 220.0f) {
                    sumBpm += rateHistory[i];
                    count++;
                }
            }

            if (count > 0) {
                currentBpm = sumBpm / (float)count;
            }

            lastBeatTime = sampleTime;
            beatDetected = true;

            // 5. Signal Quality Index (SQI) formulation (0 to 100)
            // Quality is based on amplitude consistency and absence of motion
            float amplitudeScore = min(100.0f, (abs(prevAcFilteredIR) / 400.0f) * 100.0f);
            if (motionFlag) {
                amplitudeScore *= 0.4f; // Penalize for motion
            }
            currentQuality = (uint8_t)constrain(amplitudeScore, 10.0f, 98.0f);
        }
    }

    prevAcFilteredIR = ac;
}

// =============================================================================
// Setup
// =============================================================================
void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println();
    Serial.println(F("=================================================="));
    Serial.println(F("PulsePatch Lite — ESP32-C3 Firmware v" FIRMWARE_VERSION));
    Serial.println(F("Strictly Educational Biomonitoring Device"));
    Serial.println(F("=================================================="));

    // Initialize I2C Bus on configured GPIOs
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
    Wire.setClock(400000); // 400 kHz Fast-Mode I2C

    // Initialize MAX30102 Optical Sensor
    if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
        Serial.println(F("[SENSOR] ERROR: MAX30102 sensor not found on I2C bus!"));
        Serial.println(F("[SENSOR] Verify 3.3V power, GND, SDA (GPIO4), SCL (GPIO5)."));
        sensorFound = false;
    } else {
        Serial.println(F("[SENSOR] SUCCESS: MAX30102 detected."));
        sensorFound = true;

        // Configure MAX30102 for standard photoplethysmography:
        // LED Brightness = 0x1F (approx 6.4mA to avoid skin saturation)
        // Sample Average = 4 samples
        // LED Mode = 2 (Red + IR)
        // Sample Rate = 100 Hz
        // Pulse Width = 411 us (18-bit ADC resolution)
        // ADC Range = 4096 nA
        particleSensor.setup(0x1F, 4, 2, 100, 411, 4096);
    }

    // Initialize NimBLE Stack
    NimBLEDevice::init(DEVICE_NAME);
    NimBLEDevice::setPower(ESP_PWR_LVL_P9); // Max TX power for robust indoor range
    NimBLEDevice::setSecurityAuth(false, false, false);

    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    // Create Custom Primary GATT Service
    NimBLEService* pService = pServer->createService(SERVICE_UUID);

    // 1. Heart Rate Measurement Characteristic (Notify, 12 bytes)
    pHrCharacteristic = pService->createCharacteristic(
        CHAR_HR_MEASUREMENT,
        NIMBLE_PROPERTY::NOTIFY
    );

    // 2. Raw Optical Trace Characteristic (Notify, Optional)
    pRawCharacteristic = pService->createCharacteristic(
        CHAR_RAW_SAMPLES,
        NIMBLE_PROPERTY::NOTIFY
    );

    // 3. Device & Sensor Information Characteristic (Read-Only)
    pStatusCharacteristic = pService->createCharacteristic(
        CHAR_DEVICE_STATUS,
        NIMBLE_PROPERTY::READ
    );

    // Populate Initial Device Status JSON String
    char statusJson[128];
    snprintf(statusJson, sizeof(statusJson),
        "{\"fw\":\"%s\",\"sensor\":\"%s\",\"battery_mv\":null}",
        FIRMWARE_VERSION,
        sensorFound ? "MAX30102_OK" : "MAX30102_NOT_FOUND"
    );
    pStatusCharacteristic->setValue(statusJson);

    // Start GATT Service
    pService->start();

    // Configure BLE Advertising
    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->start();

    Serial.println(F("[BLE] Advertising started. Waiting for PulsePatch mobile client..."));
}

// =============================================================================
// Main Execution Loop
// =============================================================================
void loop() {
    unsigned long now = millis();

    // 1. Poll MAX30102 sensor if detected
    if (sensorFound) {
        particleSensor.check(); // Check FIFO for new samples
        while (particleSensor.available()) {
            uint32_t irValue = particleSensor.getFIFOIR();
            particleSensor.nextSample();
            processOpticalSample(irValue, now);
        }
    }

    // 2. Dispatch 1 Hz Heart Rate Packet over BLE
    if (now - lastPacketSendTime >= 1000) {
        lastPacketSendTime = now;

        PulsePacket packet;
        packet.protocolVersion = 0x01;
        packet.flags = 0;

        // Contact detection
        if (sensorFound && particleSensor.getIR() > FINGER_CONTACT_IR_THRESHOLD) {
            packet.flags |= 0x01; // bit0: contactDetected = true
        }

        // Motion detection
        if (motionFlag) {
            packet.flags |= 0x02; // bit1: motionSuspected = true
        }

        // BPM calculation or 0xFFFF if calculating / no contact
        if ((packet.flags & 0x01) && currentBpm >= 30.0f && currentBpm <= 220.0f) {
            packet.bpmTimes10 = (uint16_t)(currentBpm * 10.0f);
            packet.quality = currentQuality;
        } else {
            packet.bpmTimes10 = 0xFFFF; // 0xFFFF denotes calculating / invalid
            packet.quality = (packet.flags & 0x01) ? 20 : 0;
        }

        packet.deviceTimestampMs = now;
        packet.sequenceNumber = currentSequence++;
        packet.reserved = 0x00;

        // Send BLE notification if connected
        if (deviceConnected && pHrCharacteristic != nullptr) {
            pHrCharacteristic->setValue((uint8_t*)&packet, sizeof(PulsePacket));
            pHrCharacteristic->notify();
        }

        // Debug output to Serial Monitor for hardware calibration
        Serial.printf(
            "[PulsePatch] Seq:%5u | Contact:%s | Motion:%s | BPM:%s | Quality:%3u%% | TS:%lums\n",
            packet.sequenceNumber,
            (packet.flags & 0x01) ? "YES" : " NO",
            (packet.flags & 0x02) ? "YES" : " NO",
            (packet.bpmTimes10 != 0xFFFF) ? String(packet.bpmTimes10 / 10.0f, 1).c_str() : "---.-",
            packet.quality,
            packet.deviceTimestampMs
        );
    }

    // Handle BLE reconnection state
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // Give Bluetooth stack time to settle
        pServer->startAdvertising();
        Serial.println(F("[BLE] Resumed advertising."));
        oldDeviceConnected = deviceConnected;
    }

    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }

    delay(5); // Yield to FreeRTOS watchdog
}
