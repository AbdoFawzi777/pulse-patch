# PulsePatch Lite — Mobile Application User Guide

Welcome to **PulsePatch Lite**, an educational, offline-first biomonitoring application engineered to interface with an ESP32-C3 microcontroller and MAX30102 optical heart rate sensor.

> [!IMPORTANT]
> **Educational & Non-Diagnostic Notice**  
> PulsePatch Lite is an educational research and engineering demonstration platform. It does not provide medical-grade ECG diagnostics, medical screening, or disease detection. Never make medical decisions based on readings from this prototype.

---

## 1. Getting Started & Onboarding

When launching PulsePatch Lite for the first time:
1. **Welcome Screen:** Introduces the project scope and non-diagnostic principles.
2. **How It Works Screen:** Visual explanation of photoplethysmography (optical LED absorption through peripheral capillary blood volume).
3. **User Preferences:** Configure your display name, preferred duration (30s to 120s), and baseline units.
4. **Permissions Screen:** Grants **Bluetooth (Nearby Devices)** and **Notifications** permissions. 
   - *Note: PulsePatch Lite functions 100% locally. Zero telemetry, location tracking, or internet data leaves your device.*

---

## 2. Connecting to Your Sensor (or Simulator)

Navigate to the **Connect Device** screen via the bottom navigation pill or drawer:

### A. Connecting to Physical ESP32-C3 Hardware
1. Ensure the ESP32-C3 is powered on (via USB-C or battery).
2. Tap **Scan for Devices**.
3. Locate **PulsePatch Lite** in the peripheral list and tap **Connect**.
4. The device card will transition to `Connected`, displaying:
   - Device Name: `PulsePatch Lite`
   - Firmware Version: `1.0.0-esp32c3`
   - Sensor Status: `MAX30102_OK`
   - RSSI: Signal strength in dBm

### B. Using the Built-In Hardware Simulator
If physical hardware is unavailable:
1. The app automatically offers the **Simulated Heart Rate Source**.
2. Tap **Start Simulator**.
3. All telemetry displays explicit `Simulator` / `Sample data` tags in compliance with our visible data truthfulness mandate.

---

## 3. Taking a Measurement

1. From the **Home Screen**, tap the prominent **Measure** action button.
2. **Measurement Preparation Screen:**
   - Select session type:
     - **Rest:** Seated rest in quiet environment (recommended 60s).
     - **Post-Activity:** Immediately following brisk stairs or exercise (recommended 70s+ to capture the 60s recovery drop).
   - Select session duration (30s, 60s, 90s, or 120s).
3. Tap **Begin Recording**:
   - The **Live Measurement Screen** opens with the circular timer countdown.
   - Rest your finger lightly and steadily over the MAX30102 sensor window.
   - Observe real-time heart rate updates, the optical pulse trace, and signal quality indicator.
   - *If your finger moves or lifts, the sensor automatically pauses countdown and alerts you: "Adjust sensor / Low signal quality".*
4. Upon timer completion:
   - The app transitions to the **Measurement Complete Screen**.
   - Displays session mean heart rate, duration, and signal quality score.

---

## 4. Reviewing AI Insights & Recovery Analysis

1. Tap **View AI Insights** or select the AI Insights icon in the bottom navigation bar:
   - **Session Pattern Analysis:**
     - Displays the machine learning classification: `Typical pattern` or `Different pattern`.
     - Read the plain-language educational explanation.
     - Review the 5 underlying statistical features (`mean_hr`, `std_hr`, `start_hr`, `end_hr`, `recovery_drop`).
   - **Recovery Analysis Screen (for Post-Activity sessions):**
     - Quantifies the 1-minute recovery drop ($\Delta \text{BPM}$ from start to 60s).
     - Compares against personal baseline (activates after 5 recorded sessions).
   - **Model Information Screen:**
     - Transparently displays model architecture (MLP 5 -> 16 -> 8 -> 2), training date, version, and training cohort data source (`synthetic bootstrap`).

---

## 5. History, Trends & PDF Pulse Summary Reports

1. **Measurement History Screen:**
   - Lists all recorded sessions with timestamp, BPM hero number, quality badge, and pattern label.
   - Filter by date range (Today, Last 7 Days, Last 30 Days, All).
2. **Historical Trends Screen:**
   - Visual trend line showing resting baseline progression over days and weeks.
3. **Exporting PDF Reports:**
   - Tap **Export PDF Summary** on the Reports screen.
   - Generates an offline, publication-grade multi-page PDF containing tabular session summaries, quality metrics, non-diagnostic disclaimers, and project documentation.
   - Share or print directly via the system share sheet.

---

## 6. Preferences, RTL & Privacy Controls

Access **Settings** from the header or navigation:
- **Language & Locale:** Instant dynamic toggle between **English (LTR)** and **Arabic (RTL - العربية)**.
- **Theme Mode:** Switch between Deep Dark Theme and Bright Light Theme.
- **Reminder Settings:** Configure daily measurement reminders. *(Explicit notice: No background sensor drain).*
- **Application Settings:** Toggle BLE auto-reconnect and 5-sample median smoothing filter.
- **Privacy & Data Management:**
  - View database storage footprint (SQLite C pure FFI).
  - Export full session history as CSV or JSON.
  - **Erase All Data:** Destructive reset that wipes the local SQLite database cleanly after explicit user confirmation dialog.
