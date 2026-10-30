---
name: health-analytics-reporting
description: Longitudinal health analytics, baseline tracking, trend calculations, statistical summary aggregation, and 100% offline clinical-grade PDF generation in Arabic and English.
---

# Health Analytics and Clinical Reporting Skill

## 1. Purpose
Governs the calculation of personalized biometric trends, historical baseline shifts, physiological recovery indices, and the generation of comprehensive daily, monthly, and annual clinical-grade PDF reports.

## 2. When to Use
- Aggregating longitudinal data across days, weeks, months, or years.
- Calculating user-specific baselines (Resting HR baseline, mean arterial pressure trends, recovery rate distribution).
- Generating offline, self-contained PDF biomonitoring reports using the `pdf` and `printing` packages.
- Formatting bilingual documents with proper Arabic RTL font shaping and English LTR alignment.

## 3. Required Inputs
- Historical session records and statistical summaries from local SQLite storage.
- Active user profile data (Age, Gender, Height, Weight, BMI).
- Date range filter (Daily, Weekly, Monthly, Annual, Custom).

## 4. Expected Outputs
- Dynamic trend matrices (Average resting pulse, SBP/DBP ranges, recovery drop trajectories).
- Standalone `.pdf` documents with consistent pagination, embedded charts, clear data provenance badges, and non-diagnostic disclaimers.

## 5. Practical Workflow
1. **Data Aggregation:** Query historical sessions within the date window. Filter out sessions with $<50\%$ valid samples.
2. **Trend Analytics:** Compute 7-day and 30-day moving averages. Identify statistical deviations ($\pm 2\sigma$) from user baseline.
3. **Data Provenance Separation:** Tag every metric in the report with its true source:
   - *Direct Measurement* (Physical sensor BLE stream).
   - *Model Estimate* (AI/Mathematical algorithm prediction).
   - *Derived Metric* (Statistical aggregation).
   - *User Provided* (Self-reported metadata).
4. **Bilingual PDF Rendering:** Utilize custom TTF fonts supporting Arabic glyphs and layout tables with exact column dimensions.

## 6. Verification Criteria
- PDF generation must succeed 100% offline without network calls.
- Empty data periods must render clean empty-state summaries rather than throwing exceptions or fabricating fake readings.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never fill missing historical days with fake synthetic readings to make charts look complete.
- **Prohibited:** Never format clinical recommendations as medical prescriptions.
- **Limitation:** Trends require at least 5 consistent valid sessions before establishing a dependable baseline.
