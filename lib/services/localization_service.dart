import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _cachePrefix = 'translation_cache_';

  String _currentLanguageCode = 'en';
  final Map<String, Map<String, String>> _translationCache = {};
  bool _isTranslating = false;

  String get currentLanguageCode => _currentLanguageCode;
  bool get isTranslating => _isTranslating;
  bool get isRTL => _currentLanguageCode == 'ar';

  GlucoraLocale get currentLocale => kSupportedLocales.firstWhere(
        (l) => l.code == _currentLanguageCode,
        orElse: () => kSupportedLocales.first,
      );

  /// Initialize - load saved language preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguageCode = prefs.getString(_prefKey) ?? 'en';
    await _loadCachedTranslations(_currentLanguageCode);
    notifyListeners();
  }

  /// Change language — translates all registered strings via OpenRouter
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLanguageCode) return;
    _currentLanguageCode = languageCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);

    if (languageCode != 'en') {
      await _loadCachedTranslations(languageCode);
    }
    notifyListeners();
  }

  /// Translate a single string (uses cache first, then OpenRouter)
  Future<String> translate(String text, {String? targetLang}) async {
    final lang = targetLang ?? _currentLanguageCode;
    if (lang == 'en' || text.trim().isEmpty) return text;

    // Check in-memory cache
    if (_translationCache[lang]?[text] != null) {
      return _translationCache[lang]![text]!;
    }

    // Check persistent cache
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix${lang}_${text.hashCode}';
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      _translationCache[lang] ??= {};
      _translationCache[lang]![text] = cached;
      return cached;
    }

    // Call OpenRouter API
    final translated = await _translateViaOpenRouter([text], lang);
    if (translated.isNotEmpty) {
      final result = translated[text] ?? text;
      _translationCache[lang] ??= {};
      _translationCache[lang]![text] = result;
      await prefs.setString(cacheKey, result);
      return result;
    }
    return text;
  }

  /// Translate a batch of strings at once (efficient)
  Future<Map<String, String>> translateBatch(
    List<String> texts, {
    String? targetLang,
  }) async {
    final lang = targetLang ?? _currentLanguageCode;
    if (lang == 'en') {
      return {for (final t in texts) t: t};
    }

    final result = <String, String>{};
    final toTranslate = <String>[];

    for (final text in texts) {
      if (text.trim().isEmpty) {
        result[text] = text;
        continue;
      }
      final cached = _translationCache[lang]?[text];
      if (cached != null) {
        result[text] = cached;
      } else {
        toTranslate.add(text);
      }
    }

    if (toTranslate.isNotEmpty) {
      final translated = await _translateViaOpenRouter(toTranslate, lang);
      final prefs = await SharedPreferences.getInstance();
      for (final entry in translated.entries) {
        result[entry.key] = entry.value;
        _translationCache[lang] ??= {};
        _translationCache[lang]![entry.key] = entry.value;
        final cacheKey = '$_cachePrefix${lang}_${entry.key.hashCode}';
        await prefs.setString(cacheKey, entry.value);
      }
    }

    return result;
  }

  Future<void> _loadCachedTranslations(String lang) async {
    // Pre-warm cache with commonly used app strings
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

  /// Core OpenRouter translation call
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
        .firstWhere((l) => l.code == targetLang,
            orElse: () => kSupportedLocales.first)
        .name;

    // Build numbered list for translation
    final numbered = texts.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');

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
      // OpenRouter API endpoint
      final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      // Using a confirmed working model on OpenRouter
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://glucora.app', // Replace with your app's URL
          'X-Title': 'Glucora App', // Your app name
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001', // Fixed model name
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.1,
          'max_tokens': 4096,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null) {
          // Extract JSON from response
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
            return parsed.map((k, v) => MapEntry(k, v.toString()));
          }
        }
      } else {
        debugPrint('[Localization] OpenRouter error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[Localization] Translation error: $e');
    }
    return {};
  }

  List<String> _getCommonAppStrings() {
    return [
      // Navigation
      'Home', 'Calories', 'Log', 'Meds', 'Profile',
      // Profile screen
      'Profile', 'Settings', 'Edit Profile', 'Save', 'Cancel',
      'Height', 'Weight', 'Weekly Report', 'History & Export',
      'Reports & History', 'FAQs', 'Log Out', 'Switch to Guardian View',
      'years', 'cm', 'kg',
      // FAQs
      'How do I connect my glucose monitor?',
      'What do the glucose ranges mean?',
      'Can I share data with my doctor?',
      'How accurate are the predictions?',
      // Settings
      'Bluetooth Pairing', 'Connect your CGM sensor or pump',
      'My Connections & Sharing', 'Doctors, guardians & location sharing',
      'Connect with Care Team', 'Find and connect with doctors & guardians',
      'Dark Mode', 'Switch between light and dark theme',
      'Language', 'Choose your preferred language',
      // Connections
      'Connections', 'Guardians', 'Doctors',
      'Location Sharing', 'Your location is visible to connections',
      'Hidden from everyone', 'Seeing your location',
      'Location hidden from this person',
      'Blocked — global sharing is off',
      'Individual toggles are disabled while global sharing is off.',
      'No guardians connected yet.', 'No doctors connected yet.',
      'Remove', 'Remove Guardian', 'Remove Doctor',
      'They will no longer see your data.',
      // Bluetooth
      'Connect Device', 'Available Devices', 'Connected',
      'Pair', 'Pairing mode',
      'To pair a new device, put it in discovery mode and tap on it.',
      // Auth
      'Login', 'Sign Up', 'Email', 'Password', 'Name',
      'Phone Number', 'Age',
      // General
      'Loading...', 'Error', 'Success', 'Retry',
      'Failed to update', 'Profile updated successfully!',
      'Error updating profile',
      // Edit profile
      'Edit Profile',
      // Logout dialog
      'Log Out', 'Are you sure to log out of your account?', 'Logout',
      // Medication
      'Medications', 'Add Medication', 'No medications added yet.',
      // Snackbars
      'Copied', 'Failed to remove', 'Failed to load',
    ];
  }
}