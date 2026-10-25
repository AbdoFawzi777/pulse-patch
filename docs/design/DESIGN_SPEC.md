# PulsePatch Lite — Design Specification Contract

**Reference Base Resolution:** $390 \times 844\text{ logical px}$  
**Font Family:** `Outfit` (Bundled locally: weights 300, 400, 500)  
**Base Background:** `#04030C` with dual radial glows  
**Source of Truth:** `docs/design/source/*.dc.html` & `docs/design/TOKENS.md`

---

## 1. Global Shell & Layout System

1. **Root Scaffolding:**
   - Background: Dark canvas `#04030C` overlaid with:
     - Top-left radial glow: `radial-gradient(80% 35% at 0% 0%, #1A0F44 0%, transparent 70%)`
     - Bottom-right radial glow: `radial-gradient(90% 45% at 100% 100%, #3A1566 0%, transparent 70%)`
   - Padding: Exactly `28px` top, `20px` horizontal, `20px` bottom (scaled by $S = \text{screenWidth} / 390.0$).
   - Status bar: Transparent with light content (`SystemUiOverlayStyle.light`).
   - Zero Material AppBar, zero Material elevation, zero M3 surface tints.

2. **Card Surfaces (`.c`):**
   - Background: `linear-gradient(160deg, #0F2160 0%, #08122E 100%)`
   - Border radius: `22px`
   - Padding: `16px`

3. **Buttons & Controls:**
   - Circular Action Button (`.rb`): $56 \times 56\text{ px}$, background `#0B1840`, border none, icon `#FFFFFF` (24x24, stroke 1.6).
   - White Pill Button (`.w`): Height `48px`, border radius `24px`, background `#FFFFFF`, text `#0B1840`, Outfit 500 16px, padding `0 24px`.
   - Dark Pill Button (`.w` dark): Height `48px`, border radius `24px`, background `#0B1840`, text `#FFFFFF`, Outfit 500 16px.

4. **Bottom Navigation Bar (`.nv`):**
   - Four $64 \times 64\text{ px}$ circular buttons with `12px` horizontal gap.
   - Active: background `#FFFFFF`, icon `#0B1840`.
   - Inactive: background `#0B1840`, icon `#C9D0F5`.
   - Order:
     1. Home (house outline)
     2. History (clock outline with hands)
     3. AI Insights (three vertical bars)
     4. Connect Device (heartbeat patch/shield)

---

## 2. Core Master Screens

### 2.1 Home Screen (`Main.dc.html` $\rightarrow$ `Home.png`)
- **Header:**
  - Left: Title `"Hi, there!"` (26px, Outfit 300, `#FFFFFF`), Subtitle `"How are you today?"` (26px, Outfit 300, `#6B6F95`).
  - Right: Two 56px circular buttons (Profile, Notifications) in `#0B1840`.
- **Status Tags:** Row with 8px gap:
  - `"Connected · PulsePatch-C3"` (border 1px `#3B4270`, radius 8px, padding 2px 6px, text 11px `#9AA0C4`)
  - `"Sample data"` (same style)
- **Hero Heart Illustration:**
  - Outer Heart: 330x300 viewBox 0 0 200 180, fill `#3A2A8F` (0.7) to `#0B2A7A` (0.6).
  - Inner Heart: Scale 0.6, translate (40, 36), fill `#C0148F` $\rightarrow$ `#4B1E9E` $\rightarrow$ `#1D4ED8`.
  - Negative margin: `-70px` overlap with cards below.
- **Card Row (2 cards side by side, gap 12px):**
  - Card 1 (Last session): Header `"Last session"` + tag `"Saved"`. Subtitle `"Mon 18:05 · not live"`. Large text `"74 BPM"` (44px, Outfit 300, tabular figures).
  - Card 2 (AI Insights): Header `"AI Insights"`. Title `"Typical pattern"` (24px, Outfit 300). White pill button `"Measure"` (48px height, 100% card width).
- **Bottom Navigation:** Circle 1 (Home) active.

### 2.2 Measuring Screen (`Live.dc.html` $\rightarrow$ `Measuring.png`)
- **Header:** 56px Back button, Title `"Measuring"` (22px, Outfit 300, center-aligned), 56px empty spacer.
- **Hero Pulse Rate:** Giant numeral `"74"` (96px, Outfit 300, tabular figures, `#FFFFFF`), subtitle `"BPM"` (20px, `#FFFFFF`).
- **Optical Pulse Trace:** 350x130 vector trace, white stroke 1.3px.
- **Trace Subtitle:** `"Optical pulse trace · Signal: Good"` (14px `#9AA0C4`).
- **Circular Countdown Timer:**
  - 160x160 circular container, dark disc fill `#070F2B`.
  - Track ring: r=72, stroke `#1B2A66` 4px.
  - Progress ring: r=72, stroke `#4C8DF5` 4px, stroke-linecap round, dasharray 130 452, rotated 90°.
  - Center: Time `"00:09"` (26px, Outfit 300) + Pause icon.
- **Bottom Action Button:** 48px Dark pill button (`#0B1840`, text `#FFFFFF`) labeled `"Stop and save"`.

### 2.3 Heart Rate / Detail Screen (`Detail.dc.html` $\rightarrow$ `Heart Rate.png`)
- **Header:** 56px Back button, Title `"Heart Rate"` (22px), 56px spacer.
- **Optical Pulse Trace:** 350x130 vector wave, stroke 1.3px white.
- **Hero Pulse Rate Row:**
  - Left: Giant `"74"` (96px, Outfit 300) + small `" BPM"` (22px, top-aligned).
  - Right: Range `"58 min  96 max"` (14px `#9AA0C4`).
