# PulsePatch Lite — Design Specification & Contract

**Version:** 1.1.0  
**Status:** Approved Design Contract (Pixel & Metric Calibrated)  
**Source of Truth:** Design boards in `docs/design/` (`Home.png`, `Measuring.png`, `Heart Rate.png`, `AI Insights.png`, `Connect device.png`, `History.png`, `App icon.png`) and `AGENT_PLAN.md`.

---

## 1. Executive Summary & Design Principles

PulsePatch Lite is an educational, non-diagnostic biomonitoring application interfacing with an ESP32-C3 + MAX30102 pulse patch over BLE.
The visual identity communicates high precision, calm modern telemetry, and dark-mode elegance:
- **Atmospheric Canvas:** Base deep near-black (`#04030C`) with exact calibrated radial glows:
  - Top-left corner: Deep cosmic indigo glow (`#190E41`).
  - Bottom-right corner: Deep royal purple glow (`#381463`).
  - Top-right and bottom-left: Pure near-black canvas (`#04030C`).
- **Precision Numerals:** Large, thin typography with tabular figures (`Outfit`, font-weight 300) for instant, legible readings.
- **Tactile Geometric Components:** 22 px rounded navy gradient cards (`#0C1A4A` to `#0B1844`), 56 px circular action buttons, 64 px circular bottom navigation pills, and crisp pill buttons.
- **Truthful Waveforms:** Optical pulse traces represented as smooth, continuous flowing waves. Never ECG spikes, never fabricated waveforms, and never diagnostic labels (no "Sinus Rhythm", "Normal/Abnormal", or ECG claims).
- **Dual-Language & Accessibility First:** Fully responsive to English and Arabic (RTL), text scaling up to 2.0x, high contrast ratios, and minimum 48x48 px touch targets.

---

## 2. Calibrated Design Tokens (Direct Pixel Extraction)

### 2.1 Color Palette

#### Base Canvas & Corner Glows
| Token Name | Hex Code / RGB | Usage |
|---|---|---|
| `bgBase` | `#04030C` (4, 3, 12) | Canvas base near-black |
| `bgGlowTopLeft` | `#190E41` (25, 14, 65) | Deep indigo radial glow in top-left |
| `bgGlowBottomRight` | `#381463` (56, 20, 99) | Deep purple radial glow in bottom-right |

#### Surface & Card Tokens
| Token Name | Hex Code / RGB | Usage |
|---|---|---|
| `cardBgNavy` | `#0B1947` (11, 25, 71) | Standard card base |
| `cardBgGradientStart` | `#0C1A4A` (12, 26, 74) | Card gradient top boundary |
| `cardBgGradientEnd` | `#0B1844` (11, 24, 68) | Card gradient bottom boundary |
| `cardBorder` | `#1E2D60` (30, 45, 96) | Subtle 1 px card contour border |
| `cardAiGradientStart` | `#451A8B` (69, 26, 139) | AI Model Result card top-left violet |
| `cardAiGradientEnd` | `#112061` (17, 32, 97) | AI Model Result card bottom-right navy |

#### Feature & Accent Tokens
| Token Name | Hex Code / RGB | Usage |
|---|---|---|
| `timerArcBlue` | `#4C8DF5` (76, 141, 245) | Circular timer active progress arc |
| `timerInnerDisc` | `#070F2B` (7, 15, 43) | Circular timer inner background circle |
| `timerTrackRing` | `#1B2A66` (27, 42, 102) | Circular timer inactive track ring |
| `buttonStopSave` | `#0B1840` (11, 24, 64) | Measuring screen "Stop and save" pill button |
| `accentPurple` | `#6D28D9` (109, 40, 217) | Secondary accent, radar mid-rings |
| `accentMagenta` | `#E11D9B` (225, 29, 155) | Variability dots, radar beacon, heart gradient |
| `accentBlue` | `#2563EB` (37, 99, 235) | Variability dots, heart gradient lower stop |
| `accentCyan` | `#22D3EE` (34, 211, 238) | Radar inner ring, pulse contour glow |
| `textPrimary` | `#FFFFFF` | Hero numbers, headings, high-contrast labels |
| `textSecondary` | `#94A3B8` | Subtitles, unit labels, inactive states |
| `textMuted` | `#64748B` | Footers, disclaimer notes, subtle metadata |

