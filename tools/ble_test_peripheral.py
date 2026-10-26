#!/usr/bin/env python3
"""
PulsePatch Lite - BLE Heart Rate Test Peripheral & Verification Utility
Conforms to Master Build Plan Section 7.3 & Universal BLE Testing Protocol.

Simulates a Bluetooth Low Energy peripheral broadcasting the standard
Bluetooth SIG Heart Rate Service (0x180D) and characteristic (0x2A37).
Provides reproducible physiological test streams:
  1. 'resting': 60-second resting session (~72 BPM with natural respiratory sinus arrhythmia)
  2. 'post-activity': 90-second recovery session (starting at ~128 BPM, recovering to ~82 BPM at 60s, ~74 BPM at 90s)
  3. 'sine': 30-second sinusoidal oscillation

Also records the ground-truth stream to CSV and calculates reference metrics:
  - mean_hr, std_hr, min_hr, max_hr, start_hr, end_hr, recovery_drop
using the exact same mathematical formulas as SessionRecorder in the Flutter app.

Requirements:
    bless, bleak (installed in .venv311)
"""

import sys
import os
import time
import math
import argparse
import asyncio
import statistics
from typing import List, Dict, Any, Optional

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


def encode_hr_packet(bpm: int, sensor_contact: bool = True, rr_interval_ms: Optional[float] = None) -> bytearray:
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


def compute_metrics(samples: List[Dict[str, Any]], session_type: str, total_duration_s: float) -> Dict[str, Any]:
    """
    Calculates session summary metrics using the exact algorithms from
    app/lib/domain/signal/session_recorder.dart:
      - mean_hr: arithmetic mean of BPMs
      - std_hr: sample standard deviation
      - min_hr, max_hr
      - start_hr: median of BPMs in first 10 seconds (t_ms <= 10000)
      - end_hr: median of BPMs in last 10 seconds (t_ms >= max_t - 10000)
      - recovery_drop:
          For post-activity >= 70s: start_hr - median(window 55s-65s)
          For rest / other: start_hr - end_hr
    """
    if not samples:
        return {}

    bpms = [float(s["bpm"]) for s in samples]
    count = len(bpms)
    mean_val = statistics.mean(bpms)
    std_val = statistics.stdev(bpms) if count > 1 else 0.0

    # start_hr: median of BPM in first 10 seconds (t_ms <= 10000)
    first_10s = [float(s["bpm"]) for s in samples if s["t_ms"] <= 10000]
    start_hr = statistics.median(first_10s) if first_10s else statistics.median(bpms[:min(10, count)])

    # end_hr: median of BPM in last 10 seconds (t_ms >= max_t - 10000)
    max_t = samples[-1]["t_ms"]
    last_10s = [float(s["bpm"]) for s in samples if s["t_ms"] >= (max_t - 10000)]
    end_hr = statistics.median(last_10s) if last_10s else statistics.median(bpms[max(0, count - 10):])

    # recovery_drop
    if "post" in session_type.lower() and total_duration_s >= 70:
        rec_window = [float(s["bpm"]) for s in samples if 55000 <= s["t_ms"] <= 65000]
        if rec_window:
            recovery_drop = start_hr - statistics.median(rec_window)
        else:
            recovery_drop = start_hr - end_hr
    else:
        recovery_drop = start_hr - end_hr

    return {
        "valid_sample_count": count,
        "total_duration_s": total_duration_s,
        "mean_hr": round(mean_val, 2),
        "std_hr": round(std_val, 2),
        "min_hr": int(min(bpms)),
        "max_hr": int(max(bpms)),
        "start_hr": round(start_hr, 1),
        "end_hr": round(end_hr, 1),
        "recovery_drop": round(recovery_drop, 1),
    }


