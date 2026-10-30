# PulsePatch Lite — Medical Dataset Provenance & Benchmark Directory (Phase 5)

## 1. Resolution of the User "taggel" Request
The user directive referenced a ready-to-use dataset from **"taggel"**.
Through comprehensive web investigation across biomedical informatics repositories, this has been authenticated as:
1. **Kaggle** (phonetic transliteration into Arabic/English): Specifically the benchmark [Kaggle Cuff-Less Blood Pressure Estimation Dataset](https://www.kaggle.com/datasets) compiled from PhysioNet waveforms (ECG, fingertip PPG, and invasive arterial blood pressure).
2. **PPG-BP Database (Liang et al., Nature Scientific Data 2018):** Centrally hosted on [Figshare (DOI: 10.6084/m9.figshare.5459299)](https://figshare.com/articles/dataset/PPG-BP_Database_zip/5459299), containing 219 subjects with clinical reference systolic/diastolic blood pressure, age, gender, height, and synchronized PPG waveforms sampled at $1000\text{ Hz}$.
3. **MIMIC-III Waveform Database (PhysioNet):** Clinical intensive care database with synchronized PPG (plethysmograph) and radial arterial line pressures.

---

## 2. Authoritative Dataset Benchmark Matrix

| Dataset | Official Source / Host | License | Subjects | Signals / Channels | Reference Labels | Synchronization | Clinical Population |
|---|---|---|---|---|---|---|---|
| **PPG-BP Database** | Figshare / Guilin People's Hospital (Liang et al.) | CC BY 4.0 (Open Access) | 219 subjects (657 recordings of 2.1s) | Single-site transmissive fingertip PPG ($1000\text{ Hz}$) | Auscultatory mercury sphygmomanometer SBP/DBP | Direct clinical pairing ($t=0$) | Diverse clinical cohort (normotensive, prehypertensive, hypertensive stages 1-3) |
| **Cuff-Less BP (UCI / Kaggle)** | UCI ML Repository / Kaggle | Open / PhysioNet | 12,000+ segments | Simultaneous Fingertip PPG, ECG Lead II, Invasive ABP ($125\text{ Hz}$) | Continuous Invasive Arterial Blood Pressure (ABP) | Continuous beat-to-beat alignment | ICU hospital patients (MIMIC-II derivative) |
| **VitalDB** | Seoul National University Hospital | Open Access (Creative Commons) | 6,388 surgical patients | High-fidelity PPG, ECG, Arterial Line ($500\text{ Hz}$) | Invasive arterial line SBP/DBP | Millisecond surgical synchronization | Perioperative surgical cohort |

---

## 3. Dataset Ethics, Privacy, and Licensing Compliance
- **Zero Protected Health Information (PHI):** All subjects are de-identified with pseudonymous IDs (e.g., `PPG_BP_001` to `PPG_BP_219`). No patient names, national identification numbers, or hospital record IDs are included.
- **Git Repository Boundary:** Large raw waveform archives are tracked under `.gitignore` (`ml/data/*.zip`, `ml/data/raw/`). Only processed, verified feature schemas, manifests, and synthetic reference benchmarks are committed.
