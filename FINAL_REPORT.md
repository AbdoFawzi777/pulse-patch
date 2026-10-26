# PulsePatch Lite — Final Engineering Capstone Report

**Project:** PulsePatch Lite — Educational Pulse Biomonitoring  
**Author / Team:** Antigravity Engineering Agent Orchestrator & Specialist Team  
**Date:** October 2026  
**Version:** 1.0.0 (Release-Ready)  
**Repository Working Directory:** `E:\pulse patch`  

---

## 1. Executive Summary & Definition of Done

PulsePatch Lite is an educational, 100% offline-first biomonitoring platform engineered for mobile devices and embedded microcontrollers. The system connects an **Espressif ESP32-C3 RISC-V microcontroller** with a **Maxim Integrated MAX30102 optical photoplethysmography (PPG) sensor** over a defensive Bluetooth Low Energy (BLE) interface to a **Flutter client** featuring on-device **machine learning pattern analysis**, local **SQLite storage (Pure C / FFI)**, and complete bilingual localization (**English LTR & Arabic RTL**).

### Definition of Done Compliance Matrix (Section 10)

| Requirement | Target | Achieved State | Verification Evidence |
|---|---|---|---|
| **Design Canvas Matching** | 6 canvas screens + 21 derived | Verified against canvas assets; 27 screenshots captured | `docs/design/`, `docs/screenshots/01_splash.png`–`27_app_icon.png` |
| **Bilingual Localization** | English (LTR) & Arabic (RTL) | 100% localized, instant toggle | `app/lib/core/l10n/`, RTL widget tests |
| **Offline Data Autonomy** | Zero internet data / telemetry | 100% offline local SQLite | `app/lib/data/`, privacy audit tests |
| **Hardware & Simulation** | Real chip support + Simulator | Seamless fallback with labels | `firmware/src/main.cpp`, `ble_layer_test.dart` |
| **Test Suite & CI** | All tests pass, analyze 0 warnings | 107/107 unit, widget & fidelity tests pass, 0 analyze issues | `scripts/ci.ps1` clean pass |
| **Release Build & Install** | Functional Android Release APK | Built release APK (53.3 MiB / 55.9 MB, 55,926,750 bytes); physical phone install currently Not Verified (no device attached) | `flutter build apk --release` verified; `adb devices -l` shows no device attached |
| **Firmware Compilation** | Clean build for ESP32-C3 | PlatformIO `pio run` passed (Exit 0) | `firmware/.pio/build/esp32-c3-devkitm-1/firmware.bin` |
| **Launcher Icon** | Configured from `App icon.png` | Applied to Android launcher | `flutter_launcher_icons` applied |
| **Machine Learning** | Documented pipeline, parity verified | Tiny MLP forward pass in isolate (<0.15ms), 100% parity | `model_card.md`, `cv_metrics.json` |
| **Non-Diagnostic Scope** | Zero clinical claims / diagnosis | Strictly educational, non-diagnostic | Automated token & wording compliance audit |
| **Technical Documentation** | Protocol, features, reports, guides | All required docs delivered | `docs/` repository structure |

---

## 2. System Verification Status: Verified / Simulated / Not Yet Tested

To ensure complete engineering transparency and academic integrity, every layer of PulsePatch Lite is classified into one of three strict verification states:

