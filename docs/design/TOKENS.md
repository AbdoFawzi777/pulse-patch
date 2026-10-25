# PulsePatch Lite — Design Tokens & Verbatim Source Code Verification

This document establishes the **absolute single source of truth** for design fidelity across all PulsePatch Lite screens, extracted verbatim from the 7 reference design files in `docs/design/source/`.

---

## 1. Global Layout & Foundation Tokens

| Token / Element | Verbatim CSS/HTML Snippet from Source | Source File & Line | Flutter Implementation & Value |
|---|---|---|---|
| **Artboard Logical Dimensions** | `width:390px;height:844px;box-sizing:border-box` | `Main.dc.html:1` | `Size(390.0, 844.0)` |
| **Page Background** | `background:radial-gradient(90% 45% at 100% 100%,#3A1566 0%,transparent 70%),radial-gradient(80% 35% at 0% 0%,#1A0F44 0%,transparent 70%),#04030C;` | `Main.dc.html:1` | `DesignCanvasScaffold` dual `RadialGradient` layers (`#3A1566` at bottom-right, `#1A0F44` at top-left) over base `#04030C` |
| **Page Padding** | `padding:28px 20px 20px;display:flex;flex-direction:column;overflow:hidden` | `Main.dc.html:1` | `EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 20.0)` |
| **Typography Family** | `font-family:Outfit,system-ui,sans-serif;font-weight:300;` | `Main.dc.html:1` | `fontFamily: 'Outfit'` (Bundled local TTF assets: 300 Light, 400 Regular, 500 Medium) |
| **Card Style (`.c`)** | `background:linear-gradient(160deg,#0F2160,#08122E);border-radius:22px;padding:16px` | `Main.dc.html:1` | `Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-0.34, -0.94), end: Alignment(0.34, 0.94), colors: [Color(0xFF0F2160), Color(0xFF08122E)]), borderRadius: BorderRadius.circular(22.0)), padding: EdgeInsets.all(16.0))` |
| **Muted Text (`.m`)** | `color:#9AA0C4;font-size:14px` | `Main.dc.html:1` | `TextStyle(fontFamily: 'Outfit', color: Color(0xFF9AA0C4), fontSize: 14.0, fontWeight: FontWeight.w300)` |
| **Tabular Numbers (`.big`)** | `font-weight:300;line-height:1;font-variant-numeric:tabular-nums` | `Main.dc.html:1` | `TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w300, height: 1.0, fontFeatures: [FontFeature.tabularFigures()])` |
| **56px Circle Button (`.rb`)** | `width:56px;height:56px;border-radius:50%;background:#0B1840;border:0;color:#fff;display:flex;align-items:center;justify-content:center` | `Main.dc.html:1` | `CircleIconButton(size: 56.0, backgroundColor: Color(0xFF0B1840), iconColor: Colors.white)` |
| **48px Pill Button (`.w`)** | `height:48px;border-radius:24px;border:0;background:#fff;color:#0B1840;font:500 16px Outfit,sans-serif;padding:0 24px` | `Main.dc.html:1` | `Container(height: 48.0, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.0)), child: Text('...', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500, fontSize: 16.0, color: Color(0xFF0B1840))))` |
| **48px Dark Pill Button** | `button.w style="background:#0B1840;color:#fff"` | `Live.dc.html:5` | `Container(height: 48.0, decoration: BoxDecoration(color: Color(0xFF0B1840), borderRadius: BorderRadius.circular(24.0)), child: Text('...', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500, fontSize: 16.0, color: Colors.white)))` |
| **Status Tag (`.tg`)** | `font-size:11px;border:1px solid #3B4270;color:#9AA0C4;border-radius:8px;padding:2px 6px` | `Main.dc.html:1` | `Container(decoration: BoxDecoration(border: Border.all(color: Color(0xFF3B4270), width: 1.0), borderRadius: BorderRadius.circular(8.0)), padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0), child: Text('...', style: TextStyle(fontFamily: 'Outfit', fontSize: 11.0, color: Color(0xFF9AA0C4))))` |
| **Bottom Navigation (`.nv`)** | `margin-top:auto;display:flex;justify-content:center;gap:12px` | `Main.dc.html:1` | `Row(mainAxisAlignment: MainAxisAlignment.center, children: [4 circles separated by SizedBox(width: 12.0)])` |
| **Inactive Nav Item** | `width:64px;height:64px;border-radius:50%;background:#0B1840;color:#C9D0F5;display:flex;align-items:center;justify-content:center` | `Main.dc.html:1` | `Container(width: 64.0, height: 64.0, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0B1840)), child: Icon(..., color: Color(0xFFC9D0F5), size: 24.0))` |
| **Active Nav Item (`.on`)** | `background:#fff;color:#0B1840` | `Main.dc.html:1` | `Container(width: 64.0, height: 64.0, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Icon(..., color: Color(0xFF0B1840), size: 24.0))` |

