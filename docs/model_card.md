# PulsePatch Lite — AI Model Card

**Model Name:** PulsePatch AI Insights  
**Engine:** small neural network running locally in the app (pure Dart isolate, 241 floating-point parameters: 216 weights + 25 biases)  
**Version:** 1.0.0  
**Date:** October 2026  
**License:** Open Source (Educational Capstone Project)  
**Classification:** Strictly Non-Diagnostic Educational Classifier  

---

## 1. Model Overview & Purpose

PulsePatch AI Insights is a compact, on-device machine learning model engineered for the **PulsePatch Lite** educational biomonitoring platform. It analyzes five session-level statistical features derived from optical pulse rate recordings to characterize heart rate and rate recovery dynamics into one of two educational pattern labels:
- **`Typical pattern` (Label 0):** The recording exhibits rate recovery behavior consistent with modeled resting stability or expected post-activity rate deceleration.
- **`Different pattern` (Label 1):** The recording deviates statistically from expected resting stability or displays a delayed post-activity rate recovery trajectory.

> [!IMPORTANT]
> **Strict Non-Diagnostic Compliance**  
> PulsePatch Lite does not diagnose, treat, or screen for medical conditions. It does not output diagnostic categories such as "Normal / Abnormal", "Healthy / Unhealthy", or "Sinus Rhythm". The labels are statistical pattern indicators intended solely for educational feedback.

---

## 2. Architecture & Computational Footprint

- **Architecture:** Feed-Forward Multi-Layer Perceptron (`MLP 5 -> 16 -> 8 -> 1 / 2`)
  - Input Layer: 5 standardized numerical features
  - Hidden Layer 1: 16 units, ReLU activation ($\max(0, z)$)
  - Hidden Layer 2: 8 units, ReLU activation ($\max(0, z)$)
  - Output Layer: 1 unit with Sigmoid logistic activation ($\sigma(z)$) / 2 units with Softmax
- **Parameters:** 241 floating-point parameters (216 weights + 25 biases)
- **Quantization:** Float32 (lossless numerical parity)
- **Runtime Inference Latency:** $< 0.15\text{ ms}$ on mobile ARM devices and background isolates
- **Memory Consumption:** $< 12\text{ KB}$ runtime footprint

---

## 3. Input Features & Standardization

The model ingests five features extracted strictly according to Section 6 of the Master Build Plan:

| Index | Feature Name | Description | Scaler Mean ($\mu$) | Scaler Scale ($\sigma$) |
|---|---|---|---|---|
| **0** | `mean_hr` | Average valid optical heart rate across the session | 88.3786 | 21.2733 |
| **1** | `std_hr` | Sample standard deviation of valid heart rate ($N-1$ DoF) | 7.1818 | 3.9030 |
| **2** | `start_hr` | Median of valid BPM in the first 10 seconds of valid data | 95.2565 | 27.6369 |
| **3** | `end_hr` | Median of valid BPM in the last 10 seconds of valid data | 81.4746 | 17.0718 |
| **4** | `recovery_drop` | Post-activity: $start\_hr - median(window_{55-65s})$; Rest: $start\_hr - end\_hr$ | 10.8546 | 13.0717 |

Standardization formula:
$$z_i = \frac{x_i - \mu_i}{\sigma_i}$$

---

## 4. Training Data & Cohort Protocol

1. **Protocol Design (Section 7.1):**
   - **Resting Protocol:** Seated rest in quiet environment for 2-3 minutes (or 60s standard session).
   - **Post-Activity Recovery Protocol:** 1 minute brisk step-test / stairs followed immediately by 1-2 minutes of seated rest (or 90s recovery session).
