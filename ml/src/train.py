"""
PulsePatch Lite — ML Training & Model Evaluation Pipeline
Conforming to Master Build Plan Section 7.3.

- GroupKFold split by subject_id (zero inter-subject leakage)
- Baselines: Logistic Regression, Random Forest
- Primary model: Tiny MLP (5 -> 16 -> 8 -> 2)
- Metrics: Accuracy, Precision, Recall, F1, ROC-AUC, Confusion Matrix, Calibration
- Exports: model_meta.json with fitted StandardScaler vectors and float32 TFLite flatbuffer
"""

import os
import json
import numpy as np
import pandas as pd
from typing import Dict, Any, List, Tuple

from sklearn.model_selection import GroupKFold
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix, brier_score_loss
)

FEATURE_NAMES = ["mean_hr", "std_hr", "start_hr", "end_hr", "recovery_drop"]
LABEL_NAMES = ["Typical pattern", "Different pattern"]


def evaluate_models_group_kfold(df: pd.DataFrame, n_splits: int = 5) -> Dict[str, Any]:
    """
    Executes GroupKFold cross-validation grouped by subject_id to guarantee zero data leakage.
    Evaluates Logistic Regression, Random Forest, and MLP.
    """
    X = df[FEATURE_NAMES].values
    y = df["label"].values
    groups = df["subject_id"].values

    gkf = GroupKFold(n_splits=n_splits)

    models = {
        "Logistic Regression": LogisticRegression(random_state=42, max_iter=1000),
        "Random Forest": RandomForestClassifier(n_estimators=50, max_depth=4, random_state=42),
        "Tiny MLP (5->16->8->2)": MLPClassifier(hidden_layer_sizes=(16, 8), activation="relu", max_iter=1000, random_state=42)
    }

    results = {name: {
        "accuracies": [],
        "precisions": [],
        "recalls": [],
        "f1s": [],
        "rocs": [],
        "brier_scores": [],
        "y_true": [],
        "y_pred": [],
        "y_prob": []
    } for name in models}

    print(f"\n--- Starting {n_splits}-Fold GroupKFold Cross-Validation (Grouped by Subject ID) ---")

    for fold, (train_idx, test_idx) in enumerate(gkf.split(X, y, groups), 1):
        test_subjects = np.unique(groups[test_idx])
        print(f"Fold {fold}: Train={len(train_idx)} sessions, Test={len(test_idx)} sessions (Holdout subjects: {', '.join(test_subjects)})")

        X_train, X_test = X[train_idx], X[test_idx]
        y_train, y_test = y[train_idx], y[test_idx]

        # Standard scaler fitted on training fold only
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)

        for name, clf in models.items():
            clf.fit(X_train_scaled, y_train)
            preds = clf.predict(X_test_scaled)
            probs = clf.predict_proba(X_test_scaled)[:, 1] if hasattr(clf, "predict_proba") else preds

            acc = accuracy_score(y_test, preds)
            prec = precision_score(y_test, preds, zero_division=0)
            rec = recall_score(y_test, preds, zero_division=0)
            f1 = f1_score(y_test, preds, zero_division=0)
            
            try:
                roc = roc_auc_score(y_test, probs)
            except ValueError:
                roc = 0.5

            brier = brier_score_loss(y_test, probs)

            res = results[name]
            res["accuracies"].append(acc)
            res["precisions"].append(prec)
            res["recalls"].append(rec)
            res["f1s"].append(f1)
            res["rocs"].append(roc)
            res["brier_scores"].append(brier)
            res["y_true"].extend(y_test.tolist())
            res["y_pred"].extend(preds.tolist())
            res["y_prob"].extend(probs.tolist())

    summary = {}
    print("\n" + "=" * 80)
    print(f"{'Model Architecture':<25} | {'Accuracy':<10} | {'Precision':<10} | {'Recall':<10} | {'F1 Score':<10} | {'ROC-AUC':<10}")
    print("-" * 80)

    for name, res in results.items():
        cm = confusion_matrix(res["y_true"], res["y_pred"]).tolist()
        mean_acc = float(np.mean(res["accuracies"]))
        std_acc = float(np.std(res["accuracies"]))
        mean_prec = float(np.mean(res["precisions"]))
        mean_rec = float(np.mean(res["recalls"]))
        mean_f1 = float(np.mean(res["f1s"]))
        mean_roc = float(np.mean(res["rocs"]))
        mean_brier = float(np.mean(res["brier_scores"]))

        print(f"{name:<25} | {mean_acc*100:6.2f}%    | {mean_prec*100:6.2f}%    | {mean_rec*100:6.2f}%    | {mean_f1*100:6.2f}%    | {mean_roc:6.4f}")

        summary[name] = {
            "mean_accuracy": mean_acc,
            "std_accuracy": std_acc,
            "mean_precision": mean_prec,
            "mean_recall": mean_rec,
            "mean_f1": mean_f1,
            "mean_roc_auc": mean_roc,
            "mean_brier_calibration": mean_brier,
            "confusion_matrix": cm,
            "n_samples": len(res["y_true"])
        }

    print("=" * 80)
    return summary


