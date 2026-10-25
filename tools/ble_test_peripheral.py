#!/usr/bin/env python3
"""
PulsePatch Lite - BLE Test Peripheral Simulation Utility

Simulates a Bluetooth Low Energy peripheral broadcasting the standard
Bluetooth SIG Heart Rate Service (0x180D) and characteristic (0x2A37).
Supports generating sinusoidal and stepped physiological BPM values (60-140 BPM)
for validating BLE connection, MTU negotiation, notification subscription,
and validity gating on real host devices without physical sensors.

Requirements:
    pip install bless bleak (or run on Linux/macOS/Windows with BLE advertising capability)
"""

import sys
import time
import math
import argparse
import asyncio

try:
    from bless import (
        BlessServer,
        BlessGATTCharacteristic,
        GATTCharacteristicProperties,
        GATTAttributePermissions,
    )
    HAVE_BLESS = True
except ImportError:
    HAVE_BLESS = False


# Standard Bluetooth SIG UUIDs
HEART_RATE_SERVICE_UUID = "0000180D-0000-1000-8000-00805f9b34fb"
HEART_RATE_MEASUREMENT_UUID = "00002A37-0000-1000-8000-00805f9b34fb"


def encode_hr_packet(bpm: int, sensor_contact: bool = True, rr_interval_ms: float = None) -> bytearray:
    """
    Encodes standard 0x2A37 Heart Rate Measurement packet.
    Flags:
      Bit 0: 0 = uint8 BPM, 1 = uint16 BPM
      Bit 1: Sensor contact detected bit
      Bit 2: Sensor contact supported bit
      Bit 4: RR-Interval present bit
    """
    flags = 0
    if sensor_contact:
        flags |= 0x06  # Contact supported (bit 2) and detected (bit 1)

    payload = bytearray()
    
    if bpm <= 255:
        # uint8 format
        payload.append(flags)
        payload.append(bpm & 0xFF)
    else:
        # uint16 format
        flags |= 0x01
        payload.append(flags)
        payload.append(bpm & 0xFF)
        payload.append((bpm >> 8) & 0xFF)

    if rr_interval_ms is not None:
        flags |= 0x10  # RR present
        payload[0] = flags
        # RR interval in 1/1024 seconds units
        rr_units = int(round(rr_interval_ms * 1024.0 / 1000.0))
        payload.append(rr_units & 0xFF)
        payload.append((rr_units >> 8) & 0xFF)

    return payload


async def run_peripheral(device_name: str, base_bpm: int, duration_sec: int):
    if not HAVE_BLESS:
        print("[!] The 'bless' package is not installed. To run the live BLE server:")
        print("    pip install bless")
        print("\n[+] Demonstration packet generator output (synthetic stream):")
        start = time.time()
        seq = 0
        while time.time() - start < duration_sec:
            t = time.time() - start
            bpm = int(round(base_bpm + 15 * math.sin(t / 5.0)))
            rr = 60000.0 / bpm
            pkt = encode_hr_packet(bpm, sensor_contact=True, rr_interval_ms=rr)
            hex_str = " ".join(f"0x{b:02X}" for b in pkt)
            print(f"  Seq {seq:04d} | BPM: {bpm:3d} | RR: {rr:5.1f}ms | Raw Bytes [{hex_str}]")
            seq += 1
            await asyncio.sleep(1.0)
        return

    server = BlessServer(name=device_name)

    print(f"[*] Starting BLE Peripheral '{device_name}'...")
    await server.add_new_service(HEART_RATE_SERVICE_UUID)
    
    char_flags = (
        GATTCharacteristicProperties.notify |
        GATTCharacteristicProperties.read
    )
    permissions = GATTAttributePermissions.readable

    await server.add_new_characteristic(
        HEART_RATE_SERVICE_UUID,
        HEART_RATE_MEASUREMENT_UUID,
        char_flags,
        None,
        permissions
    )

    await server.start()
    print(f"[+] Advertising as '{device_name}' with Heart Rate Service (0x180D)...")

    start_time = time.time()
    try:
        while time.time() - start_time < duration_sec:
            elapsed = time.time() - start_time
            # Vary BPM sinusoidally between base_bpm-10 and base_bpm+10
            bpm = int(round(base_bpm + 10.0 * math.sin(elapsed / 4.0)))
            rr = 60000.0 / bpm
            val = encode_hr_packet(bpm, sensor_contact=True, rr_interval_ms=rr)
            
            server.get_characteristic(HEART_RATE_MEASUREMENT_UUID).value = val
            server.update_value(HEART_RATE_SERVICE_UUID, HEART_RATE_MEASUREMENT_UUID)
            print(f"  [Notified] Live BPM: {bpm} (RR: {rr:.1f} ms)")
            await asyncio.sleep(1.0)
    finally:
        print("[*] Stopping BLE advertising...")
        await server.stop()


def main():
    parser = argparse.ArgumentParser(description="PulsePatch Lite BLE Heart Rate Test Peripheral")
    parser.add_argument("--name", default="PulsePatch-SimHR", help="Advertised BLE Device Name")
    parser.add_argument("--bpm", type=int, default=72, help="Base heart rate in BPM")
    parser.add_argument("--duration", type=int, default=30, help="Simulation duration in seconds")
    args = parser.parse_args()

    asyncio.run(run_peripheral(args.name, args.bpm, args.duration))


if __name__ == "__main__":
    main()
