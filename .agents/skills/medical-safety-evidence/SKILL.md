---
name: medical-safety-evidence
description: Medical safety boundaries, clinical threshold provenance, non-diagnostic disclaimers, urgent escalation protocols, uncertainty communication, and regulatory compliance.
---

# Medical Safety and Evidence Review Skill

## 1. Purpose
Ensures that all application outputs, visual indicators, user notifications, health analytics, and PDF reports comply strictly with medical software safety guidelines (FDA SaMD, EU MDR Class I/II boundaries, and educational biomonitoring limits). Prevents misleading diagnostic claims, provides evidence-based rationale, and establishes immediate emergency care escalation paths.

## 2. When to Use
- Reviewing threshold values for heart rate, blood pressure, $SpO_2$, and recovery drops.
- Authoring user-facing educational guidance, risk alerts, and recommendation copy.
- Ensuring clear disclaimers are present on all biometric dashboards and printed reports.
- Designing emergency escalation workflows for critically abnormal readings ($HR > 180$, $HR < 40$, $SpO_2 < 88\%$, $SBP > 180\text{ mmHg}$).

## 3. Required Inputs
- Proposed alert criteria or risk classification rule.
- Authoritative reference source (AHA/ACC, ESC, WHO, CDC, ESH guidelines).
- Target user demographics (Adult vs. Pediatric).

## 4. Expected Outputs
- Formally documented clinical threshold table with explicit citation provenance.
- Clear non-diagnostic educational disclaimers embedded in app views and PDF exports.
- Safe escalation protocols advising urgent professional medical consultation when readings indicate potential distress.

## 5. Practical Workflow
1. **Provenance Check:** Every alert rule must trace back to an authoritative guideline (e.g., AHA 2017 Blood Pressure Categories, WHO Pulse Oximetry Guidelines).
2. **Language Audit:** Remove all diagnostic language ("You have hypertension", "Heart arrhythmia detected"). Replace with objective, non-diagnostic educational observations ("Your resting heart rate is elevated compared to your baseline; consider discussing this trend with your physician").
3. **Red-Flag Escalation:** If critical physiological thresholds are breached, display an urgent safety notice urging immediate in-person medical care or calling emergency services (e.g., 123 in Egypt, 911/112 internationally), avoiding unnecessary app repeat measurements.
4. **Uncertainty Communication:** Explicitly inform the user when low signal quality ($SQI < 60$) or lack of calibration reduces measurement confidence.

## 6. Verification Criteria
- Non-diagnostic disclaimer displayed on Splash, About, Reports, and measurement screens.
- Zero unsupervised medication or treatment change recommendations.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never claim the app replaces a certified ECG monitor or clinical blood pressure cuff.
- **Prohibited:** Never delay urgent medical care while asking the user to complete additional app surveys or measurements.
