# PulsePatch Lite — Compliance & Forbidden Wording Audit Scan

**Total Forbidden Word Occurrences Found:** 37
**Total TensorFlow / TFLite References Found:** 3

## 1. Forbidden Wording Matches

| # | Term | File:Line | Context Snippet |
|---|---|---|---|
| 1 | `\bdiagnosis\b` | `FINAL_REPORT.md:28` | `\| **Non-Diagnostic Scope** \| Zero clinical claims / diagnosis \| Strictly educational, non-diagnostic \| Automated token & wording compliance audit \|` |
| 2 | `\bclinical\b` | `FINAL_REPORT.md:28` | `\| **Non-Diagnostic Scope** \| Zero clinical claims / diagnosis \| Strictly educational, non-diagnostic \| Automated token & wording compliance audit \|` |
| 3 | `\bdiagnosis\b` | `app/lib/core/l10n/app_en.arb:54` | `"educationalDisclaimer": "PulsePatch Lite is an educational prototype and does not provide medical diagnosis."` |
| 4 | `\bdiagnosis\b` | `app/lib/core/l10n/app_localizations.dart:326` | `/// **'PulsePatch Lite is an educational prototype and does not provide medical diagnosis.'**` |
| 5 | `\bdiagnosis\b` | `app/lib/core/l10n/app_localizations_en.dart:131` | `'PulsePatch Lite is an educational prototype and does not provide medical diagnosis.';` |
| 6 | `\bdiagnosis\b` | `app/lib/domain/ml/ai_model_metadata.dart:70` | `'PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations.',` |
| 7 | `\bdiagnosis\b` | `app/lib/features/reports/pdf_report_generator.dart:135` | `'It does NOT constitute a medical diagnosis or health evaluation.',` |
| 8 | `\bdiagnosis\b` | `app/lib/features/reports/recovery_analysis_screen.dart:416` | `'It does not constitute a cardiovascular fitness diagnosis.',` |
| 9 | `\bdiagnosis\b` | `app/lib/features/settings/about_screen.dart:315` | `'PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations. Never use this software for diagnostic monitoring, treatment decisions, or emergency cardiac detection.',` |
| 10 | `\bNormal\b` | `app/lib/shared/widgets/pulse_trace_chart.dart:83` | `..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);` |
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
| 22 | `\bECG\b` | `docs/user_guide.md:7` | `> PulsePatch Lite is an educational research and engineering demonstration platform. It does not provide medical-grade ECG diagnostics, medical screening, or disease detection. Never make medical decisions based on readings from this prototype.` |
| 23 | `\bECG\b` | `docs/design/DESIGN_SPEC.md:19` | `- **Truthful Waveforms:** Optical pulse traces represented as smooth, continuous flowing waves. Never ECG spikes, never fabricated waveforms, and never diagnostic labels (no "Sinus Rhythm", "Normal/Abnormal", or ECG claims).` |
| 24 | `\bSinus\b` | `docs/design/DESIGN_SPEC.md:19` | `- **Truthful Waveforms:** Optical pulse traces represented as smooth, continuous flowing waves. Never ECG spikes, never fabricated waveforms, and never diagnostic labels (no "Sinus Rhythm", "Normal/Abnormal", or ECG claims).` |
| 25 | `\bNormal\b` | `docs/design/DESIGN_SPEC.md:19` | `- **Truthful Waveforms:** Optical pulse traces represented as smooth, continuous flowing waves. Never ECG spikes, never fabricated waveforms, and never diagnostic labels (no "Sinus Rhythm", "Normal/Abnormal", or ECG claims).` |
| 26 | `\bAbnormal\b` | `docs/design/DESIGN_SPEC.md:19` | `- **Truthful Waveforms:** Optical pulse traces represented as smooth, continuous flowing waves. Never ECG spikes, never fabricated waveforms, and never diagnostic labels (no "Sinus Rhythm", "Normal/Abnormal", or ECG claims).` |
| 27 | `\bECG\b` | `docs/design/DESIGN_SPEC.md:155` | `- 1024x1024 master squircle, layered heart with magenta-to-purple gradient, smooth white optical pulse line with cyan glow border. Non-ECG single smooth wave. Palette tokens: `#04030C`, `#6D28D9`, `#E11D9B`, `#2563EB`, `#22D3EE`.` |
| 28 | `\bECG\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 29 | `\bEKG\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 30 | `\bSinus\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 31 | `\bNormal\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 32 | `\bAbnormal\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 33 | `\bHealthy\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 34 | `\bUnhealthy\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 35 | `\bdiagnosis\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 36 | `\barrhythmia\b` | `docs/design/DESIGN_SPEC.md:191` | `- Never write: `ECG`, `EKG`, `Sinus Rhythm`, `Arrhythmia`, `Normal/Abnormal heart health`, `Diagnosis`, `Healthy/Unhealthy`.` |
| 37 | `\bdiagnosis\b` | `docs/design/DESIGN_SPEC.md:197` | `- Every report and AI screen includes the explicit disclaimer: *"PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations."*` |

## 2. TensorFlow / TFLite References (to replace with 'small neural network running locally in the app')

| # | Term | File:Line | Context Snippet |
|---|---|---|---|
| 1 | `\btflite\b` | `FINAL_REPORT.md:45` | `\| **On-Device Model Execution** \| **Verified** \| 233 floating-point weights executed in a background Dart isolate (`Isolate.run()`) in $<0.15$ ms \| Small neural network running locally in the app (pure Dart isolate, no native TFLite dependency) \|` |
| 2 | `\bTFLite\b` | `FINAL_REPORT.md:45` | `\| **On-Device Model Execution** \| **Verified** \| 233 floating-point weights executed in a background Dart isolate (`Isolate.run()`) in $<0.15$ ms \| Small neural network running locally in the app (pure Dart isolate, no native TFLite dependency) \|` |
| 3 | `\bTensorFlow\b` | `PROGRESS.md:28` | `- **Python ML Pipeline:** Python 3.14.3 is installed. Official TensorFlow wheels are supported on Python 3.9–3.12 (recommend 3.11). User needs to install Python 3.11 (`py -3.11`). All Flutter/Dart and non-ML phases proceed immediately.` |
