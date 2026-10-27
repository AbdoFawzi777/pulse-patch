#!/usr/bin/env python3
"""
tools/replay_csv.py — Replay a raw BLE session CSV through the PulsePatch measurement pipeline.
Usage: python tools/replay_csv.py <path_to_raw_session.csv>
"""
import sys
import struct
import csv
from pathlib import Path
import statistics

def parse_packet(hex_str: str) -> dict | None:
    try:
        data = bytes.fromhex(hex_str.strip())
    except ValueError:
        return None
    if len(data) < 12:
        return None
    proto, flags = data[0], data[1]
    if proto != 1:
        return None
    bpm_times10 = struct.unpack_from('<H', data, 2)[0]
    quality = data[4]
    ts_ms = struct.unpack_from('<I', data, 5)[0]
    seq = struct.unpack_from('<H', data, 9)[0]
    raw_bpm = (bpm_times10 / 10.0) if bpm_times10 != 0xFFFF else None
    return {
        'protocolVersion': proto,
        'flags': flags,
        'contactDetected': bool(flags & 0x01),
        'motionSuspected': bool(flags & 0x02),
        'bpmTimes10': bpm_times10,
        'bpm': raw_bpm,
        'quality': quality,
        'deviceTimestampMs': ts_ms,
        'sequenceNumber': seq,
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: python tools/replay_csv.py <raw_session.csv>")
        sys.exit(1)
    path = Path(sys.argv[1])
    if not path.exists():
        print(f"File not found: {path}")
        sys.exit(1)

    packets, rejects = [], 0
    with open(path, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            pkt = parse_packet(row.get('hex', ''))
            if pkt is None:
                rejects += 1
                continue
            if pkt['bpm'] is None or pkt['quality'] < 60:
                rejects += 1
                continue
            packets.append(pkt)

    if not packets:
        print("No valid packets found.")
        sys.exit(1)

    bpms = [p['bpm'] for p in packets]
    sqis = [p['quality'] for p in packets]
    start_bpm = bpms[0]
    end_bpm = bpms[-1]
    drop = start_bpm - end_bpm

    print("==================================================")
    print("PulsePatch Lite — Offline Session Replay & Audit")
    print("==================================================")
    print(f"Valid packets     : {len(packets)}")
    print(f"Rejected packets  : {rejects}")
    print(f"Mean BPM          : {statistics.mean(bpms):.2f}")
    print(f"Std BPM           : {statistics.stdev(bpms) if len(bpms) > 1 else 0:.2f}")
    print(f"Start BPM         : {start_bpm:.1f}")
    print(f"End BPM           : {end_bpm:.1f}")
    print(f"Recovery Drop     : {drop:.1f} BPM")
    print(f"SQI min/mean/max  : {min(sqis)} / {statistics.mean(sqis):.1f} / {max(sqis)}")

    buckets = {'<60': 0, '60-74': 0, '75-89': 0, '90-100': 0}
    for s in sqis:
        if s < 60:
            buckets['<60'] += 1
        elif s < 75:
            buckets['60-74'] += 1
        elif s < 90:
            buckets['75-89'] += 1
        else:
            buckets['90-100'] += 1
    print(f"SQI distribution  : {buckets}")
    print("==================================================")

if __name__ == '__main__':
    main()