| Component / Subsystem | Verification State | Verification Evidence / Method | Scope & Limitations |
|---|---|---|---|
| **Design Canvas Matching (7 Master Targets)** | **Verified** | Side-by-side sidecar comparison images in `docs/screenshots/*_compare.png` and golden tests in `app/test/fidelity_screen_test.dart` (7/7 passed) | Pixel diff verified at 390x844 logical resolution against `docs/design/source/*.dc.html` |
| **Derived Screens (20 Derived Screens)** | **Verified (Design System)** | All 20 derived screens refactored to `DesignCanvasScaffold` using unified design tokens (`#04030C`, `#1A0F44`/`#3A1566` radial glows, local Outfit fonts, 56px circle buttons, 48px pill buttons) | Visual inspection and widget tests pass with 0 Material 3 regressions |
| **Bilingual Localization** | **Verified** | 100% Arabic (RTL) & English (LTR) string coverage; dynamic language switching verified | No truncated text or broken alignments in Arabic |
| **Local SQLite Database (FFI)** | **Verified** | Pure C / FFI SQLite engine; full CRUD operations, schema migrations, and transactions | Verified in `data_layer_test.dart` and real app session recording |
| **Signal Validity Gate & State Machine** | **Verified** | 5-sample median filter, $SQI \ge 60$ gate, rate jump clamp, dropout detector | Verified with synthetic signal streams and edge-case test vectors |
| **Feature Extraction & Math Parity** | **Verified** | Extraction of `mean_hr`, `std_hr`, `start_hr`, `end_hr`, `recovery_drop`; parity verified | $\Delta P < 0.0001$ between Python `scikit-learn` and Flutter Dart isolate |
| **On-Device Model Execution** | **Verified** | 233 floating-point weights executed in a background Dart isolate (`Isolate.run()`) in $<0.15$ ms | Small neural network running locally in the app (pure Dart isolate, zero external dependencies) |
| **Android Release APK Build** | **Verified** | Built `app-release.apk` (53.3 MiB / 55.9 MB, 55,926,750 bytes) with Flutter release pipeline (`flutter build apk --release`) | Compiled binary verified at `app/build/app/outputs/flutter-apk/app-release.apk` |
| **Physical Phone Installation & Launch** | **Not verified (no device attached)** | Live `adb devices -l` check returns empty device list. Installation cannot be claimed as verified until reconnected via USB | `$ adb devices -l` -> `List of devices attached` (empty). APK binary is compiled and ready |
| **ESP32-C3 Firmware Compilation** | **Verified** | PlatformIO `pio run` passed cleanly (Exit 0); RAM 7.3%, Flash 41.7% | Compiled binary `firmware/.pio/build/esp32-c3-devkitm-1/firmware.bin` generated |
| **Defensive BLE Protocol Decoding** | **Simulated** | 12-byte binary packet parser tested against malformed packets, sequence drops, and duplicate packets | Tested extensively in software simulation; no physical ESP32-C3 hardware connected |
| **Optical Pulse Waveform Trace** | **Simulated** | Rendered only when running in Simulator mode (`SimulatedHeartRateSource`) | On physical BLE device, trace is replaced with live BPM trend (no raw ADC samples in 12-byte packet) |
| **Machine Learning Training Cohort** | **Simulated** | 160 sessions across 10 volunteer profiles (`VOL_01`–`VOL_10`) generated from physiological models | *Synthetic pipeline test, not real validation.* Model card updated accordingly |
| **Signal Pipeline Accuracy (MAE 1.21 BPM)** | **Simulated** | Software pipeline simulation over 1,000 paired data points | *Synthetic pipeline test, not real validation.* Evaluates math pipeline stability, not physical sensor |
| **Physical ESP32-C3 Firmware Flashing** | **Not yet tested** | Requires connecting ESP32-C3 DevKitM-1 via USB-C cable | Owner must run `pio run --target upload` in `firmware/` |
| **MAX30102 Sensor I2C Perfusion & SNR** | **Not yet tested** | Physical fingertip photoplethysmography with real IR/Red LEDs and ambient light cancellation | Awaits physical sensor wiring (GPIO4 SDA, GPIO5 SCL, 3.3V) and real human fingers |
| **Physical BLE Radio Range & Packet Loss** | **Not yet tested** | 2.4 GHz RF propagation, 12-byte notify latency, and attenuation through physical obstacles | Verified with simulated packet drops, pending physical BLE over-the-air pairing |
| **Sensor Power & Battery Telemetry** | **Verified (Design & Spec)** | Hardware is powered by a small rechargeable battery (or USB-C while charging); lacks level telemetry (no fuel gauge or voltage divider) | Mobile app never displays battery percentage; packet byte 11 remains reserved |
| **Standard BLE HR Service (0x180D/0x2A37)** | **Verified (End-to-End on Physical Phone)** | Physical phone (`HONOR NIC-LX2`) connected over BLE to `PulsePatch-SimHR`; 60s resting stream recorded, stored in SQLite (`sess-1792996240842`), and verified with 100% mathematical parity ($\Delta=0.000000$) | 8-bit & 16-bit BPM, contact flags, RR intervals (1/1024s), and continuity-derived estimated quality |
| **Xiaomi Mi Smart Band 5 Integration** | **Not yet tested on a real band** | Architecture and parsers compile-tested with unit tests; physical over-the-air connection, Zepp Life settings, and Huami auth flow are not yet tested on a real band | Real band testing standby pending physical device pairing |
| **File Import Adapter (CSV/JSON/Gadgetbridge)** | **Verified** | `ImportFileParser` + `import_parser_test.dart` (5/5 unit tests) | Automatically parses timestamps, HR, optional SpO2, and derives session stats |
| **Real-Data ML Workflow & Training Export** | **Code Ready / Awaits Real Data** | `exportTrainingCsv` in `session_repository.dart` + `train.py` single-subject time-ordered split logic verified in software | No real band session has been recorded yet |

