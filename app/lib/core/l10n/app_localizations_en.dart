// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PulsePatch Lite';

  @override
  String get greeting => 'Hi, there!';

  @override
  String get questionToday => 'How are you today?';

  @override
  String connectedDeviceChip(String deviceName) {
    return 'Connected · $deviceName';
  }

  @override
  String get sampleDataChip => 'Sample data';

  @override
  String get simulatorChip => 'Simulator';

  @override
  String get lastSession => 'Last session';

  @override
  String get saved => 'Saved';

  @override
  String get notLive => 'not live';

  @override
  String get bpm => 'BPM';

  @override
  String get aiInsights => 'AI Insights';

  @override
  String get typicalPattern => 'Typical pattern';

  @override
  String get differentPattern => 'Different pattern';

  @override
  String get measure => 'Measure';

  @override
  String get measuring => 'Measuring';

  @override
  String get opticalPulseTrace => 'Optical pulse trace';

  @override
  String get signalGood => 'Signal: Good';

  @override
  String get signalWeak => 'Signal: Weak';

  @override
  String get signalFair => 'Signal: Fair';

  @override
  String get stopAndSave => 'Stop and save';

  @override
  String get heartRate => 'Heart Rate';

  @override
  String get pulseInterval => 'Pulse interval';

  @override
  String get variabilityEst => 'Variability (est.)';

  @override
  String get history => 'History';

  @override
  String get week => 'Week';

  @override
  String get day => 'Day';

  @override
  String get connectDevice => 'Connect device';

  @override
  String get scanningKeepWithin1m => 'Scanning · keep the patch within 1 m';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get modelResult => 'Model result';

  @override
  String get experimental => 'Experimental';

  @override
  String get measuredValuesUsed => 'Measured values used';

  @override
  String get patternExplanation =>
      'Similar to your last 5 rest sessions. A pattern label, not a health rating.';

  @override
  String runsOnPhone(int count) {
    return 'Runs on this phone · small neural network running locally in the app · $count sessions available';
  }

  @override
  String get sensorDisclaimer =>
      'Sensor: MAX30102 · Powered via USB-C (no battery circuit)';

  @override
  String get sampleDataPeaksDisclaimer =>
      'Sample data · estimated from optical pulse peaks';

  @override
  String get educationalDisclaimer =>
      'PulsePatch Lite is an educational prototype and does not provide medical diagnosis.';
}
