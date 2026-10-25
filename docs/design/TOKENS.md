# PulsePatch Lite — Design Tokens & Exact Canvas Specifications

Extracted directly from the HTML, CSS, and inline SVG source of truth files in `docs/design/source/*.dc.html`:
- `Main.dc.html` $\rightarrow$ **Home**
- `Live.dc.html` $\rightarrow$ **Measuring**
- `Detail.dc.html` $\rightarrow$ **Heart Rate**
- `Insights.dc.html` $\rightarrow$ **AI Insights**
- `Device.dc.html` $\rightarrow$ **Connect device**
- `History.dc.html` $\rightarrow$ **History**
- `Icon.dc.html` $\rightarrow$ **App icon**

---

## 1. Canvas Dimensions & Scaling

- **Reference Artboard Size:** $390 \times 844\text{ logical px}$ (iPhone 12/13/14 baseline).
- **Scale Factor:** $S = \text{screenWidth} / 390.0$.
- **Outer Padding:** `28px 20px 20px` (Top: 28px, Left/Right: 20px, Bottom: 20px).
- **Status Bar / Safe Area:** Transparent status bar with light icons (`SystemUiOverlayStyle.light`).

---

## 2. Color Palette & Gradients

### Backgrounds
- **Base Canvas:** `#04030C`
- **Radial Glow Top-Left:** `radial-gradient(80% 35% at 0% 0%, #1A0F44 0%, transparent 70%)`
- **Radial Glow Bottom-Right:** `radial-gradient(90% 45% at 100% 100%, #3A1566 0%, transparent 70%)`

### Card Backgrounds
- **Standard Card (`.c`):** `linear-gradient(160deg, #0F2160 0%, #08122E 100%)`, radius `22px`, padding `16px`.
- **AI Result Card:** `linear-gradient(160deg, #4A1A8F 0%, #0F2160 100%)`, radius `22px`, padding `16px`.

### Buttons & Interactive Surfaces
- **Circular Button (`.rb`):** $56 \times 56\text{ px}$, circle (`border-radius: 50%`), background `#0B1840`, border none, icon `#FFFFFF` (size 24x24, stroke 1.6).
- **White Pill Button (`.w`):** Height `48px`, `border-radius: 24px`, background `#FFFFFF`, text `#0B1840`, font Outfit 500 16px, padding `0 24px`.
- **Dark Pill Button (`.w` dark):** Height `48px`, `border-radius: 24px`, background `#0B1840`, text `#FFFFFF`, font Outfit 500 16px.

### Bottom Navigation Bar (`.nv`)
- **Container:** `gap: 12px`, centered horizontally, `margin-top: auto`.
- **Nav Circle Item:** $64 \times 64\text{ px}$, circle (`border-radius: 50%`).
  - **Inactive:** background `#0B1840`, icon `#C9D0F5` (stroke 1.6, 24x24).
  - **Active (`.on`):** background `#FFFFFF`, icon `#0B1840` (stroke 1.6, 24x24).

### Status Tags & Chips (`.tg`)
- **Border:** `1px solid #3B4270`
- **Background:** transparent / subtle dark tint
- **Radius:** `8px`
- **Padding:** `2px 6px`
- **Text:** `11px`, Outfit 300, color `#9AA0C4`

### Text Colors
- **Primary Text:** `#FFFFFF`
- **Muted Label (`.m`):** `#9AA0C4` (14px)
- **Secondary Subtitle:** `#6B6F95` (26px)
- **Active Navigation Icon:** `#0B1840`
- **Inactive Navigation Icon:** `#C9D0F5`

### Signal & Graphic Accents
- **Cyan / Waveform Accent:** `#4C8DF5` / `#22D3EE` / `#FFFFFF`
- **Neon Magenta / Beacon:** `#C0148F` / `#C026D3` / `#E11D9B`
- **Blue Variability Accent:** `#2563EB`
- **Violet Glow:** `#3A2A8F` / `#4B1E9E` / `#6D28D9`

---

## 3. Typography Hierarchy (Outfit Local Bundle)

All text uses bundled local assets:
- `Outfit-Light.ttf` $\rightarrow$ Weight `300` (Default for body, headings, hero numerals)
- `Outfit-Regular.ttf` $\rightarrow$ Weight `400`
- `Outfit-Medium.ttf` $\rightarrow$ Weight `500` (Pill buttons, active emphasis)

