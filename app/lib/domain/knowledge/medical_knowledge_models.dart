// lib/domain/knowledge/medical_knowledge_models.dart
// Data models for the PulsePatch Lite Medical Knowledge Retrieval System (System A)

class MedicalCitation {
  final String documentId;
  final String title;
  final String titleAr;
  final String organization;
  final String organizationAr;
  final int year;
  final String license;
  final String sourceUrl;
  final String sectionHeading;
  final String sectionHeadingAr;

  const MedicalCitation({
    required this.documentId,
    required this.title,
    required this.titleAr,
    required this.organization,
    required this.organizationAr,
    required this.year,
    required this.license,
    required this.sourceUrl,
    required this.sectionHeading,
    required this.sectionHeadingAr,
  });

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'title': title,
    'titleAr': titleAr,
    'organization': organization,
    'organizationAr': organizationAr,
    'year': year,
    'license': license,
    'sourceUrl': sourceUrl,
    'sectionHeading': sectionHeading,
    'sectionHeadingAr': sectionHeadingAr,
  };
}

class MedicalSection {
  final String sectionId;
  final String headingEn;
  final String headingAr;
  final List<String> keywords;
  final String contentEn;
  final String contentAr;
  final String clinicalRecommendationEn;
  final String clinicalRecommendationAr;

  const MedicalSection({
    required this.sectionId,
    required this.headingEn,
    required this.headingAr,
    required this.keywords,
    required this.contentEn,
    required this.contentAr,
    required this.clinicalRecommendationEn,
    required this.clinicalRecommendationAr,
  });

  factory MedicalSection.fromJson(Map<String, dynamic> json) {
    return MedicalSection(
      sectionId: json['section_id'] as String? ?? '',
      headingEn: json['heading_en'] as String? ?? '',
      headingAr: json['heading_ar'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      contentEn: json['content_en'] as String? ?? '',
      contentAr: json['content_ar'] as String? ?? '',
      clinicalRecommendationEn: json['clinical_recommendation_en'] as String? ?? '',
      clinicalRecommendationAr: json['clinical_recommendation_ar'] as String? ?? '',
    );
  }
}

class MedicalDocument {
  final String id;
  final String title;
  final String titleAr;
  final String organization;
  final String organizationAr;
  final int year;
  final String license;
  final String sourceUrl;
  final String scope;
  final List<MedicalSection> sections;

  const MedicalDocument({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.organization,
    required this.organizationAr,
    required this.year,
    required this.license,
    required this.sourceUrl,
    required this.scope,
    required this.sections,
  });

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? [];
    return MedicalDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      organizationAr: json['organization_ar'] as String? ?? '',
      year: json['year'] as int? ?? 2023,
      license: json['license'] as String? ?? 'Open Access',
      sourceUrl: json['source_url'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      sections: rawSections.map((s) => MedicalSection.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class KnowledgeAnswer {
  final String query;
  final String responseEn;
  final String responseAr;
  final List<MedicalCitation> citations;
  final bool isEmergency;
  final String? emergencyNoticeEn;
  final String? emergencyNoticeAr;
  final double confidenceScore;

  const KnowledgeAnswer({
    required this.query,
    required this.responseEn,
    required this.responseAr,
    required this.citations,
    this.isEmergency = false,
    this.emergencyNoticeEn,
    this.emergencyNoticeAr,
    this.confidenceScore = 1.0,
  });
}
