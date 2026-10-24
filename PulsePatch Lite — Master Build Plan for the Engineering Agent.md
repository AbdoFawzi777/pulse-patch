# PulsePatch Lite — Master Build Plan for the Engineering Agent

Owner: software lead of the PulsePatch Lite graduation team. Audience: an autonomous coding agent running on the owner's machine. Language of this document is English so the agent follows it precisely; the app itself ships in English with Arabic (RTL) as a second language.

## 0. Authority and operating rules

You have full permission to create, edit, run and delete anything inside the project workspace: Flutter app, firmware, Python ML code, datasets, tests, docs. Install any required packages. Work autonomously from Phase 0 to the last phase. Ask the owner only when blocked by something physical (the chip is not connected, a sensor measurement is needed, a volunteer must be recorded).

Rules you must follow throughout:

- Keep a file PROGRESS.md at the repo root. After every phase record: what was done, what was tested, open issues, next step. Commit after every phase with a clear message.
- Never invent hardware capabilities. The device is ESP32-C3 + MAX30102 over BLE. There is NO ECG. Never draw an ECG waveform, never write ECG, Sinus Rhythm, Normal or Abnormal health labels. The optical trace is called Optical pulse trace.
- Never show a fabricated number as live. Every value is one of: live (valid, quality-gated), last saved (with timestamp and a stale label), or none. Simulator and sample data must be visibly labeled Sample data or Simulator.
- The app is an educational prototype, not a medical device. No diagnoses, no healthy or unhealthy labels, no alarming notifications from the experimental model.
- Everything core works offline: live monitoring, local history, statistics, and AI inference. No cloud and no mandatory account.
- Quality bars: flutter analyze with zero warnings, formatted code, null safety, unit and widget tests for every feature, no hard-coded strings (use localization), no magic numbers (named constants).

## 1. Inputs you receive

1. The UI/UX canvas: Home, Measuring, Heart Rate, AI Insights, Connect device, History, and App icon boards. Treat it as the visual source of truth.
2. The master screen inventory (27 screens, section 9 below). Screens not on the canvas must be designed by you in exactly the same visual language.
3. Visual language to reproduce exactly: near-black background with deep purple and indigo glow in the corners; large thin numerals (Outfit, weight 300, tabular figures); navy gradient cards with 22 px radius; 56 px circular icon buttons for back, profile and notifications; a bottom navigation made of four 64 px circles with the active one white; layered gradient heart illustration on Home; circular timer with a blue progress arc on the measuring screen; blue and magenta dot chart for variability; white pill buttons. Icon colors: #04030C, #6D28D9, #E11D9B, #2563EB, #22D3EE. Define these as ThemeExtension tokens; also build a light theme.
4. The app icon (heart with a pulse line): export 1024 px PNG and adaptive foreground and background, then generate launcher icons with flutter\_launcher\_icons.

## 2. Technology stack (use unless a clear technical reason says otherwise)

- Flutter stable, Dart 3, Android first (iOS-compatible code).
- State management: Riverpod (with code generation optional). Navigation: go\_router with a shell route for the bottom navigation.
- Local database: Drift (SQLite). Preferences: shared\_preferences.
- BLE: flutter\_blue\_plus. Permissions: permission\_handler. Notifications: flutter\_local\_notifications.
- Charts: custom painters or fl\_chart, styled to the reference, with gap handling (null is a gap, never zero).
- ML on device: tflite\_flutter. Reports: pdf and printing, share\_plus.
- Localization: ARB files, English and Arabic with RTL support.
- Tests: flutter\_test, mocktail, integration\_test, golden tests for key screens.

## 3. Repository layout

- app/ — Flutter project, feature-first: core/ (theme, constants, utils, errors), data/ (drift, repositories), domain/ (entities, use cases, signal processing, statistics), features/ (onboarding, home, device, measurement, history, insights, reports, notifications, settings, about), shared/ (widgets).
- firmware/ — ESP32-C3 PlatformIO project.
- ml/ — Python: data, notebooks, src, models, reports, tests.
- docs/ — BLE protocol, feature definitions, model card, validation report, demo script, user guide.

## 4. Phases

### Phase 0 — Setup

Create the repo, the structure above, CI-style scripts (analyze, test, format), and PROGRESS.md. Acceptance: app launches with an empty themed shell and tests run.