---

## 2. Screen 1: Home (`Main.dc.html`)

| Element | Verbatim Snippet from `Main.dc.html` | Line | Flutter Implementation |
|---|---|---|---|
| **Greeting Title** | `<h1 style="font-size:26px">Hi, there!</h1>` | 2 | `Text('Hi, there!', style: TextStyle(fontFamily: 'Outfit', fontSize: 26.0, fontWeight: FontWeight.w300, color: Colors.white))` |
| **Greeting Subtitle** | `<p style="font-size:26px;color:#6B6F95">How are you today?</p>` | 2 | `Text('How are you today?', style: TextStyle(fontFamily: 'Outfit', fontSize: 26.0, fontWeight: FontWeight.w300, color: Color(0xFF6B6F95)))` |
| **Action Buttons** | `<button class="rb" aria-label="Profile">...</button><button class="rb" aria-label="Notifications">...</button>` | 2 | 2x `CircleIconButton(size: 56.0, backgroundColor: Color(0xFF0B1840))` with Profile and Bell icons |
| **Status Tags** | `<span class="tg">Connected · PulsePatch-C3</span><span class="tg">Sample data</span>` | 3 | Row with 2 `.tg` styled containers, 8px gap |
| **Outer Heart Path** | `<path d="M100 172C14 112 12 48 62 36c24-5 38 19 38 19s14-24 38-19c50 12 48 76-38 136z" fill="url(#a)"/>` | 4 | `CustomPainter` rendering bezier path with linear gradient `[Color(0xB33A2A8F), Color(0x990B2A7A)]` |
| **Inner Heart Path** | `<path transform="translate(40 36) scale(.6)" d="M100 172C14 112 12 48 62 36c24-5 38 19 38 19s14-24 38-19c50 12 48 76-38 136z" fill="url(#b)"/>` | 4 | `CustomPainter` scaled 0.6x translated (40, 36) with 3-stop linear gradient `[Color(0xFFC0148F), Color(0xFF4B1E9E), Color(0xFF1D4ED8)]` |
| **Cards Row Offset** | `style="display:flex;gap:12px;align-items:flex-end;margin-top:-70px"` | 5 | `Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(card1), SizedBox(width: 12), Expanded(card2)])` with top negative transform / stack overlay over heart |
| **Card 1: Last session** | `<span class="m">Last session</span><span class="tg">Saved</span><p class="m" style="margin-top:8px">Mon 18:05 · not live</p><p class="big" style="font-size:44px;margin-top:6px">74 <span class="m">BPM</span></p>` | 5 | Gradient card with `Saved` tag, timestamp, and 44px tabular BPM |
| **Card 2: AI Insights** | `<p class="m">AI Insights</p><p class="big" style="font-size:24px;margin:8px 0 12px;line-height:1.2">Typical pattern</p><button class="w" style="width:100%">Measure</button>` | 5 | Gradient card with pattern label and full-width 48px white `Measure` pill button |
| **Active Nav Index** | `<a href="#" class="on" aria-label="Home">...</a>` | 6 | Item 0 is `.on` (white circle) |

---

## 3. Screen 2: Measuring (`Live.dc.html`)