2. **Shipped Model Training Data (163 Sessions, 11 Subjects):**
   - **Synthetic Bootstrap Cohort:** 160 sessions across 10 modeled volunteer profiles (VOL_01-VOL_10, 80 rest, 80 post-activity), labeled source=synthetic (*synthetic pipeline test, not real validation*).
   - **Over-The-Air BLE Sessions from Test Peripheral (Simulated Physiology):** 3 sessions recorded on physical Android phone (HONOR NIC-LX2) over Bluetooth Low Energy from PulsePatch-SimHR (source=standard_hr, subject VOL_BLE_SIM_01):
     - sess-1792996240842 (60s resting baseline, mean HR: 71.83 BPM, Typical pattern)
     - sess-1793000580974 (90s post-activity recovery plateau, mean HR: 74.03 BPM, Typical pattern)
     - sess-1793010133841 (90s clean post-activity recovery descent, recovery drop: 9.0 BPM < 12 BPM threshold, Different pattern)
3. **Cross-Validation & Evaluation Strategy:**
   - Multi-subject combined cohort (11 subjects): 5-Fold GroupKFold grouped strictly by subject_id (zero inter-subject leakage, VOL_BLE_SIM_01 in Holdout Fold 1). Tiny MLP achieved **98.86%** on this benchmark (ROC-AUC: 0.9974).
     > [!WARNING]
     > **Cohort Composition Caveat:** 10 of the 11 subjects are synthetic simulation profiles, and the 11th subject (`VOL_BLE_SIM_01`, 3 sessions) represents simulated heart rate profiles streamed over physical BLE from the test peripheral `PulsePatch-SimHR`. Zero human subject physiological recordings are included. This 98.86% benchmark score primarily reflects synthetic-data performance, software pipeline stability, and BLE transport integration, NOT real-world human physiological generalization or clinical diagnostic accuracy. It must not stand alone as "model accuracy".
   - Single-subject BLE test peripheral data: Integration / pipeline sanity check (n=1 test session) using time-ordered chronological split (2 earlier train, 1 later test; n=1 test session passed). Serves as an end-to-end integration and pipeline sanity check, not a meaningful accuracy metric.

---

### 4.2 Real-Data Protocol (Xiaomi Mi Smart Band 5 Extension)

> [!NOTE]
> **Status: Code & Architecture Ready — Physical Session Not Yet Recorded**  
> The data export adapter, training pipeline, and single-subject split logic are fully implemented and verified in code. However, **no physical Mi Band 5 session has been recorded yet**. The physical over-the-air BLE connection is not yet tested on a real band.

1. **Device & Sensor Scope:**
   - Device: Xiaomi Mi Smart Band 5 connected via standard BLE Heart Rate Service (0x180D/0x2A37) or Huami protocol.
   - Sensor type: Wrist optical photoplethysmography (wrist optical sensor, not MAX30102).
   - Label: source=miband5.
   - **Crucial boundary:** The Mi Smart Band 5 is an educational input source, NOT a clinical gold standard. It is never used to validate MAX30102 sensor accuracy (MAE/Bland-Altman).

2. **Collection & Evaluation Protocol:**
   - Single-subject guided collection mode: Repeated short resting sessions (60s) and post-activity recovery sessions (stairs 1 min + seated recovery 90s) recorded over multiple days.
   - Evaluation Method: Strictly time-ordered chronological session split (75% train earlier, 25% test later).
   - **Zero Generalization Claim:** When evaluating single-subject data, GroupKFold across subjects is prohibited. The evaluation shows pipeline stability on one person's data and does NOT generalize to the wider population.

3. **Label Derivation for Single-Subject Data (Session Type Learning):**
   When training on single-subject exported sessions without external clinical annotations, labels are derived programmatically from the recorded session protocol:
   - **Resting Sessions (session_type == 'rest'):**
     - **Typical pattern (Label 0):** Stable resting rhythm where average BPM remains within 45–95 BPM and standard deviation (std_hr) $< 8.0\text{ BPM}$.
     - **Different pattern (Label 1):** Elevated resting rate ($> 95\text{ BPM}$) or erratic variability ($\text{std} \ge 8.0\text{ BPM}$).
   - **Post-Activity Recovery Sessions (session_type == 'post_activity'):**
     - **Typical pattern (Label 0):** Expected deceleration trajectory with rate recovery drop $\ge 12\text{ BPM}$ across the post-exercise window.
     - **Different pattern (Label 1):** Blunted or delayed rate recovery drop ($< 12\text{ BPM}$).
   
   > [!IMPORTANT]
   > **Model Learns Session Type Dynamics, NOT Health**  
   > Because labels in real single-subject training are derived directly from the user's recorded session types (Resting stability vs Post-Activity recovery), the model is learning to classify **session type and recovery trajectory patterns**, NOT personal health, fitness, or wellness rating. It cannot evaluate medical status.