### Phase 1 — Design system

Implement tokens, typography (Outfit with tabular figures), and reusable widgets: HeartRateHeroNumber, MetricCard, StatusChip, CircleIconButton, PillButton (white and dark), BleDeviceCard, SessionTile, InsightCard, PulseTraceChart, TrendChart, DotVariabilityChart, CircularTimer, EmptyState, LoadingState, ErrorBanner, ConfirmDialog, InfoTooltip, BottomCircleNav, DateRangeFilter. Each widget has a golden test and accessibility labels. Respect system text scaling, contrast and 48 px touch targets; never rely on color alone.

### Phase 2 — Onboarding and permissions

Splash with animated pulse, Welcome, How It Works (five steps, fingertip use clearly stated), User Preferences (optional name, units, privacy text, continue without account), Permissions (explain before requesting Bluetooth and notification permissions; handle denied and permanently denied with a Settings shortcut). Persist onboarding completion.

### Phase 3 — Data layer

Drift tables: sessions (id, startedAt, endedAt, type: rest or postActivity, qualitySummary, appVersion, source: device or simulator), samples (sessionId, tMs, bpm nullable, quality, isValid), session\_stats, ai\_results (sessionId, modelVersion, label, featuresJson, createdAt), reminders, settings. Repositories, migrations, export to JSON and CSV, delete-all, and storage-failure handling. Test with in-memory database.

### Phase 4 — BLE layer and simulator

Implement against an abstract HeartRateSource interface with two implementations: BleHeartRateSource (real) and SimulatedHeartRateSource (labeled Simulator, used for development and the demo fallback). Handle states: Bluetooth off, permission denied, scanning, connecting, connected, disconnected, reconnecting with backoff, no sensor data, timeouts. Protocol in section 5. Parse packets defensively; discard malformed ones and count them for diagnostics.

### Phase 5 — Measurement engine (pure Dart, fully unit-tested)

Pipeline: packet, validity gate, smoothing, outlier rejection, session recorder. Defaults, all named constants: accept BPM 30 to 220, quality at least a threshold agreed with firmware, reject jumps larger than 25 BPM between consecutive seconds, median filter over 5 samples, require 5 consecutive valid samples before showing a number, hide the number after 3 seconds without a valid sample. Session states: preparing, waitingForSignal, measuring, paused, completed, discarded. Preserve the current session when navigating away or when the connection drops briefly.

### Phase 6 — Core screens: Home, Measure, Live, Complete

Home distinguishes live, last saved (timestamp plus stale label), and none. Measurement preparation asks the session type (rest or post-activity). Live screen follows the reference, with pause, resume, stop. Complete screen shows duration, average, min, max, variability statistics, quality summary, with Save, Discard, View AI Insights. Compute everything from recorded samples only.

### Phase 7 — History, details, trends, reports

History list with search and date filters and an empty state. Session details with chart, stats, quality, recovery, AI result, and delete with confirmation. Historical trends: day and week views, session averages, rest or post-activity filters, visible gaps. Reports: date range, session count, average over eligible sessions, trend charts, rule-based written summaries labeled by source, PDF export and share, clear separation of measured values, calculated summaries, and model output. Export failure state with retry.

### Phase 8 — Statistics and recovery analysis

Implement and test exactly as defined in section 6. Recovery analysis appears only if the required timed samples exist; otherwise show an insufficient-data state, not a guess. Add a personal baseline comparison: z-score of the session against the user's own previous comparable sessions, shown only with at least 5 sessions, described as statistics and not as AI.

### Phase 9 — AI Insights integration

Load model.tflite and model\_meta.json (feature order, scaler mean and scale, label names, version, training date) from assets. Screens: AI Insights dashboard, Session Pattern Analysis (the five values, label, plain-language explanation, comparison with own history), Recovery Analysis, AI Model Information (name PulsePatch AI Insights, TensorFlow Lite, version, date, local inference, features, limitations, optional technical panel for evaluators). Run inference in an isolate. States: model loading, analyzing, model unavailable, insufficient data, invalid input. Never show a raw score as probability and never use healthy or unhealthy wording. Output labels: Typical pattern and Different pattern.

### Phase 10 — Notifications, settings, privacy, about

