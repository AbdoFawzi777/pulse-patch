---
name: qa-security-release
description: Comprehensive automated testing, unit and widget test coverage, multi-resolution regression, database migration integrity, cryptographic security, Android APK builds, and release gating.
---

# QA, Security, and Release Engineering Skill

## 1. Purpose
Governs end-to-end quality assurance, automated test suite maintenance, database migration verification, static analysis enforcement, sensitive biometric data security, and release artifact packaging for production Android deployment.

## 2. When to Use
- Writing and executing unit, widget, and cross-platform structural parity tests.
- Testing SQLite database migrations ($v1 \rightarrow v2 \rightarrow v3$) against existing user databases to prevent data loss.
- Verifying code quality with `flutter analyze` and enforcing zero lint errors.
- Building, signing, measuring binary size, and computing SHA-256 checksums for release APK packages.

## 3. Required Inputs
- Target Flutter application and test suites in `app/test/`.
- PlatformIO firmware environments in `firmware/platformio.ini`.
- Target release architecture (Android 8.0+, API 26–35).

## 4. Expected Outputs
- 100% passing test execution report across all test files.
- Verified database migration integrity proof.
- Production `app-release.apk` with verified size ($< 70\text{ MB}$) and SHA-256 hash.
- Updated release notes and version tag.

## 5. Practical Workflow
1. **Automated Test Run:** Execute `flutter test --reporter compact` across all domain, data, presentation, and regression suites.
2. **Static Analysis Gate:** Execute `flutter analyze`; reject any commit with warnings or errors.
3. **Multi-Resolution Layout Regression:** Execute `overflow_screen_test.dart` across device viewports ($360\times 800$, $390\times 844$, $411\times 891$) and font scale factors ($1.0\times$ and $1.3\times$).
4. **Data Security Audit:** Verify that no health telemetry is written to unencrypted shared storage, external logs, or remote analytics.
5. **Release Build:** Execute `flutter build apk --release`, calculate binary hash, and record release metrics.

## 6. Verification Criteria
- 100% test pass rate (zero skipped or failing tests).
- Clean APK build installable on target hardware without runtime crashes.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never bypass failing tests by commenting them out or reducing assertions.
- **Prohibited:** Never hardcode credentials, private tokens, or encryption keys in source files.
