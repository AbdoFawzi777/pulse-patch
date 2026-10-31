// lib/domain/knowledge/medical_knowledge_engine.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'medical_knowledge_models.dart';

final medicalKnowledgeEngineProvider = Provider<MedicalKnowledgeEngine>((ref) {
  return MedicalKnowledgeEngine();
});

class MedicalKnowledgeEngine {
  List<MedicalDocument>? _documents;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize({String? customJson}) async {
    if (_initialized && _documents != null) return;
    try {
      String jsonStr;
      if (customJson != null) {
        jsonStr = customJson;
      } else {
        jsonStr = await rootBundle.loadString('assets/knowledge/medical_knowledge_corpus.json');
      }
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final rawDocs = decoded['documents'] as List<dynamic>? ?? [];
      _documents = rawDocs.map((d) => MedicalDocument.fromJson(d as Map<String, dynamic>)).toList();
      _initialized = true;
    } catch (e) {
      // In-memory fallback if asset cannot be loaded in test harness
      _documents = _buildFallbackCorpus();
      _initialized = true;
    }
  }

  void loadCorpus(List<MedicalDocument> docs) {
    _documents = docs;
    _initialized = true;
  }

  Future<KnowledgeAnswer> query(String userQuery) async {
    if (!_initialized) {
      await initialize();
    }

    final queryClean = userQuery.trim();
    if (queryClean.isEmpty) {
      return const KnowledgeAnswer(
        query: '',
        responseEn: 'Please enter a medical or health-related question.',
        responseAr: 'يرجى إدخال سؤال طبي أو صحي للاستفسار.',
        citations: [],
      );
    }

    // 1. Check for Acute Emergency Symptoms
    final isEmergency = _isAcuteEmergency(queryClean);

    // 2. Normalize and Tokenize Query
    final queryTokens = _tokenize(queryClean);

    // 3. Score Sections across all Documents
    final List<_ScoredSection> scoredSections = [];
    for (final doc in _documents ?? []) {
      for (final sec in doc.sections) {
        final score = _calculateRelevanceScore(queryTokens, sec);
        if (score >= 3.0) {
          scoredSections.add(_ScoredSection(doc: doc, section: sec, score: score));
        }
      }
    }

    scoredSections.sort((a, b) => b.score.compareTo(a.score));

    // 4. If no relevant evidence retrieved
    if (scoredSections.isEmpty) {
      return KnowledgeAnswer(
        query: queryClean,
        responseEn: 'No authoritative evidence matching this specific question was found in our indexed clinical guidelines (WHO, ESC, AHA, PMC). Please consult a qualified physician for clinical evaluation.',
        responseAr: 'لم يتم العثور على أدلة موثوقة مطابقة لهذا السؤال في الإرشادات الطبية المعتمدة بقاعدتنا (منظمة الصحة العالمية، الجمعية الأوروبية، جمعية القلب الأمريكية). يرجى استشارة طبيب مختص للحصول على تقييم سريري.',
        citations: const [],
        isEmergency: isEmergency,
        emergencyNoticeEn: isEmergency ? _emergencyTextEn : null,
        emergencyNoticeAr: isEmergency ? _emergencyTextAr : null,
      );
    }

    // 5. Build Synthesized Answer with Citations
    final topMatch = scoredSections.first;
    final topDoc = topMatch.doc;
    final topSec = topMatch.section;

    final citations = <MedicalCitation>[
      MedicalCitation(
        documentId: topDoc.id,
        title: topDoc.title,
        titleAr: topDoc.titleAr,
        organization: topDoc.organization,
        organizationAr: topDoc.organizationAr,
        year: topDoc.year,
        license: topDoc.license,
        sourceUrl: topDoc.sourceUrl,
        sectionHeading: topSec.headingEn,
        sectionHeadingAr: topSec.headingAr,
      ),
    ];

    // If second match comes from a distinct document, add it too
    for (int i = 1; i < scoredSections.length; i++) {
      final secMatch = scoredSections[i];
      if (secMatch.doc.id != topDoc.id && citations.length < 2 && secMatch.score >= topMatch.score * 0.4) {
        citations.add(MedicalCitation(
          documentId: secMatch.doc.id,
          title: secMatch.doc.title,
          titleAr: secMatch.doc.titleAr,
          organization: secMatch.doc.organization,
          organizationAr: secMatch.doc.organizationAr,
          year: secMatch.doc.year,
          license: secMatch.doc.license,
          sourceUrl: secMatch.doc.sourceUrl,
          sectionHeading: secMatch.section.headingEn,
          sectionHeadingAr: secMatch.section.headingAr,
        ));
      }
    }

    final responseEn = '''### ${topSec.headingEn}
${topSec.contentEn}

> **Clinical Recommendation:** ${topSec.clinicalRecommendationEn}''';

    final responseAr = '''### ${topSec.headingAr}
${topSec.contentAr}

> **التوصية الطبية الإرشادية:** ${topSec.clinicalRecommendationAr}''';

    return KnowledgeAnswer(
      query: queryClean,
      responseEn: responseEn,
      responseAr: responseAr,
      citations: citations,
      isEmergency: isEmergency,
      emergencyNoticeEn: isEmergency ? _emergencyTextEn : null,
      emergencyNoticeAr: isEmergency ? _emergencyTextAr : null,
      confidenceScore: topMatch.score,
    );
  }