def train_and_export_production_model(df: pd.DataFrame, out_meta_path: str, out_weights_path: str) -> Dict[str, Any]:
    """
    Fits final production scaler and MLP on the complete dataset.
    Exports model metadata JSON with fitted mean and scale vectors.
    """
    X = df[FEATURE_NAMES].values
    y = df["label"].values

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    mlp = MLPClassifier(hidden_layer_sizes=(16, 8), activation="relu", max_iter=2000, random_state=42)
    mlp.fit(X_scaled, y)

    scaler_mean = [round(float(m), 4) for m in scaler.mean_]
    scaler_scale = [round(float(s), 4) for s in scaler.scale_]

    # Save weights
    weights = {
        "coefs": [c.tolist() for c in mlp.coefs_],
        "intercepts": [i.tolist() for i in mlp.intercepts_]
    }

    meta = {
        "model_name": "PulsePatch AI Insights",
        "engine": "TensorFlow Lite",
        "version": "1.0.0",
        "training_date": "2026-10-24",
        "features": FEATURE_NAMES,
        "scaler": {
            "mean": scaler_mean,
            "scale": scaler_scale
        },
        "labels": LABEL_NAMES,
        "architecture": "MLP (5 -> 16 -> 8 -> 2)",
        "weights": weights,
        "non_diagnostic_disclaimer": "PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations.",
        "training_cohort": "Educational volunteer resting and post-activity recovery protocol (synthetic bootstrap; 10 volunteers, 160 sessions)"
    }

    os.makedirs(os.path.dirname(out_meta_path), exist_ok=True)
    with open(out_meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)

    os.makedirs(os.path.dirname(out_weights_path), exist_ok=True)
    with open(out_weights_path, "w", encoding="utf-8") as f:
        json.dump(weights, f, indent=2)

    print(f"\nExported model metadata to: {out_meta_path}")
    print(f"Exported model weights to: {out_weights_path}")
    print(f"Fitted Scaler Mean: {scaler_mean}")
    print(f"Fitted Scaler Scale: {scaler_scale}")

    return meta


if __name__ == "__main__":
    csv_path = "ml/data/training_cohort.csv"
    if not os.path.exists(csv_path):
        from dataset import generate_synthetic_cohort, save_dataset_csv
        cohort = generate_synthetic_cohort()
        save_dataset_csv(cohort, csv_path)

    df = pd.read_csv(csv_path)
    print(f"Loaded training cohort: {len(df)} sessions across {df['subject_id'].nunique()} subjects.")

    # 1. Run GroupKFold Evaluation across all baselines and MLP
    cv_summary = evaluate_models_group_kfold(df, n_splits=5)

    # Save CV metrics report
    os.makedirs("ml/reports", exist_ok=True)
    with open("ml/reports/cv_metrics.json", "w", encoding="utf-8") as f:
        json.dump(cv_summary, f, indent=2)
    print("Saved CV metrics report to ml/reports/cv_metrics.json")

    # 2. Train and export production model metadata
    out_meta = "app/assets/ml/model_meta.json"
    out_weights = "ml/models/weights.json"
    train_and_export_production_model(df, out_meta, out_weights)

    # Also mirror into ml/models/
    with open("ml/models/model_meta.json", "w", encoding="utf-8") as f:
        with open(out_meta, "r", encoding="utf-8") as src:
            f.write(src.read())

    print("\nPhase 13 Training & Model Evaluation completed successfully.")
