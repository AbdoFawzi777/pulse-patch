---
name: pulsepatch-google-maps
description: Native interactive Google Maps integration, Google Places (New) Nearby Search, medical specialty filters, bottom-sheet doctor cards, and API quota governance.
---

# PulsePatch Next Generation — Google Maps & Healthcare Discovery

## 1. Native In-App Map Integration
- Embedded inside `Health Services -> Nearby Healthcare Discovery`.
- Custom map styling aligned with the Midnight Navy dark theme (`#04030C`).
- Visual pin clusters and specialized markers for:
  - Hospitals (Red Cross pin)
  - Cardiology Specialists (Heartbeat pin)
  - Primary Care / General Clinics (Teal clinic pin)
  - 24/7 Pharmacies (Green pharmacy pin)

## 2. Google Places (New) API Integration
- Uses Places API (New) Nearby Search endpoint:
  - `https://places.googleapis.com/v1/places:searchNearby`
- Radius presets: 1 km, 3 km, 5 km, 10 km.
- Selective field masks to minimize API cost:
  - `places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.nationalPhoneNumber`

## 3. User Experience & Interactions
- Bottom sheet provider detail cards on pin tap.
- Direct "Get Directions" trigger launching native maps (Google Maps / Apple Maps intent).
- Direct "Call Clinic" trigger launching phone dialer.
- Offline fallback: If no internet or API key is unconfigured, displays cached local medical directories and emergency numbers (123 Ambulance).