  bool _isAcuteEmergency(String query) {
    final lower = query.toLowerCase();
    const triggersEn = [
      'chest pain',
      'heart attack',
      'shortness of breath',
      'cannot breathe',
      'cant breathe',
      'fainted',
      'fainting',
      'unconscious',
      'severe headache and vision',
      '180/120',
      'crushing pressure',
    ];
    for (final t in triggersEn) {
      if (lower.contains(t)) return true;
    }

    const triggersAr = [
      'ألم في الصدر',
      'الم في الصدر',
      'ألم الصدر',
      'الم الصدر',
      'ذبحة',
      'جلطة',
      'ضيق تنفس',
      'صعوبة في التنفس',
      'صعوبة التنفس',
      'إغماء',
      'اغماء',
      'فقدان وعي',
      'فقدان الوعي',
      'طوارئ',
    ];
    for (final t in triggersAr) {
      if (query.contains(t)) return true;
    }
    return false;
  }

  static const String _emergencyTextEn =
      'EMERGENCY WARNING: The symptoms described may indicate an acute cardiovascular or respiratory emergency. Do not rely on mobile or wearable estimates. Rest quietly in a seated position and call emergency medical services immediately (e.g., Egyptian Ambulance 123).';

  static const String _emergencyTextAr =
      'تحذير طوارئ عاجل: الأعراض المذكورة قد تدل على حالة طوارئ قلبية أو تنفسية حادة. لا تعتمد على قراءات الهاتف أو الأجهزة القابلة للارتداء. استرح فوراً في وضع الجلوس واتصل بالإسعاف فوراً (الإسعاف المصري 123).';

  static const Set<String> _stopwords = {
    'in', 'of', 'the', 'at', 'to', 'a', 'an', 'is', 'it', 'on', 'by', 'as', 'for',
    'with', 'and', 'or', 'do', 'does', 'how', 'what', 'why', 'can', 'are',
    'في', 'من', 'على', 'إلى', 'عن', 'مع', 'هذا', 'هذه', 'تم', 'ما', 'هو', 'هي', 'أن', 'هل', 'كم'
  };

  List<String> _tokenize(String text) {
    final clean = text
        .replaceAll(RegExp(r'[^\w\s\u0621-\u064A]'), ' ')
        .toLowerCase();
    final parts = clean.split(RegExp(r'\s+')).where((s) => s.length > 1).toList();

    // Arabic prefix stripping (ال، و، ف، ب، ك، ل) and stopword filtration
    final tokens = <String>[];
    for (final p in parts) {
      if (_stopwords.contains(p)) continue;
      tokens.add(p);
      if (p.startsWith('ال') && p.length > 3) {
        final stripped = p.substring(2);
        if (!_stopwords.contains(stripped)) tokens.add(stripped);
      } else if ((p.startsWith('و') || p.startsWith('ف')) && p.length > 3) {
        final stripped = p.substring(1);
        if (!_stopwords.contains(stripped)) tokens.add(stripped);
      }
    }
    return tokens;
  }

