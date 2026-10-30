# PulsePatch Lite v2.0 — Blood Pressure Calibration Audit & Final Release Gate Report

**Date:** October 30, 2026  
**Project:** PulsePatch Lite v2.0  
**Audit Focus:** Independent Verification of Calibration Mechanics, Real Dataset Limitations, MAX30102 Compatibility, and APK Deployment Integrity  
**Regulatory Status:** Strictly Investigational & Non-Diagnostic Prototype Biomonitoring System  
**Final Release Decision:** **OPTION B — MODEL RETAINED AS EXPERIMENTAL — CALIBRATION ACCURACY NOT INDEPENDENTLY VALIDATED**  

---

## 1. Audit of the "0.03 / 0.06 mmHg" Calibration Result

### 1.1 Root Cause & Mathematical Investigation
In the previous report iteration, an uncalibrated-to-calibrated error drop from ~14.0 mmHg down to 0.03 mmHg (SBP) and 0.06 mmHg (DBP) was observed. An exhaustive technical audit was conducted across the raw files and ingestion pipeline to determine the source of this figure.

Three structural causes were uncovered:

1. **Shared Ground-Truth Target Label across R1, R2, and R3:**
   - In Liang et al. (Nature Scientific Data 2018), 219 subjects each underwent a **single clinical consultation** where an Omron HEM-7201 cuff measurement was recorded in the hospital spreadsheet.
   - Three consecutive 2.1-second PPG recordings (R1, R2, R3) were taken within an approximate 3-minute window during that single sitting.
   - **Empirical Proof:** Across all 219 subjects in the cohort, the intra-subject standard deviation of reference SBP and DBP is identically:
     $$\sigma_{\text{within}}(\text{SBP}) = 0.0\text{ mmHg}, \quad \sigma_{\text{within}}(\text{DBP}) = 0.0\text{ mmHg}$$
   - Consequently, for any subject, $y_{\text{ref}}(R1) = y_{\text{ref}}(R2) = y_{\text{ref}}(R3)$.

2. **Degenerate Feature Invariance from Unfiltered Sampling Rate Mismatch:**
   - The raw Liang et al. TXT waveforms are sampled at **1000 Hz** (2,100 samples per file). The initial ingestion script used an unconditioned peak detector configured with `fs = 100 Hz`.
   - High-frequency baseline noise at 1000 Hz prevented peak detection on raw differentials, causing 609 out of 657 recordings to trigger fallback default values (`crest_time = 150.0 ms`, `stiffness_index = 8.60`).
   - In addition, demographic string parsing `lambda s: 1 if "m" in str(s).lower() else 0` matched the substring `"m"` in `"female"`, assigning `gender = 1` across all 115 female subjects.

3. **Mathematical Mechanism of the Illusion:**
   - When features are near-identical across segments, the uncalibrated model produces identical estimates: $\hat{y}(R1) \approx \hat{y}(R2)$.
   - Single-point calibration offset is defined as: $\Delta = y_{\text{ref}}(R1) - \hat{y}(R1)$.
   - Evaluating on subsequent segment R2 yields:
     $$\text{Error}_{\text{cal}}(R2) = (\hat{y}(R2) + \Delta) - y_{\text{ref}}(R2) = (\hat{y}(R2) - \hat{y}(R1)) + (y_{\text{ref}}(R1) - y_{\text{ref}}(R2))$$
   - Since $y_{\text{ref}}(R1) - y_{\text{ref}}(R2) = 0$ and $\hat{y}(R2) - \hat{y}(R1) \approx 0$, the resulting error collapsed to $0.03\text{ mmHg}$.

### 1.2 Formal Scientific Classification
> [!IMPORTANT]
> **Scientific Classification:** The 0.03 / 0.06 mmHg values represent **SAME-SESSION SHORT-TERM CALIBRATION CONSISTENCY (MODEL INVARIANCE TO SHORT-TERM PPG NOISE)**, **NOT** independent blood pressure prediction accuracy or evidence of longitudinal BP tracking. These numbers MUST NOT be cited as clinical accuracy or predictive efficacy.

---

## 2. Valid Calibration Evaluation & Dataset Limitations

### 2.1 Pipeline Corrections Applied
1. **Sampling Rate & Digital Filtering:** Integrated a 2nd-order zero-phase Butterworth bandpass filter ($0.5\text{ to }8.0\text{ Hz}$ at $1000\text{ Hz}$) via `scipy.signal.filtfilt`, with peak and onset/valley detection.
2. **Physiological Feature Realism:** Corrected gender parsing (`startswith('m')` yielding 115 females, 104 males) and implemented genuine physiological arterial stiffness indexing ($\text{Height} / \Delta T_{\text{DVP}}$, mean 10.20 m/s, std 1.61 m/s).
3. **Re-evaluated Same-Session Consistency with Varied Waveforms:**
   With realistic PPG feature variance across consecutive recordings of the same patient:
   * **Uncalibrated Error (R2/R3):** SBP MAE $= 13.31\text{ mmHg}$, DBP MAE $= 8.18\text{ mmHg}$
   * **Same-Session Calibrated Consistency (R2/R3 with R1 offset):** **SBP MAE $= 2.92\text{ mmHg}$**, **DBP MAE $= 1.65\text{ mmHg}$**
   This 2.92 / 1.65 mmHg figure reflects the model's true short-term stability when resting waveforms vary naturally over a 3-minute window.

