# PulsePatch Lite — AI Model Card

**Model Name:** PulsePatch AI Insights  
**Engine:** TensorFlow Lite / Pure Dart High-Performance Forward Pass  
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
- **Parameters:** 233 floating-point weights and biases
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
   - **Resting Protocol:** Seated rest in quiet environment for 2–3 minutes.
   - **Post-Activity Recovery Protocol:** 1 minute brisk step-test / stairs followed immediately by 2 minutes of seated rest.
2. **Cohort Demographics:**
   - 10 anonymous volunteer subjects (`VOL_01` through `VOL_10`).
   - 160 total recording sessions (80 resting sessions, 80 post-activity sessions).
   - Data Source: Synthetic bootstrap cohort modeled honestly and strictly labeled `source=synthetic` as required by Section 7.2.
   - Ground truth class distribution: 133 Typical pattern sessions (83.1%), 27 Different pattern sessions (16.9%).
3. **Cross-Validation Setup:**
   - 5-Fold `GroupKFold` grouped strictly by `subject_id` (2 holdout volunteers per fold).
   - Zero inter-subject data leakage. Scaler fitted on training folds only.

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

Inference forward pass parity was validated across Python (`scikit-learn`), TensorFlow Lite flatbuffer, and the Flutter/Dart background isolate runner on shared test vectors:
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
