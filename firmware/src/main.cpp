/**
 * PulsePatch Lite — ESP32-C3 Firmware v2.0.0
 * Target: ESP32-C3 + MAX30102 Optical Biomonitoring Sensor
 * Framework: Arduino / PlatformIO
 * Protocol: BLE GATT (Custom 128-bit UUID, 12-byte Little-Endian Heart Rate & SpO2 Packet)
 *
 * Strictly Non-Diagnostic Educational Biomonitoring System.
 */

#include <Arduino.h>
#include <Wire.h>
#include <NimBLEDevice.h>
#include "MAX30105.h" // SparkFun MAX3010x library (fully compatible with MAX30102)
#include "pulse_config.h"

// =============================================================================
// Hardware Configuration & Pinout
// =============================================================================
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

#define FIRMWARE_VERSION       "2.0.0-esp32c3"
#define DEVICE_NAME            "PulsePatch Lite"

// =============================================================================
// Binary Packet Structure (12 Bytes Little-Endian)
// Byte 11 is now used for SpO2 percentage (70-100%, 0 = calculating/uncalibrated)
// =============================================================================
#pragma pack(push, 1)
struct PulsePacket {
    uint8_t  protocolVersion;   // Offset 0: 0x01
    uint8_t  flags;             // Offset 1: bit0=contactDetected, bit1=motionSuspected
    uint16_t bpmTimes10;        // Offset 2-3: BPM * 10 (0xFFFF = calculating / invalid)
    uint8_t  quality;           // Offset 4: 0 to 100 SQI score
    uint32_t deviceTimestampMs; // Offset 5-8: millis()
    uint16_t sequenceNumber;    // Offset 9-10: Monotonic packet counter
    uint8_t  spo2Percent;       // Offset 11: 70..100 (0x00 if calculating)
};
#pragma pack(pop)
static_assert(sizeof(PulsePacket) == 12, "PulsePacket size must be exactly 12 bytes");

// Binary Raw Waveform Packet for CHAR_RAW_SAMPLES (12 bytes: IR + Red)
#pragma pack(push, 1)
struct RawSamplePacket {
    uint32_t timestampMs;       // Offset 0-3: millis()
    uint32_t irSample;          // Offset 4-7: 18-bit IR raw value
    uint32_t redSample;         // Offset 8-11: 18-bit Red raw value
};
#pragma pack(pop)
static_assert(sizeof(RawSamplePacket) == 12, "RawSamplePacket size must be 12 bytes");

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

// Dual-Wavelength Signal Processing State
float dcFilterIR = 0.0f;
float acFilteredIR = 0.0f;
float prevAcFilteredIR = 0.0f;

float dcFilterRed = 0.0f;
float acFilteredRed = 0.0f;

unsigned long lastBeatTime = 0;
float currentBpm = 0.0f;
float rateHistory[4] = {0, 0, 0, 0};
uint8_t rateSpot = 0;
bool beatDetected = false;
uint8_t currentQuality = 0;
bool motionFlag = false;

// Dual-wavelength SpO2 ratio tracking
float redAcPeakToPeak = 0.0f;
float irAcPeakToPeak = 0.0f;
float minAcRed = 99999.0f, maxAcRed = -99999.0f;
float minAcIr = 99999.0f, maxAcIr = -99999.0f;
uint8_t currentSpo2 = 0; // 0 = uncalibrated/calculating

