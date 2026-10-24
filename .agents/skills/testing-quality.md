# Testing & Quality Assurance Playbook

**Role:** QA Engineer  
**Objective:** Comprehensive unit, widget, golden, integration, and accessibility test coverage with zero warnings.

## Commands
```powershell
flutter format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
```

## Testing Layers
1. **Unit Tests:**
   - Pure Dart validity gate and smoothing filter.
   - Session recorder state machine transitions.
   - Drift database in-memory DAO queries and migrations.
   - BLE packet decoding and defensive malformed packet rejection.
2. **Widget & Golden Tests:**
   - Design system component golden tests (`tests/goldens/`).
   - Screen golden tests for all 6 canvas screens + core derived screens.
   - Text scaling (1.0x, 1.3x, 2.0x) verification.
   - RTL layout verification (`Locale('ar')`).
3. **Integration Tests:**
   - Full end-to-end recording flow with `SimulatedHeartRateSource`.
   - SQLite persistence and reload.
   - AI inference execution and display.
