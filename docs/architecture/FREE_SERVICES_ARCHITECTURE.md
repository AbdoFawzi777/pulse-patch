# PulsePatch Next Generation — Free Services Architecture & Zero-Cost Infrastructure

**Document Version:** 2.1.0  
**Target Project:** `pulsepatch-lite` (Project Number: `908110455385`)  
**Billing Policy:** **STRICT ZERO PAID SERVICES (SPARK PLAN ONLY)**  
**Date:** 2026-10-31  

---

## 1. Architectural Philosophy & Cost Constraints

PulsePatch Next Generation was architected from inception to operate sustainably under a **100% free, zero-cost operating model**. No credit card has been provided, no paid cloud APIs are bound, and all mobile, AI, mapping, and database capabilities are engineered within free tier boundaries or open-source local-first runtimes.

```
+--------------------------------------------------------------------------+
|                      PULSEPATCH ZERO-COST ARCHITECTURE                   |
+--------------------------------------------------------------------------+
|                                                                          |
|  [ Mobile Frontend ]        [ AI & Intelligence ]      [ Maps & Search ]  |
|  * Flutter 3.38 Clean Arch  * Local RAG (Indexed TF)    * OpenStreetMap  |
|  * Drift SQLite (C-FFI)     * WHO/ESC Corpus (Offline) * Overpass API    |
|  * 100% Offline Guest Mode  * Gemini Free Tier Proxy   * Mail.ru / DE    |
|                                                                          |
|  [ Cloud Persistence ]      [ Security & Integrity ]   [ Hardware Edge ] |
|  * Firebase Spark Plan      * Firebase App Check       * ESP32-C3 Firmware|
|  * 50k Reads / 20k Writes   * Android Play Integrity   * MAX30102 PPG   |
|  * Offline Sync Outbox      * Debug Provider in Dev    * Zero Cloud Tele |
+--------------------------------------------------------------------------+
```

---

## 2. Component-by-Component Zero-Cost Breakdown

### 2.1 Firebase Cloud Infrastructure (Spark Free Plan)

PulsePatch is deployed on the **Firebase Spark Plan** (Tier 0). Under no circumstances will the project be upgraded to the Blaze plan.

| Service | Spark Free Quota | PulsePatch Implementation |
|---|---|---|
| **Cloud Firestore** | 1 GB storage, 50,000 reads/day, 20,000 writes/day, 20,000 deletes/day | **Offline Outbox Architecture:** All sessions are recorded locally to Drift SQLite. Firestore sync is batched and throttled with exponential backoff. In active daily usage, a user generates ~5 writes/day (0.025% of quota). |
| **Firebase Authentication** | 50,000 monthly active users (Phone auth excluded) | Anonymous guest authentication and email/password tokens. When network is absent, the app seamlessly defaults to SQLite Local Guest Mode. |
| **Cloud Storage** | 5 GB storage, 1 GB/day download bandwidth | Used solely for emergency cloud backup if requested. Reports are generated locally as PDF via Dart. |
| **App Check** | 10,000 verifications/day (Play Integrity) | `AndroidPlayIntegrityProvider` in production; `AndroidDebugProvider` in testing. Validates client authenticity before invoking any cloud proxy. |

---

### 2.2 Mapping & Healthcare Discovery: OpenStreetMap vs Google Maps

To avoid Google Maps Platform pay-as-you-go billing ($7.00 per 1,000 map loads, $17.00 per 1,000 Places Nearby searches), PulsePatch features a **100% free, open-source mapping stack**:

1. **Map Renderer:** `flutter_map: ^8.3.2` + `latlong2: ^0.10.1`
   - Direct vector/raster rendering using OpenStreetMap standard tile servers (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
   - Compliant with OpenStreetMap Tile Usage Policy (custom User-Agent `PulsePatch-NextGen-Health/1.0`, local tile caching).
2. **Spatial Discovery & POI Query:** Overpass API
   - Multi-endpoint fallback architecture:
     - Primary: `https://maps.mail.ru/osm/tools/overpass/api/interpreter`
     - Secondary: `https://overpass-api.de/api/interpreter`
   - Queries `amenity=hospital|clinic|pharmacy` and `healthcare=*` within bounding boxes.
   - 30-day spatial coordinate caching in SQLite to minimize network requests.
   - Authoritative fallback to curated Egyptian medical institutions when network is offline.

---

### 2.3 Medical AI: Local RAG + Gemini Free Tier

1. **Primary Intelligence: Local Medical RAG Engine (`LocalRagAiProvider`)**
   - **Cost:** **$0.00** (Zero network requests, runs 100% on-device).
   - **Corpus:** 28 authoritative clinical knowledge documents indexed from the European Society of Cardiology (ESC 2023), American Heart Association (AHA), and World Health Organization (WHO).
   - **Performance:** Sub-millisecond vector/lexical retrieval with strict citation verification (`AiCitationValidator`).
2. **Cloud Extension: Google AI Studio Gemini Free Tier (`GeminiCloudAiProvider`)**
   - **Active Model:** `gemini-3.8-flash` (Primary), `gemini-3.5-flash-lite` (Fallback).
   - **Cost:** Free tier up to 15 Requests Per Minute (RPM), 1,500 Requests Per Day (RPD).
   - **Rate Limiting:** Server/client token bucket rate limiter strictly caps outbound requests at 10 RPM to guarantee zero billing exposure.
   - **Failover:** Any HTTP 429 (Resource Exhausted) or network timeout immediately routes back to the Local RAG engine without user interruption.

---

## 3. Resilience & Offline-First Guarantees

1. **Zero External Dependency at Core:** The core app functions 100% offline (heart rate monitoring, PPG analysis, blood oxygen estimation, PDF report generation, local AI knowledge lookup).
2. **Data Privacy:** Biometric signals (raw PPG, heart rate waveforms) are stored locally in the encrypted SQLite database and are **never transmitted to external cloud servers**.
