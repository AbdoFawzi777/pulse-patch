---
name: bp-estimation-research
description: PPG-based continuous and cuffless blood pressure estimation research, feature engineering, SBP/DBP regression modeling, calibration protocols, and IEEE/AAMI validation standards.
---

# Blood Pressure Estimation Research Skill

## 1. Purpose
Guides the design, feature selection, training, calibration, and rigorous statistical validation of cuffless Blood Pressure (BP) estimation algorithms using single-site Photoplethysmography (PPG).

## 2. When to Use
- Evaluating physiological features related to arterial stiffness, vascular compliance, and pulse wave propagation.
- Developing and benchmarking regression models for Systolic Blood Pressure (SBP), Diastolic Blood Pressure (DBP), and Mean Arterial Pressure (MAP).
- Structuring subject-independent vs. calibrated patient workflows.
- Verifying model performance against IEEE 1708-2014 and AAMI/ESH/ISO standards.

## 3. Required Inputs
- Segmented single-beat PPG waveforms and first/second derivatives (VPG, APG).
- Reference SBP and DBP ground-truth measurements (mmHg) from validated auscultatory or oscillometric devices.
- Contextual patient metadata (Age, BMI, Gender, Baseline HR).

## 4. Expected Outputs
- Validated feature vector (Pulse Transit Time surrogates, Crest Time, Reflection Index, Inflection Ratio, Pulse Area Ratio).
- Estimated SBP, DBP, and MAP ($\text{mmHg}$) with confidence uncertainty intervals.
- Statistical error metrics: Mean Absolute Error (MAE), Mean Error (ME / Bias), Standard Deviation of Error (SDE), Pearson correlation ($r$).

## 5. Practical Workflow
1. **Feature Extraction:**
   - Systolic upstroke time (rise time / crest time $t_r$).
   - Diastolic decay time ($t_d$).
   - Pulse width at $25\%$, $50\%$, and $75\%$ pulse height ($PW_{25}, PW_{50}, PW_{75}$).
   - Area under systolic curve ($A_s$) vs. diastolic curve ($A_d$): Inflection ratio $A_s / A_d$.
   - Normalized pulse amplitude and stiffness index ($h / \Delta T$).
2. **Model Selection:**
   - Baseline: Ridge/Lasso Regularized Linear Regression.
   - Non-linear: Random Forest Regressor & Gradient Boosted Decision Trees.
3. **Calibration Strategy:**
   - Subject-specific offset calibration ($\Delta_{cal} = BP_{ref} - BP_{est}$).
   - Recalibration trigger when pulse morphology drifts significantly from baseline.
4. **Validation Pipeline:**
   - Strict Subject-Wise (GroupKFold) cross-validation; zero inter-subject leakage.

## 6. Verification Criteria
- AAMI Standard Target: Mean Error $\le 5.0\text{ mmHg}$, Standard Deviation $\le 8.0\text{ mmHg}$.
- Separate validation metrics reported for SBP and DBP.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never compute blood pressure solely from Heart Rate and $SpO_2$ (e.g., $SBP = BPM \times 1.5$ is completely fraudulent).
- **Prohibited:** Never claim clinical diagnostic equivalence without FDA/CE-marked multi-center clinical trials.
- **Limitation:** Vasomotor tone changes and severe arterial disease can alter PPG morphology independently of brachial pressure.
