import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(): super(const Locale('en'));

  void changeLanguage(String languageCode) {
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref){
  return LocaleNotifier();
});