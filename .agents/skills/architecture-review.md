# Architecture & System Design Playbook

**Role:** Architect  
**Objective:** Maintain modular, feature-first repository layout, clean separation of concerns, reactive Riverpod state flow, and Drift SQLite data integrity.

## Directory Layout
- `app/`
  - `lib/core/` (tokens, theme, constants, errors, l10n)
  - `lib/data/` (drift database, DAOs, repositories)
  - `lib/domain/` (entities, signal processing, feature calculation)
  - `lib/features/` (onboarding, home, device, measurement, history, insights, reports, settings)
  - `lib/shared/` (reusable visual widgets matching design contract)
- `firmware/` (PlatformIO ESP32-C3 firmware)
- `ml/` (Python training pipeline, models, parity checks)
- `docs/` (technical specs, protocols, model card, user manual)

## Architectural Constraints
- Domain logic must remain 100% pure Dart, independent of Flutter UI framework.
- No direct database access from UI widgets; access strictly via Riverpod repository providers.
- Local SQLite database must be fully testable in-memory without native binaries.
- Safe isolate dispatch for TFLite inference and intensive signal parsing.
