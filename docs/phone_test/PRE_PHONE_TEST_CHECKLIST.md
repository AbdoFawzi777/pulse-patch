# PulsePatch Lite v2.0 — Pre-Phone Test Checklist & Field Protocol

**Target Version:** v2.0.0-release  
**Target Hardware:** Android Smartphone (Android 8.0+ / API 26+) + ESP32-C3 DevKitM-1 + MAX30102  
**Safety Classification:** Strictly Investigational & Non-Diagnostic Biomonitoring Tool  
**Date:** October 30, 2026  

---

## 1. Pre-Flight Device Requirements

Ensure the Android test smartphone meets the following operational criteria:
- **Operating System:** Android 8.0 (Oreo) or higher (API Level 26–34+).
- **Bluetooth:** Bluetooth Low Energy (BLE 4.2 or 5.0+ supported hardware).
- **Location Services:** Enabled (required by Android OS for BLE scanning on API < 31).
- **USB Debugging:** Enabled in *Developer Options* (if installing via ADB).
- **Free Storage:** At least 200 MB free for database and offline PDF clinical report cache.

---

## 2. APK Installation & Permissions Protocol

### 2.1 Sideload via ADB (Recommended)
Connect the Android device to the workstation via USB and execute:

```bash
# Verify device connection
adb devices

# Sideload Release APK (preserving existing data if upgrading)
adb install -r "app/build/app/outputs/flutter-apk/app-release.apk"
```

**Binary Verification:**
- **File Name:** `app-release.apk`
- **File Size:** `63,779,872 bytes` (60.8 MB)
- **SHA-256 Hash:** `F2202EB47237621EAAA5318E19BDC4ECDFF51BFDE74259AC226F6CEEFAC20ADB`

### 2.2 Grant Permissions via ADB (Optional / Fast Setup)
Alternatively, accept prompts on first launch:
```bash
adb shell pm grant com.pulsepatch.app android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.pulsepatch.app android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant com.pulsepatch.app android.permission.BLUETOOTH_SCAN
adb shell pm grant com.pulsepatch.app android.permission.BLUETOOTH_CONNECT
```

---

## 3. Sensor Placement & Optical Perfusion Protocol

Proper physical coupling between the fingertip and MAX30102 optical sensor is required for valid photoplethysmographic signal acquisition:

1. **Finger Selection:** Left or right index finger pad (distal phalanx).
2. **Contact Pressure:** **Gentle and constant.**
   * *Excessive Pressure:* Blanches the capillary bed, extinguishing the AC pulsatile component.
   * *Insufficient Pressure:* Introduces severe ambient light interference and baseline drift.
3. **Ambient Light Shielding:** Shield the sensor module from direct sunlight, fluorescent tubes, or high-intensity LEDs.
4. **Motion Minimization:** The subject must remain stationary, seated comfortably with forearm rested on a table at heart level.

---

## 4. Step-by-Step Field Verification Procedure

| Step | Test Objective | Expected Behavior | Verification Status |
|:---:|:---|:---|:---:|
| **1** | **Cold App Launch & Shell** | Launches themed dark navy canvas (`#04030C`), system status bar, bottom navigation with 5 primary tabs. RTL layout applies when system is in Arabic. | `[ ] PASS / FAIL` |
| **2** | **User Profile Creation** | Enter Age, Gender, Height, Weight. Screen calculates BMI with validated WHO age-bracket classification (under-5 growth guidance, 5–19 z-score, adult WHO). | `[ ] PASS / FAIL` |
| **3** | **BLE Scanning & Discovery** | Navigate to *Device Connect*. Tap Scan. ESP32-C3 peripheral appears as `"PulsePatch Lite"` (`180D0000-7243-4E64-8843-50554C534531`). | `[ ] PASS / FAIL` |
| **4** | **Peripheral Pairing** | Tap Connect. State transitions from Disconnected $\to$ Connecting $\to$ Connected. RSSI indicator displays live signal strength. | `[ ] PASS / FAIL` |
| **5** | **PPG Live Streaming** | Place finger on MAX30102. Within 2–3 seconds, live optical plethysmogram curve begins rolling on `PulseTraceChart`. Heart rate updates at 1 Hz. | `[ ] PASS / FAIL` |
| **6** | **Optical Contact Gating** | Remove finger. Optical perfusion falls below 50,000 counts. System immediately displays `"Contact Lost"` warning banner without crashing. | `[ ] PASS / FAIL` |
| **7** | **Blood Pressure Estimation** | Open *Blood Pressure Monitoring*. Engine runs in-memory Pure Dart inference (<0.15 ms), displaying estimated SBP/DBP and AHA 2017 category. | `[ ] PASS / FAIL` |
| **8** | **Cuff Calibration Gate** | Enter reference arm cuff values (e.g. 120/80). System computes calibration offset $\Delta SBP, \Delta DBP$, storing entry in `bp_calibrations`. Subsequent estimates update with calibration badge. | `[ ] PASS / FAIL` |
| **9** | **Hypertensive Crisis Gate** | Enter cuff reading $\ge 180$ or $\ge 120$. System immediately displays ESC/ISH 2023 Hypertensive Crisis emergency dialog with instructions and Egyptian Emergency (Call 123). *Verify model estimates alone never trigger this alert.* | `[ ] PASS / FAIL` |
| **10** | **Session Recording & Stats** | Record a 60-second resting session. Finish session. Repository saves session records, raw sample chunks, and summary metrics (`avg_hr`, `min_hr`, `max_hr`, `sqi`). | `[ ] PASS / FAIL` |
| **11** | **Personalized Analytics** | Open *Insights Dashboard*. View trend analysis, recovery drop, baseline comparisons, and evidence-grounded non-diagnostic lifestyle insights. | `[ ] PASS / FAIL` |
| **12** | **Doctor & Clinic Discovery** | Open *Find Doctor*. Test specialty filtering (Cardiologists, Primary Care) and distance sorting. Verify complete local data handling without unauthorized geolocation tracking. | `[ ] PASS / FAIL` |
| **13** | **Clinical PDF Export** | Tap *Generate Clinical Report*. System renders a multi-page bilingual PDF (Arabic & English) with session charts, baseline statistics, cryptographic QR verification code, and clinical disclaimer. | `[ ] PASS / FAIL` |

---

## 5. Field Troubleshooting Matrix

| Issue Encountered | Likely Root Cause | Immediate Action |
|:---|:---|:---|
| **App cannot find ESP32-C3** | Bluetooth or Location disabled on phone; or firmware not in advertising state. | Verify phone Bluetooth & Location toggles are ON. Check serial output on ESP32-C3: confirm `[BLE] Advertising started`. |
| **Zero / erratic BPM readings** | Finger placed improperly or excessive motion. | Re-seat finger pad lightly on the optical window. Hold still for 10 seconds. Check if red/IR LEDs are glowing. |
| **I2C Sensor Not Detected** | SDA/SCL wire loose or wrong pins. | Check wiring: SDA $\to$ GPIO 4, SCL $\to$ GPIO 5. Confirm 3.3V power (MAX30102 will burn on 5V). |
| **App crash on BLE connection** | BLE permissions denied by Android OS. | Go to *Settings $\to$ Apps $\to$ PulsePatch Lite $\to$ Permissions* and grant *Nearby Devices* / *Bluetooth* and *Location*. |
| **Calibration offset mismatch** | Cuff entry entered with SBP $\le$ DBP. | Enter physiological values where SBP > DBP (e.g. SBP 125, DBP 82). |
