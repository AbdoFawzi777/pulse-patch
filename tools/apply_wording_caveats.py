import os

def update_final_report():
    with open('FINAL_REPORT.md', 'r', encoding='utf-8') as f:
        text = f.read()

    old_sec = """### Single-Subject Chronological Split Evaluation (`standard_hr`)
Evaluated strictly using time-ordered chronological session split (75% earlier train, 25% later test) without cross-subject leakage:
- **Train Partition (earlier sessions):** 2 sessions (`sess-1792996240842`, `sess-1793000580974`)
- **Test Partition (later session):** 1 session (`sess-1793010133841`)
- **Test Accuracy:** **100.00%** (Precision: 100%, Recall: 100%, F1: 100%)
- *Generalization Note:* Demonstrates pipeline stability on one subject's chronological data and does not make claims of population-wide generalization.

### 5-Fold GroupKFold Cross-Validation (All 11 Subjects, N=163 Sessions)
Grouped strictly by subject ID (`VOL_01`–`VOL_10` + `VOL_REAL_01` in Holdout Fold 1):

| Model Architecture | Mean Accuracy | Precision | Recall | F1 Score | ROC-AUC | Brier Loss |
|---|---|---|---|---|---|---|
| **Logistic Regression Baseline** | 92.61% ($\pm 4.3\%$) | 85.00% | 73.84% | 77.22% | 0.9597 | 0.0494 |
| **Random Forest Baseline** | 98.86% ($\pm 2.3\%$) | 100.00% | 95.56% | 97.50% | 0.9863 | 0.0101 |
| **Tiny MLP (Primary Model)** | **98.86%** ($\pm 2.3\%$) | **100.00%** | **95.56%** | **97.50%** | **0.9974** | **0.0131** |"""

    new_sec = """> [!IMPORTANT]
> **Cohort Composition Caveat & Generalization Boundary:** In this 11-subject cohort, 10 subjects (160 sessions) are synthetic simulation profiles and only 1 real subject with 3 sessions exists. Consequently, the 98.86% GroupKFold benchmark score mainly reflects synthetic-data performance and pipeline mathematical stability, NOT real-world generalization or clinical diagnostic accuracy. It must never stand alone as standalone "model accuracy".

### Single-Subject Integration / Pipeline Sanity Check (`standard_hr`, n=1 test session)
Evaluated strictly using time-ordered chronological session split (75% earlier train, 25% later test) without cross-subject leakage:
- **Train Partition (earlier sessions):** 2 sessions (`sess-1792996240842`, `sess-1793000580974`)
- **Test Partition (later session):** 1 session (`sess-1793010133841`)
- **Integration / Pipeline Sanity Check Result:** Passed successfully (1/1 test session correctly predicted; integration/pipeline sanity check on n=1 test session, not a statistical accuracy metric)
- *Generalization Note:* Serves as an end-to-end integration and pipeline sanity check demonstrating software workflow stability on one subject, and does not make claims of population-wide generalization or clinical accuracy.

### 5-Fold GroupKFold Cross-Validation (All 11 Subjects, N=163 Sessions)
Grouped strictly by subject ID (`VOL_01`–`VOL_10` + `VOL_REAL_01` in Holdout Fold 1):

| Model Architecture | Mean CV Score | Precision | Recall | F1 Score | ROC-AUC | Brier Loss | Evaluation Scope |
|---|---|---|---|---|---|---|---|
| **Logistic Regression Baseline** | 92.61% ($\pm 4.3\%$) | 85.00% | 73.84% | 77.22% | 0.9597 | 0.0494 | Synthetic-dominated benchmark |
| **Random Forest Baseline** | 98.86% ($\pm 2.3\%$) | 100.00% | 95.56% | 97.50% | 0.9863 | 0.0101 | Synthetic-dominated benchmark |
| **Tiny MLP (Primary Model)** | **98.86%** ($\pm 2.3\%$) | **100.00%** | **95.56%** | **97.50%** | **0.9974** | **0.0131** | Synthetic-dominated benchmark (10/11 subjects synthetic) |"""

    if old_sec in text:
        text = text.replace(old_sec, new_sec)
    elif old_sec.replace('\n', '\r\n') in text:
        text = text.replace(old_sec.replace('\n', '\r\n'), new_sec.replace('\n', '\r\n'))
    else:
        print("Warning: old_sec not matched in FINAL_REPORT.md")

    with open('FINAL_REPORT.md', 'w', encoding='utf-8') as f:
        f.write(text)
    print("FINAL_REPORT.md updated.")

