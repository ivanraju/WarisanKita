import 'package:flutter/material.dart';
import 'package:warisan_kita/data/services/auto_translation_service.dart';

class LanguageViewModel extends ChangeNotifier {
  String _currentLanguageCode = 'EN';
  String _currentLanguageName = 'English (United States)';

  LanguageViewModel() {
    _autoDetectDeviceSystemLocale();
  }

  String get currentLanguageCode => _currentLanguageCode;
  String get currentLanguageName => _currentLanguageName;

  final Map<String, String> _syncCache = {};

  void _autoDetectDeviceSystemLocale() {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final lang = locale.languageCode.toLowerCase();

      if (lang.contains('ms') || lang.contains('id')) {
        _currentLanguageCode = 'BM';
        _currentLanguageName = 'Bahasa Melayu (Malaysia)';
      } else if (lang.contains('zh')) {
        _currentLanguageCode = 'ZH';
        _currentLanguageName = 'Mandarin (中文 - 简体)';
      } else if (lang.contains('ja')) {
        _currentLanguageCode = 'JA';
        _currentLanguageName = 'Japanese (日本語)';
      } else {
        _currentLanguageCode = 'EN';
        _currentLanguageName = 'English (United States)';
      }
    } catch (_) {
      _currentLanguageCode = 'EN';
      _currentLanguageName = 'English (United States)';
    }
  }

  void setLanguage(String code, String name) {
    _currentLanguageCode = code;
    _currentLanguageName = name;
    notifyListeners();
  }

  /// 100% Automated Live Translation (No hardcoded dictionary maps!)
  /// Fetches real-time translation from Google Translate Live API and triggers asynchronous UI updates.
  String translate(String text) {
    if (text.trim().isEmpty || _currentLanguageCode == 'EN') {
      return text;
    }

    final cacheKey = '$_currentLanguageCode:$text';
    if (_syncCache.containsKey(cacheKey)) {
      return _syncCache[cacheKey]!;
    }

    // Trigger background live HTTP translation request from Google Translate API
    AutoTranslationService.translateText(text, _currentLanguageCode).then((translated) {
      if (translated != text && translated.isNotEmpty) {
        _syncCache[cacheKey] = translated;
        notifyListeners();
      }
    });

    return text; // Returns original text synchronously while live translation loads
  }
}