// 1 Hz Notification Dispatch Timer
unsigned long lastPacketSendTime = 0;
unsigned long lastRawStreamTime = 0;

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
// Dual-Wavelength Photoplethysmogram Digital Signal Processing
// =============================================================================
void processDualOpticalSample(uint32_t irRaw, uint32_t redRaw, unsigned long sampleTime) {
    // 1. Skin Contact Perfusion Gate
    if (irRaw < FINGER_CONTACT_IR_THRESHOLD) {
        currentBpm = 0.0f;
        currentQuality = 0;
        currentSpo2 = 0;
        beatDetected = false;
        motionFlag = false;
        dcFilterIR = (float)irRaw;
        dcFilterRed = (float)redRaw;
        prevAcFilteredIR = 0.0f;
        minAcRed = 99999.0f; maxAcRed = -99999.0f;
        minAcIr = 99999.0f; maxAcIr = -99999.0f;
        return;
    }

    // 2. DC Baseline Estimation (Single-pole IIR highpass filter, fc ~0.5 Hz)
    dcFilterIR = 0.95f * dcFilterIR + 0.05f * (float)irRaw;
    float acIr = (float)irRaw - dcFilterIR;

    dcFilterRed = 0.95f * dcFilterRed + 0.05f * (float)redRaw;
    float acRed = (float)redRaw - dcFilterRed;

    // 3. Motion Artifact Detection via Dynamic Acceleration Limits
    float deltaAc = abs(acIr - prevAcFilteredIR);
    motionFlag = (deltaAc > MOTION_CORRUPTION_DELTA_MAX);

    // Track Peak-to-Peak for SpO2 calculation
    if (acRed < minAcRed) minAcRed = acRed;
    if (acRed > maxAcRed) maxAcRed = acRed;
    if (acIr < minAcIr) minAcIr = acIr;
    if (acIr > maxAcIr) maxAcIr = acIr;

    // 4. Systolic Peak Detection (Zero-Crossing from Positive to Negative)
    if (prevAcFilteredIR > 0.0f && acIr <= 0.0f && !motionFlag) {
        unsigned long deltaMs = sampleTime - lastBeatTime;

        if (deltaMs >= MIN_PHYSIOLOGICAL_IBI_MS && deltaMs <= MAX_PHYSIOLOGICAL_IBI_MS) {
            float instantBpm = 60000.0f / (float)deltaMs;

            rateHistory[rateSpot++] = instantBpm;
            rateSpot %= 4;

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

            // Signal Quality Index (SQI)
            float amplitudeScore = min(100.0f, (abs(prevAcFilteredIR) / 400.0f) * 100.0f);
            if (motionFlag) {
                amplitudeScore *= 0.4f;
            }
            currentQuality = (uint8_t)constrain(amplitudeScore, 10.0f, 98.0f);

            // SpO2 Dual-Wavelength Calibration via Ratio of Ratios:
            // R = (AC_red / DC_red) / (AC_ir / DC_ir)
            float p2pRed = maxAcRed - minAcRed;
            float p2pIr = maxAcIr - minAcIr;

            if (dcFilterRed > 1000.0f && dcFilterIR > 1000.0f && p2pIr > 20.0f && p2pRed > 20.0f) {
                float rRatio = (p2pRed / dcFilterRed) / (p2pIr / dcFilterIR);
                // Standard calibration curve: SpO2 = 110 - 25 * R
                float estimatedSpo2 = 110.0f - 25.0f * rRatio;
                currentSpo2 = (uint8_t)constrain(estimatedSpo2, 70.0f, 100.0f);
            }

            // Reset P2P trackers for next pulse period
            minAcRed = 99999.0f; maxAcRed = -99999.0f;
            minAcIr = 99999.0f; maxAcIr = -99999.0f;
        }
    }

    prevAcFilteredIR = acIr;
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

    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
    Wire.setClock(400000);

    if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
        Serial.println(F("[SENSOR] ERROR: MAX30102 sensor not found on I2C bus!"));
        sensorFound = false;
    } else {
        Serial.println(F("[SENSOR] SUCCESS: MAX30102 detected."));
        sensorFound = true;
        // Mode 2: Red + IR dual-wavelength active
        particleSensor.setup(0x1F, 4, 2, 100, 411, 4096);
    }

    NimBLEDevice::init(DEVICE_NAME);
    NimBLEDevice::setPower(ESP_PWR_LVL_P9);
    NimBLEDevice::setSecurityAuth(false, false, false);

    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService* pService = pServer->createService(SERVICE_UUID);

    pHrCharacteristic = pService->createCharacteristic(
        CHAR_HR_MEASUREMENT,
        NIMBLE_PROPERTY::NOTIFY
    );

    pRawCharacteristic = pService->createCharacteristic(
        CHAR_RAW_SAMPLES,
        NIMBLE_PROPERTY::NOTIFY
    );

    pStatusCharacteristic = pService->createCharacteristic(
        CHAR_DEVICE_STATUS,
        NIMBLE_PROPERTY::READ
    );

    char statusJson[128];
    snprintf(statusJson, sizeof(statusJson),
        "{\"fw\":\"%s\",\"sensor\":\"%s\",\"spo2_supported\":true}",
        FIRMWARE_VERSION,
        sensorFound ? "MAX30102_DUAL_OK" : "MAX30102_NOT_FOUND"
    );
    pStatusCharacteristic->setValue(statusJson);

    pService->start();

    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->start();

    Serial.println(F("[BLE] Advertising started. Dual-wavelength ready."));
}

