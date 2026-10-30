#!/usr/bin/env python3
"""
PulsePatch Lite v2.0 - Systematic Blood Pressure Model & Feature Optimization Benchmark
Evaluates candidate models across base vs engineered features using strict Subject-Wise GroupKFold.
"""

import json
import os
import numpy as np
import pandas as pd
from sklearn.model_selection import GroupKFold
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Ridge, ElasticNet, HuberRegressor, BayesianRidge, Lasso
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor, ExtraTreesRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.metrics import mean_absolute_error, root_mean_squared_error

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(SCRIPT_DIR, "..", "data", "processed", "ppg_bp_real_cohort.csv")

def bhs_grade(errors):
    abs_errors = np.abs(errors)
    p5 = float(np.mean(abs_errors <= 5) * 100)
    p10 = float(np.mean(abs_errors <= 10) * 100)
    p15 = float(np.mean(abs_errors <= 15) * 100)
    if p5 >= 60 and p10 >= 85 and p15 >= 95:
        grade = "A"
    elif p5 >= 50 and p10 >= 75 and p15 >= 90:
        grade = "B"
    elif p5 >= 40 and p10 >= 65 and p15 >= 85:
        grade = "C"
    else:
        grade = "D"
    return grade, p5, p10, p15

def run_evaluation():
    df = pd.read_csv(DATA_PATH)
    print(f"Loaded {len(df)} records across {df['subject_id'].nunique()} unique subjects.")

    # Base features
    base_cols = [
        "age", "gender", "bmi", "hr_bpm",
        "crest_time_ms", "decay_time_ms", "pw50_ms",
        "area_ratio", "reflection_index", "stiffness_index"
    ]

    # Engineered features (physiologically motivated)
    df_feat = df.copy()
    total_time = (df_feat["crest_time_ms"] + df_feat["decay_time_ms"]).replace(0, 1)
    df_feat["duty_cycle"] = df_feat["crest_time_ms"] / total_time
    df_feat["crest_decay_ratio"] = df_feat["crest_time_ms"] / df_feat["decay_time_ms"].replace(0, 1)
    df_feat["pw50_relative"] = df_feat["pw50_ms"] / total_time
    df_feat["age_stiffness"] = df_feat["age"] * df_feat["stiffness_index"]
    df_feat["bmi_stiffness"] = df_feat["bmi"] * df_feat["stiffness_index"]
    df_feat["hr_crest"] = df_feat["hr_bpm"] * (df_feat["crest_time_ms"] / 1000.0)
    df_feat["refl_stiff"] = df_feat["reflection_index"] * df_feat["stiffness_index"]

    eng_cols = base_cols + [
        "duty_cycle", "crest_decay_ratio", "pw50_relative",
        "age_stiffness", "bmi_stiffness", "hr_crest", "refl_stiff"
    ]

    feature_sets = {
        "Base_10": base_cols,
        "Eng_17": eng_cols,
    }

    model_factories = {
        "Ridge_a1.0": lambda: Ridge(alpha=1.0),
        "Ridge_a10.0": lambda: Ridge(alpha=10.0),
        "Ridge_a50.0": lambda: Ridge(alpha=50.0),
        "Huber": lambda: HuberRegressor(epsilon=1.35, alpha=1.0, max_iter=500),
        "BayesianRidge": lambda: BayesianRidge(),
        "ElasticNet": lambda: ElasticNet(alpha=0.1, l1_ratio=0.5, random_state=42),
        "RandomForest_d6": lambda: RandomForestRegressor(n_estimators=100, max_depth=6, min_samples_leaf=3, random_state=42),
        "ExtraTrees_d6": lambda: ExtraTreesRegressor(n_estimators=100, max_depth=6, min_samples_leaf=3, random_state=42),
        "GBDT_d3": lambda: GradientBoostingRegressor(n_estimators=80, max_depth=3, learning_rate=0.05, subsample=0.8, random_state=42),
        "MLP_32x16": lambda: MLPRegressor(hidden_layer_sizes=(32, 16), activation='relu', alpha=0.05, max_iter=800, random_state=42),
        "MLP_16x8": lambda: MLPRegressor(hidden_layer_sizes=(16, 8), activation='relu', alpha=0.1, max_iter=800, random_state=42),
    }

    groups = df["subject_id"].values
    gkf = GroupKFold(n_splits=5)
    
    benchmark_results = []

    for fset_name, cols in feature_sets.items():
        X = df_feat[cols].values
        y_sbp = df_feat["sbp"].values
        y_dbp = df_feat["dbp"].values

        for m_name, m_fact in model_factories.items():
            sbp_preds = np.zeros(len(df_feat))
            dbp_preds = np.zeros(len(df_feat))

            for train_idx, test_idx in gkf.split(X, y_sbp, groups=groups):
                X_train, X_test = X[train_idx], X[test_idx]
                y_sbp_train = y_sbp[train_idx]
                y_dbp_train = y_dbp[train_idx]

                scaler = StandardScaler()
                X_train_s = scaler.fit_transform(X_train)
                X_test_s = scaler.transform(X_test)

                sbp_m = m_fact()
                dbp_m = m_fact()

                sbp_m.fit(X_train_s, y_sbp_train)
                dbp_m.fit(X_train_s, y_dbp_train)

                sbp_preds[test_idx] = sbp_m.predict(X_test_s)
                dbp_preds[test_idx] = dbp_m.predict(X_test_s)

            sbp_err = sbp_preds - y_sbp
            dbp_err = dbp_preds - y_dbp

            sbp_mae = float(mean_absolute_error(y_sbp, sbp_preds))
            sbp_rmse = float(root_mean_squared_error(y_sbp, sbp_preds))
            sbp_sde = float(np.std(sbp_err))
            sbp_bias = float(np.mean(sbp_err))
            sbp_r = float(np.corrcoef(y_sbp, sbp_preds)[0, 1])

            dbp_mae = float(mean_absolute_error(y_dbp, dbp_preds))
            dbp_rmse = float(root_mean_squared_error(y_dbp, dbp_preds))
            dbp_sde = float(np.std(dbp_err))
            dbp_bias = float(np.mean(dbp_err))
            dbp_r = float(np.corrcoef(y_dbp, dbp_preds)[0, 1])

            sbp_grade, sbp_p5, sbp_p10, sbp_p15 = bhs_grade(sbp_err)
            dbp_grade, dbp_p5, dbp_p10, dbp_p15 = bhs_grade(dbp_err)

            benchmark_results.append({
                "features": fset_name,
                "model": m_name,
                "sbp_mae": sbp_mae,
                "sbp_rmse": sbp_rmse,
                "sbp_sde": sbp_sde,
                "sbp_bias": sbp_bias,
                "sbp_r": sbp_r,
                "sbp_bhs": sbp_grade,
                "sbp_p5": sbp_p5,
                "dbp_mae": dbp_mae,
                "dbp_rmse": dbp_rmse,
                "dbp_sde": dbp_sde,
                "dbp_bias": dbp_bias,
                "dbp_r": dbp_r,
                "dbp_bhs": dbp_grade,
                "dbp_p5": dbp_p5,
            })

    res_df = pd.DataFrame(benchmark_results)
    # Sort by SBP MAE ascending
    res_df = res_df.sort_values(by="sbp_mae")
    
    print("\n" + "=" * 90)
    print("BENCHMARK RESULTS (SUBJECT-WISE 5-FOLD GROUPKFOLD)")
    print("=" * 90)
    print(res_df.to_string(index=False))

    out_csv = os.path.join(SCRIPT_DIR, "..", "reports", "model_optimization_benchmark.csv")
    os.makedirs(os.path.dirname(out_csv), exist_ok=True)
    res_df.to_csv(out_csv, index=False)
    print(f"\nSaved benchmark results to {out_csv}")

if __name__ == "__main__":
    run_evaluation()
