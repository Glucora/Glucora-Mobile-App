import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─── RECOMMENDATION MODEL ─────────────────────────────────────────────────────

/// A single structured recommendation parsed from the AI response.
class AIRecommendation {
  final String category;   // 'dietary' | 'activity' | 'monitoring' | 'general'
  final String title;      // short label — first sentence or heading
  final String message;    // full advice text

  const AIRecommendation({
    required this.category,
    required this.title,
    required this.message,
  });
}

// ─── AI SERVICE ───────────────────────────────────────────────────────────────

class AIService {
  static String get _apiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENROUTER_API_KEY not found in environment variables. Please check your .env file.');
    }
    return key;
  }
  
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'meta-llama/llama-3.2-3b-instruct:free';

  /// Calls OpenRouter with the patient's glucose data and returns a structured
  /// list of [AIRecommendation] objects ready to display and save to DB.
  static Future<List<AIRecommendation>> getRecommendations({
    required double currentGlucose,
    required double predictedGlucose,
    double targetMin = 70,
    double targetMax = 180,
  }) async {
    final glucoseStatus = currentGlucose < targetMin
        ? 'BELOW target range (too low)'
        : currentGlucose > targetMax
            ? 'ABOVE target range (too high)'
            : 'within target range';

    final trend = predictedGlucose > currentGlucose + 10
        ? 'rising'
        : predictedGlucose < currentGlucose - 10
            ? 'falling'
            : 'stable';

    final prompt = '''
You are a diabetes management AI assistant helping a patient understand their glucose data.

Patient glucose data:
- Current glucose: ${currentGlucose.toInt()} mg/dL — $glucoseStatus
- Target range: ${targetMin.toInt()}–${targetMax.toInt()} mg/dL
- Predicted glucose in 1 hour: ${predictedGlucose.toInt()} mg/dL (trend: $trend)

Give exactly 3 personalized recommendations. Use this EXACT format with no deviation:

DIETARY: [one sentence of specific dietary advice based on the glucose level above]
ACTIVITY: [one sentence of specific physical activity advice]
MONITORING: [one sentence about what the patient should watch for or track]

Rules:
- Each line must start with the category label in capitals followed by a colon
- Tailor advice to the actual glucose values — do not give generic advice
- Never recommend insulin doses or specific medications
- Keep each recommendation under 40 words
''';

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer ${_apiKey}',  // ✅ Using the getter
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://glucora.app',
              'X-Title': 'Glucora AI Companion',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a diabetes management assistant. Follow formatting instructions exactly. Never give medical diagnosis or medication dosage advice.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.6,
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['choices']?[0]?['message']?['content'] ?? '';

        if (kDebugMode) print('[AIService] Raw response:\n$raw');

        final parsed = _parseResponse(raw.trim());

        if (parsed.isNotEmpty) return parsed;

        // If parsing fails return a best-effort single item with the full text
        return [
          AIRecommendation(
            category: 'general',
            title: 'Personalized advice',
            message: raw.trim(),
          ),
        ];
      } else {
        if (kDebugMode) {
          print('[AIService] HTTP ${response.statusCode}: ${response.body}');
        }
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('[AIService] getRecommendations error: $e');
      rethrow; // let the screen handle the error — no silent fallback
    }
  }

  /// Parses the AI text into structured [AIRecommendation] objects.
  /// Expects lines like: "DIETARY: some advice text"
  static List<AIRecommendation> _parseResponse(String raw) {
    final List<AIRecommendation> results = [];

    // Category label → normalized key
    final Map<String, String> categoryMap = {
      'DIETARY': 'dietary',
      'DIET': 'dietary',
      'FOOD': 'dietary',
      'NUTRITION': 'dietary',
      'ACTIVITY': 'activity',
      'EXERCISE': 'activity',
      'PHYSICAL': 'activity',
      'MONITORING': 'monitoring',
      'MONITOR': 'monitoring',
      'TRACKING': 'monitoring',
      'GENERAL': 'general',
    };

    // Category → display title
    const Map<String, String> titleMap = {
      'dietary': 'Dietary advice',
      'activity': 'Physical activity',
      'monitoring': 'What to monitor',
      'general': 'General advice',
    };

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Match lines like "DIETARY: some text" or "1. DIETARY: some text"
      final match = RegExp(
        r'^(?:\d+[\.\)]\s*)?([A-Z]+)\s*:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (match != null) {
        final labelRaw = match.group(1)!.toUpperCase();
        final messageText = match.group(2)!.trim();

        // Find which category this label maps to
        String? category;
        for (final key in categoryMap.keys) {
          if (labelRaw.contains(key)) {
            category = categoryMap[key];
            break;
          }
        }

        // Skip duplicates of the same category
        if (category != null &&
            results.every((r) => r.category != category)) {
          results.add(AIRecommendation(
            category: category,
            title: titleMap[category] ?? 'Advice',
            message: messageText,
          ));
        }
      }
    }

    return results;
  }

  /// Quick connectivity check — returns true if the API responds.
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer ${_apiKey}',  // ✅ Using the getter
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': "Reply with 'ok'"},
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('[AIService] testConnection error: $e');
      return false;
    }
  }
}