# PulsePatch Lite — Blockers & Dependencies Tracking

| ID | Category | Description | Impact | Mitigation / Workaround | Status |
|---|---|---|---|---|---|
| **DEP-001** | Dataset Access | Direct Kaggle API download requires `KAGGLE_USERNAME` and `KAGGLE_KEY` credentials | Automated background dataset fetching might fail if unauthenticated | Provide direct dataset retrieval script using public mirror (Figshare PPG-BP open direct URL / PhysioNet open archives) and offline fallback dataset. | `MITIGATED` |
| **DEP-002** | Hardware Availability | Physical ESP32-C3 DevKitM-1 + MAX30102 breadboard hardware is physically unattached in this dev session | OTA validation on living human tissue is pending physical lab bring-up | Use physical Android phone (`HONOR NIC-LX2`) connected via ADB with real BLE transport simulator and on-device unit/widget test suites. | `ACTIVE_LIMITATION` |
| **DEP-003** | Map Service Credentials | Google Maps API key requires billing profile for high-quota searches | Maps view might fail if restricted | Use Flutter `flutter_map` (OpenStreetMap tile provider) with Nominatim / Overpass API for doctor & clinic search with zero API key dependencies, plus Google Maps intent fallback. | `MITIGATED` |