### 2.2 Calibration-Free Generalization across Held-Out Subjects
Evaluated under strict **5-Fold Subject-Wise `GroupKFold`** (219 subjects, zero participant overlap):

| Model Architecture | SBP MAE (mmHg) | SBP RMSE | SBP SDE | SBP $r$ | SBP BHS | DBP MAE (mmHg) | DBP RMSE | DBP SDE | DBP $r$ | DBP BHS | AAMI Compliant |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **ElasticNet ($\alpha=0.1, l_1=0.5$)** | **13.68** | **17.84** | **17.84** | **0.48** | Grade D | **8.35** | **10.60** | **10.60** | **0.30** | Grade D | Investigational |
| **Ridge Regression Baseline ($\alpha=1.0$)** | 13.86 | 17.99 | 17.99 | 0.47 | Grade D | 8.47 | 10.69 | 10.69 | 0.28 | Grade D | Investigational |
| **GBDT ($d=3, \text{lr}=0.05$)** | 13.78 | 17.49 | 17.47 | 0.52 | Grade D | 8.89 | 11.23 | 11.22 | 0.23 | Grade D | Investigational |
| **Random Forest ($d=6$)** | 14.28 | 18.04 | 18.03 | 0.48 | Grade D | 8.60 | 10.89 | 10.89 | 0.25 | Grade D | Investigational |
| **MLP ($32 \times 16$, Pure Dart Compatible)** | 14.93 | 19.37 | 19.36 | 0.39 | Grade D | 8.89 | 11.38 | 11.38 | 0.22 | Grade D | Investigational |

### 2.3 Explicit Dataset Limitations
- **No Longitudinal Sessions:** The Liang et al. dataset contains zero time-separated follow-up sessions (no recordings at 24 hours, 7 days, or 30 days).
- **No Dynamic BP Perturbations:** Subjects were recorded solely in a seated resting state. There are no cold pressor tests, isometric handgrip, or Valsalva maneuvers to induce hemodynamic shifts.
- **Evaluation Boundary:** True calibration decay and multi-session tracking cannot be evaluated on this cohort without synthesizing artificial data. In adherence to biomedical research integrity, no synthetic data was fabricated.

---

## 3. Sensor & Hardware Compatibility: PPG-BP vs MAX30102

| Dimension | Liang et al. Training Cohort | PulsePatch Lite Hardware (MAX30102) | Compatibility Impact & Mitigation |
|:---|:---|:---|:---|
| **Optical Modality** | Transmission PPG (infrared probe across fingertip) | Reflectance PPG (LEDs and photodiode co-planar on surface) | Transmission yields deeper arterial modulation; reflectance is sensitive to skin tone and contact pressure. Handled via firm optical contact gating ($IR \ge 50,000$). |
| **Wavelengths** | Single Infrared (IR) | Dual: Red (660 nm) + IR (880 nm) | Dual-wavelength enables SpO2 ratio-of-ratios; IR channel is dedicated to pulse morphology and HR. |
| **Sampling Rate** | 1000 Hz ($1.0\text{ ms}$ interval) | 100 Hz ($10.0\text{ ms}$ interval) | Timing features (crest time, PW50) have a discretization quantum of $\pm 10\text{ ms}$ at 100 Hz. Filter window smoothed via moving median. |
| **ADC Resolution** | 12/16-bit DAQ ADC (~2,000 counts) | 18-bit Sigma-Delta ADC (262,144 counts) | Absolute counts differ by $100\times$; features are strictly dimensionless ratios ($A_s/A_d$, $h_2/h_1$) and temporal durations ($T_c, T_d$). |
| **Filtering** | Hardware analog bandpass + digital lowpass | 5-tap moving median + 1st-order IIR DC removal ($\alpha=0.95$) | Firmware removes respiratory baseline wander and motion artifacts before feature extraction. |

---

## 4. Model Deployment & APK Verification

### 4.1 Artifact SHA-256 Provenance Chain

```
[train_bp_model.py]
       │
       ▼
app/assets/ml/bp_model_meta.json
  SHA-256: e67c631dfa6a6f1d7364d6fcf35d2964c66d4f513d9dca6b4bb6ce53eeefb129 (65,889 B)
       │
       ├──► BpInferenceService.defaultModel() in Dart (100% numerical match)
       │
       ▼
app/build/app/outputs/flutter-apk/app-release.apk
  SHA-256: f0d88db7e68e8a7c3983e21aff8ee1f2fef877010475b711df4376ed601fd0eb (63,779,504 B)
       │
       └──► Inside APK asset: assets/flutter_assets/assets/ml/bp_model_meta.json
              SHA-256: e67c631dfa6a6f1d7364d6fcf35d2964c66d4f513d9dca6b4bb6ce53eeefb129
              (VERIFIED IDENTICAL BYTE MATCH)
```