| Element | Verbatim Snippet from `Live.dc.html` | Line | Flutter Implementation |
|---|---|---|---|
| **Top Bar** | `<button class="rb" aria-label="Back">...</button><h1>Measuring</h1><span style="width:56px"></span>` | 2 | `Row(children: [CircleIconButton(back), Expanded(center: Text('Measuring', 22px)), SizedBox(width: 56)])` |
| **BPM Hero Number** | `<div style="text-align:center;margin-top:20px"><p class="big" style="font-size:96px">74</p><p style="font-size:20px">BPM</p></div>` | 2 | Column with `Text('74', style: TextStyle(fontSize: 96.0, fontWeight: FontWeight.w300))` and `Text('BPM', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300))` |
| **Pulse Trace Path** | `<path fill="none" stroke="#fff" stroke-width="1.300" stroke-linejoin="round" d="M0 90C20 90 25 30 45 30S65 95 85 90 105 24 125 28 145 95 165 90 185 22 205 26 225 96 245 90 265 28 285 30 305 95 325 90 340 50 350 60"/>` | 3 | `CustomPainter` drawing 350x130 SVG path with `Paint()..color = Colors.white..strokeWidth = 1.3..style = PaintingStyle.stroke` |
| **Pulse Trace Caption** | `<p class="m" style="text-align:center">Optical pulse trace · Signal: Good</p>` | 3 | `Text('Optical pulse trace · Signal: Good', style: TextStyle(color: Color(0xFF9AA0C4), fontSize: 14.0))` |
| **Timer Dimensions** | `style="position:relative;width:160px;height:160px"` | 4 | `SizedBox(width: 160.0, height: 160.0)` |
| **Timer Outer Circle** | `<circle cx="80" cy="80" r="76" fill="#070F2B"/>` | 4 | Background filled circle `r = 76`, `Color(0xFF070F2B)` |
| **Timer Track Circle** | `<circle cx="80" cy="80" r="72" fill="none" stroke="#1B2A66" stroke-width="4"/>` | 4 | Track circle `r = 72`, `strokeWidth = 4.0`, `Color(0xFF1B2A66)` |
| **Timer Arc Circle** | `<circle cx="80" cy="80" r="72" fill="none" stroke="#4C8DF5" stroke-width="4" stroke-linecap="round" stroke-dasharray="130 452" transform="rotate(90 80 80)"/>` | 4 | Progress arc `r = 72`, `strokeWidth = 4.0`, `Color(0xFF4C8DF5)`, sweep angle calculated from progress |
| **Timer Center Text & Icon** | `<span style="font-size:26px">00:09</span><svg width="24" height="24" viewBox="0 0 24 24" fill="#fff" aria-label="Pause"...><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>` | 4 | Stack center column: `Text('00:09', 26px)` + pause icon (two 4x14 rects with rx=1 gap 8) |
| **Stop and Save Button** | `<button class="w" style="margin:20px auto 0;background:#0B1840;color:#fff">Stop and save</button>` | 5 | 48px pill button: `backgroundColor = Color(0xFF0B1840)`, `color = Colors.white`, `text = 'Stop and save'` |

---

## 4. Screen 3: Heart Rate Summary (`Detail.dc.html`)

