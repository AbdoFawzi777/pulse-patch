import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PulsePatch Lite'**
  String get appTitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, there!'**
  String get greeting;

  /// No description provided for @questionToday.
  ///
  /// In en, this message translates to:
  /// **'How are you today?'**
  String get questionToday;

  /// No description provided for @connectedDeviceChip.
  ///
  /// In en, this message translates to:
  /// **'Connected · {deviceName}'**
  String connectedDeviceChip(String deviceName);

  /// No description provided for @sampleDataChip.
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get sampleDataChip;

  /// No description provided for @simulatorChip.
  ///
  /// In en, this message translates to:
  /// **'Simulator'**
  String get simulatorChip;

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last session'**
  String get lastSession;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @notLive.
  ///
  /// In en, this message translates to:
  /// **'not live'**
  String get notLive;

  /// No description provided for @bpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get bpm;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @typicalPattern.
  ///
  /// In en, this message translates to:
  /// **'Typical pattern'**
  String get typicalPattern;

  /// No description provided for @differentPattern.
  ///
  /// In en, this message translates to:
  /// **'Different pattern'**
  String get differentPattern;

  /// No description provided for @measure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get measure;

  /// No description provided for @measuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring'**
  String get measuring;

  /// No description provided for @opticalPulseTrace.
  ///
  /// In en, this message translates to:
  /// **'Optical pulse trace'**
  String get opticalPulseTrace;

  /// No description provided for @signalGood.
  ///
  /// In en, this message translates to:
  /// **'Signal: Good'**
  String get signalGood;

  /// No description provided for @signalWeak.
  ///
  /// In en, this message translates to:
  /// **'Signal: Weak'**
  String get signalWeak;

  /// No description provided for @signalFair.
  ///
  /// In en, this message translates to:
  /// **'Signal: Fair'**
  String get signalFair;

  /// No description provided for @stopAndSave.
  ///
  /// In en, this message translates to:
  /// **'Stop and save'**
  String get stopAndSave;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @pulseInterval.
  ///
  /// In en, this message translates to:
  /// **'Pulse interval'**
  String get pulseInterval;

  /// No description provided for @variabilityEst.
  ///
  /// In en, this message translates to:
  /// **'Variability (est.)'**
  String get variabilityEst;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect device'**
  String get connectDevice;

  /// No description provided for @scanningKeepWithin1m.
  ///
  /// In en, this message translates to:
  /// **'Scanning · keep the patch within 1 m'**
  String get scanningKeepWithin1m;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @modelResult.
  ///
  /// In en, this message translates to:
  /// **'Model result'**
  String get modelResult;

  /// No description provided for @experimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get experimental;

  /// No description provided for @measuredValuesUsed.
  ///
  /// In en, this message translates to:
  /// **'Measured values used'**
  String get measuredValuesUsed;

  /// No description provided for @patternExplanation.
  ///
  /// In en, this message translates to:
  /// **'Similar to your last 5 rest sessions. A pattern label, not a health rating.'**
  String get patternExplanation;

  /// No description provided for @runsOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Runs on this phone · small neural network running locally in the app · {count} sessions available'**
  String runsOnPhone(int count);

  /// No description provided for @sensorDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Sensor: MAX30102 · Powered via USB-C (no battery circuit)'**
  String get sensorDisclaimer;

  /// No description provided for @sampleDataPeaksDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Sample data · estimated from optical pulse peaks'**
  String get sampleDataPeaksDisclaimer;

  /// No description provided for @educationalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'PulsePatch Lite is an educational prototype and does not provide medical diagnosis.'**
  String get educationalDisclaimer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
