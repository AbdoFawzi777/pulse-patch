# PulsePatch Lite — Compliance & Forbidden Wording Audit Scan

**Total Forbidden Word Occurrences Found:** 23
**Total TensorFlow / TFLite References Found:** 3

## 1. Forbidden Wording Matches

| # | Term | File:Line | Context Snippet |
|---|---|---|---|
| 1 | `\bdiagnosis\b` | `FINAL_REPORT.md:28` | `\| **Non-Diagnostic Scope** \| Zero clinical claims / diagnosis \| Strictly educational, non-diagnostic \| Automated token & wording compliance audit \|` |
| 2 | `\bclinical\b` | `FINAL_REPORT.md:28` | `\| **Non-Diagnostic Scope** \| Zero clinical claims / diagnosis \| Strictly educational, non-diagnostic \| Automated token & wording compliance audit \|` |
| 3 | `\bdiagnosis\b` | `app/lib/core/l10n/app_en.arb:54` | `"educationalDisclaimer": "PulsePatch Lite is an educational prototype and does not provide medical diagnosis."` |
| 4 | `\bdiagnosis\b` | `app/lib/core/l10n/app_localizations.dart:326` | `/// **'PulsePatch Lite is an educational prototype and does not provide medical diagnosis.'**` |
| 5 | `\bdiagnosis\b` | `app/lib/core/l10n/app_localizations_en.dart:131` | `'PulsePatch Lite is an educational prototype and does not provide medical diagnosis.';` |
| 6 | `\bdiagnosis\b` | `app/lib/domain/ml/ai_model_metadata.dart:72` | `'PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations.',` |
| 7 | `\bdiagnosis\b` | `app/lib/features/onboarding/welcome_screen.dart:82` | `'PulsePatch Lite is an open-source educational biomonitoring application designed for physiological learning. It is not a medical device and provides no medical diagnosis.',` |
| 8 | `\bdiagnosis\b` | `app/lib/features/reports/pdf_report_generator.dart:135` | `'It does NOT constitute a medical diagnosis or health evaluation.',` |
| 9 | `\bdiagnosis\b` | `app/lib/features/reports/recovery_analysis_screen.dart:373` | `'It does not constitute a cardiovascular fitness diagnosis.',` |
| 10 | `\bdiagnosis\b` | `app/lib/features/settings/about_screen.dart:292` | `'PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations. Never use this software for diagnostic monitoring, treatment decisions, or emergency cardiac detection.',` |
| 11 | `\bNormal\b` | `app/test/ai_insights_test.dart:107` | `expect(state.result?.label.toLowerCase(), isNot(contains('normal')));` |
| 12 | `\bHealthy\b` | `app/test/ai_insights_test.dart:108` | `expect(state.result?.label.toLowerCase(), isNot(contains('healthy')));` |
| 13 | `\bAbnormal\b` | `app/test/ai_insights_test.dart:134` | `expect(state.result?.label.toLowerCase(), isNot(contains('abnormal')));` |
| 14 | `\bUnhealthy\b` | `app/test/ai_insights_test.dart:135` | `expect(state.result?.label.toLowerCase(), isNot(contains('unhealthy')));` |
| 15 | `\bdiagnosis\b` | `app/test/settings_screens_test.dart:239` | `'educational prototype and does not provide medical diagnosis',` |
| 16 | `\bECG\b` | `docs/demo_script.md:21` | `> Second: **Visible Data Truthfulness**. When testing without hardware, the app prominently flags data as 'Simulator' or 'Sample data'. Furthermore, we strictly comply with non-diagnostic boundaries: zero fabricated ECG terminology and zero medical diagnostic claims."` |
| 17 | `\bSinus\b` | `docs/model_card.md:20` | `> PulsePatch Lite does not diagnose, treat, or screen for medical conditions. It does not output diagnostic categories such as "Normal / Abnormal", "Healthy / Unhealthy", or "Sinus Rhythm". The labels are statistical pattern indicators intended solely for educational feedback.` |
| 18 | `\bNormal\b` | `docs/model_card.md:20` | `> PulsePatch Lite does not diagnose, treat, or screen for medical conditions. It does not output diagnostic categories such as "Normal / Abnormal", "Healthy / Unhealthy", or "Sinus Rhythm". The labels are statistical pattern indicators intended solely for educational feedback.` |
| 19 | `\bAbnormal\b` | `docs/model_card.md:20` | `> PulsePatch Lite does not diagnose, treat, or screen for medical conditions. It does not output diagnostic categories such as "Normal / Abnormal", "Healthy / Unhealthy", or "Sinus Rhythm". The labels are statistical pattern indicators intended solely for educational feedback.` |
| 20 | `\bHealthy\b` | `docs/model_card.md:20` | `> PulsePatch Lite does not diagnose, treat, or screen for medical conditions. It does not output diagnostic categories such as "Normal / Abnormal", "Healthy / Unhealthy", or "Sinus Rhythm". The labels are statistical pattern indicators intended solely for educational feedback.` |
| 21 | `\bUnhealthy\b` | `docs/model_card.md:20` | `> PulsePatch Lite does not diagnose, treat, or screen for medical conditions. It does not output diagnostic categories such as "Normal / Abnormal", "Healthy / Unhealthy", or "Sinus Rhythm". The labels are statistical pattern indicators intended solely for educational feedback.` |
| 22 | `\bclinical\b` | `docs/model_card.md:76` | `- **Crucial boundary:** The Mi Smart Band 5 is an educational input source, NOT a clinical gold standard. It is never used to validate MAX30102 sensor accuracy (MAE/Bland-Altman).` |
| 23 | `\bECG\b` | `docs/user_guide.md:7` | `> PulsePatch Lite is an educational research and engineering demonstration platform. It does not provide medical-grade ECG diagnostics, medical screening, or disease detection. Never make medical decisions based on readings from this prototype.` |

## 2. TensorFlow / TFLite References (to replace with 'small neural network running locally in the app')

| # | Term | File:Line | Context Snippet |
|---|---|---|---|
| 1 | `\btflite\b` | `FINAL_REPORT.md:134` | `- Successfully built Android release APK: `app\build\app\outputs\flutter-apk\app-release.apk` (55.8 MB, optimized without native C++ TFLite binaries).` |
| 2 | `\bTFLite\b` | `FINAL_REPORT.md:134` | `- Successfully built Android release APK: `app\build\app\outputs\flutter-apk\app-release.apk` (55.8 MB, optimized without native C++ TFLite binaries).` |
| 3 | `\bTensorFlow\b` | `PROGRESS.md:29` | `- **Python ML Pipeline:** Python 3.14.3 is installed. Official TensorFlow wheels are supported on Python 3.9–3.12 (recommend 3.11). User needs to install Python 3.11 (`py -3.11`). All Flutter/Dart and non-ML phases proceed immediately.` |