Notifications center only for real events: device connected or disconnected, measurement completed, data-quality warning, AI analysis finished, user reminders. Reminder settings with schedule and permission status; do not claim background monitoring. Profile and preferences (name, units, theme, language, local data), application settings (Bluetooth shortcut, measurement and chart preferences, AI preferences, export), Privacy and Data Management (local storage, on-device inference, delete data, export history, statement that no external service receives data), About (project, hardware, Flutter and TensorFlow Lite, educational disclaimer, version, credits).

### Phase 11 — System states and hardening

Implement a reusable message plus recovery action for: first launch, Bluetooth off, permission denied, scanning, connecting, connected, disconnected, reconnecting, no sensor data, weak signal, invalid measurement, measuring, completed, model loading, analyzing, model unavailable, insufficient data, no history, storage failure, export failure, unexpected error (global error boundary with safe logging). Write the Device Troubleshooting screen with actionable steps for each failure.

### Phase 12 — Firmware (ESP32-C3 + MAX30102)

PlatformIO project using a MAX3010x library and NimBLE. Read the sensor, compute BPM and a signal-quality value, notify over the characteristics in section 5. Document wiring (I2C pins, 3.3 V), sampling rate, and the algorithm. If the firmware does not send raw samples, the app must hide the optical trace and show the trend line instead. Battery is exposed only if a real measurement circuit exists.

### Phase 13 — ML data collection, training, and analysis

See section 7. Deliver a trained model, a model card, and a data analysis report.

### Phase 14 — Integration with the real chip

Follow the checklist in section 8. Calibrate thresholds from real recordings.

### Phase 15 — QA and release

Full test run, accessibility review (TalkBack, text scale 1.3 and 2.0, contrast), Arabic RTL review, performance profile (steady 60 fps on the live screen, no memory growth in a 30-minute session), battery and BLE reconnect stress test, small-screen and large-screen checks. Build a release APK, write the user guide and the 5-minute demo script (simulator fallback plus real device).

## 5. BLE contract (agree with firmware; defaults below)

Use a custom 128-bit service UUID (generate and record it in docs/ble\_protocol.md). Characteristics:

- Heart rate measurement (notify), 12 bytes little-endian: uint8 protocolVersion, uint8 flags (bit0 contactDetected, bit1 motionSuspected), uint16 bpmTimes10 (0xFFFF means invalid), uint8 quality 0 to 100, uint32 deviceTimestampMs, uint16 sequence.
- Raw optical samples (notify, optional): batches of uint16 samples with a start timestamp and sampling rate. Only used if the firmware really sends them.
- Device info (read): firmware version string and sensor status (sensor found, sensor error). Battery characteristic only if hardware supports it.

The app must work with sequence gaps, duplicate packets, and out-of-order packets, and measure last communication time for diagnostics.

## 6. Feature definitions (shared by Dart and Python; must be identical)

Write these in docs/feature\_definitions.md and implement once in Dart and once in Python, with a shared set of golden test vectors that both must pass.

- Valid samples only: samples that pass the validity gate. A session needs at least 30 valid seconds to be analyzable.
- mean\_hr: mean of valid BPM values.
- std\_hr: sample standard deviation of valid BPM values.
- start\_hr: median of valid BPM in the first 10 seconds of valid data.
- end\_hr: median of valid BPM in the last 10 seconds of valid data.
- recovery\_drop: for post-activity sessions that last at least 70 seconds, median of the first 10 seconds minus median of the window 55 to 65 seconds. For rest sessions, start\_hr minus end\_hr. If the window lacks valid data, recovery\_drop is null and the session is marked Insufficient for AI.
- Variability statistic shown in the UI: standard deviation of successive differences of detected pulse intervals, labeled estimated, only when peak timing is available.

## 7. Machine learning and data analysis (do all of it)

### 7.1 Be honest about data

The two labels (typical pattern and different pattern) must be defined before training and written in the model card. Use this protocol unless the owner changes it: record each volunteer in resting sessions (label by protocol: typical = seated rest, 2 to 3 minutes) and post-activity sessions (step test or brisk stairs for 1 minute, then seated recovery, 2 minutes) and define the classes from the protocol plus a documented rule, for example the post-activity recovery profile versus the person's resting profile. Whatever rule is used, it must be written down and reproducible. Never claim the labels mean healthy or unhealthy.

