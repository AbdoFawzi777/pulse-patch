# PulsePatch Lite v2.0 — Blood Pressure Model Validation & Clinical Performance Report

## 1. Executive Summary & Clinical Standards
PulsePatch Lite uses photoplethysmography (PPG) morphological features combined with demographic baseline parameters to estimate Blood Pressure (Systolic BP, Diastolic BP, and Mean Arterial Pressure). Estimates are benchmarked against the **AAMI/ESH/ISO SP10:2018 Standard** (Mean Absolute Error $\le 5\text{ mmHg}$, Standard Deviation $\le 8\text{ mmHg}$) and the **British Hypertension Society (BHS)** Grading Protocol.

## 2. Benchmark Dataset & Zero-Leakage Validation
- **Benchmark Source:** Mirror of Liang et al. Nature Scientific Data 2018 (219 subjects, 657 recordings).
- **Split Strategy:** Subject-Wise GroupKFold (5 Folds). Recordings from any given patient appear strictly in either the training set or the validation set, ensuring zero patient memorization leakage.

## 3. Comparative Model Evaluation Results

| Model Architecture | Metric | SBP Value | SBP BHS | SBP AAMI | DBP Value | DBP BHS | DBP AAMI |
|---|---|---|---|---|---|---|---|
| **Ridge** | MAE / SDE / r | 6.65 ± 8.33 (r=0.72) | Grade C (44.1% ≤5) | FAIL | 5.40 ± 6.72 (r=0.61) | Grade B (54.5% ≤5) | FAIL |
| **GBDT** | MAE / SDE / r | 6.99 ± 8.61 (r=0.70) | Grade C (42.5% ≤5) | FAIL | 5.63 ± 7.07 (r=0.56) | Grade B (53.1% ≤5) | FAIL |
| **MLP_Linear_DartCompatible** | MAE / SDE / r | 7.64 ± 9.51 (r=0.64) | Grade D (39.6% ≤5) | FAIL | 6.07 ± 7.50 (r=0.52) | Grade C (46.4% ≤5) | FAIL |

## 4. Pure Dart Inference Architecture
To guarantee maximum portability, battery efficiency, and zero binary size bloat:
1. Normalization scalers ($\mu, \sigma$) and trained Ridge & MLP layer weights are serialized to `app/assets/ml/bp_model_meta.json`.
2. The Dart engine loads the matrix in an isolated background thread (`Isolate`), performing vector dot products in $<0.15\text{ ms}$ with zero native C++ crash surfaces.
3. Patient calibration offset ($\Delta SBP, \Delta DBP$) from gold-standard cuff measurements is supported with a recommended 30-day recalibration window.