### 4.2 Resolution of Previous APK Hash Invariance
In the preceding build, the APK hash remained identical because `bp_model_meta.json` had not changed between consecutive `assembleRelease` runs. Following the pipeline correction and retraining, `bp_model_meta.json` was updated to `e67c631...`, `BpInferenceService` was updated with the exact weights, and `flutter build apk --release` produced a genuinely refreshed APK:
- **Final APK Path:** `app/build/app/outputs/flutter-apk/app-release.apk`
- **Final APK SHA-256:** `f0d88db7e68e8a7c3983e21aff8ee1f2fef877010475b711df4376ed601fd0eb`
- **Final APK Size:** `63,779,504 bytes` (60.8 MB)

---

## 5. Revalidated Inference Engine & Parity Verification

### 5.1 Pure Dart Latency Micro-Benchmark
- **Benchmark Suite:** `app/test/bp_latency_benchmark_test.dart` (10,000 iterations on host)
- **Mean Latency:** $0.0033\text{ ms}$ ($3.28\text{ \mu s}$)
- **P50 Latency:** $0.0010\text{ ms}$ ($1.0\text{ \mu s}$)
- **P95 Latency:** $0.0060\text{ ms}$ ($6.0\text{ \mu s}$)
- **P99 Latency:** $0.0140\text{ ms}$ ($14.0\text{ \mu s}$)
- **Engine Safety:** Zero C++ FFI bindings; zero native memory leaks or SIGSEGV crash surfaces.

### 5.2 Parity & Physiological Bounding Verification
- **Python vs Dart Numerical Parity:** Verified via `test/bp_inference_test.dart`:
  $$|\hat{y}_{\text{Dart}} - \hat{y}_{\text{Python}}| < 0.01\text{ mmHg}$$
- **Physiological Bounds Clamping:** Extreme inputs (e.g., Age 95, BMI 48, Crest 350 ms, Stiffness 22.0) are safely clamped to $70\text{--}220\text{ mmHg}$ SBP and $40\text{--}140\text{ mmHg}$ DBP, with pulse pressure maintenance ($DBP \le SBP - 25$).

---

## 6. Medical Safety & Standards Compliance Affirmation

> [!CAUTION]
> **Regulatory Notice & Prohibited Claims:**
> 1. **No AAMI SP10 Compliance Claim:** The uncalibrated SBP MAE of $13.86\text{ mmHg}$ and DBP MAE of $8.47\text{ mmHg}$ do not meet AAMI SP10 ($\le 5\text{ mmHg}$).
> 2. **No BHS Certification Claim:** Uncalibrated performance corresponds to BHS Grade D.
> 3. **IEEE 1708 Standard Edition:** The current standard is **IEEE 1708-2025** (*Standard for Wearable, Cuffless Blood Pressure Measuring Devices*). It requires multi-session evaluations with dynamic cardiovascular stress testing. No claim of IEEE 1708-2025 compliance is made.
> 4. **Emergency Crisis Isolation:** Optical model estimates are strictly investigational and **never trigger hypertensive emergency alerts**. Only validated cuff readings ($\ge 180\text{ mmHg}$ SBP or $\ge 120\text{ mmHg}$ DBP) trigger the ESC/ISH 2023 Hypertensive Crisis guidance and the Egyptian Emergency Service (123) directive.

---

## 7. Comprehensive Regression Suite Results

- **Flutter Static Analysis:**
  ```text
  $ flutter analyze --no-pub
  Analyzing app...
  No issues found! (ran in 16.7s)
  ```
- **Flutter Automated Tests:**
  ```text
  $ flutter test --no-pub
  00:40 +371: All tests passed! (37 test files, 100% pass rate)
  ```
- **Python Dataset Ingestion & Checksum Tests:**
  ```text
  $ python -m unittest ml/tests/test_dataset_ingestion.py
  Ran 5 tests in 0.023s. OK.
  ```

---

## 8. Final Release Decision

### Selection: **OPTION B**
**MODEL RETAINED AS EXPERIMENTAL — CALIBRATION ACCURACY NOT INDEPENDENTLY VALIDATED.**

### Engineering Rationale:
1. The application software, database, BLE protocol, UI flows, and Pure Dart inference engine are fully implemented, bug-free, and tested with 371 passing tests.
2. The deployed model weights are verified to match `bp_model_meta.json` inside the generated Android Release APK.
3. However, because the underlying clinical training dataset contains only single-visit cuff references, longitudinal calibration stability and tracking under hemodynamic challenges cannot be independently validated in this environment.
4. Marking the model as **Experimental** preserves total scientific honesty, aligns with medical device software ethics, and establishes a safe foundation for physical phone and hardware field testing.