def generate_bpm_for_mode(mode: str, elapsed: float, duration: float, base_bpm: int) -> int:
    """Generates deterministic, physiological BPM for given test mode and elapsed time."""
    if mode == "resting":
        # Realistic resting baseline with respiratory sinus arrhythmia (~0.25 Hz)
        rsa = 1.8 * math.sin(2.0 * math.pi * 0.25 * elapsed)
        drift = 0.5 * math.sin(elapsed * 0.05)
        return int(round(base_bpm + rsa + drift))

    elif mode == "post-activity":
        # Post-exercise heart rate recovery curve:
        # 0s - 10s: high plateau (peak post-exercise ~127-128 BPM)
        # 10s - 60s: steep exponential deceleration toward ~82 BPM
        # 60s - 90s: gentle leveling toward ~74 BPM
        if elapsed <= 10.0:
            return int(round(128.0 - 0.2 * elapsed))
        elif elapsed <= 60.0:
            # Exponential decay: 126 down to 82
            p = (elapsed - 10.0) / 50.0
            decay = (1.0 - math.exp(-2.5 * p)) / (1.0 - math.exp(-2.5))
            return int(round(126.0 - 44.0 * decay))
        else:
            # 82 down to 74, clamped so it never drops below normal recovery baseline
            p = min(1.0, max(0.0, (elapsed - 60.0) / 30.0))
            rsa = 1.0 * math.sin(elapsed * 0.25)
            return int(round(82.0 - 8.0 * p + rsa))

    else:  # 'sine'
        return int(round(base_bpm + 10.0 * math.sin(elapsed / 4.0)))


async def run_peripheral(device_name: str, mode: str, base_bpm: int, duration_sec: int, csv_out: Optional[str] = None):
    if not HAVE_BLESS:
        print("[!] ERROR: 'bless' is not available in the current environment.")
        print("    Please run with .venv311\\Scripts\\python.exe")
        sys.exit(1)

    print("=" * 80)
    print(f"PULSEPATCH LITE — BLE TEST PERIPHERAL")
    print(f"Device Name: {device_name}")
    print(f"Mode:        {mode.upper()}")
    print(f"Duration:    {duration_sec} seconds")
    print(f"Base BPM:    {base_bpm}")
    if csv_out:
        print(f"Ground Truth CSV: {csv_out}")
    print("=" * 80)

    server = BlessServer(name=device_name)

    print(f"[*] Initializing GATT Heart Rate Service (0x180D)...")
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

    print(f"[*] Starting BLE Advertisement...")
    await server.start()
    print(f"[+] ADVERTISING ACTIVE. Waiting for phone to connect as '{device_name}'...\n")

    samples: List[Dict[str, Any]] = []
    start_time = time.time()
    seq = 0

    try:
        while True:
            elapsed = time.time() - start_time
            if elapsed >= duration_sec:
                break

            bpm = generate_bpm_for_mode(mode, elapsed, duration_sec, base_bpm)
            rr = 60000.0 / bpm
            t_ms = int(round(elapsed * 1000.0))

            val = encode_hr_packet(bpm, sensor_contact=True, rr_interval_ms=rr)
            server.get_characteristic(HEART_RATE_MEASUREMENT_UUID).value = val
            server.update_value(HEART_RATE_SERVICE_UUID, HEART_RATE_MEASUREMENT_UUID)

            sample_entry = {
                "sequence": seq,
                "t_ms": t_ms,
                "elapsed_s": round(elapsed, 2),
                "bpm": bpm,
                "rr_ms": round(rr, 1),
            }
            samples.append(sample_entry)

            hex_str = " ".join(f"0x{b:02X}" for b in val)
            print(f"  [Seq {seq:03d} | {elapsed:05.1f}s] Live BPM: {bpm:3d} (RR: {rr:5.1f}ms) | Raw: [{hex_str}]")

            seq += 1
            await asyncio.sleep(1.0)

    except KeyboardInterrupt:
        print("\n[*] Interrupted by user.")
    finally:
        print("\n[*] Stopping BLE server...")
        try:
            await server.stop()
        except Exception:
            pass

    actual_duration = time.time() - start_time
    stats = compute_metrics(samples, mode, actual_duration)

    # Save Ground Truth CSV if requested
    if csv_out and samples:
        os.makedirs(os.path.dirname(os.path.abspath(csv_out)), exist_ok=True)
        with open(csv_out, "w", encoding="utf-8") as f:
            f.write("sequence,t_ms,elapsed_s,bpm,rr_ms\n")
            for s in samples:
                f.write(f"{s['sequence']},{s['t_ms']},{s['elapsed_s']},{s['bpm']},{s['rr_ms']}\n")
        print(f"\n[+] Ground-truth stream saved to: {csv_out}")

    print("\n" + "=" * 80)
    print("GROUND TRUTH STREAM REFERENCE METRICS (Exact mathematical expectation)")
    print("=" * 80)
    for k, v in stats.items():
        print(f"  {k:<22}: {v}")
    print("=" * 80)
    print("Use these values to verify against the Session Details screen in the mobile app.\n")
    return stats