| Element | Verbatim Snippet from `Detail.dc.html` | Line | Flutter Implementation |
|---|---|---|---|
| **Top Bar** | `<button class="rb" aria-label="Back">...</button><h1>Heart Rate</h1><span style="width:56px"></span>` | 2 | `Row(children: [CircleIconButton(back), Expanded(center: Text('Heart Rate', 22px)), SizedBox(width: 56)])` |
| **Optical Trace** | `<svg width="350" height="130" viewBox="0 0 350 130"...><path fill="none" stroke="#fff" stroke-width="1.300".../>` | 2 | Exact identical 350x130 white stroke 1.300 pulse trace |
| **Hero Row** | `<p class="big" style="font-size:96px">74<span style="font-size:22px;vertical-align:top"> BPM</span></p><p class="m">58 min&nbsp;&nbsp;96 max</p>` | 3 | Row: left `Text.rich('74' (96px) + ' BPM' (22px))`, right `Text('58 min  96 max', 14px, #9AA0C4)` |
| **Card 1: Pulse interval** | `<div class="c" style="margin-bottom:8px"><div class="r"><span>Pulse interval</span><span style="font-size:24px">811 <span class="m">ms</span></span></div></div>` | 4 | Gradient card, row: `Pulse interval` + `811 ms` (24px) |
| **Card 2: Variability** | `<div class="c"><div class="r"><span>Variability (est.)</span><span style="font-size:24px">41 <span class="m">ms</span></span></div>` | 5 | Gradient card, row: `Variability (est.)` + `41 ms` (24px) |
| **Dot Chart Specs** | `<svg width="318" height="120" viewBox="0 0 318 120" role="img" aria-label="Sample variability chart by time of day">` | 5 | `SizedBox(width: 318.0, height: 120.0)` |
| **Dot Chart Layout** | 12 columns (x: 12, 38, 64, 90, 116, 142, 168, 194, 220, 246, 272, 298), 4 dots/col, `r="5"`, `opacity=".85"`, colors `#2563EB` & `#C026D3` | 5 | `CustomPainter` rendering exact 48 dots matching source coordinates and colors |
| **Dot Chart Time Labels** | `<div class="r m"><span>6am</span><span>9am</span><span>12pm</span><span>3pm</span><span>6pm</span><span>9pm</span></div>` | 5 | `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ['6am', '9am', '12pm', '3pm', '6pm', '9pm'])` |
| **Footnote** | `<p class="m" style="margin-top:10px">Sample data · estimated from optical pulse peaks</p>` | 6 | `Text('Sample data · estimated from optical pulse peaks', style: TextStyle(color: Color(0xFF9AA0C4), fontSize: 14.0))` |

---

## 5. Screen 4: AI Insights (`Insights.dc.html`)

| Element | Verbatim Snippet from `Insights.dc.html` | Line | Flutter Implementation |
|---|---|---|---|
| **Top Bar** | `<button class="rb" aria-label="Back">...</button><h1>AI Insights</h1><span style="width:56px"></span>` | 2 | Standard header with 56px back button and centered 22px title |
| **Hero Card Gradient** | `background:linear-gradient(160deg,#4A1A8F,#0F2160)` | 2 | Purple-to-navy linear gradient card (`Color(0xFF4A1A8F)` to `Color(0xFF0F2160)`) |
| **Hero Card Content** | `<div class="r"><span class="m">Model result</span><span class="tg">Experimental</span></div><p class="big" style="font-size:40px;margin:14px 0 10px;line-height:1.1">Typical pattern</p><p class="m">Similar to your last 5 rest sessions. A pattern label, not a health rating.</p>` | 2 | Header row with `Experimental` tag, 40px pattern headline, and educational disclaimer subtitle |
| **Section Label** | `<p class="m" style="margin:18px 0 8px">Measured values used</p>` | 3 | `Text('Measured values used', style: TextStyle(color: Color(0xFF9AA0C4), fontSize: 14.0))` |
| **Feature Grid Layout** | `<div style="display:flex;flex-wrap:wrap;gap:10px">` (NO CAROUSEL) | 3 | `Wrap(spacing: 10.0, runSpacing: 10.0, children: [4x half-width cards, 1x full-width card])` |
| **Feature Card 1** | `<div class="c" style="flex:1 1 40%"><p class="m">mean_hr</p><p style="font-size:26px;margin-top:6px">74 BPM</p></div>` | 3 | Half-width card with `mean_hr` and 26px value |
| **Feature Card 2** | `<div class="c" style="flex:1 1 40%"><p class="m">std_hr</p><p style="font-size:26px;margin-top:6px">3.1</p></div>` | 3 | Half-width card with `std_hr` and 26px value |
| **Feature Card 3** | `<div class="c" style="flex:1 1 40%"><p class="m">start_hr</p><p style="font-size:26px;margin-top:6px">78 BPM</p></div>` | 3 | Half-width card with `start_hr` and 26px value |
| **Feature Card 4** | `<div class="c" style="flex:1 1 40%"><p class="m">end_hr</p><p style="font-size:26px;margin-top:6px">70 BPM</p></div>` | 3 | Half-width card with `end_hr` and 26px value |
| **Feature Card 5** | `<div class="c" style="flex:1 1 100%"><div class="r"><span class="m">recovery_drop</span><span style="font-size:26px">−8 BPM</span></div></div>` | 3 | Full-width card with row layout for `recovery_drop` and 26px value |
| **Footnote** | `<p class="m" style="margin-top:14px">Runs on this phone · small neural network running locally in the app · 6 sessions available</p>` | 4 | Text footnote with accurate offline engine string |
| **Active Nav Index** | `<a href="#" class="on" aria-label="Insights">...</a>` | 4 | Item 2 is `.on` (white circle) |

