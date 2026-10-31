---
name: pulsepatch-health-ai
description: Advanced Health AI architecture, provider-independent model abstraction, bilingual RAG, authoritative citation verification, and strict medical safety boundaries.
---

# PulsePatch Next Generation — Health AI Architecture

## 1. Provider-Independent Architecture

PulsePatch decouples the application from any single AI vendor or backend:
```
[MedicalKnowledgeAssistantScreen] / [AI Insights UI]
                       │
             [AiModelRouter]
           ┌───────────┴───────────┐
     [FirebaseAiProvider]   [LocalRagAiProvider]
     (Gemini 1.5 Flash)      (Offline Evidence RAG)
           │                       │
     [App Check / Auth]     [Authoritative JSON DB]
```

### Core Abstractions
- `AiProvider`: Interface declaring `Future<AiResponse> generateResponse(AiPromptRequest request)` and stream support.
- `AiModelRouter`: Evaluates internet connectivity, Firebase App Check / user session state, and user preference to route queries to Cloud (Gemini) or Offline Local RAG.
- `HealthContextBuilder`: Synthesizes user vitals (recent HR, SpO2, calibrated BP, age, gender) into an anonymized clinical prompt context.
- `AiSafetyPolicy`: Intercepts user inputs and AI outputs to enforce safety rules, emergency escalation, and non-diagnostic disclaimers.
- `AiCitationValidator`: Enforces evidence provenance (WHO, ESC/ISH 2023, PubMed PMID, AHA guidelines).

## 2. Bilingual RAG (Retrieval-Augmented Generation)
- Curated vector/keyword corpus in both English and Arabic.
- Citations must include:
  - Source organization / Journal (e.g. WHO 2023 Guidelines, European Heart Journal)
  - Key finding / Guideline threshold
  - Exact disclaimer: "PulsePatch provides educational insights only. Consult a physician for diagnosis."

## 3. Strict Safety Boundaries
- **Hypertensive Crisis Alert**: BP >= 180 mmHg systolic OR >= 120 mmHg diastolic triggers immediate red emergency banner with 123 (Egyptian Ambulance) direct call option.
- **Symptom Flagging**: Chest pain, shortness of breath, left arm numbness trigger immediate emergency escalation advice.
- No prescriptive drug dosage or diagnostic determination.