- **Card 1 (Pulse interval):** Title `"Pulse interval"`, Value `"811 ms"` (24px).
- **Card 2 (Variability est.):** Title `"Variability (est.)"`, Value `"41 ms"` (24px).
  - 48-dot variability matrix (318x120, colors `#C026D3` magenta and `#2563EB` blue, radius 5, opacity 0.85).
  - Timeline labels: `6am`, `9am`, `12pm`, `3pm`, `6pm`, `9pm` (14px `#9AA0C4`).
- **Footer Disclaimer:** `"Sample data · estimated from optical pulse peaks"` (14px `#9AA0C4`).

### 2.4 AI Insights Screen (`Insights.dc.html` $\rightarrow$ `AI Insights.png`)
- **Header:** 56px Back button, Title `"AI Insights"` (22px), 56px spacer.
- **Model Result Card:** Linear gradient `#4A1A8F` to `#0F2160`, radius 22px, padding 16px.
  - Header: `"Model result"` + Tag `"Experimental"`.
  - Title: `"Typical pattern"` (40px, Outfit 300, line-height 1.1).
  - Explanation: `"Similar to your last 5 rest sessions. A pattern label, not a health rating."` (14px `#9AA0C4`).
- **Measured Values Header:** `"Measured values used"` (14px `#9AA0C4`).
- **Feature Cards Grid (flex wrap, gap 10px):**
  - Card 1: `"mean_hr"` $\rightarrow$ `"74 BPM"` (26px)
  - Card 2: `"std_hr"` $\rightarrow$ `"3.1"` (26px)
  - Card 3: `"start_hr"` $\rightarrow$ `"78 BPM"` (26px)
  - Card 4: `"end_hr"` $\rightarrow$ `"70 BPM"` (26px)
  - Card 5: Full width, `"recovery_drop"` $\rightarrow$ `"−8 BPM"` (26px)
- **Footer Text:** `"Runs on this phone · small neural network running locally in the app · 6 sessions available"` (14px `#9AA0C4`).
- **Bottom Navigation:** Circle 3 (Insights) active.

### 2.5 Connect Device Screen (`Device.dc.html` $\rightarrow$ `Connect device.png`)
- **Header:** 56px Back button, Title `"Connect device"` (22px), 56px spacer.
- **Scanning Radar:** 320x250 vector radar with center magenta beacon (r=14 `#C0148F`) and concentric rings (r=45 `#4C8DF5`, r=80 `#3A2A8F` 0.6, r=115 `#3A2A8F` 0.4).
- **Scanning Subtitle:** `"Scanning · keep the patch within 1 m"` (14px `#9AA0C4`, center-aligned).
- **Device List:**
  - Device Card 1: `"PulsePatch-C3"`, `"Signal strong · −52 dBm"`, White pill button `"Connect"`.
  - Device Card 2: `"PulsePatch-C3 (2)"`, `"Signal weak · −85 dBm"`, Dark pill button `"Connect"` (`#0B1840`, text `#FFFFFF`).
- **Footer Disclaimer:** `"Sensor: MAX30102 · Rechargeable battery / USB-C (no battery level reported)"` (14px `#9AA0C4`).
- **Bottom Navigation:** Circle 4 (Device) active.

### 2.6 History Screen (`History.dc.html` $\rightarrow$ `History.png`)
- **Header:** 56px Back button, Title `"History"` (22px), 56px spacer.
- **Filter Row:** White pill button `"Week"`, Dark pill button `"Day"`, Tag `"Sample data"` right-aligned.
- **History List (4 cards, gap 10px):**
  - Card 1: `"Today 18:05"`, `"Quality: Good · Pattern: typical"`, `"74 BPM"` (40px, Outfit 300).
  - Card 2: `"Sun 09:30"`, `"Quality: Good · Pattern: typical"`, `"71 BPM"` (40px, Outfit 300).
  - Card 3: `"Fri 20:12"`, `"Quality: Fair · Pattern: typical"`, `"82 BPM"` (40px, Outfit 300).
  - Card 4: `"Thu 07:45"`, `"Quality: Good · Pattern: typical"`, `"68 BPM"` (40px, Outfit 300).
- **Bottom Navigation:** Circle 2 (History) active.

---

## 3. Derived Screens (21 Screens)

All derived screens strictly inherit these identical tokens:
- Background: `#04030C` with top-left `#1A0F44` and bottom-right `#3A1566` radial glows.
- Fonts: `Outfit` (300 headings, 400 body, 500 buttons).
- Headers: 56px circular back button (`#0B1840`), 22px Outfit 300 title, 56px spacer.
- Cards: `linear-gradient(160deg, #0F2160, #08122E)`, radius `22px`, padding `16px`.
- Buttons: 48px pill buttons (white for primary, `#0B1840` for secondary).
- Chips: 1px border `#3B4270`, radius 8px, text 11px `#9AA0C4`.

Inventory of 21 Derived Screens:
1. `Splash Screen`
2. `Welcome / Onboarding Screen`
3. `How It Works Screen`
4. `Permissions Screen`
5. `User Preferences Screen`
6. `Measurement Preparation Screen`
7. `Session Details Screen`
8. `Historical Trends Screen`
9. `Reports Screen`
10. `Recovery Analysis Screen`
11. `AI Insights Dashboard Screen`
12. `AI Model Information Screen`
13. `Notifications Center Screen`
14. `Reminder Settings Screen`
15. `Profile & Preferences Screen`
16. `Application Settings Screen`
17. `Privacy & Data Management Screen`
18. `About Screen`
19. `Device Troubleshooting Screen`
20. `System State Banner / Overlay`
21. `Global Error Boundary View`
