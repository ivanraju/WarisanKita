import 'dart:convert';
import 'package:http/http.dart' as http;

class AutoTranslationService {
  static final Map<String, String> _translationCache = {};

  /// Dynamically translates any English text to target language using Google Translate Live API
  static Future<String> translateText(String text, String targetLanguageCode) async {
    if (text.trim().isEmpty || targetLanguageCode == 'EN') {
      return text;
    }

    String apiTarget = 'en';
    if (targetLanguageCode == 'BM') {
      apiTarget = 'ms';
    } else if (targetLanguageCode == 'ZH') {
      apiTarget = 'zh-CN';
    } else if (targetLanguageCode == 'JA') {
      apiTarget = 'ja';
    }

    final cacheKey = '$apiTarget:$text';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$apiTarget&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0] is List) {
          final StringBuffer sb = StringBuffer();
          for (var segment in data[0]) {
            if (segment is List && segment.isNotEmpty && segment[0] is String) {
              sb.write(segment[0]);
            }
          }
          final translatedResult = sb.toString();
          if (translatedResult.isNotEmpty) {
            _translationCache[cacheKey] = translatedResult;
            return translatedResult;
          }
        }
      }
    } catch (_) {
      // Fallback if offline or timeout
    }

    return text;
  }
}