#### Interactive Component Dimensions & Colors
| Component | Logical Dimensions | Background | Text / Icon | Border |
|---|---|---|---|---|
| PillButton (White) | Width 96 pt, Height 42–48 pt | `#FFFFFF` | `#04030C` (Outfit 600) | None |
| PillButton (Dark) | Width 96 pt, Height 42 pt | `#0F1C3F` | `#FFFFFF` (Outfit 500) | `1px #22335E` |
| Stop and Save Pill | Width 165 pt, Height 50 pt | `#0B1840` | `#FFFFFF` (Outfit 600) | `1px #1E2D60` |
| Header Circle (56px) | 56 x 56 pt | `#0F172A` | `#FFFFFF` (24 pt icon) | `1px rgba(255,255,255,0.08)` |
| Bottom Circle (64px) Active | 64 x 64 pt | `#FFFFFF` | `#04030C` (28 pt icon) | None |
| Bottom Circle (64px) Inactive | 64 x 64 pt | `#0D1632` | `#94A3B8` (28 pt icon) | None |
| Circular Timer | Diameter 145 pt (radius 72.5 pt) | `#070F2B` | White 30 pt time, pause icon | Arc `#4C8DF5`, Track `#1B2A66` |

---

### 2.2 Typography (`Outfit`)

The entire application standardizes on the **Outfit** Google Font family, explicitly utilizing OpenType tabular figures (`FontFeature.tabularFigures()`) for numerical stability.

| Role | Font Size | Line Height | Weight | Letter Spacing | Features / Notes |
|---|---|---|---|---|---|
| `HeroNumberLarge` | 96 px | 1.0 | 300 (Light) | -2.0 px | Measuring screen live BPM |
| `HeroNumberMedium` | 84 px | 1.0 | 300 (Light) | -1.5 px | Heart Rate screen summary BPM |
| `HeroNumberCard` | 48 – 56 px | 1.0 | 300 (Light) | -1.0 px | Home last session & History items |
| `HeadingLarge` | 28 px | 34 px | 600 (SemiBold) | -0.5 px | Screen greeting, primary titles |
| `HeadingMedium` | 22 – 24 px | 28 px | 500 (Medium) | -0.3 px | Screen headers, modal titles |
| `Subtitle` | 20 – 22 px | 26 px | 400 (Regular) | 0 px | Secondary greeting ("How are you today?") |
| `BodyText` | 15 – 16 px | 22 px | 400 (Regular) | 0 px | Informational copy, card descriptions |
| `LabelBold` | 16 px | 20 px | 600 (SemiBold) | 0 px | Button text, interactive targets |
| `LabelRegular` | 13 – 14 px | 18 px | 400 / 500 | 0.2 px | Card headers, metrics labels, timestamps |
| `CaptionMuted` | 11 – 12 px | 16 px | 400 (Regular) | 0.3 px | Disclaimers, footer notices, chip text |

---

## 3. Analysis of the 6 Canvas Screens & App Icon

### 3.1 `Home.png` (Screen 6: Home)
- **Top Header:** Left: "Hi, there!" (White, 28 px SemiBold); below it "How are you today?" (`#64748B`, 22 px Regular). Right: Profile and Notifications 56 px circular buttons.
- **Status Chips:** Pill chips `Connected · PulsePatch-C3` and `Sample data` (`#0B1229`, border `#1E2B52`).
- **Centerpiece Illustration:** Layered heart graphic: outer navy-purple silhouette (`#171B42`); inner heart gradient magenta (`#E11D9B`) to blue (`#2563EB`).
- **Metrics Grid (Two columns, 22 px radius cards `#0B1947`):**
  - Left ("Last session"): "Mon 18:05 · not live", hero `74` with `BPM`.
  - Right ("AI Insights"): "Typical\npattern", white PillButton "Measure".
- **Bottom Navigation Bar:** Four 64 px circles; Circle 1 (Home) is active (solid white background `#FFFFFF`, dark icon `#04030C`).

