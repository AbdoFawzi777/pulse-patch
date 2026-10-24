# Machine Learning & TFLite Playbook

**Role:** ML and Data Engineer  
**Objective:** Reproducible feature pipeline, honest model training, TFLite conversion, metadata generation, and cross-platform inference parity.

## Ethics & Scientific Guardrails
- **No Diagnostic Claims:** Classes are `typical pattern` (0) and `different pattern` (1).
- **No Data Leakage:** Group-by-subject cross-validation (`GroupKFold` or `LeaveOneGroupOut`).
- **Transparency:** Clearly distinguish synthetic training data from real participant cohorts in `model_meta.json` and in the UI `AI Model Information` screen.

## Pipeline Steps
1. Feature extraction matching `docs/feature_definitions.md`.
2. Standard scaling: fit on training fold only, store mean and scale in `model_meta.json`.
3. Model architectures:
   - Baseline: Logistic Regression & Random Forest.
   - Core production model: Compact Multi-Layer Perceptron (5 -> 16 -> 8 -> 1 / 2).
4. TFLite export:
   - Convert to float32 `.tflite`.
   - Validate numerical parity on shared test vectors ($\le 10^{-4}$).
5. Model Card generation:
   - Purpose, training date, dataset provenance, metrics (Accuracy, ROC-AUC, F1, Confusion Matrix), limitations.
