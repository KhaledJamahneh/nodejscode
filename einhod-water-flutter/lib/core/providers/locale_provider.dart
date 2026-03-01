import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar')) {
    _loadLocale();
  }

  void _loadLocale() {
    final savedLocale = StorageService.getLocale();
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  void setLocale(Locale locale) {
    if (state == locale) return;
    state = locale;
    StorageService.saveLocale(locale.languageCode);
  }

  void toggleLocale() {
    if (state.languageCode == 'en') {
      state = const Locale('ar');
    } else {
      state = const Locale('en');
    }
    StorageService.saveLocale(state.languageCode);
  }
}