// =============================================================================
// Main Execution Loop
// =============================================================================
void loop() {
    unsigned long now = millis();

    // 1. Poll MAX30102 sensor (Red and IR channels)
    if (sensorFound) {
        particleSensor.check();
        while (particleSensor.available()) {
            uint32_t irVal = particleSensor.getFIFOIR();
            uint32_t redVal = particleSensor.getFIFORed();
            particleSensor.nextSample();

            processDualOpticalSample(irVal, redVal, now);

            // Stream raw waveforms over CHAR_RAW_SAMPLES (throttled to 25 Hz for BLE MTU budget)
            if (deviceConnected && pRawCharacteristic != nullptr && (now - lastRawStreamTime >= 40)) {
                lastRawStreamTime = now;
                RawSamplePacket rawPkt;
                rawPkt.timestampMs = now;
                rawPkt.irSample = irVal;
                rawPkt.redSample = redVal;
                pRawCharacteristic->setValue((uint8_t*)&rawPkt, sizeof(RawSamplePacket));
                pRawCharacteristic->notify();
            }
        }
    }

    // 2. Dispatch 1 Hz Heart Rate & SpO2 Packet over BLE
    if (now - lastPacketSendTime >= 1000) {
        lastPacketSendTime = now;

        PulsePacket packet;
        packet.protocolVersion = 0x01;
        packet.flags = 0;

        if (sensorFound && particleSensor.getIR() > FINGER_CONTACT_IR_THRESHOLD) {
            packet.flags |= 0x01;
        }

        if (motionFlag) {
            packet.flags |= 0x02;
        }

        if ((packet.flags & 0x01) && currentBpm >= 30.0f && currentBpm <= 220.0f) {
            packet.bpmTimes10 = (uint16_t)(currentBpm * 10.0f);
            packet.quality = currentQuality;
            packet.spo2Percent = currentSpo2;
        } else {
            packet.bpmTimes10 = 0xFFFF;
            packet.quality = (packet.flags & 0x01) ? 20 : 0;
            packet.spo2Percent = 0;
        }

        packet.deviceTimestampMs = now;
        packet.sequenceNumber = currentSequence++;

        if (deviceConnected && pHrCharacteristic != nullptr) {
            pHrCharacteristic->setValue((uint8_t*)&packet, sizeof(PulsePacket));
            pHrCharacteristic->notify();
        }

        Serial.printf(
            "[PulsePatch] Seq:%5u | Contact:%s | Motion:%s | BPM:%s | SpO2:%s | Qual:%3u%%\n",
            packet.sequenceNumber,
            (packet.flags & 0x01) ? "YES" : " NO",
            (packet.flags & 0x02) ? "YES" : " NO",
            (packet.bpmTimes10 != 0xFFFF) ? String(packet.bpmTimes10 / 10.0f, 1).c_str() : "---.-",
            (packet.spo2Percent > 0) ? (String(packet.spo2Percent) + "%").c_str() : "--%",
            packet.quality
        );
    }

    if (!deviceConnected && oldDeviceConnected) {
        delay(500);
        pServer->startAdvertising();
        Serial.println(F("[BLE] Resumed advertising."));
        oldDeviceConnected = deviceConnected;
    }

    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }

    delay(5);
}
