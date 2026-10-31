---
name: pulsepatch-medical-data-governance
description: Medical safety boundaries, hypertensive crisis escalation protocols, Egyptian emergency 123 integration, non-diagnostic disclaimers, and health data privacy.
---

# PulsePatch Next Generation — Medical Data Governance & Safety

## 1. Clinical Boundaries & Disclaimers
- PulsePatch is strictly an educational biometric monitoring tool and research platform.
- It is NOT an FDA/CE-cleared diagnostic medical device.
- Mandatory non-diagnostic disclaimer must appear on:
  - Application startup / onboarding
  - Live measurement screen footer
  - Medical AI assistant responses
  - Exported PDF clinical reports

## 2. Emergency Escalation Protocol
- **Hypertensive Crisis Alert Trigger**:
  - Systolic BP >= 180 mmHg OR Diastolic BP >= 120 mmHg (ESC/ISH 2023 Guidelines).
  - Tachycardia at rest: HR > 130 bpm; Severe Bradycardia: HR < 40 bpm.
  - Severe Hypoxia: SpO2 < 90%.
- **Emergency Action**:
  - Displays high-priority crimson alert banner.
  - Egypt Emergency Hotline: `123` (Ambulance).
  - Prominently displays: "Seek immediate medical attention. If you experience chest pain, breathlessness, or speech difficulty, call 123 immediately."

## 3. Data Privacy & Compliance
- Local-first architecture: No health data leaves the device unless the user explicitly enables Cloud Sync or exports a report.
- Anonymized telemetry: Session exports strip personally identifiable names unless explicitly printed on clinical PDF by the user.
- User right to erasure: Single-tap database clear in Profile Settings completely purges local SQLite records.
