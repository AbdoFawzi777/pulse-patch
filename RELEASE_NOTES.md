# PulsePatch Lite — Release Notes

## Version: `v1.0.0-rc1-software` (October 2026)

### Status: Software Stack Verified — Physical Hardware Integration Pending

> [!IMPORTANT]
> **Physical Hardware Bring-Up Notice:**  
> This release packages the fully verified Flutter mobile application, on-device machine learning engine, local SQLite persistence layer, and ESP32-C3 firmware source code.
> Physical breadboard wiring and optical sensor testing with the physical **ESP32-C3 DevKitM-1 + MAX30102** module has **NOT** been performed yet. All claims in this release reflect software verification on target phone hardware with simulated BLE transport.

---

### Artifact Details
- **Target Architecture:** Android (ARM64 / ARMv7 / x86_64) — API Level 26+ (Tested on Android 15, API 35)
- **Binary Path:** [`app/build/app/outputs/flutter-apk/app-release.apk`](file:///e:/pulse%20patch/app/build/app/outputs/flutter-apk/app-release.apk)
- **Binary Size:** 63,286,106 bytes (60.4 MB)
- **SHA-256 Checksum:** `9CFC7F6F9298BA2891FDE6258B6CACE696BAAF45BEB4ADA90412A715A7C9BE70`

---

### What Is Verified & Included ✅

1. **Automated Test Suite & Static Analysis:**
   - **311 / 311 automated tests passing (100% pass rate)**.
   - `flutter analyze`: **0 issues found**.
   - `overflow_screen_test.dart`: **174 / 174 automated permutations passing** (29 UI surfaces × 3 device resolutions × 2 text scales with 0 layout overflows).

2. **Physical Phone Installation & Navigation:**
   - Deployed and verified on physical `HONOR NIC-LX2` (Android 15, API 35).
   - Cold start, interactive gesture navigation, and screen transitions verified across all primary flows.

3. **Over-The-Air BLE Pipeline:**
   - 3 complete sessions recorded over physical BLE from peripheral `PulsePatch-SimHR` (255 valid packets ingested).
   - **100% exact mathematical parity ($\Delta = 0.000000$)** across all 11 statistical features between raw packet recomputation and app-stored database features.

4. **On-Device Machine Learning Classifier:**
   - Pure Dart background isolate forward pass ($< 0.15$ ms execution time).
   - 241 parameters (5 -> 16 -> 8 -> 1 architecture: 216 weights + 25 biases).
   - Both educational labels (`Typical pattern` and `Different pattern`) demonstrated from auto-triggered inference on physical hardware without heuristic bias.
   - 98.86% GroupKFold cross-validation benchmark on 11-subject cohort (*Caveat: 10/11 subjects synthetic*).

5. **Stability & Resource Health:**
   - **Dual-run foreground stability verified on target phone:**
     - **Run 1 (Idle-foreground, ~14 min, 15 samples, PID 10520):** PSS 317.9 MB -> 248.77 MB; drop at ~12 min verified as Android ART GC compaction. 0 ANRs. SQLite integrity OK.
     - **Run 2 (Active-streaming, ~3.75 min, 15 samples, PID 22865):** PSS 348–366 MB, CPU 0–37.5%. 0 ANRs. PID stable.

6. **Offline Autonomy & Privacy:**
   - 100% offline local SQLite persistence (Pure C / FFI via `drift`). Zero network requests, zero analytics, zero external cloud telemetry.
   - Self-contained offline PDF biomonitoring report generator verified with explicit 3-tier data origin separation.

7. **Hardware Bring-Up Readiness (Firmware & Host Tooling):**
   - Centralized hardware configuration header: [`firmware/include/pulse_config.h`](file:///e:/pulse%20patch/firmware/include/pulse_config.h).
   - PlatformIO build targets: standard, `esp32-c3-devkitm-1-debug-raw` (CSV serial output), and `esp32-c3-devkitm-1-i2c-scanner`.
   - Host C++ struct serialization test (`firmware/test/test_pulse_packet_host.cpp`) matching golden binary payload [`test_assets/golden_pulse_packet.bin`](file:///e:/pulse%20patch/test_assets/golden_pulse_packet.bin).
   - Hidden in-app **BLE Diagnostics Screen** (Settings > About, 7 taps).
   - Raw packet session CSV recorder with system share sheet export.
   - Offline session replay CLI tool: [`tools/replay_csv.py`](file:///e:/pulse%20patch/tools/replay_csv.py).
   - Step-by-step hardware bring-up checklist: [`docs/hardware_bringup_checklist.md`](file:///e:/pulse%20patch/docs/hardware_bringup_checklist.md).

---

### What Is Pending ⏳

- **Phase 14 — Physical Breadboard Integration:**
  - Physical wiring of ESP32-C3 DevKitM-1 to MAX30102 sensor module.
  - Optical skin perfusion calibration and raw photoplethysmogram signal capture on living human tissue.
  - End-to-end OTA verification between custom ESP32-C3 firmware and PulsePatch Lite mobile app.

---

### Known Limitations ⚠️

- **Simulated Physiology:** All 3 recorded BLE sessions utilized `PulsePatch-SimHR` peripheral (real BLE RF transmission, simulated human pulse physiology).
- **Synthetic Cohort Dominance:** The 98.86% GroupKFold score reflects synthetic-data benchmark performance and does not represent real-world clinical population generalization.
- **Design Mockup Fidelity Score:** `ConnectDeviceScreen` achieves SSIM 65.0% / Match 74.1% against static canvas mockups due to dynamic live-scanning radar UI, animated pulse waves, and RSSI device cards added during engineering refinement.

---

### Installation on Target Device

```bash
# Connect phone via USB with USB Debugging enabled
adb install -r app/build/app/outputs/flutter-apk/app-release.apk

# Grant BLE and Notification permissions upon first launch
```
