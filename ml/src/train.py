"""
PulsePatch Lite — ML Training & Model Evaluation Pipeline
Conforming to Master Build Plan Section 7.3 & Multi-Source Real Data Extension.

Supports:
- Real-world single-subject datasets (time-ordered chronological split, no GroupKFold)
- Multi-subject cohorts (GroupKFold grouped by subject_id, zero inter-subject leakage)
- Source-isolated evaluation reports (e.g. real Mi Band 5 wrist data vs synthetic baseline)
- Pure-Dart float32 weights export with fitted StandardScaler vectors
"""

import os
import sys
import json
import argparse
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


def derive_educational_labels_if_missing(df: pd.DataFrame) -> pd.DataFrame:
    """
    If 'label' column is not in exported CSV or contains NaNs, derives educational classification
    labels based on the standard resting & post-activity recovery protocol heuristics.
    """
    df = df.copy()
    has_nans = ("label" in df.columns) and df["label"].isna().any()
    if "label" not in df.columns or has_nans:
        labels = []
        for _, row in df.iterrows():
            if "label" in df.columns and not pd.isna(row["label"]):
                labels.append(int(row["label"]))
                continue

            stype = str(row.get("session_type", "rest")).lower()
            mean_hr = float(row.get("mean_hr", 70.0))
            std_hr = float(row.get("std_hr", 3.0))
            recovery_drop = float(row.get("recovery_drop", 0.0))
            
            if "post" in stype or "activity" in stype:
                # Post-activity recovery: typical recovery shows >= 12 BPM drop in 60s
                if recovery_drop >= 12.0:
                    labels.append(0)  # Typical pattern
                else:
                    labels.append(1)  # Different pattern (blunted recovery)
            else:
                # Resting stability: typical resting is within 45-95 BPM with std < 8.0 BPM
                if mean_hr < 45.0 or mean_hr > 95.0 or std_hr > 8.0:
                    labels.append(1)  # Different pattern (elevated or erratic)
                else:
                    labels.append(0)  # Typical pattern
        df["label"] = labels
        df["label_name"] = [LABEL_NAMES[int(l)] for l in labels]
    return df


def evaluate_models_single_subject_time_split(df: pd.DataFrame, test_ratio: float = 0.25) -> Dict[str, Any]:
    """
    Evaluates models on a single-subject dataset using a strictly time-ordered
    chronological split (no GroupKFold, no shuffling).
    Guarantees no temporal leakage from future sessions into past training.
    """
    print("\n" + "=" * 80)
    print("SINGLE-SUBJECT DATASET DETECTED (1 unique subject)")
    print("Evaluation method: Time-ordered chronological session split (75% train, 25% test).")
    print("CRITICAL NOTE: Results show pipeline stability on one person's data and do NOT generalize.")
    print("=" * 80)

    # Sort chronologically if timestamps exist
    if "created_at" in df.columns:
        df = df.sort_values(by="created_at").reset_index(drop=True)
    elif "session_id" in df.columns:
        df = df.sort_values(by="session_id").reset_index(drop=True)

    X = df[FEATURE_NAMES].values
    y = df["label"].values

    n_total = len(df)
    n_train = max(1, min(n_total - 1, int(n_total * (1.0 - test_ratio)))) if n_total > 1 else 1
    n_test = n_total - n_train

    print(f"Time-Ordered Split: {n_train} training sessions (earlier), {n_test} test sessions (later)")

    X_train, X_test = X[:n_train], X[n_train:]
    y_train, y_test = y[:n_train], y[n_train:]

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    models = {
        "Logistic Regression": LogisticRegression(random_state=42, max_iter=1000),
        "Random Forest": RandomForestClassifier(n_estimators=50, max_depth=4, random_state=42),
        "Tiny MLP (5->16->8->2)": MLPClassifier(hidden_layer_sizes=(16, 8), activation="relu", max_iter=1500, random_state=42)
    }

    results = {}
    print("\n" + "-" * 80)
    print(f"{'Model Architecture':<25} | {'Accuracy':<10} | {'Precision':<10} | {'Recall':<10} | {'F1 Score':<10} | {'ROC-AUC':<10}")
    print("-" * 80)

    for name, clf in models.items():
        # Handle cases where training set might have only 1 class
        unique_classes = np.unique(y_train)
        if len(unique_classes) < 2:
            print(f"Warning: Training partition contains only class {unique_classes[0]}. Using class priors.")
            acc = 1.0 if np.all(y_test == unique_classes[0]) else 0.0
            prec = 1.0 if acc == 1.0 else 0.0
            rec = 1.0 if acc == 1.0 else 0.0
            f1 = 1.0 if acc == 1.0 else 0.0
            roc = 0.5
            brier = 0.0 if acc == 1.0 else 1.0
            cm = [[len(y_test), 0], [0, 0]] if unique_classes[0] == 0 else [[0, 0], [0, len(y_test)]]
        else:
            clf.fit(X_train_scaled, y_train)
            preds = clf.predict(X_test_scaled)
            probs = clf.predict_proba(X_test_scaled)[:, 1] if hasattr(clf, "predict_proba") else preds

            acc = float(accuracy_score(y_test, preds))
            prec = float(precision_score(y_test, preds, zero_division=0))
            rec = float(recall_score(y_test, preds, zero_division=0))
            f1 = float(f1_score(y_test, preds, zero_division=0))
            try:
                roc = float(roc_auc_score(y_test, probs))
            except ValueError:
                roc = 0.5
            brier = float(brier_score_loss(y_test, probs))
            cm = confusion_matrix(y_test, preds, labels=[0, 1]).tolist()

        print(f"{name:<25} | {acc*100:6.2f}%    | {prec*100:6.2f}%    | {rec*100:6.2f}%    | {f1*100:6.2f}%    | {roc:6.4f}")

        results[name] = {
            "evaluation_type": "single_subject_time_ordered_split",
            "generalization_note": "Evaluated on single-subject data; demonstrates pipeline stability on one subject only and does not generalize.",
            "mean_accuracy": acc,
            "std_accuracy": 0.0,
            "mean_precision": prec,
            "mean_recall": rec,
            "mean_f1": f1,
            "mean_roc_auc": roc,
            "mean_brier_calibration": brier,
            "confusion_matrix": cm,
            "train_samples": n_train,
            "test_samples": n_test
        }

    print("-" * 80)
    return results