### 3.2 `Measuring.png` (Screen 11: Live Heart Rate)
- **Top Bar:** 56 px circular Back button, centered title "Measuring".
- **Live Display:** Hero `74` (Outfit 300, 96 px) + `BPM` (16 px).
- **Waveform:** Smooth white optical pulse trace, stroke width 2.5 px. Subtitle: "Optical pulse trace · Signal: Good".
- **Circular Timer Widget (Calibrated):**
  - Diameter: 145 pt logical (290 px at 2x).
  - Center disc: `#070F2B`.
  - Inactive ring: `#1B2A66`.
  - Active progress arc: `#4C8DF5` (vibrant blue, stroke 3 pt / 6 px).
  - Time text: `00:09` (Outfit 400, tabular, 30 px, white).
  - Pause icon: `||` centered beneath the time.
- **Primary Button (Calibrated):** Navy PillButton "Stop and save", width 165 pt, height 50 pt, background `#0B1840`.

### 3.3 `Heart Rate.png` (Screen 13: Measurement Complete / Summary)
- **Top Bar:** 56 px circular Back button, title "Heart Rate".
- **Upper Waveform:** Smooth optical pulse trace (~100 px).
- **Hero Stats:** Hero `74` (84 px) + `BPM` (18 px), right-aligned "58 min 96 max" (`#94A3B8`).
- **Pulse Interval Card:** 22 px radius navy card, "Pulse interval" (`#FFFFFF`, 16 px) -> `811 ms` (26 px).
- **Variability (est.) Card:** 22 px radius navy card, "Variability (est.)" -> `41 ms`. Dot chart: 6 time columns (`6am`, `9am`, `12pm`, `3pm`, `6pm`, `9pm`) with magenta (`#E11D9B`) and blue (`#2563EB`) scatter dots.
- **Footer Disclaimer:** "Sample data · estimated from optical pulse peaks".

### 3.4 `AI Insights.png` (Screen 15: Session Pattern Analysis)
- **Top Bar:** 56 px circular Back button, title "AI Insights".
- **Model Result Card:** Violet-to-navy gradient (`#451A8B` to `#112061`, 22 px radius). "Model result" + "Experimental" pill chip. Main text "Typical pattern" (Outfit 500, 32 px). Plain explanation: "Similar to your last 5 rest sessions. A pattern label, not a health rating."
- **Feature Cards Stack (5 cards in `#0B1947`):**
  1. `mean_hr` -> `74 BPM`
  2. `std_hr` -> `3.1`
  3. `start_hr` -> `78 BPM`
  4. `end_hr` -> `70 BPM`
  5. `recovery_drop` -> `-8 BPM`
- **Footer Text:** "Runs on this phone · small neural network running locally in the app · 6 sessions available".
- **Bottom Navigation:** Circle 3 (Insights) is active.

### 3.5 `Connect device.png` (Screen 7: Device Connection)
- **Top Bar:** 56 px circular Back button, title "Connect device".
- **Scanning Radar:** Concentric circles: center solid magenta beacon (`#E11D9B`, 28 px diameter), cyan inner ring (`#22D3EE`), purple middle ring (`#6D28D9`), dark indigo outer ring (`#1D1C48`). Subtitle: "Scanning · keep the patch within 1 m".
- **Device List:**
  - Card 1: "PulsePatch-C3", "Signal strong · -52 dBm", white PillButton "Connect".
  - Card 2: "PulsePatch-C3 (2)", "Signal weak · -85 dBm", dark PillButton "Connect".
- **Footer Disclaimer:** "Sensor: MAX30102 · Battery and firmware shown only if reported".

### 3.6 `History.png` (Screen 19: Measurement History)
- **Top Bar:** 56 px circular Back button, title "History".
- **Filter Bar:** Segmented pill toggle: "Week" (active: white `#FFFFFF`, black text) vs "Day" (navy `#0E1736`, white text). Right: "Sample data" pill chip.
- **Session Cards (`#0B1947`):**
  - Item 1: "Today 18:05", "Quality: Good · Pattern: typical", `74 BPM`.
  - Item 2: "Sun 09:30", "Quality: Good · Pattern: typical", `71 BPM`.
  - Item 3: "Fri 20:12", "Quality: Fair · Pattern: typical", `82 BPM`.
  - Item 4: "Thu 07:45", "Quality: Good · Pattern: typical", `68 BPM`.
- **Bottom Navigation:** Circle 2 (History) is active.

### 3.7 `App icon.png` (Application Launcher Icon)
- 1024x1024 master squircle, layered heart with magenta-to-purple gradient, smooth white optical pulse line with cyan glow border. Non-ECG single smooth wave. Palette tokens: `#04030C`, `#6D28D9`, `#E11D9B`, `#2563EB`, `#22D3EE`.

