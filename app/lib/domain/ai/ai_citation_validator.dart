import '../knowledge/medical_knowledge_models.dart';

/// Result of evaluating a single citation against the authoritative indexed corpus
class CitationValidationResult {
  const CitationValidationResult({
    required this.isValid,
    required this.citation,
    this.failureReason,
  });

  final bool isValid;
  final MedicalCitation citation;
  final String? failureReason;

  @override
  String toString() => isValid
      ? 'Valid citation: ${citation.documentId}'
      : 'Invalid citation: ${citation.documentId} - $failureReason';
}

/// Aggregated report of validating a list of citations
class CitationValidationReport {
  const CitationValidationReport({
    required this.allValid,
    required this.results,
    required this.hasPpgBpDisclaimer,
  });

  final bool allValid;
  final List<CitationValidationResult> results;
  final bool hasPpgBpDisclaimer;
}

/// Metadata signature of an indexed authoritative document
class _DocumentSignature {
  const _DocumentSignature({
    required this.id,
    required this.titleSubstrings,
    required this.allowedDomains,
    required this.minYear,
    required this.maxYear,
    required this.validSectionHeadings,
  });

  final String id;
  final List<String> titleSubstrings;
  final List<String> allowedDomains;
  final int minYear;
  final int maxYear;
  final List<String> validSectionHeadings;
}

/// Validates that generated AI answers adhere to authoritative citation standards
/// and strictly verifies citations against the real indexed clinical corpus
class AiCitationValidator {
  const AiCitationValidator();

  /// Maximum acceptable publication year (prevent futuristic/hallucinated citations)
  static const int currentMaxYear = 2026;

  /// Authoritative clinical organizations accepted in citations
  static const List<String> authoritativeOrganizations = [
    'WHO',
    'World Health Organization',
    'ESC',
    'European Society of Cardiology',
    'ESH',
    'European Society of Hypertension',
    'AHA',
    'American Heart Association',
    'ACC',
    'American College of Cardiology',
    'PMC',
    'PubMed Central',
    'NIH',
    'IEEE',
  ];

  /// Trusted domains for clinical guideline sources
  static const List<String> trustedDomains = [
    'who.int',
    'iris.who.int',
    'eshonline.org',
    'ahajournals.org',
    'ncbi.nlm.nih.gov',
    'pmc.ncbi.nlm.nih.gov',
  ];

