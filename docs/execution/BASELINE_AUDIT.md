# PulsePatch Lite — Baseline Architecture & Codebase Audit (Phase 2)
**Audit Date:** October 30, 2026  
**Auditor:** Principal Engineering Agent Orchestrator  
**Baseline Git Commit:** `87dbe88`  
**Test Suite State:** 311 / 311 tests passing (100% pass rate)  
**Static Analysis:** `flutter analyze` clean (0 warnings, 0 errors)  

---

## 1. Executive Summary & True System State

This baseline audit traces every physiological measurement and feature from its physical/embedded source to the user-facing dashboards and reports.

```
┌─────────────────┐      BLE GATT      ┌──────────────────┐      C-FFI      ┌─────────────────┐
│ ESP32-C3 Sensor │ ─────────────────> │ Flutter App Core │ ──────────────> │ Drift SQLite DB │
│ (MAX30102 I2C)  │   (12-Byte 1 Hz)   │ (Ingestion/Isol) │                 │ (pulse_patch.db)│
└─────────────────┘                    └────────┬─────────┘                 └─────────────────┘
                                                │
                                                ▼
                                       ┌──────────────────┐
                                       │ Pure Dart MLP AI │
                                       │ (241 Parameters) │
                                       └──────────────────┘
```

---

## 2. Measurement Tracing Matrix

| Measurement / Feature | Embedded Firmware | BLE Transport | Dart Processing | Database Persistence | UI Dashboard / Report | Real Status |
|---|---|---|---|---|---|---|
| **Heart Rate (BPM)** | Calculated from IR peak detection | Packaged in `PulsePacket.bpmTimes10` (Offset 2-3) | Decoded by `BlePacket.parse()`, filtered by `SignalQualityFilter` | Saved in `samples.bpm` and `session_stats.mean_hr` | Live line graph, completed summary card | **Working & Verified** (311 tests pass) |
| **Oxygen Saturation ($SpO_2$)** | **NOT computed** (Firmware only reads IR channel; Red channel read in setup but unused in loop) | Reserved byte at offset 11 (`0x00`) | `BlePacket.spo2` defaults to null unless imported | Schema columns exist (`samples.spo2`, `session_stats.avg_spo2`), but values are `NULL` during live BLE | **Unimplemented in Firmware** (Requires dual-channel calculation) |
| **Raw PPG Waveform** | `CHAR_RAW_SAMPLES` characteristic created, but `notify()` **never called** | UUID `180D0002` defined | `PulsePatchSource.opticalWaveformStream` exists but receives no packets from ESP32 | Not saved to DB | Visualizer shows synthetic pulse wave | **Unimplemented** (Firmware does not stream raw FIFO samples) |
| **Blood Pressure (SBP/DBP)** | None | None | None | None | None | **Missing** (Primary Phase 4 Objective) |
| **Signal Quality (SQI)** | Simple amplitude heuristic | Packaged in `PulsePacket.quality` (Offset 4) | `SignalQualityFilter` gates $<60$ | Saved in `samples.quality` | Colored pill badge | **Working & Verified** |
| **AI Pattern Classification** | None | None | Pure Dart isolate forward pass (5 features) | Saved in `ai_results` | Typical vs Different pattern cards | **Working & Verified** (241 params) |
| **Patient Profile & BMI** | None | None | None | None (Only basic SharedPreferences name) | Basic settings screen | **Missing** (Phase 7 Objective) |
| **Doctor Discovery & Maps** | None | None | None | None | None | **Missing** (Phase 10 Objective) |
| **Comprehensive Reports** | None | None | Offline PDF generator (`PdfReportGenerator`) | Reads `sessions`, `stats`, `ai_results` | Printable PDF | **Working for sessions; needs Daily/Monthly/Annual multi-period expansion** |

---

## 3. Firmware Gap Analysis (`firmware/src/main.cpp`)

1. **Dual LED Mode Configured but Single-Channel Polling:**
   - In `setup()`: `particleSensor.setup(0x1F, 4, 2, 100, 411, 4096);` (Mode 2 = Red + IR).
   - In `loop()`:
     ```cpp
     uint32_t irValue = particleSensor.getFIFOIR();
     particleSensor.nextSample();
     processOpticalSample(irValue, now);
     ```
   - **Gap:** `particleSensor.getFIFORed()` is never called in the loop! Red channel photons are discarded, making physical $SpO_2$ ratio calculation impossible in the current binary.
2. **Raw PPG Waveform Transport Unimplemented:**
   - Characteristic `CHAR_RAW_SAMPLES` (`180D0002`) is initialized with `NIMBLE_PROPERTY::NOTIFY`, but `pRawCharacteristic->notify()` is never invoked in `loop()`.
3. **Firmware-Side Blood Pressure Surrogates:**
   - No pulse transit time (PTT) or crest-time extraction on chip.

---

## 4. Mobile Client Gap Analysis (`app/`)

1. **Database Schema Version 2:**
   - Database has 6 tables: `sessions`, `samples`, `session_stats`, `ai_results`, `reminders`, `app_settings`.
   - **Gaps for v2.0:**
     - Missing `user_profiles` table (Age, Gender, Height, Weight, BMI, Medical Conditions).
     - Missing `bp_calibrations` table (Cuff reference SBP/DBP, timestamps, calibration slope/intercept).
     - Missing `bp_estimates` table (Estimated SBP, DBP, MAP, uncertainty confidence interval).
     - Missing `health_alerts` table (Longitudinal anomaly tracking, urgent escalation logs).
     - Missing `doctor_cache` table (Offline clinic discovery cache).
2. **Missing Doctor Discovery & Mapping:**
   - No map dependencies (`flutter_map` or Google Maps) in `pubspec.yaml`.
   - No geolocation permission handlers for clinic searching.

---

## 5. Summary Action Items for Implementation
- **Firmware:** Read both `getFIFOIR()` and `getFIFORed()`, implement ratio-of-ratios $R$ for $SpO_2$, stream batched raw PPG on `180D0002`.
- **Database:** Create migration v3 adding tables for Patient Profiles, Blood Pressure Estimates/Calibrations, and Doctor/Clinic Cache.
- **Machine Learning:** Build research-driven BP regression model on PPG-BP / Kaggle / MIMIC benchmarks, export to Pure Dart.
- **Doctor Discovery:** Integrate OpenStreetMap (`flutter_map` + Overpass API) with geolocation and manual city search.
