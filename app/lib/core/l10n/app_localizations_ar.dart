// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'PulsePatch Lite';

  @override
  String get greeting => 'مرحباً!';

  @override
  String get questionToday => 'كيف حالك اليوم؟';

  @override
  String connectedDeviceChip(String deviceName) {
    return 'متصل · $deviceName';
  }

  @override
  String get sampleDataChip => 'بيانات تجريبية';

  @override
  String get simulatorChip => 'المحاكي';

  @override
  String get lastSession => 'آخر جلسة';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get notLive => 'غير مباشر';

  @override
  String get bpm => 'نبضة/د';

  @override
  String get aiInsights => 'رؤى الذكاء الاصطناعي';

  @override
  String get typicalPattern => 'نمط معتاد';

  @override
  String get differentPattern => 'نمط مختلف';

  @override
  String get measure => 'قياس';

  @override
  String get measuring => 'جاري القياس';

  @override
  String get opticalPulseTrace => 'المخطط الضوئي للنبض';

  @override
  String get signalGood => 'الإشارة: جيدة';

  @override
  String get signalWeak => 'الإشارة: ضعيفة';

  @override
  String get signalFair => 'الإشارة: مقبولة';

  @override
  String get stopAndSave => 'إيقاف وحفظ';

  @override
  String get heartRate => 'معدل النبض';

  @override
  String get pulseInterval => 'فاصل النبض';

  @override
  String get variabilityEst => 'التباين (تقديري)';

  @override
  String get history => 'السجل';

  @override
  String get week => 'أسبوع';

  @override
  String get day => 'يوم';

  @override
  String get connectDevice => 'توصيل الجهاز';

  @override
  String get scanningKeepWithin1m => 'جاري المسح · أبقِ اللاصقة ضمن نطاق 1 متر';

  @override
  String get connect => 'اتصال';

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get modelResult => 'نتيجة النموذج';

  @override
  String get experimental => 'تجريبي';

  @override
  String get measuredValuesUsed => 'القيم المقاسة المستخدمة';

  @override
  String get patternExplanation =>
      'مشابه لآخر 5 جلسات راحة لك. تصنيف نمط، وليس تقييماً صحياً.';

  @override
  String runsOnPhone(int count) {
    return 'يعمل محلياً على هذا الهاتف · شبكة عصبية صغيرة تعمل محلياً داخل التطبيق · $count جلسات متوفرة';
  }

  @override
  String get sensorDisclaimer =>
      'المستشعر: MAX30102 · تشغيل عبر USB-C (لا توجد دائرة بطارية)';

  @override
  String get sampleDataPeaksDisclaimer =>
      'بيانات تجريبية · تقديرية بناءً على قمم النبض الضوئي';

  @override
  String get educationalDisclaimer =>
      'تطبيق PulsePatch Lite نموذج تعليمي أولي ولا يقدم تشخيصاً طبياً.';
}
