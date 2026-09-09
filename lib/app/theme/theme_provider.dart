import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App appearance. Defaults to following the OS, which is what users of a
/// premium iOS app expect; the profile screen can override it.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void set(ThemeMode mode) => state = mode;

  /// Explicit dark toggle used by the switch in Profil → Tungi rejim.
  void setDark(bool isDark) => state = isDark ? ThemeMode.dark : ThemeMode.light;

  void useSystem() => state = ThemeMode.system;
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

/// Supported languages — Uzbek is the default per the product spec.
enum AppLanguage { uz, ru, en }

extension AppLanguageX on AppLanguage {
  Locale get locale => switch (this) {
        AppLanguage.uz => const Locale('uz'),
        AppLanguage.ru => const Locale('ru'),
        AppLanguage.en => const Locale('en'),
      };

  String get label => switch (this) {
        AppLanguage.uz => "O'zbekcha",
        AppLanguage.ru => 'Русский',
        AppLanguage.en => 'English',
      };

  String get flag => switch (this) {
        AppLanguage.uz => '🇺🇿',
        AppLanguage.ru => '🇷🇺',
        AppLanguage.en => '🇬🇧',
      };
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.uz);

  void set(AppLanguage language) => state = language;
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) => LanguageNotifier());

final localeProvider = Provider<Locale>((ref) => ref.watch(languageProvider).locale);
