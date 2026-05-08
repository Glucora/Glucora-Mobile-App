import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_strings.dart';
import 'translation_cache_db.dart';

/// Supported languages for Glucora
class GlucoraLocale {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const GlucoraLocale({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

const List<GlucoraLocale> kSupportedLocales = [
  GlucoraLocale(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
  GlucoraLocale(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇪🇬'),
  GlucoraLocale(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
  GlucoraLocale(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
  GlucoraLocale(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  GlucoraLocale(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
  GlucoraLocale(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
];

class LocalizationService extends ChangeNotifier {
  static const String _prefKey = 'selected_language_code';

  String _currentLanguageCode = 'en';
  // In-memory layer — fastest possible lookup, lives only for the app session
  final Map<String, Map<String, String>> _translationCache = {};
  bool _isTranslating = false;

  // SQLite cache layer — persists across sessions
  final _db = TranslationCacheDb();

  String get currentLanguageCode => _currentLanguageCode;
  bool get isTranslating => _isTranslating;
  bool get isRTL => _currentLanguageCode == 'ar';

  GlucoraLocale get currentLocale => kSupportedLocales.firstWhere(
        (l) => l.code == _currentLanguageCode,
        orElse: () => kSupportedLocales.first,
      );

  /// Initialize — load saved language preference and warm up cache
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguageCode = prefs.getString(_prefKey) ?? 'en';

    // Optionally prune stale entries older than 30 days on startup
    await _db.pruneOlderThan(30);

    await _loadCachedTranslations(_currentLanguageCode);
    notifyListeners();
  }

  /// Change language — translates all registered strings via OpenRouter
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLanguageCode) return;
    _currentLanguageCode = languageCode;

    // SharedPreferences is still fine for this single string preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);

    if (languageCode != 'en') {
      await _loadCachedTranslations(languageCode);
    }
    notifyListeners();
  }

  /// Translate a single string.
  /// Cache lookup order: in-memory → SQLite → API call
  Future<String> translate(String text, {String? targetLang}) async {
    final lang = targetLang ?? _currentLanguageCode;
    if (lang == 'en' || text.trim().isEmpty) return text;

    // 1. In-memory cache (no async, instant)
    if (_translationCache[lang]?[text] != null) {
      return _translationCache[lang]![text]!;
    }

    // 2. SQLite cache (fast local DB read)
    final cached = await _db.get(lang, text);
    if (cached != null) {
      _translationCache[lang] ??= {};
      _translationCache[lang]![text] = cached;
      return cached;
    }

    // 3. API call — only when both caches miss
    final translated = await _translateViaOpenRouter([text], lang);
    if (translated.isNotEmpty) {
      final result = translated[text] ?? text;
      _translationCache[lang] ??= {};
      _translationCache[lang]![text] = result;
      await _db.put(lang, text, result);
      return result;
    }

    return text;
  }

  /// Translate a batch of strings efficiently.
  /// Hits in-memory first, then SQLite for the rest, then API only for true misses.
  Future<Map<String, String>> translateBatch(
    List<String> texts, {
    String? targetLang,
  }) async {
    final lang = targetLang ?? _currentLanguageCode;
    if (lang == 'en') {
      return {for (final t in texts) t: t};
    }

    final result = <String, String>{};
    final notInMemory = <String>[];

    // ── Pass 1: in-memory cache ──────────────────────────────────────────
    for (final text in texts) {
      if (text.trim().isEmpty) {
        result[text] = text;
        continue;
      }
      final cached = _translationCache[lang]?[text];
      if (cached != null) {
        result[text] = cached;
      } else {
        notInMemory.add(text);
      }
    }

    if (notInMemory.isEmpty) return result;

    // ── Pass 2: SQLite batch lookup (single query for all misses) ─────────
    final dbHits = await _db.getMany(lang, notInMemory);
    final notInDb = <String>[];

    for (final text in notInMemory) {
      if (dbHits.containsKey(text)) {
        result[text] = dbHits[text]!;
        // Promote to in-memory so next call is instant
        _translationCache[lang] ??= {};
        _translationCache[lang]![text] = dbHits[text]!;
      } else {
        notInDb.add(text);
      }
    }

    if (notInDb.isEmpty) return result;

    // ── Pass 3: API call only for strings missing from both caches ────────
    final translated = await _translateViaOpenRouter(notInDb, lang);
    if (translated.isNotEmpty) {
      for (final entry in translated.entries) {
        result[entry.key] = entry.value;
        _translationCache[lang] ??= {};
        _translationCache[lang]![entry.key] = entry.value;
      }
      // Write all new translations in one SQLite transaction
      await _db.putMany(lang, translated);
    }

    // Fall back to original text for anything the API didn't return
    for (final text in notInDb) {
      result.putIfAbsent(text, () => text);
    }

    return result;
  }

  /// Pre-warms the cache with common app strings for the given language.
  /// Shows the isTranslating flag so the UI can display a loading indicator.
  Future<void> _loadCachedTranslations(String lang) async {
    if (lang == 'en') return;

    final commonStrings = _getCommonAppStrings();
    _isTranslating = true;
    notifyListeners();

    try {
      await translateBatch(commonStrings, targetLang: lang);
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Core OpenRouter translation call — only called on cache misses.
  Future<Map<String, String>> _translateViaOpenRouter(
    List<String> texts,
    String targetLang,
  ) async {
    final apiKey = dotenv.env['OPENROUTERLOC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[Localization] OPENROUTERLOC_API_KEY not found in .env');
      return {};
    }

    final langName = kSupportedLocales
        .firstWhere(
          (l) => l.code == targetLang,
          orElse: () => kSupportedLocales.first,
        )
        .name;

    final numbered =
        texts.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');

    final prompt = '''
You are a medical app translator for a diabetes management app called Glucora.
Translate the following UI strings from English to $langName.
Rules:
- Keep the same tone (professional but friendly)
- Preserve any special characters, punctuation at start/end
- Do NOT translate: email addresses, phone numbers, version numbers, proper nouns like "Glucora", "Dexcom", "Medtronic", "Abbott"
- Return ONLY a JSON object with the original English text as keys and translated text as values
- No explanations, no markdown, just pure JSON

Strings to translate:
$numbered

Return format:
{"original text 1": "translated text 1", "original text 2": "translated text 2", ...}
''';

    try {
      final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://glucora.app',
              'X-Title': 'Glucora App',
            },
            body: jsonEncode({
              'model': 'google/gemini-2.0-flash-001',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.1,
              'max_tokens': 4096,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['choices']?[0]?['message']?['content'] as String?;
        if (content != null) {
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            final parsed =
                jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
            return parsed.map((k, v) => MapEntry(k, v.toString()));
          }
        }
      } else {
        debugPrint(
            '[Localization] OpenRouter error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[Localization] Translation error: $e');
    }

    return {};
  }

  List<String> _getCommonAppStrings() {
    return AppStrings.getAllStrings();
  }
}