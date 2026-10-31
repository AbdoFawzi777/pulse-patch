/// Strict medical safety policy governing clinical queries and vital triggers
/// Aligned with WHO 2023, ESC/ESH 2023 Hypertension Guidelines, and AHA Clinical Consensus
class AiSafetyPolicy {
  const AiSafetyPolicy();

  static const String emergencyHotlineEgypt = '123';
  static const String disclaimerEn =
      'PulsePatch provides educational biomonitoring insights only and is not a substitute for clinical medical diagnosis or treatment.';
  static const String disclaimerAr =
      'يوفر تطبيق PulsePatch معلومات وإرشادات تعليمية للرصد الحيوي فقط ولا يغني عن الاستشارة أو التشخيص الطبي المتخصص.';

  /// Detects whether query mentions acute emergency symptoms
  bool isAcuteEmergency(String query) {
    final lower = query.toLowerCase();

    final acutePatterns = [
      'chest pain',
      'heart attack',
      'crushing pain',
      'pressure in chest',
      'shortness of breath',
      'cannot breathe',
      'difficulty breathing',
      'left arm pain',
      'arm numbness',
      'jaw pain',
      'stroke',
      'slurred speech',
      'facial drooping',
      'loss of consciousness',
      'fainted',
      'passing out',
      'coughing blood',
      'severe dizziness',
      'ألم في الصدر',
      'ألم بالصدر',
      'نوبة قلبية',
      'جلطة',
      'ضيق تنفس',
      'صعوبة في التنفس',
      'مش قادر أتنفس',
      'تنميل بالذراع الأيسر',
      'ألم بالفك',
      'إغماء',
      'فقدان الوعي',
      'سكتة دماغية',
      'بصق دم',
      'دوخة شديدة ومفاجئة',
    ];

    for (final pattern in acutePatterns) {
      if (lower.contains(pattern)) return true;
    }
    return false;
  }

  /// Detects if physiological context indicates vital emergency.
  /// NOTE: Only verified clinical cuff readings, severe hypoxia, or extreme arrhythmias may trigger crisis.
  /// Experimental PPG estimates must NEVER trigger this threshold.
  bool isPhysiologicalCrisis({
    double? sbp,
    double? dbp,
    double? hr,
    double? spo2,
  }) {
    // ESC/ISH 2023 Hypertensive crisis threshold: SBP >= 180 or DBP >= 120 mmHg
    // Note: In clinical practice, an asymptomatic reading requires repeat measurement.
    if (sbp != null && sbp >= 180.0) return true;
    if (dbp != null && dbp >= 120.0) return true;

    // Severe Hypoxia: SpO2 < 90%
    if (spo2 != null && spo2 > 0 && spo2 < 90.0) return true;

    // Extreme Tachycardia or Bradycardia at rest
    if (hr != null && (hr > 150.0 || (hr > 0 && hr < 40.0))) return true;

    return false;
  }

  /// Distinguishes Hypertensive Emergency (crisis with target organ symptoms)
  /// from Severe Asymptomatic Hypertension (formerly hypertensive urgency)
  bool isHypertensiveEmergency({
    required double cuffSbp,
    required double cuffDbp,
    required bool hasAcuteSymptoms,
  }) {
    final isCrisisLevel = cuffSbp >= 180.0 || cuffDbp >= 120.0;
    return isCrisisLevel && hasAcuteSymptoms;
  }

  /// Identifies Severe Asymptomatic Hypertension (cuff >= 180/120 mmHg without red-flag symptoms)
  bool isSevereAsymptomaticHypertension({
    required double cuffSbp,
    required double cuffDbp,
    bool hasAcuteSymptoms = false,
  }) {
    final isCrisisLevel = cuffSbp >= 180.0 || cuffDbp >= 120.0;
    return isCrisisLevel && !hasAcuteSymptoms;
  }

  /// Standard clinical emergency warning response for acute target-organ emergencies
  String getEmergencyAdvice({required bool isArabic}) {
    if (isArabic) {
      return 'تنبيه طوارئ حاد: الأعراض أو القياسات المدخلة قد تشير إلى حالة طبية طارئة تتطلب تدخلاً فورياً.\n'
          '1. اتصل بالإسعاف فوراً (الخط الساخن في مصر: 123) أو توجه لأقرب قسم طوارئ.\n'
          '2. استرح تماماً وتجنب أي مجهود بدني مفاجئ.\n'
          '3. إذا كنت تعاني من ألم بالصدر أو صعوبة بالتنفس، لا تقم بقيادة السيارة بنفسك.';
    } else {
      return 'ACUTE EMERGENCY ALERT: The described symptoms or biometric measurements may indicate an urgent medical situation.\n'
          '1. Call Emergency Medical Services immediately (Egypt Ambulance: 123) or proceed to the nearest emergency department.\n'
          '2. Sit down, rest quietly, and avoid physical exertion.\n'
          '3. If experiencing chest pressure, breathlessness, or left arm pain, do not attempt to drive yourself to the clinic.';
    }
  }

  /// Evidence-based repeat-measurement protocol for severe asymptomatic cuff readings (ESC/ESH 2023)
  String getSevereHypertensionAdvice({required bool isArabic}) {
    if (isArabic) {
      return 'إرشادات الارتفاع الشديد في ضغط الدم (دون أعراض طارئة):\n'
          '1. استرخِ في وضع الجلوس لمدة 5 دقائق بهدوء تام دون كلام.\n'
          '2. تأكد من إسناد الذراع عند مستوى القلب، وإبقاء القدمين منبسطتين على الأرض.\n'
          '3. تأكد من عدم تناول الكافيين أو ممارسة الرياضة خلال الـ 30 دقيقة الماضية.\n'
          '4. أعد القياس مرتين باستخدام جهاز قياس ضغط معتمد للذراع (جهاز الكفة / Cuff Sphygmomanometer) واحسب المتوسط.\n'
          '5. إذا ظلت القراءة ≥ 180/120 مم زئبق، تواصل مع طبيبك المعالج أو العيادة الخارجية خلال 24 ساعة.\n'
          '⚠️ تنبيه: إذا ظهرت أعراض مثل ألم بالصدر، ضيق تنفس، اضطراب في الرؤية، أو صداع حاد مفاجئ، اتصل بالإسعاف (123) فوراً.';
    } else {
      return 'Severe Blood Pressure Protocol (Asymptomatic - ESC/ESH 2023 Guidelines):\n'
          '1. Sit quietly and rest for 5 minutes without speaking.\n'
          '2. Support your arm at heart level with feet flat on the floor.\n'
          '3. Confirm no caffeine, exercise, or smoking occurred in the past 30 minutes.\n'
          '4. Take two repeat readings 1-2 minutes apart with a certified arm cuff sphygmomanometer and average them.\n'
          '5. If readings remain ≥ 180/120 mmHg without symptoms, contact your treating physician or outpatient clinic within 24 hours.\n'
          '⚠️ Warning: If acute symptoms occur (chest pain, shortness of breath, visual changes, or sudden severe headache), call emergency services (123) immediately.';
    }
  }
}
