# PulsePatch Lite v2.0 — Blood Pressure Model Validation & Clinical Performance Report

## 1. Executive Summary & Clinical Standards
PulsePatch Lite uses photoplethysmography (PPG) morphological features combined with demographic baseline parameters to estimate Blood Pressure (Systolic BP, Diastolic BP, and Mean Arterial Pressure). Estimates are benchmarked against the **AAMI/ESH/ISO SP10:2018 Standard** (Mean Absolute Error $\le 5\text{ mmHg}$, Standard Deviation $\le 8\text{ mmHg}$) and the **British Hypertension Society (BHS)** Grading Protocol.

## 2. Benchmark Dataset & Zero-Leakage Validation
- **Benchmark Source:** Liang et al. Nature Scientific Data 2018 (CC0 Figshare DOI: 10.6084/m9.figshare.5459299.v5) — 219 subjects, 657 records.
- **Split Strategy:** Subject-Wise GroupKFold (5 Folds). Recordings from any given patient appear strictly in either the training set or the validation set, ensuring zero patient memorization leakage.

## 3. Comparative Model Evaluation Results

| Model Architecture | SBP MAE (mmHg) | SBP SDE | SBP r | SBP BHS | SBP AAMI | DBP MAE (mmHg) | DBP SDE | DBP r | DBP BHS | DBP AAMI |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Ridge_Baseline** | 13.86 | 17.99 | 0.47 | Grade D (24.4% ≤5) | FAIL | 8.47 | 10.69 | 0.28 | Grade D (35.5% ≤5) | FAIL |
| **ElasticNet** | 13.68 | 17.84 | 0.48 | Grade D (26.2% ≤5) | FAIL | 8.35 | 10.60 | 0.30 | Grade D (36.7% ≤5) | FAIL |
| **Random_Forest** | 14.28 | 18.03 | 0.48 | Grade D (23.4% ≤5) | FAIL | 8.60 | 10.89 | 0.25 | Grade D (37.6% ≤5) | FAIL |
| **GBDT** | 13.78 | 17.47 | 0.52 | Grade D (25.6% ≤5) | FAIL | 8.89 | 11.22 | 0.23 | Grade D (35.8% ≤5) | FAIL |
| **MLP_DartCompatible** | 14.93 | 19.36 | 0.39 | Grade D (23.0% ≤5) | FAIL | 8.89 | 11.38 | 0.22 | Grade D (35.9% ≤5) | FAIL |

## 4. Pure Dart Inference Architecture
To guarantee maximum portability, battery efficiency, and zero binary size bloat:
1. Normalization scalers ($\mu, \sigma$) and trained Ridge & MLP layer weights are serialized to `app/assets/ml/bp_model_meta.json`.
2. The Dart engine loads the matrix in an isolated background thread (`Isolate`), performing vector dot products in $<0.15\text{ ms}$ with zero native C++ crash surfaces.
3. Patient calibration offset ($\Delta SBP, \Delta DBP$) from gold-standard cuff measurements is supported with a recommended 30-day recalibration window.