### 7.2 Data sources

1. Own data (primary): add an Export for training feature in the app (CSV with the five features, session type, subject id as an anonymous code, quality, device source). Collect a minimum target of 8 or more consenting volunteers and 150 or more sessions; record a written consent text in docs. Also record a reference heart rate with a pulse oximeter or chest strap for validation.
2. Public data (to build and test the pipeline before own data exists): choose public PPG or heart-rate datasets such as PPG-DaLiA, WESAD or BIDMC; verify license and availability yourself and cite them. Convert them to the same five features.
3. Synthetic data: only to unit-test code and to bootstrap a demo model; every synthetic row has source=synthetic, and a model trained mainly on synthetic data must say so in the app's Model Information screen.

### 7.3 Pipeline (Python 3.11, in ml/)

- Ingestion, cleaning, and feature extraction using the shared definitions.
- EDA notebook: distributions, class balance, per-subject differences, quality effects, missing data.
- Split by subject (GroupKFold or leave-one-subject-out), never by random rows, to avoid leakage.
- Baselines: logistic regression and random forest; then a tiny Keras MLP (for example 5 to 16 to 8 to 1 or softmax). Choose the simplest model that performs well; report accuracy, precision, recall, F1, ROC-AUC, confusion matrix, and calibration with confidence intervals.
- Fit the standard scaler on training data only; save mean and scale into model\_meta.json.
- Export to TensorFlow Lite (float32 first; quantize only if accuracy does not drop). Verify parity: Python model versus TFLite versus the Dart implementation on the shared test vectors within a small tolerance.
- Write the model card: purpose, data, labels, metrics, limits, known failure modes, version, date.
- Make training reproducible: fixed seeds, requirements.txt, a single make or script command.

### 7.4 Data analysis deliverables

- Sensor validation report: MAX30102 BPM versus the reference device with mean absolute error, mean absolute percentage error, and Bland-Altman plots, split by rest and post-activity and by signal quality.
- Recovery analysis report: distribution of recovery\_drop by session type and by volunteer.
- Signal quality study: how quality, motion, and finger pressure affect errors, which feeds the thresholds in Phase 5.
- A short summary for the graduation presentation with limitations stated plainly.

## 8. Checklist when the chip is connected

1. Flash firmware, confirm serial output of BPM and quality.
2. Scan from the app, connect, verify notifications, check packet rate and loss.
3. Compare app BPM with the reference device at rest, 3 volunteers.
4. Tune the validity thresholds (quality, jump limit, hide delay) from real data and record the final values in docs.
5. Test: finger removed, finger moved, Bluetooth switched off mid-session, device powered off, phone screen locked, app backgrounded, reconnect.
6. Record the first real dataset with the Export for training feature.
7. Retrain, re-export, rerun parity tests, ship the new model.

## 9. Screen checklist (all must exist)

Splash, Welcome, How It Works, User Preferences, Permissions, Home, Device Connection, Device Details, Device Troubleshooting, Measurement Preparation, Live Heart Rate, Measurement Quality, Measurement Complete, AI Insights Dashboard, Session Pattern Analysis, Recovery Analysis, Historical Trends, AI Model Information, Measurement History, Session Details, Reports, Notifications Center, Reminder Settings, Profile and Preferences, Application Settings, Privacy and Data Management, About and Project Information.

Navigation: bottom circles for Home, History, Insights, Device or Settings as drawn on the canvas; a prominent Measure action on Home. Back navigation everywhere; the current session survives navigation.

## 10. Definition of done

- All 27 screens match the canvas style, work in English and Arabic, dark and light themes.
- Works fully offline with the real device and with the simulator.
- Tests pass, analyze is clean, release APK builds, icon applied.
- Model trained on documented data, parity-tested, model card shipped, the Model Information screen shows the true version, date, and data source.
- No ECG, diagnosis, or unsupported claims anywhere in the UI, PDF reports, or notifications.
- docs/ contains the BLE protocol, feature definitions, model card, validation report, user guide, and demo script.

## 11. Final report format

When finished, produce FINAL\_REPORT.md containing: what was built per phase, test results, model metrics, sensor validation results, known limitations, items still needing the owner (physical tasks, consent forms, extra data), and exact commands to run the app, firmware flashing, training, and exporting the model.