def compare_with_app_export(ground_truth_csv: str, app_export_csv: str):
    """Compares ground-truth peripheral stream against CSV exported from the app."""
    import pandas as pd
    gt_df = pd.read_csv(ground_truth_csv)
    app_df = pd.read_csv(app_export_csv)

    print("=" * 80)
    print("COMPARISON: GROUND TRUTH PERIPHERAL STREAM vs APP EXPORTED DATA")
    print("=" * 80)
    print(f"Ground Truth Samples: {len(gt_df)}")
    print(f"App Export Samples:   {len(app_df)}")
    
    gt_bpm = gt_df["bpm"].values
    # Check app column name
    col = "bpm" if "bpm" in app_df.columns else "raw_bpm"
    app_bpm = app_df[col].dropna().values

    print(f"\nMetric               | Ground Truth | App Export | Difference")
    print("-" * 65)
    print(f"Sample Count         | {len(gt_bpm):<12} | {len(app_bpm):<10} | {len(app_bpm) - len(gt_bpm)}")
    print(f"Mean HR (BPM)        | {gt_bpm.mean():<12.2f} | {app_bpm.mean():<10.2f} | {abs(app_bpm.mean() - gt_bpm.mean()):.2f}")
    print(f"Std Dev HR (BPM)     | {gt_bpm.std():<12.2f} | {app_bpm.std():<10.2f} | {abs(app_bpm.std() - gt_bpm.std()):.2f}")
    print(f"Min HR (BPM)         | {gt_bpm.min():<12} | {app_bpm.min():<10} | {abs(app_bpm.min() - gt_bpm.min())}")
    print(f"Max HR (BPM)         | {gt_bpm.max():<12} | {app_bpm.max():<10} | {abs(app_bpm.max() - gt_bpm.max())}")
    print("=" * 80)


def main():
    parser = argparse.ArgumentParser(description="PulsePatch Lite BLE Heart Rate Test Peripheral")
    parser.add_argument("--name", default="PulsePatch-SimHR", help="Advertised BLE Device Name (default: PulsePatch-SimHR)")
    parser.add_argument("--mode", choices=["resting", "post-activity", "sine"], default="resting", help="Simulation mode (default: resting)")
    parser.add_argument("--bpm", type=int, default=None, help="Base BPM (default: 72 for resting, 128 for post-activity)")
    parser.add_argument("--duration", type=int, default=None, help="Duration in seconds (default: 60 for resting, 90 for post-activity)")
    parser.add_argument("--csv-out", default=None, help="Optional path to output ground-truth CSV log")
    parser.add_argument("--compare", nargs=2, metavar=("GT_CSV", "APP_CSV"), help="Compare GT CSV with App exported CSV")
    args = parser.parse_args()

    if args.compare:
        compare_with_app_export(args.compare[0], args.compare[1])
        return

    # Set defaults based on mode
    if args.duration is None:
        duration = 60 if args.mode == "resting" else (90 if args.mode == "post-activity" else 30)
    else:
        duration = args.duration

    if args.bpm is None:
        base_bpm = 72 if args.mode != "post-activity" else 128
    else:
        base_bpm = args.bpm

    csv_path = args.csv_out or f"docs/field_test/raw/ble_gt_{args.mode}_{int(time.time())}.csv"

    asyncio.run(run_peripheral(args.name, args.mode, base_bpm, duration, csv_path))


if __name__ == "__main__":
    main()