---

## 6. Screen 5: Connect Device (`Device.dc.html`)

| Element | Verbatim Snippet from `Device.dc.html` | Line | Flutter Implementation |
|---|---|---|---|
| **Top Bar** | `<button class="rb" aria-label="Back">...</button><h1>Connect device</h1><span style="width:56px"></span>` | 2 | Standard header with 56px back button and centered 22px title |
| **Scanning Rings SVG** | `<svg width="320" height="250" viewBox="0 0 320 250"...>` | 2 | `SizedBox(width: 320.0, height: 250.0)` |
| **Outer Ring 1** | `<circle cx="160" cy="125" r="115" opacity=".4" stroke="#3A2A8F" fill="none"/>` | 2 | `CustomPainter` circle `r = 115`, `Color(0x663A2A8F)` |
| **Middle Ring 2** | `<circle cx="160" cy="125" r="80" opacity=".6" stroke="#3A2A8F" fill="none"/>` | 2 | `CustomPainter` circle `r = 80`, `Color(0x993A2A8F)` |
| **Inner Ring 3** | `<circle cx="160" cy="125" r="45" stroke="#4C8DF5" fill="none"/>` | 2 | `CustomPainter` circle `r = 45`, `Color(0xFF4C8DF5)` |
| **Center Pulsing Dot** | `<circle cx="160" cy="125" r="14" fill="#C0148F"/>` | 2 | `CustomPainter` filled circle `r = 14`, `Color(0xFFC0148F)` |
| **Subtitle** | `<p class="m" style="text-align:center;margin-bottom:12px">Scanning · keep the patch within 1 m</p>` | 3 | `Text('Scanning · keep the patch within 1 m', style: TextStyle(color: Color(0xFF9AA0C4), fontSize: 14.0))` |
| **Discovered Device 1** | `<p style="font-size:18px">PulsePatch-C3</p><p class="m">Signal strong · −52 dBm</p><button class="w">Connect</button>` | 4 | Gradient card, row with device name/signal and white pill button `Connect` |
| **Discovered Device 2** | `<p style="font-size:18px">PulsePatch-C3 (2)</p><p class="m">Signal weak · −85 dBm</p><button class="w" style="background:#0B1840;color:#fff">Connect</button>` | 5 | Gradient card, row with device name/signal and dark navy pill button `Connect` (`#0B1840`) |
| **Footnote** | `<p class="m" style="margin-top:12px">Sensor: MAX30102 · Battery and firmware shown only if reported</p>` | 6 | Honest compliance footnote |
| **Active Nav Index** | `<a href="#" class="on" aria-label="Device">...</a>` | 6 | Item 3 is `.on` (white circle) |

---

## 7. Screen 6: History (`History.dc.html`)

