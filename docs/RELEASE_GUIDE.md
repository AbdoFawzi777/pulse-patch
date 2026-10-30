# PulsePatch Lite v2.0 — Software Release & Operator Guide

**Release Target:** PulsePatch Lite v2.0-RC  
**Date:** October 30, 2026  
**Audience:** System Integrators, Mobile Engineers, Clinical Evaluators, and QA Engineers  

---

## 1. System Requirements & Toolchain Prerequisites

### 1.1 Mobile Host Environment
- **Flutter SDK:** Version `3.29.x` or compatible (Dart SDK `^3.10.8`).
- **Android SDK:** API Level 34 (Android 14) platform tools, minimum SDK version `21` (Android 5.0 Lollipop).
- **Java Development Kit (JDK):** Version 17 (recommended for Gradle 8.x).
- **Target Architectures:** `arm64-v8a`, `armeabi-v7a`, `x86_64`.

### 1.2 Embedded Firmware Environment
- **Hardware:** ESP32-C3 RISC-V Microcontroller (Single-Core 160 MHz, integrated 2.4 GHz Wi-Fi and Bluetooth 5 LE).
- **Sensor:** Maxim Integrated MAX30102 High-Sensitivity Pulse Oximeter and Heart-Rate Biosensor module via I2C (SDA = GPIO 4, SCL = GPIO 5, $400\text{ kHz}$ Fast Mode).
- **Toolchain:** PlatformIO Core (`pio`) or Arduino IDE with ESP32 board support packages (`v2.0.14`+).

---

## 2. Repository Setup & Dependencies

```bash
# Clone the repository
git clone https://github.com/AbdoFawzi777/pulse-patch.git
cd "pulse patch"

# Install Flutter dependencies
cd app
flutter pub get
```

---

## 3. Database Architecture & Schema Initialization

The application utilizes an embedded SQLite engine with C-FFI bindings (`sqlite3` and `sqlite3_flutter_libs`). Database initialization occurs automatically upon first app launch:

- **Database File:** Located at `<ApplicationDocumentsDirectory>/pulse_patch.db`.
- **Integrity Guarantee:** `PRAGMA foreign_keys = ON;` enforced on every connection.
- **Current Schema Version:** `3`
- **Core Entities:**
  1. `sessions`: Recording metadata and duration logs.
  2. `samples`: High-frequency $1\text{ Hz}$ telemetry samples (BPM, SQI, SpO2).
  3. `session_stats`: Computed physiological aggregations.
  4. `ai_results`: On-device neural network pattern evaluations.
  5. `reminders`: User measurement reminders.
  6. `app_settings`: Key-value application configuration.
  7. `user_profiles`: Patient anthropometrics (Age, Gender, Height, Weight, Baseline BP).
  8. `bp_calibrations`: Physical cuff reference calibration offsets.
  9. `bp_estimates`: Experimental PPG Ridge regression outputs.
  10. `health_alerts`: Longitudinal anomaly logs and clinical escalation notices.
  11. `doctor_cache`: Offline Egyptian cardiology hospital directory.

---

## 4. Firmware Compilation & Flashing (ESP32-C3)

1. Connect the ESP32-C3 development board via USB-C.
2. In terminal, navigate to the firmware workspace:
   ```bash
   cd firmware
   pio run --target upload
   ```
3. Open serial monitor ($115200\text{ baud}$) to observe startup diagnostics:
   ```
   [PulsePatch-C3] Initializing MAX30102 on I2C... SUCCESS.
   [PulsePatch-C3] Starting NimBLE Advertising (UUID: 180D)...
   [PulsePatch-C3] Device ready for BLE pairing as 'PulsePatch-C3'.
   ```

---

## 5. Mobile Application Execution & Testing

### 5.1 Development Run
```bash
cd app
flutter run
```

### 5.2 Automated Quality Assurance Suite
```bash
# Run all 356 automated unit, widget, and integration tests
flutter test

# Run static analysis
flutter analyze --no-pub
```

### 5.3 Building Release Artifacts
```bash
# Build standalone Release APK
flutter build apk --release

# Output path:
# build/app/outputs/flutter-apk/app-release.apk

# Optional: Build Android App Bundle (for Google Play distribution)
flutter build appbundle --release
```

---

## 6. Sideloading & Installation on Physical Android Devices

To install the release APK on a physical Android handset:

```bash
# Verify USB connection to Android device
adb devices

# Install APK directly (allowing replace existing)
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

### Android Permissions Configuration
Upon first launch, the application requests the following runtime permissions:
- **Bluetooth Scan & Connect (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`):** Required to discover and ingest BLE telemetry packets from `PulsePatch-C3`.
- **Location (`ACCESS_FINE_LOCATION`):** Required by Android BLE discovery stack and optional Doctor Discovery distance calculations. Zero user location data ever leaves the device.
- **Notifications (`POST_NOTIFICATIONS`):** Required for reminder alerts and urgent clinical alerts.

---

## 7. Operational Workflows

### 7.1 Pairing & Live Measurement
1. Power on the ESP32-C3 sensor.
2. Open **PulsePatch Lite** and tap **Connect Device** on the Home dashboard.
3. Select `PulsePatch-C3` from the discovered peripheral list.
4. Once connected, place your index finger gently and stably on the optical sensor.
5. Tap **Start Measurement**; remain seated and still for the 2-minute recording.
6. The app automatically streams live pulse waveforms, evaluates heart rate, calculates SpO2, and executes the on-device AI pattern model.

### 7.2 Blood Pressure Calibration
1. Navigate to **Profile & Preferences** → **Blood Pressure**.
2. Perform a live PPG reading.
3. Measure your blood pressure using a certified clinical arm-cuff sphygmomanometer.
4. Enter the cuff Systolic and Diastolic values into the calibration fields and tap **Calibrate Model**.
5. The linear offset is stored locally in SQLite and applied to subsequent experimental estimates.

### 7.3 Exporting Clinical PDF Reports
1. Navigate to **Profile & Preferences** → **Clinical Reports** (or from the Insights screen).
2. Choose your desired reporting range: **Daily**, **7 Days**, **30 Days**, **Yearly**, or **All Time**.
3. Tap **Export & Share PDF Report** to render a publication-grade, A4 multi-page report complete with statistical tables, trend breakdowns, and medical provenance notices.