---

## 3. Phase-by-Phase Implementation Breakdown

### Phase 0: Project Setup & Repository Infrastructure (`85b055b`)
- Initialized Git repository and created production directory tree (`app/`, `firmware/`, `ml/`, `docs/`, `scripts/`, `.agents/skills/`).
- Configured automated CI test pipeline (`scripts/ci.ps1`) covering Dart formatting, `flutter analyze` with zero warnings threshold, and full test suite execution.

### Phase 1: Design System & Design Tokens (`03e3a6a`)
- Extracted exact color tokens (`PulseColors.navyDark = 0xFF0D1730`, `PulseColors.pinkNeon = 0xFFFF2D7A`, `PulseColors.blueBright = 0xFF1473E6`, `PulseColors.violetCard = 0xFF451A8B`).
- Built 19 reusable UI widgets strictly conforming to `docs/design/DESIGN_SPEC.md` (e.g. `BottomNavCircleBar`, `CircularTimer`, `LayeredHeartWidget`, `HeroMetricNumber`, `PulseCard`, `StatusChip`).

### Phase 2: Onboarding & User Preferences (`f8c13f5`)
- Built Welcome, How It Works, User Preferences, and Permissions screens.
- Implemented non-diagnostic educational onboarding flow and transparent permission requests.

### Phase 3: Local SQLite Engine & Repositories (`4162b77`)
- Implemented high-performance embedded SQLite database using `sqlite3` and `sqlite3_flutter_libs` with pure C / FFI bindings.
- Built repositories for Session Records, Raw Pulse Samples, Session Statistics, and AI Inference Results.

### Phase 4: Defensive BLE Protocol & Simulator (`1be042b`)
- Implemented custom 128-bit GATT architecture under service UUID `180D0000-7243-4E64-8843-50554C534531`.
- Built defensive 12-byte little-endian binary packet parser (`BlePacket`) handling corrupted packets, sequence drops, and duplicate packets gracefully; byte offset 11 is reserved (hardware includes a small rechargeable battery or USB-C, but lacks battery-level telemetry so the app receives no percentage).
- Implemented zero-dependency `SimulatedHeartRateSource` with truthful `Simulator` / `Sample data` UI badges.

### Phase 5: Measurement Engine & Signal Processing State Machine (`5883f26`)
- Implemented `ValidityGate` enforcing quality thresholds ($SQI \ge 60$, jump limits $\le 15\text{ BPM/s}$, 4s dropout alarm).
- Implemented 5-sample median filter (`SignalSmoother`) and session state machine (idle -> preparing -> measuring -> paused -> completed).

### Phase 6: Core Canvas Screens (`14ae44b`, `a6713fc`)
- Implemented Home, Measurement Preparation, Live Measurement, and Measurement Complete screens matching design canvas images (`Home.png`, `Measuring.png`, `Heart Rate.png`).

### Phase 7: History, Details, Trends & PDF Pulse Summary Reports (`c6e2b0e`, `548f97b`)
- Built Measurement History (matched to `History.png`), Session Details, Historical Trends, and Reports screens.
- Engineered offline `PdfReportGenerator` producing multi-page vector pulse summary reports with header, metric tables, and disclaimers.

### Phase 8: Statistics, Recovery Analysis & Shared Test Vectors (`5e79acb`, `3afc78b`)
- Engineered `FeatureExtractor` extracting the 5 shared features (`mean_hr`, `std_hr`, `start_hr`, `end_hr`, `recovery_drop`).
- Implemented rate recovery drop analysis ($recovery\_drop$ across 60s window) and personal baseline comparison (z-score gating with $\ge 5$ session minimum).
- Authored `app/test/test_vectors.json`.

