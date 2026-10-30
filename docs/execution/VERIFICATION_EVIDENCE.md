# PulsePatch Lite — Verification Evidence Log

| Verification Item | Requirement / Metric | Actual Result Measured | Evidence Location | Status |
|---|---|---|---|---|
| **Git Baseline** | Clean master working tree | Commit `ef46409`, branch `master`, 0 uncommitted changes | `git status`, `git log -1` | `VERIFIED` |
| **Toolchain Baseline** | Flutter 3.38.9, Dart 3.10.8, Python 3.14.3 | Flutter 3.38.9, Dart 3.10.8, Python 3.14.3, NumPy 2.4.4, Scikit-Learn 1.9.1 | Terminal execution output | `VERIFIED` |
| **Test Suite Baseline** | All prior unit/widget tests pass | 311 / 311 passing tests | Prior verified audit run | `VERIFIED` |
| **"Taggel" Identification** | Resolves user dataset ambiguity | Identified as Kaggle / PPG-BP benchmark database (Liang et al., 219 subjects) | Web search & `DECISION_LOG.md` | `VERIFIED` |
| **Database Parity Baseline** | 6 tables, 40 columns | 100% schema match verified via `verify_erd_parity.py` | `docs/erd/DATA_DICTIONARY.md` | `VERIFIED` |
