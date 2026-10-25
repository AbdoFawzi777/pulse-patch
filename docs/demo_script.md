# PulsePatch Lite — 5-Minute Capstone Demo Script

**Audience:** Graduation Examination Panel & Technical Reviewers  
**Duration:** 5 Minutes  
**Equipment Needed:**
- Android Smartphone / Tablet with PulsePatch Lite installed
- ESP32-C3 + MAX30102 Sensor Patch (or Simulator fallback)
- USB-C charging cable (patch is powered by a small rechargeable battery, or USB-C while charging)
- Printed or on-screen slide presentation

---

## Timeline & Presentation Walkthrough

### 0:00 – 1:00 | Introduction & Architectural Rigor
- **Speaker:**
  > "Distinguished committee members, welcome to PulsePatch Lite. Our objective was to engineer an end-to-end, privacy-preserving biomonitoring system that bridges custom embedded firmware, Bluetooth Low Energy communication, and on-device machine learning in Flutter.
  > 
  > Before diving in, two foundational architectural choices define this project:
  > First: **100% Offline Privacy**. Zero telemetry, tracking, or network calls leave this device. All recordings remain encrypted in local SQLite storage.
  > Second: **Visible Data Truthfulness**. When testing without hardware, the app prominently flags data as 'Simulator' or 'Sample data'. Furthermore, we strictly comply with non-diagnostic boundaries: zero fabricated ECG terminology and zero medical diagnostic claims."

---

### 1:00 – 2:00 | Hardware & Embedded BLE Protocol
- **Speaker:**
  > *(Show physical ESP32-C3 patch or open the Connect Device screen)*
  > "Here is our sensor patch: a 3.3V Espressif ESP32-C3 paired with a Maxim MAX30102 dual-wavelength optical photodiode.
  > 
  > In the firmware, we implemented a custom GATT architecture operating under our dedicated 128-bit service UUID. Every second, the microcontroller evaluates finger contact, analyzes 1st-derivative motion artifacts, and transmits a tight 12-byte binary packet containing protocol version, flags, BPM scaled by 10, signal quality from 0 to 100, and sequence counter."
- **Action:**
  - In app, tap **Scan for Devices** -> tap **Connect**.
  - Show the Device Info card displaying firmware `1.0.0-esp32c3` and sensor `MAX30102_OK` (powered by small rechargeable battery; battery level telemetry is absent so no percentage is displayed).
  - *(Fallback if hardware absent: tap 'Start Simulator' to demonstrate the defensive BLE parser with identical packet structures).*

---

### 2:00 – 3:15 | Live Measurement & Dynamic Fault Tolerance
- **Speaker:**
  > "Let's record a live resting session. We tap 'Measure' on the home canvas, choose a 60-second resting protocol, and begin."
- **Action:**
  - Tap **Begin Recording**.
  - Rest finger on the sensor. The circular countdown begins; show the live heart rate number updating smoothly alongside the optical trend trace and 'Good' quality badge.
- **Demonstrate Fault Tolerance (Interactive Test):**
  > "Watch what happens if the user experiences sudden hand motion or lifts their finger:"
  - Lift finger off sensor for 2 seconds.
  - Point out that the UI immediately displays `Weak signal / Adjust sensor`, pauses the timer, and masks BPM to prevent outlier corruption.
  - Return finger: quality index recovers to $>60$ and countdown seamlessly completes.
  - App transitions to **Measurement Complete Screen**.

---

### 3:15 – 4:15 | On-Device AI Pattern Analysis & Recovery Analysis
- **Speaker:**
  > "Now we transition to AI Insights. Rather than relying on cloud APIs, PulsePatch Lite executes a Multi-Layer Perceptron directly on-device in a background isolate in less than 0.2 milliseconds.
  > 
  > The model extracts five statistical features: mean heart rate, sample standard deviation, start rate, end rate, and the 60-second recovery drop.
  > 
  > Here, our session is classified as 'Typical pattern' with plain-language, non-alarming context. In post-activity sessions, the app evaluates rate recovery drop, which our pipeline simulation study showed averages 21.6 BPM."
- **Action:**
  - View the **Session Pattern Analysis** screen (pixel-matched to the canvas image).
  - Open **Model Information** screen to demonstrate scientific honesty: show model version 1.0.0, architecture MLP 5->16->8->2, and explicit label indicating training data cohort.

---

### 4:15 – 5:00 | History, Internationalization & PDF Export
- **Speaker:**
  > "Finally, let's explore our data management features:
  > In **History**, sessions are browsable with trend curves.
  > In **Reports**, we can generate an offline, publication-grade PDF pulse summary report ready to share.
  > And across the entire system, we support full **Arabic RTL** localization and instant theme switching."
- **Action:**
  - Switch to Settings -> toggle language to **العربية**. Show the interface flipping cleanly into right-to-left layout.
  - Tap **Export PDF Summary** -> display the generated PDF report.
- **Closing Statement:**
  > "PulsePatch Lite demonstrates that consumer mobile devices and low-cost microcontrollers can deliver robust, accessible, and privacy-preserving physiological monitoring. Thank you, and I look forward to your questions."
