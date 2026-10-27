# pulse patch (PulsePatch Lite)

[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-311%2F311%20Passed-brightgreen.svg)](app/test)
[![Static Analysis](https://img.shields.io/badge/flutter%20analyze-0%20Issues-brightgreen.svg)](app)
[![Target Platform](https://img.shields.io/badge/Platform-Android%2015%20%7C%20iOS-blue.svg)](app)
[![Firmware](https://img.shields.io/badge/Firmware-ESP32--C3%20RISC--V-orange.svg)](firmware)
[![Database](https://img.shields.io/badge/Database-SQLite%20(Pure%20C%2FFFI)-indigo.svg)](app/lib/data/drift)
[![ML Engine](https://img.shields.io/badge/ML%20Engine-Pure%20Dart%20MLP%20(241%20params)-purple.svg)](app/lib/domain/ai)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline%20%2F%20Zero%20Cloud-success.svg)](docs)

> **Privacy-Preserving Educational Pulse Biomonitoring Platform**  
> An end-to-end wearable biomonitoring system bridging an embedded **ESP32-C3 RISC-V** microcontroller and a **MAX30102 photoplethysmography sensor** over Bluetooth Low Energy to a **Flutter** mobile client featuring **local Pure C/FFI SQLite persistence**, **on-device pure Dart neural network inference**, and **full bilingual localization (English LTR & Arabic RTL)**.

---

## ⚠️ Non-Diagnostic & Hardware Status Disclosure

> [!IMPORTANT]
> **Strictly Educational Biomonitoring Platform — Zero Medical Claims**  
> `pulse patch` is an academic engineering capstone research project. It does not provide medical diagnosis, clinical electrocardiogram (ECG) screening, or disease detection.

> [!NOTE]
> **Engineering Verification Boundary:**
> - **Software Stack:** **100% Verified and Defense-Ready.** The complete Flutter mobile application, on-device small neural network, local Drift SQLite database, BLE GATT ingestion, and offline PDF reporting are fully implemented and verified with **311 / 311 passing automated tests**.
> - **Over-The-Air BLE Field Verification:** Verified on a physical **HONOR NIC-LX2** smartphone running Android 15 across 3 complete sessions using the `PulsePatch-SimHR` peripheral (real BLE RF transmission with simulated physiological pulse curves).
> - **Physical ESP32-C3 + MAX30102 Hardware:** Firmware source code compiles cleanly (PlatformIO, RAM 7.3%, Flash 41.7%), but physical breadboard wiring and optical sensor testing on living human tissue is **PENDING** laboratory hardware testing (Phase 14).

---

## 📱 System Architecture

```
┌─────────────────────────────────┐
│     ESP32-C3 RISC-V Firmware    │
│  - MAX30102 Optical PPG Sensor  │
│  - 100 Hz Sampling, I2C 400 kHz │
│  - IIR DC Removal & SQI Gate    │
│  - 12-Byte Little-Endian Packet │
└───────────────┬─────────────────┘
                │ Bluetooth Low Energy (1 Hz Notify)
                ▼
┌─────────────────────────────────────────────────────────┐
│                   pulse patch Mobile App                │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │               Flutter UI (29 Screens)           │   │
│   │   - 174 Multi-Resolution Permutations (0 ovf)   │   │
│   │   - Instant Arabic (RTL) / English (LTR) Toggle │   │
│   │   - Real-Time Dynamic Radar Scanner UI          │   │
│   └───────────────────────┬─────────────────────────┘   │
│                           │                             │
│   ┌───────────────────────┴─────────────────────────┐   │
│   │             Signal Processing Pipeline          │   │
│   │   - 5-Sample Median Filter                      │   │
│   │   - Rate Jump Clamp (&le; 30 BPM)               │   │
│   │   - Signal Quality Index (SQI &ge; 60 Gate)     │   │
│   └───────────────────────┬─────────────────────────┘   │
│                           │                             │
│   ┌───────────────────────┴─────────────────────────┐   │
│   │            On-Device Machine Learning           │   │
│   │   - Pure Dart MLP (5 -> 16 -> 8 -> 1)           │   │
│   │   - 241 Parameters in Background Isolate        │   │
│   │   - Execution Time: < 0.15 ms (Zero TFLite)     │   │
│   │   - Labels: "Typical pattern" / "Different"     │   │
│   └───────────────────────┬─────────────────────────┘   │
│                           │                             │
│   ┌───────────────────────┴─────────────────────────┐   │
│   │           Privacy-First Storage & Export        │   │
│   │   - Local Drift SQLite Engine (Pure C / FFI)    │   │
│   │   - Zero Network Calls / Zero Cloud Telemetry   │   │
│   │   - 100% Offline PDF Biomonitoring Reports      │   │
│   │   - Full Local JSON & CSV Data Portability      │   │
│   └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features & Services

| Feature | Description |
|---|---|
| **Real-Time Pulse Ingestion** | Ingests live pulse stream at 1 Hz via custom 12-byte Little-Endian BLE GATT packet, with automatic fallback to built-in physiological simulator. |
| **Dual Measurement Protocols** | Supports **Resting** sessions (60 seconds) and **Post-Activity Recovery** sessions (90 seconds) with recovery drop calculation ($\Delta \text{BPM}$). |
| **Signal Quality Gating (SQI)** | Rejects motion-corrupted samples with an optical SQI score $< 60$ and pauses timers automatically upon sensor contact loss. |
| **On-Device AI Classification** | Extracts 11 mathematical features and classifies pulse recovery dynamics into educational labels (`Typical pattern` / `Different pattern`) via a background Dart isolate. |
| **Local SQLite Persistence** | Pure C / FFI SQLite storage via Drift ORM. Fast, crash-resilient, and 100% offline with zero cloud transmission. |
| **100% Offline PDF Reports** | Generates professional biomonitoring PDF reports directly on-device with explicit 3-tier data origin separation (synthetic / simulated / physical). |
| **Bilingual Localization** | Full native support for **Arabic (RTL)** and **English (LTR)** with instant in-app switching. |
| **Hardware Bring-Up Diagnostics** | Hidden engineering diagnostic screen (7 taps on version) showing live 12-byte hex streams, throughput, sequence gaps, parse rejects, and raw CSV session logging. |

---

## 🛠️ Technology Stack

| Layer | Language / Technology | Purpose |
|---|---|---|
| **Mobile Client** | **Dart / Flutter 3.x** | Cross-platform UI, 29 screens, Riverpod state management, GoRouter. |
| **Embedded Firmware** | **C++ / Arduino Core** | ESP32-C3 RISC-V firmware, NimBLE-Arduino GATT server, SparkFun MAX3010x I2C driver. |
| **Machine Learning** | **Pure Dart Isolate** | Lightweight Multi-Layer Perceptron (241 weights and biases) executing without external C++ runtimes. |
| **Database** | **SQLite (via Drift ORM & C-FFI)** | Local relational database for sessions and time-series heart rate samples. |
| **Analytics & Tooling** | **Python 3.10+** | Parity verification script, stability telemetry analyzers, offline CSV replay tool (`replay_csv.py`). |

---

## 📊 Verification & Defense Metrics

| Verification Dimension | Measured Result | Audit Evidence |
|---|---|---|
| **Automated Test Suite** | **311 / 311 Passed (100%)** | `flutter test` in [`app/test`](app/test) |
| **Static Code Analysis** | **0 Issues Found** | `flutter analyze` clean |
| **Screen Overflow Regression** | **174 / 174 Permutations (0 Overflows)** | 29 surfaces &times; 3 device viewports &times; 2 text scales (1.0x & 1.3x) |
| **Mathematical Parity** | **$\Delta = 0.000000$ (Exact Match)** | 100% parity across all 11 features between Python recomputation and SQLite |
| **Physical Phone Stability** | **0 ANRs / 0 Crashes** | Dual stability runs on HONOR NIC-LX2 (14m idle + 3.75m streaming) |
| **Firmware Compilation** | **PlatformIO Clean (Exit 0)** | Flash: 41.7%, RAM: 7.3%, Binary size: 572,352 bytes |
| **Binary Release Package** | **v1.0.0-rc1-software** | Release APK (59.6 MB), SHA-256 verified |

---

## 🚀 Quick Start Guide

### 1. Install Android Release APK
The pre-built release package is ready for direct installation on Android 8.0+ devices:
```bash
# Connect Android phone via USB with USB Debugging enabled
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

### 2. Run Mobile App Tests
```bash
cd app
flutter pub get
flutter test
```

### 3. Flash ESP32-C3 Firmware
```bash
cd firmware
# Standard firmware
pio run -e esp32-c3-devkitm-1 -t upload

# I2C Scanner to verify MAX30102 at 0x57
pio run -e esp32-c3-devkitm-1-i2c-scanner -t upload

# Serial debug CSV output at 115200 baud
pio run -e esp32-c3-devkitm-1-debug-raw -t upload
```

### 4. Replay Recorded Raw BLE Sessions Offline
```bash
python tools/replay_csv.py test_assets/sample_replay.csv
```

---

## 📁 Repository Structure

```
pulse-patch/
├── app/                           # Flutter mobile application
│   ├── assets/                    # Model weights, fonts, launcher icon
│   ├── lib/
│   │   ├── core/                  # Theme, localization (AR/EN), error boundary
│   │   ├── data/                  # Drift SQLite database, repositories
│   │   ├── domain/                # BLE packet parser, ML isolate engine
│   │   ├── features/              # 29 UI screens (Home, Measure, AI, History, Reports...)
│   │   └── shared/                # Shared UI widgets (charts, pulse painter)
│   └── test/                      # 311 automated unit, widget, and regression tests
├── firmware/                      # ESP32-C3 RISC-V firmware
│   ├── include/pulse_config.h     # Centralized hardware configuration
│   ├── src/main.cpp               # I2C driver, IIR filter, 12-byte BLE server
│   ├── platformio.ini             # PlatformIO build environments
│   └── test/                      # Host-compiled C++ struct parity test
├── ml/                            # Machine learning model training
│   ├── models/                    # Exported model weights and metadata
│   └── src/train.py               # Feature normalization and MLP training pipeline
├── tools/                         # Engineering tools
│   ├── replay_csv.py              # Offline BLE session replayer
│   ├── run_active_stability.py    # Active BLE streaming stability collector
│   └── generate_team_technical_report.py # Technical defense PDF generator
└── docs/                          # Comprehensive technical documentation
    ├── hardware_bringup_checklist.md  # 3.3V wiring and step-by-step bring-up guide
    ├── model_card.md              # 241-parameter MLP model card and caveats
    └── field_test/reports/        # Arabic technical defense PDF report
```

---

## 📄 Comprehensive Arabic Technical Report

A detailed Arabic engineering report prepared specifically for the defense committee and engineering team is available in the repository:  
👉 [`docs/field_test/reports/pulse_patch_technical_defense_report_ar.pdf`](docs/field_test/reports/pulse_patch_technical_defense_report_ar.pdf)

---

## 📜 License & Academic Integrity

Developed as an engineering capstone graduation project (Class of 2026). Strictly for educational, research, and non-commercial pulse biomonitoring exploration.
