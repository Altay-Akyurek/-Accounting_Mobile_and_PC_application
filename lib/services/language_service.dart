import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LanguageService {
  static final LanguageService instance = LanguageService._();
  LanguageService._();

  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('tr', 'TR'));

  Future<void> init() async {
    final box = await Hive.openBox('settings');
    final languageCode = box.get('languageCode', defaultValue: 'tr');
    localeNotifier.value = Locale(languageCode);
  }

  Future<void> changeLanguage(String languageCode) async {
    localeNotifier.value = Locale(languageCode);
    final box = await Hive.openBox('settings');
    await box.put('languageCode', languageCode);
  }
}