---

## 4. The 21 Derived Screens (Master Screen Inventory)

Out of the 27 screens in Section 9 of the Master Build Plan, 6 are provided in the canvas images and 21 are derived. All 21 derived screens strictly adhere to the calibrated design tokens, 22 px card radii, 56 px circular action buttons, and `Outfit` typography:

1. **Splash Screen:** Atmospheric dark background with glowing animated pulse heart icon, thin app title `PulsePatch Lite`, and version tag.
2. **Welcome Screen:** Introductory walkthrough, hero graphic, 3 core value cards (Offline first, BLE sensor, On-device pattern analysis), white PillButton "Get Started".
3. **How It Works Screen:** 5-step numbered cards: 1. Place patch on fingertip; 2. Keep hand still; 3. Optical LED detects pulse; 4. View live telemetry; 5. Explore local AI patterns.
4. **User Preferences Screen:** Optional user display name, metric units selector, educational privacy statement, white PillButton "Continue".
5. **Permissions Screen:** Educational pre-permission cards explaining Bluetooth and Notification access. Grant buttons with Settings redirect if permanently denied.
6. **Device Details Screen:** 56 px back button, connected device card, live RSSI signal meter, firmware version string, MAX30102 sensor status, packet diagnostics (sequence, loss count).
7. **Device Troubleshooting Screen:** Guided recovery steps for connection drops, Bluetooth off, weak signal, sensor error, or finger detachment.
8. **Measurement Preparation Screen:** Session type selector: Pill toggle for "Resting Session" vs "Post-Activity Session". Fingertip placement check card, white PillButton "Start Measurement".
9. **Measurement Quality Screen:** Dedicated real-time diagnostic panel: MAX30102 signal quality score (0–100), finger contact status, and motion artifact flags.
10. **AI Insights Dashboard Screen:** Aggregated pattern history: count of Typical vs Different sessions, consistency score, recovery trends.
11. **Recovery Analysis Screen:** Post-activity recovery drop metric (`recovery_drop = start_hr - 60s_window_hr`), personal baseline comparison against user's prior sessions, recovery curve chart.
12. **Historical Trends Screen:** Daily and weekly trend charts with explicit gap handling (missing days show gaps, never zeroed). Rest vs Post-activity filtering.
13. **AI Model Information Screen:** Model transparency card: `PulsePatch AI Insights`, small neural network running locally in the app, version, training date, input features, limitations, non-diagnostic disclaimer.
14. **Session Details Screen:** Drill-down view for an individual session: date/time, optical pulse trace playback, full statistics, AI classification, export to CSV/JSON, delete with confirmation.
15. **Reports Screen:** Date range picker, session count, PDF generation preview with charts, share intent button, print action.
16. **Notifications Center Screen:** Real event logs: Device connected/disconnected, measurement completed, quality warnings, scheduled reminders.
17. **Reminder Settings Screen:** Daily measurement schedule picker, permission status, explicit disclaimer: No background sensor monitoring.
18. **Profile and Preferences Screen:** User display name, theme toggle (Dark default / Light available), language selector (English / Arabic RTL), data export.
19. **Application Settings Screen:** BLE auto-reconnect toggle, measurement duration default (30s to 120s), chart smoothing preference, developer mode.
20. **Privacy and Data Management Screen:** Transparent local SQLite storage declaration, export complete database, "Erase All Data" red confirmation modal.
21. **About and Project Information Screen:** Graduation project credits, ESP32-C3 + MAX30102 hardware documentation, open source licenses, educational prototype disclaimer.

---

## 5. Medical & Non-Diagnostic Compliance Guardrails

1. **Strict Terminology:**
   - Always write: `Optical pulse trace`, `Pulse interval`, `Estimated variability`, `Typical pattern`, `Different pattern`.
   - Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.
2. **Data Truthfulness:**
   - Any synthetic or simulator data must bear a prominent visible chip: `Sample data` or `Simulator`.
   - Any stale value must be labeled with its exact timestamp and `not live` / `Saved`.
   - Gaps in sensor streams are displayed as gaps in charts, never connected as 0 BPM.
3. **No Medical Claims:**
   - Every report and AI screen includes the explicit disclaimer: *"PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations."*