4. **Execution Command:**
   `ash
   py ml/src/train.py --data <exported_sessions.csv> --export_production
   `

---

## 5. Quantitative Evaluation Metrics

> [!NOTE]
> **Synthetic Pipeline Test, Not Real Validation**  
> All metrics below are derived from cross-validation over the 160 modeled synthetic volunteer sessions. They serve to verify the ML pipeline and mathematical stability, not diagnostic accuracy on human subjects.

Cross-validation performance across holdout synthetic volunteer subjects (*synthetic pipeline test, not real validation*):

| Metric | Logistic Regression Baseline | Random Forest Baseline | Tiny MLP (Primary Model) | Evaluation Classification |
|---|---|---|---|---|
| **Accuracy** | 93.75% ($\pm 3.1\%$) | 100.00% ($\pm 0.0\%$) | **99.38%** ($\pm 0.9\%$) | Synthetic pipeline test, not real validation |
| **Precision** | 85.00% | 100.00% | **100.00%** | Synthetic pipeline test, not real validation |
| **Recall** | 78.29% | 100.00% | **97.14%** | Synthetic pipeline test, not real validation |
| **F1 Score** | 79.72% | 100.00% | **98.46%** | Synthetic pipeline test, not real validation |
| **ROC-AUC** | 0.9781 | 1.0000 | **1.0000** | Synthetic pipeline test, not real validation |
| **Brier Calibration Score** | 0.0468 | 0.0094 | **0.0051** | Synthetic pipeline test, not real validation |

### Confusion Matrix (Aggregated 160 Modeled Synthetic Holdout Sessions)
*(Synthetic pipeline test, not real validation)*
```
                    Predicted Typical    Predicted Different
Actual Typical            133                    0
Actual Different            1                   26
```

---

## 6. Mathematical Parity & Test Vectors

Inference forward pass parity was validated across Python (`scikit-learn` training weights) and the Flutter/Dart background isolate runner on shared test vectors:
- **Vector 1 (Standard Resting Typical):** $100\%$ agreement ($P_{typical} = 97.7\%$, Label 0).
- **Vector 2 (Post-Activity Robust Drop):** $100\%$ agreement ($P_{typical} = 99.9\%$, Label 0).
- **Vector 3 (Post-Activity Blunted Drop):** $100\%$ agreement ($P_{different} = 99.6\%$, Label 1).
- **Vector 4 (Outlier Elevated Session):** $100\%$ agreement ($P_{different} = 90.3\%$, Label 1).
- **Maximum Absolute Discrepancy ($\Delta P$):** $< 0.0001$ across all test vectors.

---

## 7. Limitations & Known Failure Modes

1. **Short Sessions ($< 30\text{ seconds}$):** Gated out automatically by `AiInferenceService.insufficientData`.
2. **Motion Artifacts & Vasoconstriction:** Intense finger motion or severe peripheral vasoconstriction drops optical signal quality below $SQI = 60$. When samples are invalid, feature calculation is suppressed.
3. **Synthetic Training Bootstrap:** The model is currently bootstrapped on synthetic volunteer data modeled after physiological norms. Retraining on physical volunteer recordings is supported via one documented command:
   ```bash
   py ml/src/train.py
   ```
4. **Physical Interpretation:** A "Different pattern" output indicates statistical variance from the typical resting/recovery profile and does NOT imply cardiac disease or pathology.