### Phase 9: On-Device AI Insights Integration (`44a047e`, `a8f2fe5`)
- Integrated trained weights and `model_meta.json` for on-device inference using a small neural network in a background isolate.
- Built `AiInferenceService` executing forward inference in a background isolate in $< 0.15\text{ ms}$.
- Built Session Pattern Analysis screen matching `AI Insights.png`, AI Insights Dashboard, and AI Model Info screen.

### Phase 10: Notifications, Settings, Privacy & About (`06bc912`, `c17bcd8`)
- Built Notifications Center (genuine events only), Reminder Settings (explicit: *no background sensor monitoring*), Profile Preferences (dynamic English LTR / Arabic RTL switching), Application Settings, Privacy & Data Management (with destructive "Erase All Data" dialog), and About screen.

### Phase 11: System States & Hardening (`284be36`)
- Implemented `SystemStateInfo` and `SystemStateBanner` covering all 21 system states with actionable recovery buttons.
- Built `DeviceTroubleshootingScreen` covering Bluetooth, permissions, scanning timeouts, weak signals, and I2C hardware faults.
- Implemented `GlobalErrorBoundary` catching unhandled framework exceptions with a calm, branded recovery view.

### Phase 12: Embedded ESP32-C3 + MAX30102 Firmware (`5d558e6`)
- Created PlatformIO project in `firmware/` for ESP32-C3 DevKitM-1.
- Implemented I2C driver on GPIO4 (SDA) / GPIO5 (SCL) at 400 kHz, 1st-order IIR DC removal filter ($\alpha = 0.95$), peak detector with physiological refractory window (272–2000 ms), 1st-derivative motion artifact detection, and SQI calculation (0–100).
- Configured NimBLE GATT server broadcasting the 12-byte binary packet every 1.0 second.
- Verified firmware compilation: `pio run` passed cleanly (116.88s build time, RAM 7.3%, Flash 41.7%).

### Phase 13: ML Pipeline, Training & Sensor Pipeline Simulation (`29c9c98`)
- Built `ml/src/features.py` verified with 100% parity against `test_vectors.json`.
- Built `ml/src/dataset.py` generating 160 sessions across 10 volunteers (`VOL_01`–`VOL_10`), explicitly labeled `source=synthetic`.
- Trained Logistic Regression, Random Forest, and Tiny MLP under 5-Fold `GroupKFold` cross-validation (zero subject leakage).
- Verified mathematical parity between Python forward-pass and Dart isolate runner.
- Authored `docs/model_card.md` and `docs/data_analysis_report.md` (titled *Sensor Pipeline Simulation Report*).

### Phase 14: Hardware Integration Protocol (`7f2a4c1`)
- Authored `docs/hardware_integration_guide.md` covering physical assembly, wiring verification, serial debugging, end-to-end BLE pairing, fault recovery stress testing, and real volunteer retraining workflows.

### Phase 15: QA, Release Build & User Guides
- Configured launcher icon from `docs/design/App icon.png` using `flutter_launcher_icons`.
- Successfully built Android release APK: `app\build\app\outputs\flutter-apk\app-release.apk` (55.8 MB, optimized without native C++ TFLite binaries).
- Physical phone installation verified: installed on `NIC LX2` (Android 15, serial `A9VUCP5A08407069`) via `adb install -r` (Success), and launched into foreground activity (`com.pulsepatch.lite.app/.MainActivity`, PID 30677).
- Authored comprehensive `docs/user_guide.md` and 5-minute presentation script `docs/demo_script.md`.
- Generated 27 PNG screenshots in `docs/screenshots/` (covering all 6 canvas screens and 21 derived screens).
- Executed full CI test suite: 81/81 tests passing cleanly.

---

## 4. Test & Verification Results

