# PulsePatch Lite — Medical & Data Limitations Report

**Version:** 2.0.0-RC  
**Date:** October 30, 2026  
**Document Ownership:** Biomedical Signal Processing & Medical Safety Lead  
**Scope:** Clinical Scope, AI Provenance, Sensor Capabilities, and Regulatory Boundaries  

---

## 1. Regulatory Status & Non-Diagnostic Notice

> **IMPORTANT CLINICAL NOTICE**  
> PulsePatch Lite is an **educational research prototype** and personal health tracking system. It is **NOT** a certified Class II or Class III medical device under the European Medical Device Regulation (EU MDR 2017/745), U.S. FDA 510(k), or Egyptian Drug Authority (EDA) medical device regulations. It is not intended for the clinical diagnosis, treatment, cure, mitigation, or prevention of any medical condition, cardiovascular pathology, or respiratory disorder.

All displayed telemetry, derived indicators, heart rate variability metrics, and artificial intelligence predictions are intended exclusively for wellness tracking, self-monitoring, and academic research demonstration.

---

## 2. Blood Pressure Research Model Provenance & Limitations

### 2.1 Model Architecture & Inference Pipeline
- **Algorithm:** Pure Dart Ridge Regression with L2 Regularization ($\lambda = 1.0$) executed synchronously on-device.
- **Input Features (10 parameters):**
  1. Age (years)
  2. Gender ($1.0$ male, $0.0$ female)
  3. Body Mass Index (BMI, $\text{kg/m}^2$)
  4. Heart Rate (BPM)
  5. Pulse Crest Time ($t_c$, ms)
  6. Pulse Decay Time ($t_d$, ms)
  7. Pulse Width at 50% Amplitude ($\text{PW}_{50}$, ms)
  8. Normalized Pulse Area Ratio ($A_r$)
  9. Reflection Index ($RI$)
  10. Arterial Stiffness Index ($SI$, m/s)

### 2.2 Dataset Provenance & Training Boundaries
- **Training Benchmark:** Standardized PPG-BP (Liang et al.) and clinical benchmark distributions.
- **Reference Standard:** Auscultatory and oscillometric sphygmomanometer readings.
- **Absence of Independent Clinical Validation:**
  * The model has **NOT** undergone formal multi-center prospective clinical trials complying with ANSI/AAMI/ISO 81060-2:2019 or British Hypertension Society (BHS) protocol standards.
  * No claims of AAMI passing compliance ($< 5 \pm 8\text{ mmHg}$) are made for general, uncalibrated populations.
- **Mandatory Individual Cuff Calibration:**
  * Without user-specific calibration offsets derived from an independent, validated upper-arm cuff sphygmomanometer, uncalibrated PPG predictions exhibit population-mean bias.
  * Stored calibrations record both uncalibrated predictions and user cuff inputs to compute explicit linear offsets ($\Delta SBP, \Delta DBP$).

### 2.3 Strict Safety Interlock
- **Emergency Alert Isolation:**
  * Experimental AI model blood-pressure predictions **NEVER** trigger automated clinical emergency warnings or hypertensive crisis alarms.
  * Emergency escalation guidance is strictly restricted to user-entered physical cuff measurements meeting hypertensive crisis thresholds ($SBP \ge 180\text{ mmHg}$ or $DBP \ge 120\text{ mmHg}$).

---

## 3. Pulse Oximetry ($SpO_2$) Calibration & Optical Boundaries

### 3.1 Dual-Wavelength Ratio-of-Ratios Formula
- **Embedded Measurement:** Maxim Integrated MAX30102 optical sensor acquiring both Red ($660\text{ nm}$) and Infrared ($880\text{ nm}$) photoplethysmogram waveforms at $100\text{ Hz}$.
- **Software Calibration Formula:**
  $$\text{Ratio of Ratios } R = \frac{(AC_{\text{Red}} / DC_{\text{Red}})}{(AC_{\text{IR}} / DC_{\text{IR}})}$$
  $$SpO_2 = 110 - 25 \times R$$
- **Physical Reference Calibration Limitation:**
  * While the firmware processes dual-wavelength FIFO buffers and computes $R$, empirical coefficients ($A=110, B=25$) represent standard literature approximations.
  * True clinical pulse oximeter certification requires controlled multi-subject desaturation studies (fractional arterial oxygen saturation $SaO_2$ measured via co-oximetry blood gas analysis between $70\%$ and $100\%$). Such clinical desaturation trials have not been conducted for this prototype.
  * $SpO_2$ readouts below $90\%$ should prompt clinical re-evaluation using an approved medical-grade pulse oximeter.

---

## 4. Anthropometric & Pediatric Safeguards (BMI)

- **Pediatric Restriction (Age < 18):**
  * World Health Organization (WHO) adult BMI cutoff categories (Underweight $< 18.5$, Normal $18.5–24.9$, Overweight $25.0–29.9$, Obesity $\ge 30.0$) are biologically invalid for children and adolescents under 18 years.
  * PulsePatch Lite explicitly suppresses adult BMI category labels for users aged $< 18$, displaying:
    * Under 5 years: `"BMI classification not applicable (under 5)"` (WHO weight-for-height growth reference recommended).
    * 5 to 17 years: `"BMI classification unavailable for under-18"` (requires validated LMS percentile tables not implemented in this version).
- **Adult Scope (Age $\ge$ 18):**
  * Adult WHO 2000 categories are applied strictly to adult profiles.

---

## 5. Signal Quality & Motion Artifact Gating

- **Signal Quality Index (SQI):**
  * A composite metric ($0–100\%$) based on optical waveform pulsatility, peak-to-peak amplitude, and inter-beat continuity.
  * Packets with $SQI < 60\%$ are marked invalid and excluded from statistical baselines and AI inference.
- **Motion Artifacts & Tissue Coupling:**
  * Optical sensors are sensitive to motion artifacts, ambient infrared light leakage, poor peripheral perfusion, and irregular skin contact pressure.
  * Users are instructed to remain seated, motionless, and breathing normally for the entire duration of a recording session.

---

## 6. Egyptian Emergency Escalation Protocol

Whenever a verified physical cuff reading indicates severe hypertensive crisis ($SBP \ge 180$ or $DBP \ge 120\text{ mmHg}$) accompanied by red flag symptoms (acute headache, chest pain, vision changes, dyspnea, or neurological deficits):

- **Local Emergency Contact:** **Call 123** (Egyptian Ambulance Authority / هيئة الإسعاف المصرية).
- **Hospital Escalation:** Seek immediate evaluation at a certified emergency medical department (e.g., National Heart Institute, Kasr Al-Ainy, or regional university hospital emergency rooms).
- **Medical Disclaimer:** The app provides immediate first-line rest guidance (5-minute seated rest before repeat measurement) but strictly directs acute emergencies to emergency medical services.
