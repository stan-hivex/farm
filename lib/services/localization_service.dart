import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _localeKey = 'selectedLocale';

  /// Get the saved locale from SharedPreferences
  static Future<Locale> getSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);

      if (localeString != null && localeString.isNotEmpty) {
        return Locale(localeString);
      }
    } catch (e) {
      debugPrint('Error reading saved locale: $e');
    }

    // Default to English if nothing is saved
    return const Locale('en');
  }

  /// Save the selected locale to SharedPreferences
  static Future<void> saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      debugPrint('Locale saved: ${locale.languageCode}');
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Change the application locale immediately
  static Future<void> changeLocale(
    BuildContext context,
    Locale newLocale,
  ) async {
    try {
      // Update EasyLocalization
      await context.setLocale(newLocale);

      // Persist the choice
      await saveLocale(newLocale);

      debugPrint('Locale changed to: ${newLocale.languageCode}');
    } catch (e) {
      debugPrint('Error changing locale: $e');
    }
  }

  /// Reset locale to English (called on logout)
  static Future<void> resetLocaleToEnglish(BuildContext context) async {
    try {
      final englishLocale = const Locale('en');
      await context.setLocale(englishLocale);
      await saveLocale(englishLocale);
      debugPrint('Locale reset to English');
    } catch (e) {
      debugPrint('Error resetting locale: $e');
    }
  }

  /// Get all supported locales
  static List<Locale> getSupportedLocales() {
    return const [
      Locale('en'),
      Locale('sw'),
      Locale('fr'),
      Locale('es'),
      Locale('ar'),
    ];
  }

  /// Get the current locale from context
  static Locale getCurrentLocale(BuildContext context) {
    return context.locale;
  }

  /// Check if current locale is RTL (Arabic)
  static bool isRTL(BuildContext context) {
    return context.locale.languageCode == 'ar';
  }

  /// Get language name for display
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'sw':
        return 'Kiswahili';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }
}
