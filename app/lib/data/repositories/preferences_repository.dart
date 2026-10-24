import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/preference_keys.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesRepository(prefs);
});

class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  bool get isOnboardingCompleted =>
      _prefs.getBool(PreferenceKeys.isOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(PreferenceKeys.isOnboardingCompleted, value);
  }

  String get userName => _prefs.getString(PreferenceKeys.userName) ?? '';

  Future<void> setUserName(String name) async {
    await _prefs.setString(PreferenceKeys.userName, name);
  }

  bool get useBpmUnits => _prefs.getBool(PreferenceKeys.useBpmUnits) ?? true;

  Future<void> setUseBpmUnits(bool value) async {
    await _prefs.setBool(PreferenceKeys.useBpmUnits, value);
  }

  bool get isDarkTheme => _prefs.getBool(PreferenceKeys.isDarkTheme) ?? true;

  Future<void> setDarkTheme(bool value) async {
    await _prefs.setBool(PreferenceKeys.isDarkTheme, value);
  }

  String get selectedLocale =>
      _prefs.getString(PreferenceKeys.selectedLocale) ?? 'en';

  Future<void> setSelectedLocale(String localeCode) async {
    await _prefs.setString(PreferenceKeys.selectedLocale, localeCode);
  }

  int get measurementDurationSeconds =>
      _prefs.getInt(PreferenceKeys.measurementDurationSeconds) ?? 60;

  Future<void> setMeasurementDurationSeconds(int seconds) async {
    await _prefs.setInt(PreferenceKeys.measurementDurationSeconds, seconds);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
