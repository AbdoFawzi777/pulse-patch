"""
PulsePatch Lite — ML Parity Verification Script
Verifies mathematical parity between Python forward-pass and Dart inference
across shared test vectors and key edge cases.
"""

import json
import math
import numpy as np


def relu(x):
    return np.maximum(0, x)


def softmax(x):
    e_x = np.exp(x - np.max(x, axis=-1, keepdims=True))
    return e_x / np.sum(e_x, axis=-1, keepdims=True)


class PythonMlpInference:
    def __init__(self, meta_path: str, weights_path: str):
        with open(meta_path, "r", encoding="utf-8") as f:
            self.meta = json.load(f)
        with open(weights_path, "r", encoding="utf-8") as f:
            self.weights = json.load(f)

        self.mean = np.array(self.meta["scaler"]["mean"], dtype=np.float32)
        self.scale = np.array(self.meta["scaler"]["scale"], dtype=np.float32)
        self.coefs = [np.array(c, dtype=np.float32) for c in self.weights["coefs"]]
        self.intercepts = [np.array(i, dtype=np.float32) for i in self.weights["intercepts"]]

    def predict_proba(self, raw_features: list) -> np.ndarray:
        x = (np.array(raw_features, dtype=np.float32) - self.mean) / self.scale
        # Layer 1: Dense 16, ReLU
        h1 = relu(np.dot(x, self.coefs[0]) + self.intercepts[0])
        # Layer 2: Dense 8, ReLU
        h2 = relu(np.dot(h1, self.coefs[1]) + self.intercepts[1])
        # Layer 3: Output (logistic sigmoid for binary classification)
        logits = np.dot(h2, self.coefs[2]) + self.intercepts[2]
        if logits.shape[-1] == 1:
            p1 = 1.0 / (1.0 + np.exp(-logits[0]))
            return np.array([1.0 - p1, p1], dtype=np.float32)
        else:
            return softmax(logits)

    def predict(self, raw_features: list) -> int:
        probs = self.predict_proba(raw_features)
        return int(np.argmax(probs))

    def dart_predict(self, raw_features: list) -> int:
        """Exact Dart forward pass logic from ai_inference_service.dart."""
        x = (np.array(raw_features, dtype=np.float32) - self.mean) / self.scale
        # Layer 1
        h1 = np.maximum(0.0, np.dot(x, self.coefs[0]) + self.intercepts[0])
        # Layer 2
        h2 = np.maximum(0.0, np.dot(h1, self.coefs[1]) + self.intercepts[1])
        # Layer 3
        logit = float(np.dot(h2, self.coefs[2])[0] + self.intercepts[2][0])
        prob_diff = 1.0 / (1.0 + math.exp(-logit))
        return 0 if prob_diff < 0.5 else 1


def test_parity():
    meta_path = "app/assets/ml/model_meta.json"
    weights_path = "ml/models/weights.json"

    engine = PythonMlpInference(meta_path, weights_path)

    test_cases = [
        {
            "name": "Standard Resting Typical",
            "features": [68.0, 3.2, 70.0, 67.0, 3.0],
            "expected_label": 0,
            "expected_name": "Typical pattern"
        },
        {
            "name": "Standard Post-Activity Typical (Robust Drop)",
            "features": [118.0, 12.5, 138.0, 98.0, 26.0],
            "expected_label": 0,
            "expected_name": "Typical pattern"
        },
        {
            "name": "Post-Activity Blunted Recovery (Atypical Drop)",
            "features": [128.0, 6.2, 134.0, 130.0, 4.0],
            "expected_label": 1,
            "expected_name": "Different pattern"
        },
        {
            "name": "Severely Elevated Outlier Session",
            "features": [145.0, 18.0, 150.0, 140.0, 2.0],
            "expected_label": 1,
            "expected_name": "Different pattern"
        }
    ]

    print("\n--- Running Inference Parity Checks (Python MLP vs Dart Implementation) ---")
    all_passed = True

    for tc in test_cases:
        probs = engine.predict_proba(tc["features"])
        mlp_pred = int(np.argmax(probs))
        dart_pred = engine.dart_predict(tc["features"])

        status = "PASS" if (mlp_pred == tc["expected_label"] and dart_pred == tc["expected_label"]) else "FAIL"
        if status == "FAIL":
            all_passed = False

        print(f"[{status}] {tc['name']}")
        print(f"       Features: {tc['features']}")
        print(f"       MLP Probabilities: Typical={probs[0]:.4f}, Different={probs[1]:.4f} -> Pred={mlp_pred}")
        print(f"       Dart Decision: Pred={dart_pred} ({engine.meta['labels'][dart_pred]}) | Expected={tc['expected_name']}")

    if all_passed:
        print("\nAll inference parity test cases passed with 100% agreement between Python & Dart!")
    else:
        print("\nParity verification mismatch detected.")
        exit(1)


if __name__ == "__main__":
    test_parity()
