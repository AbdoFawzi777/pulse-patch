---
name: biomedical-signal-processing
description: Photoplethysmogram (PPG) signal interpretation, dual-wavelength SpO2 ratio-of-ratios calibration, baseline wander filtration, motion artifact gating, and pulse morphological feature extraction.
---

# Biomedical Signal Processing Skill

## 1. Purpose
Provides authoritative, scientifically grounded procedures for processing raw single- and dual-channel photoplethysmogram (PPG) signals acquired from optical sensors (such as MAX30102). Covers noise rejection, beat segmentation, Signal Quality Index (SQI) formulation, physiological heart rate estimation, and dual-wavelength oxygen saturation ($SpO_2$) calculation.

## 2. When to Use
- Implementing or auditing PPG digital filtering (IIR DC removal, bandpass filter $0.5 - 5.0\text{ Hz}$, moving median).
- Calculating dual-wavelength $SpO_2$ using the calibration curve $R = \frac{AC_{red}/DC_{red}}{AC_{ir}/DC_{ir}}$.
- Formulating waveform signal quality metrics and detecting motion corruption.
- Extracting morphological pulse features for downstream blood pressure modeling.

## 3. Required Inputs
- Raw time-series samples from Red ($660\text{ nm}$) and Infrared ($880\text{ nm}$) optical channels.
- Sampling rate $f_s$ (default $100\text{ Hz}$).
- Per-sample or batch timestamps ($t\text{ ms}$).

## 4. Expected Outputs
- DC-removed pulsatile AC signal waveform.
- Beat-to-beat Inter-Beat Intervals (IBI) in milliseconds.
- Filtered Heart Rate (BPM).
- Calibrated $SpO_2$ percentage ($70\% - 100\%$) with valid perfusion flags.
- Multidimensional Signal Quality Index ($SQI \in [0, 100]$).
- Extracted pulse landmark points (systolic peak, dicrotic notch, diastolic peak).

## 5. Practical Workflow
1. **DC Offset Removal:** Apply 1st-order IIR high-pass filter ($y[n] = x[n] - x[n-1] + \alpha y[n-1]$ with $\alpha \approx 0.95$) to isolate pulsatile microvascular changes from static tissue absorption.
2. **Bandpass Filtering:** Suppress high-frequency sensor quantization noise and powerline ripple using a Butterworth filter or fast 5-sample median window.
3. **Perfusion Index & Contact Verification:** Check $DC_{ir} > 50,000\text{ counts}$. Flag contact loss if amplitude is sub-threshold.
4. **$SpO_2$ Ratio-of-Ratios:**
   - Extract peak-to-peak AC and mean DC for both Red and IR.
   - Compute $R = (AC_{red} / DC_{red}) / (AC_{ir} / DC_{ir})$.
   - Convert to saturation using empirical empirical calibration: $SpO_2 = 110 - 25 \times R$ (clamped to $[70.0, 100.0]$).
5. **Peak Detection:** Employ adaptive thresholding and refractory periods ($270\text{ ms} \approx 220\text{ BPM}$) to locate systolic peaks.

## 6. Verification Criteria
- $SpO_2$ must yield null/abstain when finger is off or $SQI < 60$.
- HR must clamp within physiological bounds ($30 - 220\text{ BPM}$).
- Maximum rate jump $\le 30\text{ BPM/s}$.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never convert raw IR LED counts directly into $SpO_2$ percentage.
- **Prohibited:** Never simulate $SpO_2$ using arbitrary random noise or a fixed $98\%$ constant without optical ratios.
- **Limitation:** Motion artifacts can mimic optical pulsations; strict SQI gating must suppress corrupted frames.