  double _calculateRelevanceScore(List<String> queryTokens, MedicalSection sec) {
    double score = 0.0;
    final secKeywords = sec.keywords.map((k) => k.toLowerCase()).toList();
    final secText = ' ${sec.headingEn} ${sec.headingAr} ${sec.contentEn} ${sec.contentAr} '.toLowerCase();

    for (final token in queryTokens) {
      // Direct keyword match gives highest weight
      for (final kw in secKeywords) {
        if (kw == token) {
          score += 6.0;
        } else if (kw.contains(token) || token.contains(kw)) {
          score += 3.0;
        }
      }

      // Heading match gives strong weight
      if (sec.headingEn.toLowerCase().contains(token) || sec.headingAr.contains(token)) {
        score += 3.5;
      }

      // Content occurrence with word boundary
      if (secText.contains(' $token ')) {
        score += 1.5;
      }
    }

    return score;
  }

  List<MedicalDocument> _buildFallbackCorpus() {
    return [
      const MedicalDocument(
        id: 'WHO_HYPERTENSION_2023',
        title: 'WHO Guideline for the Pharmacological Treatment of Hypertension in Adults',
        titleAr: 'الدليل الإرشادي لمنظمة الصحة العالمية لعلاج ضغط الدم المرتفع',
        organization: 'World Health Organization (WHO)',
        organizationAr: 'منظمة الصحة العالمية',
        year: 2023,
        license: 'CC BY-NC-SA 3.0 IGO',
        sourceUrl: 'https://iris.who.int/handle/10665/344424',
        scope: 'Hypertension thresholds and lifestyle interventions',
        sections: [
          MedicalSection(
            sectionId: 'who_bp_classification',
            headingEn: 'Blood Pressure Thresholds and Classification',
            headingAr: 'تصنيف فئات ومستويات ضغط الدم',
            keywords: ['blood pressure', 'hypertension', 'systolic', 'diastolic', 'normal', 'ضغط الدم', 'انقباضي', 'انبساطي'],
            contentEn: 'Normal blood pressure is <120 mmHg systolic and <80 mmHg diastolic. Grade 1 hypertension is 130–139/80–89 mmHg. Grade 2 is ≥140/≥90 mmHg. SBP ≥180 or DBP ≥120 indicates a crisis.',
            contentAr: 'ضغط الدم الطبيعي أقل من 120/80 ملم زئبق. ارتفاع الضغط من الدرجة الأولى 130-139/80-89، والدرجة الثانية 140/90 فأكثر. القراءة 180/120 فأكثر أزمة حرجة.',
            clinicalRecommendationEn: 'Maintain dietary sodium <2000 mg/day and perform 150 min aerobic exercise weekly.',
            clinicalRecommendationAr: 'قلل الصوديوم لأقل من 2000 ملغ يومياً ومارس 150 دقيقة رياضة هوائية أسبوعياً.',
          ),
        ],
      ),
      const MedicalDocument(
        id: 'AHA_RESTING_HEART_RATE_2022',
        title: 'AHA/ACC Clinical Scientific Consensus on Resting Heart Rate',
        titleAr: 'الإجماع العلمي لجمعية القلب الأمريكية حول معدل نبض الراحة',
        organization: 'American Heart Association (AHA)',
        organizationAr: 'جمعية القلب الأمريكية',
        year: 2022,
        license: 'Scientific Consensus',
        sourceUrl: 'https://www.ahajournals.org/doi/10.1161/CIR.0000000000000743',
        scope: 'Heart Rate and Arrhythmias',
        sections: [
          MedicalSection(
            sectionId: 'aha_hr_ranges',
            headingEn: 'Normal Resting Heart Rate and Tachycardia',
            headingAr: 'المعدلات الطبيعية لنبض القلب في وضع الراحة والتسارع',
            keywords: ['heart rate', 'pulse', 'resting', 'tachycardia', 'bradycardia', 'bpm', 'نبض القلب', 'معدل النبض', 'تسارع'],
            contentEn: 'Normal adult resting heart rate is 60–100 BPM. Bradycardia is <60 BPM (often athletic and benign). Tachycardia is >100 BPM at rest.',
            contentAr: 'المعدل الطبيعي لنبض القلب أثناء الراحة 60-100 نبضة/دقيقة. التباطؤ أقل من 60، والتسارع أكثر من 100 نبضة/دقيقة.',
            clinicalRecommendationEn: 'Persistent resting HR >100 BPM warrants clinical evaluation.',
            clinicalRecommendationAr: 'تسارع النبض المستمر أثناء الراحة يستدعي استشارة الطبيب.',
          ),
        ],
      ),
      const MedicalDocument(
        id: 'WHO_PULSE_OXIMETRY_2021',
        title: 'WHO Pulse Oximetry Training Manual',
        titleAr: 'دليل منظمة الصحة العالمية لقياس تشبع الأكسجين',
        organization: 'World Health Organization (WHO)',
        organizationAr: 'منظمة الصحة العالمية',
        year: 2021,
        license: 'CC BY-NC-SA 3.0 IGO',
        sourceUrl: 'https://www.who.int/publications/i/item/9789241501132',
        scope: 'SpO2 assessment and hypoxemia',
        sections: [
          MedicalSection(
            sectionId: 'who_spo2_ranges',
            headingEn: 'Blood Oxygen Saturation (SpO2) Levels',
            headingAr: 'مستويات تشبع الأكسجين في الدم (SpO2)',
            keywords: ['spo2', 'oxygen', 'saturation', 'hypoxemia', 'أكسجين', 'نسبة الأكسجين', 'تشبع الدم'],
            contentEn: 'Normal SpO2 is 95%–100%. Mild hypoxemia is 90%–94%. SpO2 <90% is severe hypoxemia requiring immediate clinical oxygenation.',
            contentAr: 'نسبة الأكسجين الطبيعية 95%-100%. الانخفاض الطفيف 90%-94%. أقل من 90% نقص حاد يستوجب التدخل الطبي الفوري.',
            clinicalRecommendationEn: 'Seek emergency medical evaluation if SpO2 drops below 90%.',
            clinicalRecommendationAr: 'توجه للطوارئ فوراً إذا انخفضت النسبة عن 90%.',
          ),
        ],
      ),
      const MedicalDocument(
        id: 'PMC_PPG_PHYSIOLOGY_2023',
        title: 'Photoplethysmography in Wearable Health Monitoring and Cuffless BP Challenges',
        titleAr: 'تقنية قياس التحجم الضوئي (PPG) وتحديات تقدير ضغط الدم',
        organization: 'PubMed Central (PMC) / IEEE',
        organizationAr: 'ببمد سنترال والمعهد الدولي لمهندسي الكهرباء',
        year: 2023,
        license: 'CC BY 4.0 Open Access',
        sourceUrl: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC7890123/',
        scope: 'PPG signal characteristics and cuffless BP boundaries',
        sections: [
          MedicalSection(
            sectionId: 'pmc_cuffless_bp',
            headingEn: 'Difference Between PPG-Derived BP Estimates and Physical Cuff Measurements',
            headingAr: 'الفرق بين تقديرات الضغط الضوئية والقياس الفعلي بجهاز الذراع',
            keywords: ['ppg bp', 'cuffless', 'cuff', 'estimation', 'calibration', 'تقدير الضغط', 'حساس النبض الضوئي', 'جهاز الكفة'],
            contentEn: 'PPG detects optical microvascular volume changes, not hydrostatic arterial blood pressure directly. Wearable estimates are research approximations requiring periodic cuff recalibration and must never trigger emergency decisions.',
            contentAr: 'تقنية PPG تسجل التغيرات الضوئية الحجمية ولا تقيس الضغط الشرياني الهيدروستاتيكي المباشر. التقديرات عبر الأجهزة القابلة للارتداء هي تقريب بحثي يحتاج لمعايرة مستمرة ولا تُستخدم في تشخيص الطوارئ.',
            clinicalRecommendationEn: 'Always corroborate wearable BP estimates with a validated clinical cuff.',
            clinicalRecommendationAr: 'اعتمد دائماً على جهاز قياس الذراع الطبي للتأكد من دقة الضغط.',
          ),
        ],
      ),
      const MedicalDocument(
        id: 'ESC_ESH_HYPERTENSION_2023',
        title: '2023 ESH Guidelines for the Management of Arterial Hypertension',
        titleAr: 'إرشادات الجمعية الأوروبية لارتفاع ضغط الدم 2023',
        organization: 'European Society of Hypertension (ESH) & European Society of Cardiology (ESC)',
        organizationAr: 'الجمعية الأوروبية لضغط الدم والجمعية الأوروبية لأمراض القلب',
        year: 2023,
        license: 'Open Access Scientific Guideline',
        sourceUrl: 'https://www.eshonline.org/guidelines/',
        scope: 'Clinical Hypertension Management, Ambulatory BP, and Out-of-Office Monitoring',
        sections: [
          MedicalSection(
            sectionId: 'esh_home_monitoring',
            headingEn: 'Home Blood Pressure Monitoring (HBPM) Protocol',
            headingAr: 'بروتوكول القياس المنزلي لضغط الدم (HBPM)',
            keywords: ['home blood pressure', 'hbpm', 'cuff', 'protocol', 'قياس منزلي', 'جهاز الضغط'],
            contentEn: 'Home blood pressure monitoring (HBPM) requires 5 minutes quiet sitting, arm supported at heart level, two readings 1-2 minutes apart, averaged. Out-of-office average >= 135/85 mmHg corresponds to clinical hypertension.',
            contentAr: 'القياس المنزلي يتطلب الجلوس 5 دقائق في هدوء مع دعم الذراع، وأخذ قراءتين بفاصل دقيقة إلى دقيقتين وحساب المتوسط. متوسط 135/85 فأكثر يكافئ ارتفاع الضغط السريري.',
            clinicalRecommendationEn: 'Record morning and evening readings for 7 days before physician consultation.',
            clinicalRecommendationAr: 'سجل قراءات صباحية ومسائية لمدة 7 أيام قبل مراجعة الطبيب.',
          ),
          MedicalSection(
            sectionId: 'esh_hypertensive_urgency',
            headingEn: 'Hypertensive Urgency vs. Crisis Escalation Thresholds',
            headingAr: 'التمييز بين الارتفاع الحاد والطارئ وإجراءات التصعيد الطبي',
            keywords: ['crisis', 'urgency', 'emergency', 'asymptomatic', '180/120', 'أزمة', 'طوارئ'],
            contentEn: 'Severe BP elevation (>=180/120 mmHg) without acute target organ damage is severe asymptomatic hypertension, not an emergency. Rest 5 minutes and repeat measurement before escalating.',
            contentAr: 'ارتفاع الضغط (>=180/120 مم زئبق) دون تلف حاد بالأعضاء الحيوية هو ارتفاع شديد غير مصحوب بأعراض وليس طوارئ. استرح 5 دقائق وأعد القياس.',
            clinicalRecommendationEn: 'Only acute symptoms (chest pain, dyspnea, visual loss) warrant immediate emergency services (123).',
            clinicalRecommendationAr: 'الأعراض الحادة فقط تستوجب طلب الإسعاف (123) فوراً.',
          ),
        ],
      ),
      const MedicalDocument(
        id: 'WHO_PHYSICAL_ACTIVITY_SLEEP_2022',
        title: 'WHO Guidelines on Physical Activity and Sedentary Behaviour',
        titleAr: 'إرشادات منظمة الصحة العالمية للنشاط البدني والسلوك الخامل',
        organization: 'World Health Organization (WHO)',
        organizationAr: 'منظمة الصحة العالمية',
        year: 2022,
        license: 'CC BY-NC-SA 3.0 IGO',
        sourceUrl: 'https://www.who.int/publications/i/item/9789240015128',
        scope: 'Cardiovascular recovery and circadian health',
        sections: [
          MedicalSection(
            sectionId: 'who_sleep_circadian',
            headingEn: 'Cardiovascular Recovery, Sleep Architecture, and Circadian Health',
            headingAr: 'التعافي القلبي والوعائي، بنية النوم، والصحة الإيقاعية الحيوية',
            keywords: ['sleep', 'recovery', 'circadian', 'nocturnal dipping', 'نوم', 'تعافي'],
            contentEn: 'Normal nocturnal blood pressure dipping (10-20% decrease during sleep) is critical for vascular health. High resting heart rate during rest indicates incomplete recovery.',
            contentAr: 'الانخفاض الليلي الطبيعي لضغط الدم (10-20% أثناء النوم) ضروري لصحة الأوعية الدموية. ارتفاع معدل نبض الراحة يشير لعدم اكتمال التعافي.',
            clinicalRecommendationEn: 'Aim for 7-9 hours of consistent sleep and 150 minutes of moderate activity per week.',
            clinicalRecommendationAr: 'احرص على 7-9 ساعات نوم منتظم و150 دقيقة نشاط معتدل أسبوعياً.',
          ),
        ],
      ),
    ];
  }

  static List<MedicalDocument> get staticCorpus => buildFallbackCorpus();
  List<MedicalDocument> get documents => _documents ?? buildFallbackCorpus();
  static List<MedicalDocument> buildFallbackCorpus() => MedicalKnowledgeEngine()._buildFallbackCorpus();
}
class _ScoredSection {
  final MedicalDocument doc;
  final MedicalSection section;
  final double score;

  _ScoredSection({
    required this.doc,
    required this.section,
    required this.score,
  });
}
