# PulsePatch Lite — Feature Definitions & Mathematical Specifications

This specification is the binding mathematical contract between the Flutter/Dart application (`app/lib/domain/signal/`) and the Python Machine Learning pipeline (`ml/src/features.py`). Both implementations MUST pass the shared test vectors in `test_vectors.json` with an absolute numerical tolerance $\le 10^{-5}$.

---

## 1. Validity Gating Prerequisite

Only samples that successfully pass the **Validity Gate** are included in feature calculations:
- $30 \le \text{BPM} \le 220$
- Signal Quality score $\ge 60$
- $|\text{BPM}_t - \text{BPM}_{t-1}| \le 25\text{ BPM}$ between consecutive seconds
- Motion flag == 0 and Contact flag == 1

A session MUST contain at least **30 valid seconds** ($N \ge 30$) to be analyzable by statistics and ML. Sessions with $< 30$ valid samples are marked `Insufficient data`.

---

## 2. Core Feature Definitions

### 2.1 `mean_hr` (Mean Heart Rate)
The arithmetic sample mean of all valid BPM samples in the session:
$$\mu = \frac{1}{N} \sum_{i=1}^N \text{BPM}_i$$

### 2.2 `std_hr` (Sample Standard Deviation)
The sample standard deviation of valid BPM samples with Bessel's correction ($N-1$ degrees of freedom):
$$s = \sqrt{\frac{1}{N-1} \sum_{i=1}^N (\text{BPM}_i - \mu)^2}$$

### 2.3 `start_hr` (Initial Heart Rate)
The median BPM of valid samples recorded during the first 10 seconds of valid data ($t \in [0, 10\text{s}]$):
$$\text{start\_hr} = \text{median}(\{\text{BPM}_i \mid t_i \in [0, 10\text{s}]\})$$
*(For even count $M$, median is the arithmetic mean of the two middle values).*

### 2.4 `end_hr` (Final Heart Rate)
The median BPM of valid samples recorded during the last 10 seconds of valid data ($t \in [T_{\text{max}} - 10\text{s}, T_{\text{max}}]$):
$$\text{end\_hr} = \text{median}(\{\text{BPM}_i \mid t_i \in [T_{\text{max}} - 10\text{s}, T_{\text{max}}]\})$$

### 2.5 `recovery_drop` (Heart Rate Recovery Metric)
- **For Post-Activity Sessions:**
  - Requires total valid duration $T_{\text{valid}} \ge 70\text{ seconds}$.
  - Defined as the initial median BPM minus the median BPM in the recovery window between second 55 and second 65:
    $$\text{window\_60s\_hr} = \text{median}(\{\text{BPM}_i \mid t_i \in [55\text{s}, 65\text{s}]\})$$
    $$\text{recovery\_drop} = \text{start\_hr} - \text{window\_60s\_hr}$$
  - If the $[55\text{s}, 65\text{s}]$ window contains fewer than 5 valid samples, `recovery_drop` is `null` and the session is marked `Insufficient for AI`.
- **For Resting Sessions:**
  $$\text{recovery\_drop} = \text{start\_hr} - \text{end\_hr}$$

### 2.6 `variability_est_ms` (Pulse Interval Variability Estimate)
Standard deviation of successive differences (SDSD / RMSSD) computed from consecutive valid pulse intervals (in milliseconds):
$$\text{variability} = \sqrt{\frac{1}{K-1} \sum_{k=1}^{K-1} (\Delta I_k - \overline{\Delta I})^2}$$
where $\Delta I_k = I_{k+1} - I_k$ and $I_k \approx \frac{60000}{\text{BPM}_k}$.
*Labeled in the UI strictly as "Estimated variability", never as diagnostic HRV.*

---

## 3. Personal Baseline Statistical Comparison (z-score)

For user longitudinal comparison:
$$z = \frac{x_{\text{session}} - \mu_{\text{baseline}}}{\sigma_{\text{baseline}}}$$
- **Strict Guardrail:** Displayed ONLY when the user has at least **5 comparable prior sessions** of the same session protocol (resting or post-activity).
- **Communication Guardrail:** Strictly described in UI as **statistics** (sample z-score / baseline distance), NEVER as AI or medical assessment.
- Interpretation:
  - $|z| \le 1.0$: Typical for your baseline (within 1 SD)
  - $1.0 < |z| \le 2.0$: Mild variation from baseline
  - $|z| > 2.0$: Noticeable variation from baseline
