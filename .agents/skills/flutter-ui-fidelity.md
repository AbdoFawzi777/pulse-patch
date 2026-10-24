# Flutter UI Fidelity Playbook

**Role:** Flutter UI Engineer  
**Objective:** Reproduce the design images and design tokens with 100% pixel fidelity and flawless design contract adherence.

## Rules
1. **Source of Truth:** `docs/design/DESIGN_SPEC.md` and `docs/design/*.png`.
2. **Typography:** Standardize on Google Font `Outfit`. All numbers must use tabular figures:
   ```dart
   fontFamily: 'Outfit',
   fontFeatures: const [FontFeature.tabularFigures()],
   fontWeight: FontWeight.w300,
   ```
3. **Colors & Atmosphere:**
   - Background: `#04030C` with top-left glow `#190E41` and bottom-right glow `#381463`.
   - Card background: `#0B1947` (or subtle gradient `#0C1A4A` to `#0B1844`), border: `1px #1E2D60`.
   - AI result card: Gradient `#451A8B` to `#112061`.
   - Card radius: Exactly `22.0 px`.
   - Header action circles: `56.0 px` diameter (`#0F172A`).
   - Bottom navigation circles: `64.0 px` diameter (`#FFFFFF` active with dark icon `#04030C`, `#0D1632` inactive).
   - Circular timer: Diameter `145.0 pt`, center disc `#070F2B`, track `#1B2A66`, active arc `#4C8DF5`.
   - Stop and save pill button: Width `165.0 pt`, height `50.0 pt`, background `#0B1840`.
4. **Localization & RTL:**
   - English (`en`) and Arabic (`ar`).
   - Use AppLocalizations with ARB files.
   - Text direction flips gracefully in RTL mode (`Directionality.of(context)`).
5. **Accessibility:**
   - Minimum 48x48 pt touch target size.
   - Text scaling up to 2.0x without clipping or pixel overflow.
   - High contrast ratios.

## Checklist
- [ ] Theme extension tokens loaded and tested.
- [ ] Golden tests generated and verified for each component.
- [ ] Dark and light theme variants supported.
- [ ] Zero overflow errors on small (360x640) and large screens.
- [ ] No hardcoded strings; all strings via l10n.