def evaluate_models_group_kfold(df: pd.DataFrame, n_splits: int = 5) -> Dict[str, Any]:
    """
    Executes GroupKFold cross-validation grouped by subject_id to guarantee zero data leakage.
    Evaluates Logistic Regression, Random Forest, and MLP across multiple subjects.
    """
    X = df[FEATURE_NAMES].values
    y = df["label"].values
    groups = df["subject_id"].values

    unique_groups = len(np.unique(groups))
    actual_splits = min(n_splits, unique_groups)

    gkf = GroupKFold(n_splits=actual_splits)

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

    print(f"\n--- Starting {actual_splits}-Fold GroupKFold Cross-Validation (Grouped by Subject ID) ---")

    for fold, (train_idx, test_idx) in enumerate(gkf.split(X, y, groups), 1):
        test_subjects = np.unique(groups[test_idx])
        print(f"Fold {fold}: Train={len(train_idx)} sessions, Test={len(test_idx)} sessions (Holdout subjects: {', '.join(test_subjects)})")

        X_train, X_test = X[train_idx], X[test_idx]
        y_train, y_test = y[train_idx], y[test_idx]

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
            "evaluation_type": "multi_subject_group_kfold",
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


def train_and_export_production_model(
    df: pd.DataFrame,
    out_meta_path: str,
    out_weights_path: str,
    dominant_source: str = "synthetic"
) -> Dict[str, Any]:
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

    weights = {
        "coefs": [c.tolist() for c in mlp.coefs_],
        "intercepts": [i.tolist() for i in mlp.intercepts_]
    }

    if dominant_source in ["miband5", "real_miband5"]:
        cohort_desc = "Educational volunteer protocol with Mi Smart Band 5 (wrist optical sensor, not MAX30102; 1 subject, time-ordered split)"
        sensor_note = "trained on Mi Band 5 wrist data (wrist optical sensor, not MAX30102)"
        gen_disclaimer = "Evaluated on single-subject time-ordered split. Demonstrates pipeline execution on real wrist data; does not generalize."
    elif dominant_source in ["pulsepatch", "real_pulsepatch"]:
        cohort_desc = "Educational volunteer protocol with PulsePatch optical sensor (1 subject, time-ordered split)"
        sensor_note = "trained on PulsePatch fingertip optical sensor"
        gen_disclaimer = "Single-subject protocol. Educational demonstration only."
    else:
        cohort_desc = "Educational volunteer resting and post-activity recovery protocol (synthetic pipeline test, not real validation; 10 modeled volunteers, 160 sessions)"
        sensor_note = "modeled optical sensor simulation (synthetic pipeline test, not real validation)"
        gen_disclaimer = "Synthetic pipeline test, not real validation."

    meta = {
        "model_name": "PulsePatch AI Insights",
        "engine": "small neural network running locally in the app",
        "version": "1.0.0",
        "training_date": "2026-10-25",
        "features": FEATURE_NAMES,
        "scaler": {
            "mean": scaler_mean,
            "scale": scaler_scale
        },
        "labels": LABEL_NAMES,
        "architecture": "MLP (5 -> 16 -> 8 -> 2)",
        "weights": weights,
        "training_cohort": cohort_desc,
        "sensor_note": sensor_note,
        "generalization_note": gen_disclaimer,
        "non_diagnostic_disclaimer": "PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations. Do not use wrist band as reference for sensor accuracy claims."
    }

    os.makedirs(os.path.dirname(out_meta_path), exist_ok=True)
    with open(out_meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)

    os.makedirs(os.path.dirname(out_weights_path), exist_ok=True)
    with open(out_weights_path, "w", encoding="utf-8") as f:
        json.dump(weights, f, indent=2)

    print(f"\nExported model metadata to: {out_meta_path}")
    print(f"Exported model weights to: {out_weights_path}")
    print(f"Sensor Note: {sensor_note}")
    print(f"Fitted Scaler Mean: {scaler_mean}")
    print(f"Fitted Scaler Scale: {scaler_scale}")

    return meta


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PulsePatch Lite ML Training Pipeline")
    parser.add_argument("--data", type=str, default=None, help="Path to training CSV file (synthetic or real exported data)")
    parser.add_argument("--export_production", action="store_true", default=False, help="Update production app model weights and metadata")
    args = parser.parse_args()

    csv_path = args.data
    if csv_path is None:
        csv_path = "ml/data/training_cohort.csv"
        if not os.path.exists(csv_path):
            from dataset import generate_synthetic_cohort, save_dataset_csv
            cohort = generate_synthetic_cohort()
            save_dataset_csv(cohort, csv_path)

    if not os.path.exists(csv_path):
        print(f"Error: Training file not found at: {csv_path}")
        sys.exit(1)

    df = pd.read_csv(csv_path)

    # Normalize column names if exported from app
    if "subject_id" in df.columns and "subject_code" in df.columns:
        df["subject_id"] = df["subject_id"].fillna(df["subject_code"])
    elif "subject_code" in df.columns and "subject_id" not in df.columns:
        df["subject_id"] = df["subject_code"]
    elif "subject_id" not in df.columns:
        df["subject_id"] = "VOL_01"
    if "source" not in df.columns:
        df["source"] = "synthetic"

    # Derive labels if missing
    df = derive_educational_labels_if_missing(df)

    num_subjects = df["subject_id"].nunique()
    sources = df["source"].unique().tolist()
    print(f"\nLoaded dataset: {len(df)} sessions across {num_subjects} subject(s). Sources: {sources}")

    os.makedirs("ml/reports", exist_ok=True)

    # Separate evaluation per source
    for src in sources:
        df_src = df[df["source"] == src].copy()
        print(f"\n>>> Evaluating Source: '{src}' ({len(df_src)} sessions) <<<")
        src_subjects = df_src["subject_id"].nunique()

        if src_subjects == 1:
            report = evaluate_models_single_subject_time_split(df_src, test_ratio=0.25)
        else:
            report = evaluate_models_group_kfold(df_src, n_splits=5)

        clean_src_name = src.replace("/", "_").replace(" ", "_")
        report_path = f"ml/reports/metrics_{clean_src_name}.json"
        with open(report_path, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)
        print(f"Saved evaluation report for source '{src}' to: {report_path}")

    # Primary overall evaluation
    if num_subjects == 1:
        overall_report = evaluate_models_single_subject_time_split(df, test_ratio=0.25)
    else:
        overall_report = evaluate_models_group_kfold(df, n_splits=5)

    with open("ml/reports/cv_metrics.json", "w", encoding="utf-8") as f:
        json.dump(overall_report, f, indent=2)
    print("Saved primary metrics report to ml/reports/cv_metrics.json")

    # Production Model Export
    dominant_src = sources[0] if len(sources) > 0 else "synthetic"
    out_meta = "app/assets/ml/model_meta.json"
    out_weights = "ml/models/weights.json"

    # If --export_production is passed OR it's the standard synthetic cohort, export production weights
    if args.export_production or "synthetic" in sources:
        train_and_export_production_model(df, out_meta, out_weights, dominant_source=dominant_src)
        with open("ml/models/model_meta.json", "w", encoding="utf-8") as f:
            with open(out_meta, "r", encoding="utf-8") as src_file:
                f.write(src_file.read())

    print("\nML Training & Evaluation pipeline completed successfully.")
