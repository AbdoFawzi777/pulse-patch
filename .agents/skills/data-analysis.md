# Data Analysis & Validation Playbook

**Role:** ML and Data Engineer / Statistics Engineer  
**Objective:** Deliver quantitative validation reports, Bland-Altman agreement studies, and recovery profiling for the graduation team presentation.

## Deliverables
1. **Sensor Validation Report (`docs/sensor_validation_report.md`):**
   - MAX30102 optical sensor BPM vs Reference device (chest strap / commercial pulse oximeter).
   - Metrics: Mean Absolute Error (MAE), Mean Absolute Percentage Error (MAPE), Pearson $r$.
   - Bland-Altman bias, limits of agreement ($95\% \text{ LoA}$), stratified by Rest vs Post-activity and signal quality.
2. **Recovery Dynamics Study (`docs/recovery_analysis_report.md`):**
   - Distributions of `recovery_drop` across resting vs post-exercise recovery sessions.
   - Volunteer recovery profiling and baseline consistency.
3. **Signal Quality & Motion Study:**
   - Impact of motion artifacts and fingertip contact pressure on PPG waveform morphology.
   - Empirically derived thresholds for the Phase 5 validity gate.