| Style | Font Size | Weight | Line Height | Features / Notes |
|---|---|---|---|---|
| **Giant Hero BPM** | `96px` | 300 | 1.0 | `FontFeature.tabularFigures()`, color `#FFFFFF` |
| **Card Hero Number** | `44px` / `40px` | 300 | 1.0 | `FontFeature.tabularFigures()`, color `#FFFFFF` |
| **Greeting Title** | `26px` | 300 | 1.0 | Color `#FFFFFF` |
| **Greeting Subtitle** | `26px` | 300 | 1.0 | Color `#6B6F95` |
| **Top App Bar Title** | `22px` | 300 | 1.0 | Center-aligned or spaced, color `#FFFFFF` |
| **Card Metric Header**| `24px` / `26px` | 300 | 1.0 | Color `#FFFFFF` |
| **Section Header** | `18px` | 300 | 1.0 | Color `#FFFFFF` |
| **Pill Button Text** | `16px` | 500 | 1.0 | Outfit 500 |
| **Muted Body / Label**| `14px` | 300 | 1.3 | Color `#9AA0C4` |
| **Tag Chip Text** | `11px` | 300 | 1.0 | Color `#9AA0C4` |

---

## 4. SVG Vector Elements & Exact Coordinates

### A. Home Heart Illustration (`Main.dc.html`)
- **Dimensions:** $330 \times 300\text{ px}$, viewBox `0 0 200 180`.
- **Outer Heart Path:**
  `M100 172C14 112 12 48 62 36c24-5 38 19 38 19s14-24 38-19c50 12 48 76-38 136z`
  Fill: `linearGradient (0,0) -> (0,1)`: `#3A2A8F` (opacity 0.7) to `#0B2A7A` (opacity 0.6).
- **Inner Heart Path:**
  Transform: `translate(40, 36) scale(0.6)`
  `M100 172C14 112 12 48 62 36c24-5 38 19 38 19s14-24 38-19c50 12 48 76-38 136z`
  Fill: `linearGradient (0,0) -> (0,1)`: `#C0148F` (0%) $\rightarrow$ `#4B1E9E` (50%) $\rightarrow$ `#1D4ED8` (100%).
- **Card Overlap:** `margin-top: -70px` for the card row below it.

### B. Optical Pulse Trace (`Live.dc.html`, `Detail.dc.html`)
- **Dimensions:** $350 \times 130\text{ px}$, viewBox `0 0 350 130`.
- **Path:**
  `M0 90C20 90 25 30 45 30S65 95 85 90 105 24 125 28 145 95 165 90 185 22 205 26 225 96 245 90 265 28 285 30 305 95 325 90 340 50 350 60`
- **Stroke:** `#FFFFFF`, `stroke-width: 1.3`, `stroke-linejoin: round`.

### C. Circular Timer Arc (`Live.dc.html`)
- **Dimensions:** $160 \times 160\text{ px}$, viewBox `0 0 160 160`.
- **Background Disc:** `cx=80, cy=80, r=76`, fill `#070F2B`.
- **Track Ring:** `cx=80, cy=80, r=72`, stroke `#1B2A66`, stroke-width `4`.
- **Progress Ring:** `cx=80, cy=80, r=72`, stroke `#4C8DF5`, stroke-width `4`, stroke-linecap `round`, `stroke-dasharray="130 452"`, `transform="rotate(90 80 80)"`.
- **Center Content:** Time `00:09` (Outfit 300 26px) + Pause icon (two white rounded bars $4 \times 14\text{ px}$ with rx 1).

### D. Dot Variability Chart (`Detail.dc.html`)
- **Dimensions:** $318 \times 120\text{ px}$, viewBox `0 0 318 120`.
- **Grid:** 12 columns at $x \in [12, 38, 64, 90, 116, 142, 168, 194, 220, 246, 272, 298]$, 4 dots per column at $r=5$, opacity 0.85.
- **Colors:** `#C026D3` (magenta) and `#2563EB` (blue).
- **Time Labels:** `6am`, `9am`, `12pm`, `3pm`, `6pm`, `9pm` in `#9AA0C4` 14px.

### E. Scanning Radar (`Device.dc.html`)
- **Dimensions:** $320 \times 250\text{ px}$, viewBox `0 0 320 250`.
- **Center Beacon:** `cx=160, cy=125, r=14`, fill `#C0148F`.
- **Inner Ring:** `r=45`, stroke `#4C8DF5`.
- **Middle Ring:** `r=80`, stroke `#3A2A8F`, opacity `0.6`.
- **Outer Ring:** `r=115`, stroke `#3A2A8F`, opacity `0.4`.
