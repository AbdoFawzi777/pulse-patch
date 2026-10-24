import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/preferences_repository.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    return Locale(prefsRepo.selectedLocale);
  }

  Future<void> setLocale(String languageCode) async {
    final prefsRepo = ref.read(preferencesRepositoryProvider);
    await prefsRepo.setSelectedLocale(languageCode);
    state = Locale(languageCode);
  }
}
