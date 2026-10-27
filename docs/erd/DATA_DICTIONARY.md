# PulsePatch Lite — Database Data Dictionary

> **Scope:** Authoritative schema reference for the local SQLite database engine (`pulse_patch.db`) created by `AppDatabase` via Pure C / FFI.  
> **Schema Version:** `2` (Managed with `PRAGMA user_version = 2;`)  
> **Foreign Keys Enforcement:** `PRAGMA foreign_keys = ON;` enabled at connection initialization ([`app_database.dart:45`](file:///e:/pulse%20patch/app/lib/data/drift/app_database.dart#L45)).

---

## 1. Schema Overview & Relational Architecture

The database consists of **6 tables** and **1 index**:
- **`sessions`**: Root entity recording measurement sessions.
- **`samples`**: High-frequency time-series telemetry records linked 1:N to `sessions`.
- **`session_stats`**: Precomputed 11-feature summary linked 1:1 to `sessions`.
- **`ai_results`**: On-device machine learning inference output linked 1:1 to `sessions`.
- **`reminders`**: Standalone user schedule for local daily measurement notifications.
- **`app_settings`**: Standalone key-value store for global runtime configurations.

All relational child tables (`samples`, `session_stats`, `ai_results`) enforce **`ON DELETE CASCADE`** against `sessions(id)`: deleting a session cleanly purges its samples, statistics, and AI classifications in an atomic operation.

---

## 2. Table-by-Table Data Dictionary

### 2.1 Table: `sessions`
* **Purpose:** Stores top-level metadata, configuration, protocol type, and temporal boundaries for each recorded pulse measurement session.
* **Cardinality:** 1 session contains 0..N `samples`, 0..1 `session_stats`, and 0..1 `ai_results`.

| Column Name | SQL Type | Dart Type | Constraints | Nullable | Default | Unit / Format | Description & Domain Values |
|---|---|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | `PRIMARY KEY` | NO | None | UUIDv4 | Unique session identifier generated at session creation. |
| `started_at` | `INTEGER` | `DateTime` | `NOT NULL` | NO | None | Epoch Milliseconds | Unix epoch timestamp when recording started. |
| `ended_at` | `INTEGER` | `DateTime?` | None | YES | `NULL` | Epoch Milliseconds | Unix epoch timestamp when recording terminated. Null if session is currently active or aborted prematurely. |
| `type` | `TEXT` | `SessionType` | `NOT NULL` | NO | None | Enum String | Protocol mode: <br>• `'rest'`: 60-second baseline resting pulse protocol.<br>• `'postActivity'`: 90-second recovery drop protocol. |
| `quality_summary` | `TEXT` | `QualitySummary` | `NOT NULL` | NO | None | Enum String | Aggregate signal quality assessment: <br>• `'good'`: Valid samples $\ge 80\%$.<br>• `'fair'`: Valid samples $50\% - 79\%$.<br>• `'weak'`: Valid samples $< 50\%$. |
| `app_version` | `TEXT` | `String` | `NOT NULL` | NO | None | SemVer String | Mobile application version active during recording (e.g. `'1.0.0+2'`). |
| `source` | `TEXT` | `SessionSource` | `NOT NULL` | NO | None | Enum Code String | Ingestion telemetry origin: <br>• `'pulsepatch'`: Custom ESP32-C3 hardware patch over BLE.<br>• `'standard_hr'`: Standard BLE GATT 0x180D heart rate peripheral.<br>• `'generic_ble'`: Generic BLE biometric provider.<br>• `'miband5'`: Xiaomi Mi Smart Band 5 peripheral.<br>• `'import'`: CSV/JSON offline imported recording.<br>• `'simulator'`: Internal deterministic pulse generator. |

---

### 2.2 Table: `samples`
* **Purpose:** High-frequency, time-series telemetry samples captured second-by-second from the sensor or simulation pipeline.
* **Index:** `CREATE INDEX idx_samples_session_id ON samples (session_id);` for fast temporal series lookups.

| Column Name | SQL Type | Dart Type | Constraints | Nullable | Default | Unit / Format | Description & Classification |
|---|---|---|---|---|---|---|---|
| `id` | `INTEGER` | `int?` | `PRIMARY KEY AUTOINCREMENT` | NO | None | Monotonic Integer | Internal database autoincrement sequence key. |
| `session_id` | `TEXT` | `String` | `NOT NULL`, `REFERENCES sessions(id) ON DELETE CASCADE` | NO | None | UUIDv4 | Foreign key referencing the parent session. |
| `t_ms` | `INTEGER` | `int` | `NOT NULL` | NO | None | Milliseconds (ms) | Relative offset timestamp from the start of the session ($t=0$). |
| `bpm` | `REAL` | `double?` | None | YES | `NULL` | Beats Per Minute (BPM) | **Raw/Filtered Measurement:** Pulse rate calculated by sensor/DSP. `NULL` if sensor is in calculating state (`0xFFFF`). |
| `quality` | `INTEGER` | `int` | `NOT NULL` | NO | None | Percent ($0 - 100$) | **Raw Metric:** Signal Quality Index (SQI) derived from optical waveform SNR, amplitude consistency, and motion flags. |
| `is_valid` | `INTEGER` | `bool` | `NOT NULL` | NO | None | Boolean ($0$ or $1$) | **Gating Flag:** Derived indicator ($1 = \text{valid}$, $0 = \text{invalid}$) indicating whether sample passed $SQI \ge 60$ and physiological jump limits. |
| `spo2` | `REAL` | `double?` | Added in Migration v2 | YES | `NULL` | Percentage ($\%$) | **Raw/Telemetry:** Blood oxygen saturation level if reported by peripheral hardware; otherwise `NULL`. |

---

### 2.3 Table: `session_stats`
* **Purpose:** Stores precomputed mathematical summary metrics and 11 statistical features extracted from valid samples ($SQI \ge 60$) of a completed session.
* **Relationship:** 1:1 with `sessions(id)` (Primary key is also Foreign Key).

| Column Name | SQL Type | Dart Type | Constraints | Nullable | Default | Unit / Format | Description & Nature (Raw vs Derived) |
|---|---|---|---|---|---|---|---|
| `session_id` | `TEXT` | `String` | `PRIMARY KEY`, `REFERENCES sessions(id) ON DELETE CASCADE` | NO | None | UUIDv4 | Primary and foreign key referencing `sessions(id)`. |
| `mean_hr` | `REAL` | `double` | `NOT NULL` | NO | None | BPM | **Derived:** Arithmetic mean of valid heart rate readings $\mu = \frac{1}{N}\sum \text{BPM}_i$. |
| `std_hr` | `REAL` | `double` | `NOT NULL` | NO | None | BPM | **Derived:** Standard deviation of valid heart rate readings $\sigma = \sqrt{\frac{1}{N-1}\sum (\text{BPM}_i - \mu)^2}$. |
| `min_hr` | `REAL` | `double` | `NOT NULL` | NO | None | BPM | **Derived:** Lowest valid heart rate recorded in session. |
| `max_hr` | `REAL` | `double` | `NOT NULL` | NO | None | BPM | **Derived:** Highest valid heart rate recorded in session. |
| `start_hr` | `REAL` | `double` | `NOT NULL` | NO | None | BPM | **Derived:** Average heart rate during the initial 10 seconds of the session. |
| `end_hr` | `REAL` | `double` | `NOT NULL` | NO | None | BPM | **Derived:** Average heart rate during the final 10 seconds of the session. |
| `recovery_drop` | `REAL` | `double?` | None | YES | `NULL` | BPM | **Derived:** Post-activity heart rate recovery drop ($\text{start\_hr} - \text{end\_hr}$). Relevant for post-activity sessions; `NULL` for resting. |
| `pulse_interval_ms` | `REAL` | `double?` | None | YES | `NULL` | Milliseconds (ms) | **Derived:** Estimated mean inter-beat interval: $60000 / \text{mean\_hr}$. |
| `variability_est_ms`| `REAL` | `double?` | None | YES | `NULL` | Milliseconds (ms) | **Derived:** Short-term pulse rate variability estimate derived from adjacent sample differences. |
| `valid_sample_count`| `INTEGER` | `int` | `NOT NULL` | NO | None | Count | **Derived:** Total number of accepted samples with $SQI \ge 60$. |
| `total_duration_seconds`| `INTEGER` | `int`| `NOT NULL` | NO | None | Seconds (s) | **Derived:** Total elapsed wall-clock recording duration. |
| `avg_spo2` | `REAL` | `double?` | Added in Migration v2 | YES | `NULL` | Percentage ($\%$) | **Derived:** Arithmetic average of valid SpO2 telemetry across the session. |

---

### 2.4 Table: `ai_results`
* **Purpose:** Stores on-device machine learning inference classifications and model execution metadata for a session.
* **Relationship:** 1:1 with `sessions(id)` (Primary key is also Foreign Key).

| Column Name | SQL Type | Dart Type | Constraints | Nullable | Default | Unit / Format | Description & Nature |
|---|---|---|---|---|---|---|---|
| `session_id` | `TEXT` | `String` | `PRIMARY KEY`, `REFERENCES sessions(id) ON DELETE CASCADE` | NO | None | UUIDv4 | Primary and foreign key referencing `sessions(id)`. |
| `model_version` | `TEXT` | `String` | `NOT NULL` | NO | None | Version String | Identifier of on-device neural network (e.g. `'1.0.0-tiny-mlp'`). |
| `label` | `TEXT` | `String` | `NOT NULL` | NO | None | Categorical String | **Derived Classification:** Educational pattern label: <br>• `'Typical pattern'`: Recovery or resting trajectory conforms to expected physiological decline.<br>• `'Different pattern'`: Recovery curve displays sluggish descent or plateau. |
| `features_json` | `TEXT` | `String` | `NOT NULL` | NO | None | Serialized JSON | **Derived Vector:** JSON payload containing the 11 z-score normalized features fed into the MLP isolate forward pass and classification confidence score. |
| `created_at` | `INTEGER` | `DateTime` | `NOT NULL` | NO | None | Epoch Milliseconds | Unix epoch timestamp when background isolate forward pass executed. |

---

### 2.5 Table: `reminders`
* **Purpose:** Stores user-configured recurring daily notification reminders for scheduled biomonitoring measurements.
* **Cardinality:** Independent standalone configuration entity.

| Column Name | SQL Type | Dart Type | Constraints | Nullable | Default | Unit / Format | Description |
|---|---|---|---|---|---|---|---|
| `id` | `INTEGER` | `int?` | `PRIMARY KEY AUTOINCREMENT` | NO | None | Monotonic Integer | Primary key identifier for the reminder notification. |
| `hour` | `INTEGER` | `int` | `NOT NULL` | NO | None | Hour ($0 - 23$) | Hour of the day in 24-hour format when alert triggers. |
| `minute` | `INTEGER` | `int` | `NOT NULL` | NO | None | Minute ($0 - 59$) | Minute of the hour when alert triggers. |
| `label` | `TEXT` | `String` | `NOT NULL` | NO | None | String | User-defined label (e.g. `'Morning Resting Pulse'`). |
| `is_enabled` | `INTEGER` | `bool` | `NOT NULL` | NO | None | Boolean ($0$ or $1$) | Flag indicating whether background alarm service triggers notification ($1 = \text{enabled}$, $0 = \text{disabled}$). |
| `days_of_week` | `TEXT` | `List<int>` | `NOT NULL` | NO | None | Comma-delimited | Days of week active: `'1,2,3,4,5,6,7'` ($1 = \text{Monday}, 7 = \text{Sunday}$). |

---

### 2.6 Table: `app_settings`
* **Purpose:** Stores global application configuration settings and state flags as key-value pairs.
* **Cardinality:** Independent standalone configuration entity.

| Column Name | SQL Type | Dart Type | Constraints | Nullable | Default | Unit / Format | Description |
|---|---|---|---|---|---|---|---|
| `key` | `TEXT` | `String` | `PRIMARY KEY` | NO | None | Key String | Configuration identifier (e.g. `'dark_mode'`, `'language_code'`). |
| `value` | `TEXT` | `String` | `NOT NULL` | NO | None | Value String | Serialized string or JSON representation of the configuration value. |

---

## 3. Entities Outside the Database (Non-Relational Assets)

To maintain strict architectural boundaries, the following project components are **explicitly not stored in the relational database**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 OUTSIDE THE DATABASE (Non-Relational Assets)                │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. ESP32-C3 + MAX30102 Hardware:                                            │
│    Physical microcontroller and optical PPG sensor generating analog        │
│    signals and I2C registers; transient state not persistent in DB.         │
│                                                                             │
│ 2. 12-Byte Little-Endian BLE GATT Notification Packet:                      │
│    Transient over-the-air binary transport stream (Protocol v1: flags,      │
│    BPM*10, SQI, timestamp, seq). Parsed in memory before row ingestion.   │
│                                                                             │
│ 3. ML Model Weights (`app/assets/ml/weights.json`):                         │
│    Static neural network weights (5->16->8->1, 241 parameters) bundled      │
│    directly inside application assets; evaluated in pure Dart isolate.      │
│                                                                             │
│ 4. PDF Biomonitoring Reports:                                               │
│    Self-contained portable document files generated on-demand by            │
│    `PdfReportGenerator` into application file storage, not DB blobs.        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Verification Checksum & Code Cross-Reference

* **Parity Verification Script:** [`tools/verify_erd_parity.py`](file:///e:/pulse%20patch/tools/verify_erd_parity.py)
* **Mermaid ERD Specification:** [`docs/erd/pulse_patch_erd.mmd`](file:///e:/pulse%20patch/docs/erd/pulse_patch_erd.mmd)
* **High-Resolution Diagram (PNG):** [`docs/erd/pulse_patch_erd.png`](file:///e:/pulse%20patch/docs/erd/pulse_patch_erd.png) ($3008 \times 1590\text{ px}$)
* **Vector Diagram (SVG):** [`docs/erd/pulse_patch_erd.svg`](file:///e:/pulse%20patch/docs/erd/pulse_patch_erd.svg)
* **Printable Document (PDF):** [`docs/erd/pulse_patch_erd.pdf`](file:///e:/pulse%20patch/docs/erd/pulse_patch_erd.pdf) (A4 Landscape)