def update_model_card():
    with open('docs/model_card.md', 'r', encoding='utf-8') as f:
        text = f.read()

    old_p = """3. **Cross-Validation & Evaluation Strategy:**
   - Multi-subject combined cohort (11 subjects): 5-Fold GroupKFold grouped strictly by subject_id (zero inter-subject leakage, VOL_REAL_01 in Holdout Fold 1). Tiny MLP achieved **98.86% Accuracy**, **100% Precision**, **97.50% F1**, and **0.9974 ROC-AUC**.
   - Single-subject real data: Time-ordered chronological split (2 earlier train, 1 later test) achieving **100% Accuracy**. Zero generalization claim across subjects."""

    new_p = """3. **Cross-Validation & Evaluation Strategy:**
   - Multi-subject combined cohort (11 subjects): 5-Fold GroupKFold grouped strictly by subject_id (zero inter-subject leakage, VOL_REAL_01 in Holdout Fold 1). Tiny MLP achieved **98.86%** on this benchmark (ROC-AUC: 0.9974).
     > [!WARNING]
     > **Cohort Composition Caveat:** 10 of the 11 subjects are synthetic simulation profiles and only 1 real subject with 3 sessions exists; this 98.86% benchmark score primarily reflects synthetic-data performance and mathematical stability, NOT real-world generalization or clinical diagnostic accuracy. It must not stand alone as "model accuracy".
   - Single-subject real data: Integration / pipeline sanity check (n=1 test session) using time-ordered chronological split (2 earlier train, 1 later test; n=1 test session passed). Serves as an end-to-end integration and pipeline sanity check, not a meaningful accuracy metric."""

    if old_p in text:
        text = text.replace(old_p, new_p)
    elif old_p.replace('\n', '\r\n') in text:
        text = text.replace(old_p.replace('\n', '\r\n'), new_p.replace('\n', '\r\n'))
    else:
        print("Warning: old_p not matched in docs/model_card.md")

    with open('docs/model_card.md', 'w', encoding='utf-8') as f:
        f.write(text)
    print("docs/model_card.md updated.")

def update_progress():
    with open('PROGRESS.md', 'r', encoding='utf-8') as f:
        text = f.read()

    text = text.replace(
        "Steps 1, 2, 3, 4 VERIFIED: 3 physical phone BLE sessions, 100% mathematical parity ($\\Delta=0.000000$), retraining on real data (98.86% acc, 0.9974 ROC-AUC), offline PDF generated; 179/179 tests pass",
        "Steps 1, 2, 3, 4 VERIFIED: 3 physical phone BLE sessions, 100% mathematical parity ($\\Delta=0.000000$), real-data pipeline integration sanity check (n=1 test session passed), combined GroupKFold (98.86% synthetic-dominated benchmark, 0.9974 ROC-AUC), offline PDF generated; 180/180 tests pass"
    )

    text = text.replace(
        "Sub-step 3: Evaluated single-subject time-ordered chronological split (2 earlier train, 1 later test): 100% Accuracy.",
        "Sub-step 3: Evaluated single-subject real data as an integration/pipeline sanity check (2 earlier train, 1 later test; n=1 test session passed, sanity check rather than generalizable accuracy metric)."
    )

    text = text.replace(
        "Sub-step 4: Evaluated 5-fold GroupKFold across all 11 subjects (`VOL_REAL_01` in Holdout Fold 1): Tiny MLP achieved **98.86% Accuracy**, **100.00% Precision**, **97.50% F1 Score**, and **0.9974 ROC-AUC**.",
        "Sub-step 4: Evaluated 5-fold GroupKFold across all 11 subjects (`VOL_REAL_01` in Holdout Fold 1): Tiny MLP achieved **98.86%** on this benchmark (100.00% Precision, 97.50% F1, 0.9974 ROC-AUC). *(Explicit Caveat: 10 of the 11 subjects are synthetic and only 1 real subject with 3 sessions exists; this metric mainly reflects synthetic-data performance and mathematical stability, not real-world generalization).* "
    )

    text = text.replace(
        "integrated into the combined training pipeline (98.86% accuracy, 0.9974 ROC-AUC), and exported as an offline PDF report.",
        "integrated into the combined training pipeline (98.86% synthetic-dominated benchmark, 0.9974 ROC-AUC; 10/11 subjects synthetic caveat), and exported as an offline PDF report."
    )

    with open('PROGRESS.md', 'w', encoding='utf-8') as f:
        f.write(text)
    print("PROGRESS.md updated.")

def update_field_test_report():
    with open('docs/field_test/FIELD_TEST_REPORT.md', 'r', encoding='utf-8') as f:
        text = f.read()

    text = text.replace(
        "- **Single-Subject Chronological Split (`standard_hr`):** 2 train / 1 test -> **100% Accuracy**.",
        "- **Single-Subject Pipeline Sanity Check (`standard_hr`):** 2 train / 1 test -> **Integration/pipeline sanity check passed (n=1 test session)** (not a generalizable accuracy metric)."
    )

    text = text.replace(
        "- **11-Subject 5-Fold GroupKFold:** Tiny MLP achieved **98.86% Accuracy**, **100.00% Precision**, **97.50% F1 Score**, and **0.9974 ROC-AUC**.",
        "- **11-Subject 5-Fold GroupKFold:** Tiny MLP achieved **98.86%** (100.00% Precision, 97.50% F1 Score, and 0.9974 ROC-AUC). *(Explicit Caveat: 10 of 11 subjects are synthetic simulation profiles and only 1 real subject with 3 sessions exists; this benchmark score mainly reflects synthetic-data performance and mathematical stability, not real-world generalization).*"
    )

    with open('docs/field_test/FIELD_TEST_REPORT.md', 'w', encoding='utf-8') as f:
        f.write(text)
    print("docs/field_test/FIELD_TEST_REPORT.md updated.")

if __name__ == '__main__':
    update_final_report()
    update_model_card()
    update_progress()
    update_field_test_report()
