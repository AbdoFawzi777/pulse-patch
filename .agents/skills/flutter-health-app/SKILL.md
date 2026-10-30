---
name: flutter-health-app
description: Flutter application architecture, Clean Architecture layers, Riverpod state management, Drift SQLite C-FFI persistence, responsive multi-resolution UI, and BLE lifecycle management.
---

# Flutter Health Application Engineering Skill

## 1. Purpose
Guides the architectural design, implementation, state management, and user interface development for the PulsePatch Lite mobile client using Flutter and Dart. Ensures rock-solid reliability, responsive design across device resolutions, zero layout overflows, and seamless local SQLite persistence.

## 2. When to Use
- Implementing or modifying UI screens, widgets, navigation routes (GoRouter), or localization (Arabic/English).
- Managing FlutterRiverpod providers for BLE connection, live measurement state machines, and patient profiles.
- Writing Drift ORM tables, queries, and automated database migrations.
- Ensuring zero static analysis warnings and complete automated test coverage.

## 3. Required Inputs
- Figma / Canvas design tokens (colors, typography, spacing, border radiuses).
- State requirements: Disconnected, Scanning, Connecting, Live Streaming, Saving, Error.
- Database schema and repository interfaces.

## 4. Expected Outputs
- Fully responsive Flutter widgets passing multi-resolution overflow tests ($360\times 800$, $390\times 844$, $411\times 891$ at $1.0\times$ and $1.3\times$ text scaling).
- State notifiers with clean separation between UI and business logic.
- Automated widget and integration tests.
- Clean `flutter analyze` with 0 issues.

## 5. Practical Workflow
1. **Layer Separation:** Maintain Domain (Entities, Use Cases) $\rightarrow$ Data (Drift, Repositories) $\rightarrow$ Presentation (Screens, Providers).
2. **Defensive Layout:** Use `FittedBox`, `SingleChildScrollView`, and `Wrap` on critical measurement readouts to prevent pixel overflow on high text scale factors.
3. **Database Transactions:** Perform all multi-row session and sample insertions inside atomic transactions (`db.execute('BEGIN TRANSACTION;')`).
4. **State Machine Management:** Ensure timers pause when BLE packets indicate contact loss or when signal quality drops below threshold.

## 6. Verification Criteria
- `flutter analyze` returns 0 issues.
- `flutter test` passes 100% of tests.
- `overflow_screen_test.dart` passes all permutations without layout exceptions.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never execute heavy signal processing or mathematical model loops on the main Flutter UI thread; always dispatch to background isolates.
- **Prohibited:** Never hardcode English strings in widget trees; use `AppLocalizations` for bilingual support.
