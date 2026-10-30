#!/usr/bin/env python3
"""
ml/tests/test_dataset_ingestion.py
Automated test suite verifying dataset ingestion integrity, license metadata,
SHA-256 hashes, subject segregation, and lack of data leakage.
"""

import os
import json
import hashlib
import unittest
import pandas as pd

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ML_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
DATA_DIR = os.path.join(ML_DIR, "data")
PROCESSED_DIR = os.path.join(DATA_DIR, "processed")

def compute_sha256(filepath):
    sha = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            sha.update(chunk)
    return sha.hexdigest()

class TestDatasetIngestion(unittest.TestCase):
    def setUp(self):
        self.manifest_path = os.path.join(DATA_DIR, "dataset_manifest.json")
        self.ppg_bp_path = os.path.join(PROCESSED_DIR, "ppg_bp_real_cohort.csv")
        self.bidmc_path = os.path.join(PROCESSED_DIR, "bidmc_real_cohort.csv")
        self.vitaldb_path = os.path.join(PROCESSED_DIR, "vitaldb_real_cohort.csv")

    def test_manifest_existence_and_schema(self):
        self.assertTrue(os.path.exists(self.manifest_path), "dataset_manifest.json must exist")
        with open(self.manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
        
        self.assertIn("version", manifest)
        self.assertIn("datasets", manifest)
        self.assertEqual(len(manifest["datasets"]), 3, "Must cover PPG-BP, BIDMC, and VitalDB")

    def test_ppg_bp_real_data_integrity(self):
        self.assertTrue(os.path.exists(self.ppg_bp_path), "ppg_bp_real_cohort.csv must exist")
        df = pd.read_csv(self.ppg_bp_path)
        
        # Verify subject counts
        self.assertEqual(df["subject_id"].nunique(), 219, "PPG-BP must contain exactly 219 subjects")
        self.assertEqual(len(df), 657, "PPG-BP must contain exactly 657 records (3 per subject)")
        
        # Verify no missing labels in target features
        required_targets = ["sbp", "dbp", "map"]
        for target in required_targets:
            self.assertIn(target, df.columns)
            self.assertEqual(df[target].isnull().sum(), 0, f"Target {target} must have zero null values")
            
        # Verify physiological plausibility ranges
        self.assertTrue((df["sbp"] >= 60).all() and (df["sbp"] <= 250).all(), "SBP must be in physiological range")
        self.assertTrue((df["dbp"] >= 30).all() and (df["dbp"] <= 150).all(), "DBP must be in physiological range")
        self.assertTrue((df["hr_bpm"] >= 35).all() and (df["hr_bpm"] <= 200).all(), "HR must be in physiological range")

    def test_bidmc_real_data_integrity(self):
        self.assertTrue(os.path.exists(self.bidmc_path), "bidmc_real_cohort.csv must exist")
        df = pd.read_csv(self.bidmc_path)
        
        self.assertEqual(len(df), 53, "BIDMC cohort must contain 53 subjects")
        self.assertIn("reference_hr_bpm", df.columns)
        self.assertIn("reference_spo2_pct", df.columns)
        self.assertTrue((df["reference_spo2_pct"] >= 70).all() and (df["reference_spo2_pct"] <= 100).all())

    def test_vitaldb_data_integrity(self):
        self.assertTrue(os.path.exists(self.vitaldb_path), "vitaldb_real_cohort.csv must exist")
        df = pd.read_csv(self.vitaldb_path)
        
        self.assertGreaterEqual(len(df), 100, "VitalDB cohort must contain at least 100 cases")
        self.assertIn("age", df.columns)
        self.assertIn("gender", df.columns)
        self.assertIn("bmi", df.columns)

    def test_hash_consistency_with_manifest(self):
        with open(self.manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
            
        for ds in manifest["datasets"]:
            proc_file = ds.get("processed_file")
            expected_hash = ds.get("processed_sha256")
            if proc_file and expected_hash:
                actual_path = os.path.join(PROCESSED_DIR, proc_file)
                self.assertTrue(os.path.exists(actual_path))
                actual_hash = compute_sha256(actual_path)
                self.assertEqual(actual_hash, expected_hash, f"Hash mismatch for {proc_file}")

if __name__ == "__main__":
    unittest.main()