  /// Indexed document signatures from medical_knowledge_corpus.json
  static const Map<String, _DocumentSignature> _indexedCorpus = {
    'WHO_HYPERTENSION_2023': _DocumentSignature(
      id: 'WHO_HYPERTENSION_2023',
      titleSubstrings: ['Hypertension', 'Pharmacological Treatment', 'Lifestyle'],
      allowedDomains: ['who.int', 'iris.who.int'],
      minYear: 2023,
      maxYear: 2023,
      validSectionHeadings: [
        'Blood Pressure Thresholds and Classification',
        'Evidence-Based Non-Pharmacological Interventions for BP Control',
        'تصنيف فئات ومستويات ضغط الدم',
        'التدخلات غير الدوائية المبنية على الأدلة للتحكم في ضغط الدم',
        'Thresholds',
      ],
    ),
    'ESC_ESH_HYPERTENSION_2023': _DocumentSignature(
      id: 'ESC_ESH_HYPERTENSION_2023',
      titleSubstrings: ['ESH Guidelines', 'Management of Arterial Hypertension'],
      allowedDomains: ['eshonline.org', 'escardio.org'],
      minYear: 2023,
      maxYear: 2023,
      validSectionHeadings: [
        'Home Blood Pressure Monitoring (HBPM) Protocol',
        'Hypertensive Urgency vs. Crisis Escalation Thresholds',
        'بروتوكول القياس المنزلي لضغط الدم (HBPM)',
        'التمييز بين الارتفاع الحاد والطارئ وإجراءات التصعيد الطبي',
      ],
    ),
    'AHA_RESTING_HEART_RATE_2022': _DocumentSignature(
      id: 'AHA_RESTING_HEART_RATE_2022',
      titleSubstrings: ['Resting Heart Rate', 'Scientific Consensus'],
      allowedDomains: ['ahajournals.org'],
      minYear: 2022,
      maxYear: 2022,
      validSectionHeadings: [
        'Normal Adult Resting Heart Rate and Tachycardia/Bradycardia Thresholds',
        'المعدلات الطبيعية لنبض القلب في وضع الراحة وعتبات التسارع والتباطؤ',
        'Normal Resting Heart Rate and Tachycardia',
      ],
    ),
    'WHO_PULSE_OXIMETRY_2021': _DocumentSignature(
      id: 'WHO_PULSE_OXIMETRY_2021',
      titleSubstrings: ['Pulse Oximetry', 'Training Manual'],
      allowedDomains: ['who.int'],
      minYear: 2021,
      maxYear: 2021,
      validSectionHeadings: [
        'Clinical Oxygen Saturation (SpO2) Tiers and Hypoxemia Definitions',
        'Measurement Pitfalls, Perfusion Artifacts, and Skin Pigmentation Factors',
        'مستويات تشبع الأكسجين في الدم (SpO2) وتصنيفات نقص التأكسج',
        'أخطاء القياس وعوامل ضعف التروية وتأثير صبغة الجلد',
        'Blood Oxygen Saturation (SpO2) Levels',
      ],
    ),
    'PMC_PPG_PHYSIOLOGY_2023': _DocumentSignature(
      id: 'PMC_PPG_PHYSIOLOGY_2023',
      titleSubstrings: ['Photoplethysmography', 'Wearable Health Monitoring', 'Cuffless BP'],
      allowedDomains: ['ncbi.nlm.nih.gov', 'pmc.ncbi.nlm.nih.gov', 'ieee.org'],
      minYear: 2023,
      maxYear: 2023,
      validSectionHeadings: [
        'Difference Between PPG-Derived BP Estimates and Physical Cuff Measurements',
        'الفرق بين تقديرات الضغط الضوئية والقياس الفعلي بجهاز الذراع',
      ],
    ),
    'WHO_PHYSICAL_ACTIVITY_SLEEP_2022': _DocumentSignature(
      id: 'WHO_PHYSICAL_ACTIVITY_SLEEP_2022',
      titleSubstrings: ['Physical Activity', 'Circadian'],
      allowedDomains: ['who.int'],
      minYear: 2022,
      maxYear: 2022,
      validSectionHeadings: [
        'Cardiovascular Recovery, Sleep Architecture, and Circadian Health',
        'التعافي القلبي والوعائي، بنية النوم، والصحة الإيقاعية الحيوية',
      ],
    ),
  };

