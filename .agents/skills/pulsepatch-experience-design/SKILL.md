---
name: pulsepatch-experience-design
description: Design system tokens, bilingual typography (EN/AR), emotional micro-interactions, responsive multi-resolution layouts, and accessibility standards for PulsePatch Next Generation.
---

# PulsePatch Next Generation — Experience Design & Design System

## 1. Visual Identity & Design Tokens

### Color Palette
- **Canvas / Background**: Midnight Navy `#04030C` (primary surface background)
- **Cards & Elevated Containers**: Deep Indigo `#0B1840` (base surface), `#0F2160` (highlight/stroke surface)
- **Primary Accent / Biometric Action**: Electric Cyan `#22D3EE` (active states, primary buttons, pulse wave)
- **Clinical Vital Status**:
  - Normal / Optimal: Status Green `#10B981` (high SQI, normal HR, normotensive)
  - Warning / Elevated: Warm Amber `#F59E0B` (moderate SQI, pre-hypertension, elevated HR)
  - Critical / Crisis: Urgent Coral / Crimson `#EF4444` (crisis BP >=180/120 mmHg, low SQI, emergency)
- **Neutral Typography**:
  - High Emphasis: Pure White `#FFFFFF`
  - Medium Emphasis: Muted Slate `#94A3B8`
  - Subtle Borders & Dividers: Dark Indigo Border `rgba(34, 211, 238, 0.15)` or `rgba(255, 255, 255, 0.1)`

## 2. Bilingual Typography (English & Arabic)
- **English**: Modern sans-serif with geometric precision (`Outfit`).
- **Arabic**: Legible, harmonious Noto Sans Arabic / Cairo shaping.
- Line heights must accommodate Arabic diacritics and ascenders/descenders (+15% leading compared to Latin).
- Use `Directionality` and `Bidi` awareness: layout mirrors in RTL mode while technical acronyms (HR, SpO2, mmHg, BPM) preserve LTR order.

## 3. Responsive Multi-Resolution Support
- Target screens:
  - Compact (360x800, e.g., standard Android phones)
  - Medium (390x844, e.g., iPhone 14/15, Pixel 7)
  - Large (411x891, e.g., Pixel 7 Pro, Galaxy S23 Ultra)
- Must scale up to `textScaleFactor = 1.3x` without `RenderFlex` overflows.
- Mandatory use of `Flexible`, `Expanded`, `SingleChildScrollView`, and text overflow ellipsis on row headers.

## 4. Emotional Micro-Interactions & Haptics
- **Heart Pulse Animation**: Real-time heartbeat expansion with physiological double-peak easing curve. Test guard enabled (`isTesting` prevents infinite loop in unit tests).
- **PPG Waveform Visualizer**: 25 Hz sampled rolling buffer, `RepaintBoundary` for zero jank (60 FPS), clear "MAX30102 PPG · 25 Hz" badge.
- **Haptic Feedback**: Subtle vibration on vital threshold changes and recording start/stop.