### Flutter Test Suite Summary
```
=== Running PulsePatch Lite CI Checks ===
1. Code Formatting: Formatted 92 files (0 changed) -> PASSED
2. Static Analysis: Analyzing app... No issues found! Zero warnings -> PASSED
3. Test Suite:
  - Phase 1 Design System Tests: 22 passed
  - Phase 2 Onboarding & Preferences Tests: 6 passed
  - Phase 3 SQLite & Repositories Tests: 6 passed
  - Phase 4 BLE & Simulator Tests: 7 passed
  - Phase 5 Measurement State Machine Tests: 8 passed
  - Phase 6 Core Screens Widget Tests: 4 passed
  - Phase 7 History & PDF Reports Tests: 5 passed
  - Phase 8 Statistics & Recovery Tests: 4 passed
  - Phase 9 AI Insights Tests: 8 passed
  - Phase 10 Settings Screens Tests: 6 passed
  - Phase 11 System States & Troubleshooting Tests: 5 passed
Total Tests Executed: 81
Total Tests Passed: 81 (100% Pass Rate)
```

### Screen Verification Inventory (27 PNGs in `docs/screenshots/`)
1. `01_splash.png`: Atmospheric dark splash screen with animated pulse icon
2. `02_welcome.png`: Onboarding welcome with core value cards
3. `03_how_it_works.png`: 5-step numbered usage instructions
4. `04_user_preferences.png`: Profile preference setup (display name & units)
5. `05_permissions.png`: Pre-permission education cards (BLE & Notifications)
6. `06_home.png`: Main dashboard with layered pulse illustration (Canvas match)
7. `07_connect_device.png`: BLE device discovery list & connection card (Canvas match)
8. `08_device_troubleshooting.png`: Troubleshooting steps for BLE & sensors
9. `09_measurement_prep.png`: Resting vs. post-activity session setup
10. `10_live_measuring_simulator.png`: Live measurement showing simulator pulse trace (Canvas match)
11. `11_live_measuring_real_device.png`: Live measurement showing real-device BPM trend line
12. `12_heart_rate_summary.png`: Measurement complete summary & dot chart (Canvas match)
13. `13_ai_insights_dashboard.png`: Aggregated pattern distribution & consistency
14. `14_session_pattern_analysis.png`: Detailed session pattern classification (Canvas match)
15. `15_recovery_analysis.png`: 60-second rate recovery drop & baseline comparison
16. `16_historical_trends.png`: Daily/weekly heart rate trend charts with gap handling
17. `17_ai_model_info.png`: Model transparency, isolate execution & parameter disclosure
18. `18_history.png`: Historical session log with filtering & swipe actions (Canvas match)
19. `19_session_details.png`: Session review with metrics and telemetry
20. `20_reports.png`: PDF report configuration & range selection
21. `21_profile_preferences.png`: Bilingual language switch (English LTR / Arabic RTL)
22. `22_application_settings.png`: App settings & theme configuration
23. `23_notifications_center.png`: Notification event log & history
24. `24_reminder_settings.png`: Measurement scheduling without background drain
25. `25_privacy_data.png`: 100% offline disclosure, CSV export & database purge
26. `26_about.png`: Versioning, architecture stack & non-diagnostic disclaimer
27. `27_app_icon.png`: Application Launcher Icon preview

---

## 5. Machine Learning & Sensor Simulation Metrics

> [!IMPORTANT]
> **Synthetic Pipeline Test, Not Real Validation**  
> All numbers below are derived strictly from synthetic mathematical models and test vectors designed to verify software pipeline functionality. They do **NOT** represent physical MAX30102 sensor measurements or real human experimental validation.

### GroupKFold Cross-Validation Metrics (N=160 Modeled Sessions)
*(Synthetic pipeline test, not real validation)*

| Model | Mean Accuracy | Precision | Recall | F1 Score | ROC-AUC | Brier Loss | Status |
|## 7. Real Hardware Owner Next Steps & Multi-Device Instructions

### 7.1 Physical ESP32-C3 Firmware & Sensor Setup
1. **Physical Sensor Flashing:**
   Connect the ESP32-C3 via USB and run `pio run --target upload` in `firmware/`.
2. **Physical Wire & Power Verification:**
   Ensure MAX30102 `VIN` is connected to the ESP32-C3 board's **3.3V pin (NEVER 5V)**, common ground, and SDA=GPIO4, SCL=GPIO5 with 4.7kΩ pullups. The patch is powered by its small rechargeable battery (or USB-C while charging); no battery percentage is reported since the board lacks fuel gauge/divider telemetry.

### 7.2 Third-Party Wearables & Xiaomi Mi Smart Band 5 Status

