---
name: doctor-discovery-maps
description: Doctor and clinic discovery, medical specialty filtering, location privacy, distance calculation, OpenStreetMap/Overpass and Google Places integration, and clinic profile rendering.
---

# Doctor Discovery and Maps Skill

## 1. Purpose
Defines protocols for discovering verified nearby healthcare providers, clinics, and cardiologists based on user location or manual city selection, displaying real distances, ratings, and operating hours without violating patient health data privacy.

## 2. When to Use
- Implementing or enhancing the "Find a Doctor" screen, clinic list, and interactive map views.
- Integrating mapping providers (OpenStreetMap / Overpass API, Google Places, Nominatim).
- Calculating Haversine geographical distances and sorting provider results.
- Handling device location permissions gracefully with manual city/area selection fallback.

## 3. Required Inputs
- User coordinates (Latitude, Longitude) or selected administrative area/city (e.g., Cairo, Giza, Alexandria).
- Target medical specialty (Cardiology, Internal Medicine, General Practice).
- Search radius (e.g., $5\text{ km}, 10\text{ km}, 25\text{ km}$).

## 4. Expected Outputs
- List of healthcare facilities with verified Name, Address, Specialty, Distance, Coordinates, Phone Number, Operating Hours, and Rating.
- Interactive map markers with callout detail sheets.
- Direct link/intent to system map application for turn-by-turn navigation.

## 5. Practical Workflow
1. **Privacy Shield:** Never transmit patient biometric measurements, heart rate history, or AI risk labels to the map provider or location API. Send only latitude/longitude and query terms ("hospital", "cardiologist").
2. **Permission Handling:** Request `ACCESS_FINE_LOCATION` with clear rationale. If denied, immediately provide intuitive manual city dropdown without disabling the feature.
3. **Data Retrieval:**
   - Primary open provider: Query OpenStreetMap Overpass API for `amenity=doctors` or `amenity=hospital` tagged with relevant medical specialty.
   - Fallback/Direct: Provide external map search launch intent for Google Maps / Apple Maps.
4. **Distance & Sorting:** Compute spherical distance using Haversine formula and sort results ascending by distance.
5. **Transparency:** Mark data freshness timestamp and indicate clearly if opening hours or ratings are unavailable from the public directory.

## 6. Verification Criteria
- Zero mock/fabricated doctor records in production flows.
- Clean handling of network timeouts or zero search results with user-friendly guidance.

## 7. Known Limitations & Prohibited Shortcuts
- **Prohibited:** Never invent fake clinic names, fabricated 5-star ratings, or fictitious phone numbers.
- **Prohibited:** Never automatically book appointments without explicit external provider API contracts.
- **Limitation:** Public directory opening hours and phone numbers may become outdated; include clear attribution.