  /// Backward-compatible check: returns true if citations contain at least one valid source
  bool hasAuthoritativeCitations(List<MedicalCitation> citations) {
    if (citations.isEmpty) return false;

    for (final c in citations) {
      final res = validateCitation(c);
      if (res.isValid) return true;

      // Fallback check on org string for legacy compatibility
      for (final org in authoritativeOrganizations) {
        if (c.organization.contains(org) || c.documentId.contains(org)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Validates a single citation against the authoritative indexed corpus
  CitationValidationResult validateCitation(MedicalCitation citation) {
    // 1. Verify Document ID is not blank and is indexed in the corpus
    if (citation.documentId.trim().isEmpty) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Missing document ID',
      );
    }

    final docSignature = _indexedCorpus[citation.documentId];
    if (docSignature == null) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Hallucinated or unverified document ID: ${citation.documentId}',
      );
    }

    // 2. Publication year verification (must be reasonable and not in the future)
    if (citation.year > currentMaxYear) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Future/hallucinated publication year: ${citation.year} > $currentMaxYear',
      );
    }
    if (citation.year < 2000) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Outdated/invalid publication year: ${citation.year}',
      );
    }

    // 3. Source URL verification (must be valid URI and from trusted domains)
    final uri = Uri.tryParse(citation.sourceUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Malformed or missing source URL: ${citation.sourceUrl}',
      );
    }

    final host = uri.host.toLowerCase();
    final isTrustedDomain = docSignature.allowedDomains.any((d) => host.contains(d));
    if (!isTrustedDomain) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Untrusted or hallucinated domain in URL: $host',
      );
    }

    // 4. Title integrity verification against indexed document metadata
    if (citation.title.trim().isEmpty) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Empty document title',
      );
    }
    final matchesTitle = docSignature.titleSubstrings.any(
      (sub) => citation.title.toLowerCase().contains(sub.toLowerCase()) ||
               sub.toLowerCase().contains(citation.title.toLowerCase()),
    );
    if (!matchesTitle) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Citation title "${citation.title}" does not correlate with document "${citation.documentId}"',
      );
    }

    // 5. Section Heading verification (must match an indexed clinical section)
    if (citation.sectionHeading.trim().isEmpty) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Missing section heading',
      );
    }
    final matchesHeading = docSignature.validSectionHeadings.any(
      (h) => h.toLowerCase() == citation.sectionHeading.toLowerCase() ||
             citation.sectionHeading.toLowerCase().contains(h.toLowerCase()) ||
             h.toLowerCase().contains(citation.sectionHeading.toLowerCase()),
    );
    if (!matchesHeading) {
      return CitationValidationResult(
        isValid: false,
        citation: citation,
        failureReason: 'Section heading "${citation.sectionHeading}" is not indexed in document ${citation.documentId}',
      );
    }

    return CitationValidationResult(
      isValid: true,
      citation: citation,
    );
  }

  /// Verifies a batch of citations and checks for PPG BP distinction if BP is mentioned
  CitationValidationReport validateCitations(
    List<MedicalCitation> citations, {
    String? responseText,
  }) {
    if (citations.isEmpty) {
      return const CitationValidationReport(
        allValid: false,
        results: [],
        hasPpgBpDisclaimer: false,
      );
    }

    final results = citations.map(validateCitation).toList();
    final allValid = results.every((r) => r.isValid);

    bool hasPpgDisclaimer = true;
    if (responseText != null && isPpgBpDiscussion(responseText)) {
      hasPpgDisclaimer = verifyPpgBpSeparation(responseText);
    }

    return CitationValidationReport(
      allValid: allValid && hasPpgDisclaimer,
      results: results,
      hasPpgBpDisclaimer: hasPpgDisclaimer,
    );
  }

  /// Determines if a response or query discusses blood pressure estimation from optical/wearable PPG
  static bool isPpgBpDiscussion(String text) {
    final lower = text.toLowerCase();
    return (lower.contains('ppg') || lower.contains('optical') || lower.contains('wearable')) &&
        (lower.contains('blood pressure') ||
            lower.contains('bp') ||
            lower.contains('hypertension') ||
            lower.contains('ضغط الدم') ||
            lower.contains('ارتفاع الضغط'));
  }

  /// Verifies that wearable PPG blood pressure is explicitly distinguished from clinical arm cuff measurements
  static bool verifyPpgBpSeparation(String text) {
    final lower = text.toLowerCase();
    // Must mention cuff / sphygmomanometer / calibration and non-diagnostic or research limitation
    final mentionsCuff = lower.contains('cuff') ||
        lower.contains('sphygmomanometer') ||
        lower.contains('كفة') ||
        lower.contains('جهاز الذراع');
    final mentionsLimitation = lower.contains('research') ||
        lower.contains('approximation') ||
        lower.contains('calibration') ||
        lower.contains('non-diagnostic') ||
        lower.contains('معايرة') ||
        lower.contains('تقريب بحثي') ||
        lower.contains('لا يغني');

    return mentionsCuff && mentionsLimitation;
  }
}
