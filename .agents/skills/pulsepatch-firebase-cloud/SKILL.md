---
name: pulsepatch-firebase-cloud
description: Firebase Cloud Platform architecture, user authentication, offline-first SQLite-to-Firestore synchronization queue, Cloud Storage, and security rules.
---

# PulsePatch Next Generation — Firebase Cloud Platform

## 1. Cloud Architecture & Offline-First Strategy
The user's local health data is the single source of truth. Cloud sync is optional, non-blocking, and privacy-preserving.
```
[Flutter UI]
     │
[Biometric Repository]
     │
[Local SQLite (Drift)]  ◄─── Real-time Local Read/Write
     │
[Sync Queue / Outbox]
     │ (When Online & User Authenticated)
     ▼
[Cloud Firestore / Cloud Storage]
```

## 2. Authentication Flow
- **Local Guest Mode (Default)**: Full app access without requiring an account or internet. All data stored in local encrypted Drift SQLite.
- **Cloud Connect Mode**: Optional Google Sign-In or Anonymous-to-Account upgrade via `FirebaseAuth`.
- User UID scopes all remote documents: `users/{userId}/sessions/{sessionId}`.

## 3. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 4. App Check & Cloud Storage
- Firebase App Check protects backend endpoints and Firebase AI logic from unauthorized scraping.
- Clinical PDF reports uploaded to `users/{userId}/reports/{reportId}.pdf` with metadata tags.
