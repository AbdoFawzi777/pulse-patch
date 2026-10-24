# Documentation & Release Playbook

**Role:** Documentation Engineer  
**Objective:** Maintain complete project documentation, reproducible user guides, graduation presentation materials, and release build artifacts.

## Documentation Index
- `docs/ble_protocol.md`: ESP32-C3 GATT specification and packet layouts.
- `docs/feature_definitions.md`: Exact mathematical definitions of feature vectors.
- `docs/model_card.md`: Full transparency documentation of the deployed TFLite model.
- `docs/user_guide.md`: End-user manual for device pairing and telemetry recording.
- `docs/demo_script.md`: 5-minute timed demonstration script for project defense.
- `FINAL_REPORT.md`: Comprehensive graduation project sign-off and retrospective.

## Release Verification
- Android Release APK built with `--release`.
- Launcher icon applied via `flutter_launcher_icons`.
- Zero analyzer warnings.
- All golden tests passing.