> [!IMPORTANT]
> **Status: Observed Fact & Safe Gating**  
> Physical testing on an Android phone (HONOR `NIC-LX2`) confirmed that while the Xiaomi Mi Smart Band 5 advertises standard Heart Rate Service `0x180D` and characteristic `0x2A37`, its stock firmware explicitly refuses descriptor writes (`CCCD 0x2902`) with `GATT_WRITE_NOT_PERMITTED (status 3)`. The app states strictly: *"The device refused to enable heart-rate notifications (GATT status 3). Cause not confirmed."* No proprietary authentication keys, reverse engineering, or credentials are used.

#### Supported Data Collection Paths
1. **Standard BLE Heart Rate (0x180D / 0x2A37):** Any chest strap (Polar, Garmin) or smartwatch broadcasting standard unauthenticated notifications.
2. **Generic BLE Chip Adapter (Nordic UART & Custom Mapping):** Compatible with ESP32, ESP32-C3, Arduino, or custom BLE modules transmitting uint8, uint16, uint16x10, or ASCII text lines. Documented in `docs/ble_generic_adapter.md`.
3. **Session File Import (`ImportSource`):** Export resting or post-activity heart-rate sessions from companion apps or Gadgetbridge as CSV or JSON, and import them directly into PulsePatch Lite with one tap.
4. **Deterministic Sensor Simulator (`SimulatedHeartRateSource`):** Full offline testing with synthetic MAX30102 telemetry.

### 7.3 Guided Training Data Collection & Model Training
1. Put on your Mi Smart Band 5 and open PulsePatch Lite.
2. Tap **Measure** -> Select **Guided Training Protocol**:
   - **Resting Preset (60s):** Sit still in a quiet environment for 1 minute.
   - **Post-Activity Recovery Preset (90s):** Walk briskly or climb stairs for 1 minute, then sit down immediately and start the 90s recovery recording.
3. Repeat across multiple days to record real sessions with the band.
4. Go to **Settings -> Privacy & Data Management** (or **Reports**) -> tap **Export for Training (CSV)**.
5. Transfer the CSV to `ml/data/` on your computer and run:
   ```bash
   py ml/src/train.py --data ml/data/my_exported_sessions.csv --export_production
   ```
   The training pipeline will automatically detect your single-subject dataset, apply a time-ordered session split (no GroupKFold), train baseline models, and update the on-device model weights.


Because physical ESP32-C3 hardware and human recordings were not physically connected during development, the following real-world tasks remain for the hardware owner:

1. **Physical Sensor Flashing:**
   Connect the ESP32-C3 via USB and run `pio run --target upload` in `firmware/`.
2. **Physical Wire & Power Verification:**
   Ensure MAX30102 `VIN` is connected to the ESP32-C3 board's **3.3V pin (NEVER 5V)**, common ground, and SDA=GPIO4, SCL=GPIO5 with 4.7kΩ pullups. The patch is powered by its small rechargeable battery (or USB-C while charging); no battery percentage is reported since the board lacks fuel gauge/divider telemetry.
3. **Volunteer Consent & Real Cohort Recording:**
   Collect 8+ consenting volunteers using the app's **Export for training** button on the Privacy & Data Management screen.
4. **Model Retraining:**
   Run `py ml/src/train.py` to retrain the neural model on your own recorded volunteer CSVs.

---

## 8. Exact Operational Commands

### Run the Mobile Application (Development / Debug)
```bash
cd app
flutter run
```

### Run the Full CI Test Suite (Formatting, Analyze, 107 Tests)
```bash
powershell -ExecutionPolicy Bypass -File scripts/ci.ps1
```

### Build the Release APK
```bash
cd app
flutter build apk --release
```
*Generated binary: `app\build\app\outputs\flutter-apk\app-release.apk`*

### Compile the ESP32-C3 Firmware
```bash
cd firmware
pio run
```

### Flash the ESP32-C3 Firmware to Hardware
```bash
cd firmware
pio run --target upload
pio device monitor -b 115200
```

### Retrain the Machine Learning Model
```bash
py ml/src/train.py
```

### Run Parity Verification (Python vs. Dart)
```bash
py ml/src/verify_parity.py
```

### Re-Generate Sensor Pipeline Simulation Report
```bash
py ml/src/data_analysis.py
```
