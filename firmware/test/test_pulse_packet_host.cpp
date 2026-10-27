// Host-only g++ test: Serialize PulsePacket and compare against golden bytes.
// Compile: g++ -std=c++17 -I../include -o test_pulse_packet_host firmware/test/test_pulse_packet_host.cpp
// Run: ./test_pulse_packet_host

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cassert>
#include "../include/pulse_config.h"

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

static_assert(sizeof(PulsePacket) == BLE_PACKET_BYTES,
              "PulsePacket size mismatch — expected 12 bytes");

int main() {
    // Golden bytes (matches test_assets/golden_pulse_packet.bin)
    const uint8_t GOLDEN[12] = {
        0x01, 0x00,              // protocolVersion=1, flags=0
        0xD0, 0x02,              // bpmTimes10=720 (72.0 BPM) LE
        0x55,                    // quality=85
        0xE8, 0x03, 0x00, 0x00,  // deviceTimestampMs=1000 LE
        0x01, 0x00,              // sequenceNumber=1 LE
        0x00                     // reserved=0
    };

    PulsePacket pkt{};
    pkt.protocolVersion  = 1;
    pkt.flags            = 0;
    pkt.bpmTimes10       = 720;
    pkt.quality          = 85;
    pkt.deviceTimestampMs = 1000;
    pkt.sequenceNumber   = 1;
    pkt.reserved         = 0;

    uint8_t buf[12];
    memcpy(buf, &pkt, 12);

    printf("Serialized: ");
    for (int i = 0; i < 12; i++) printf("%02X ", buf[i]);
    printf("\nGolden:     ");
    for (int i = 0; i < 12; i++) printf("%02X ", GOLDEN[i]);
    printf("\n");

    assert(memcmp(buf, GOLDEN, 12) == 0 && "PulsePacket serialization mismatch!");
    printf("PASS: PulsePacket 12-byte layout matches golden bytes.\n");
    return 0;
}