| Element | Verbatim Snippet from `History.dc.html` | Line | Flutter Implementation |
|---|---|---|---|
| **Top Bar** | `<button class="rb" aria-label="Back">...</button><h1>History</h1><span style="width:56px"></span>` | 2 | Standard header with 56px back button and centered 22px title |
| **Filter Row** | `<div style="display:flex;gap:8px;margin:8px 0 16px"><button class="w">Week</button><button class="w" style="background:#0B1840;color:#fff">Day</button><span class="tg" style="margin-left:auto;align-self:center">Sample data</span></div>` | 2 | Row with white pill `Week`, dark navy pill `Day`, and right-aligned `Sample data` tag |
| **Session Card 1** | `Today 18:05`, `Quality: Good · Pattern: typical`, `74 BPM` (40px) | 2 | Gradient card with session timestamp, quality/pattern subtitle, and large 40px BPM |
| **Session Card 2** | `Sun 09:30`, `Quality: Good · Pattern: typical`, `71 BPM` (40px) | 2 | Gradient card with session timestamp, quality/pattern subtitle, and large 40px BPM |
| **Session Card 3** | `Fri 20:12`, `Quality: Fair · Pattern: typical`, `82 BPM` (40px) | 2 | Gradient card with session timestamp, quality/pattern subtitle, and large 40px BPM |
| **Session Card 4** | `Thu 07:45`, `Quality: Good · Pattern: typical`, `68 BPM` (40px) | 2 | Gradient card with session timestamp, quality/pattern subtitle, and large 40px BPM |
| **Active Nav Index** | `<a href="#" class="on" aria-label="History">...</a>` | 2 | Item 1 is `.on` (white circle) |

---

## 8. Screen 7: App Icon (`Icon.dc.html`)

| Element | Verbatim Snippet from `Icon.dc.html` | Line | Flutter Implementation |
|---|---|---|---|
| **Icon Container** | `width:360px;height:360px;border-radius:22%;overflow:hidden;box-shadow:0 12px 30px rgba(0,0,0,.5)` | 4 | `ClipRRect(borderRadius: BorderRadius.circular(360 * 0.22))` |
| **Background Radial Gradient** | `<radialGradient id="bg" cx=".5" cy=".38" r=".85"><stop offset="0" stop-color="#2A1A7A"/><stop offset=".6" stop-color="#0B0A2A"/><stop offset="1" stop-color="#04030C"/></radialGradient>` | 3 | Radial gradient with center at `(0.5, 0.38)`, stops: 0: `#2A1A7A`, 0.6: `#0B0A2A`, 1.0: `#04030C` |
| **Shadow Heart (Outer)** | `<path transform="translate(50 54) scale(1.4) translate(-50 -54)" d="M50 84C14 58 12 30 31 24c10-3 17 5 19 9 2-4 9-12 19-9 19 6 17 34-19 60z" fill="url(#h2)"/>` | 3 | 1.4x scaled heart path with gradient `[Color(0x807C3AED), Color(0x401D4ED8)]` |
| **Outline Heart (Middle)** | `<path transform="translate(50 54) scale(1.12) translate(-50 -54)" d="M50 84C14 58 12 30 31 24c10-3 17 5 19 9 2-4 9-12 19-9 19 6 17 34-19 60z" fill="none" stroke="#6D5BD0" stroke-width=".8" opacity=".7"/>` | 3 | 1.12x scaled stroke heart path with color `Color(0xB36D5BD0)`, stroke width 0.8 |
| **Main Heart** | `<path d="M50 84C14 58 12 30 31 24c10-3 17 5 19 9 2-4 9-12 19-9 19 6 17 34-19 60z" fill="url(#h1)"/>` | 3 | Main heart path with 3-stop linear gradient `[Color(0xFFE11D9B), Color(0xFF6D28D9), Color(0xFF2563EB)]` |
| **Glow Pulse Line** | `<path d="M16 57H35L41 57L46 41L53 71L59 50L63 57H84" fill="none" stroke="#22D3EE" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" opacity=".28"/>` | 3 | Optical pulse wave path, stroke `#22D3EE` with 0.28 opacity, stroke width 7.0 |
| **Sharp Pulse Line** | `<path d="M16 57H35L41 57L46 41L53 71L59 50L63 57H84" fill="none" stroke="#fff" stroke-width="3.400" stroke-linecap="round" stroke-linejoin="round"/>` | 3 | Sharp white optical pulse wave line, stroke width 3.400, cap round, join round |
