import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─── RECOMMENDATION MODEL ─────────────────────────────────────────────────────

class AIRecommendation {
  final String category;
  final String title;
  final String message;

  const AIRecommendation({
    required this.category,
    required this.title,
    required this.message,
  });
}

// ─── AI SERVICE ───────────────────────────────────────────────────────────────

class AIService {
  static final String _apiKey = dotenv.env['OPENROUTER_API_KEY']!;
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Fallback list — tries each in order until one works
 static const List<String> _models = [
  // BEST ALL-ROUNDER - Updated Llama
  'meta-llama/llama-3.3-70b-instruct:free',
  
  // EXCELLENT FOR REASONING/CODING
  'deepseek/deepseek-r1:free',
  
  // LATEST NVIDIA MODELS (Very fast)
  'nvidia/nemotron-3-super:free',      // 120B MoE, 1M context [citation:1]
  'nvidia/nemotron-nano-9b-v2:free',   // Fastest, 100-150 token/s [citation:4]
  
  // GOOGLE'S LATEST
  'google/gemma-4-31b-it:free',        // Updated version [citation:1]
  
  // OPENAI'S OPEN-WEIGHT MODELS
  'openai/gpt-oss-120b:free',          // 117B MoE [citation:1]
  'openai/gpt-oss-20b:free',           // Lighter version
  
  // NVIDIA MULTIMODAL (if you need image/video)
  'nvidia/nemotron-nano-12b-2-vl:free',
  
  // FAST & LIGHTWEIGHT
  'z-ai/glm-4.5-air:free',             // 90-130 token/s [citation:4]
      
    'openrouter/free',                  
  
];

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

    for (final model in _models) {
      try {
        if (kDebugMode) print('[AIService] Trying model: $model');

        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://glucora.app',
                'X-Title': 'Glucora AI Companion',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are a diabetes management assistant. Follow formatting instructions exactly. Never give medical diagnosis or medication dosage advice.',
                  },
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': 0.6,
                'max_tokens': 250,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final raw =
              data['choices']?[0]?['message']?['content'] as String? ?? '';

          if (kDebugMode) print('[AIService] Raw response from $model:\n$raw');

          if (raw.trim().isEmpty) {
            if (kDebugMode) {
              print('[AIService] Empty response from $model, trying next...');
            }
            continue;
          }

          final parsed = _parseResponse(raw.trim());
          if (parsed.isNotEmpty) return parsed;

          // Parsing failed but we have text — return as general advice
          return [
            AIRecommendation(
              category: 'general',
              title: 'Personalized advice',
              message: raw.trim(),
            ),
          ];
        } else if (response.statusCode == 429 ||
            response.statusCode == 404 ||
            response.statusCode == 503) {
          if (kDebugMode) {
            print(
                '[AIService] $model returned ${response.statusCode}, trying next...');
          }
          continue;
        } else {
          if (kDebugMode) {
            print(
                '[AIService] $model returned ${response.statusCode}: ${response.body}');
          }
          continue;
        }
      } catch (e) {
        if (kDebugMode) print('[AIService] $model failed: $e, trying next...');
        continue;
      }
    }

    throw Exception('All models failed. Please try again later.');
  }

  // ─── PARSER ───────────────────────────────────────────────────────────────

  static List<AIRecommendation> _parseResponse(String raw) {
    final List<AIRecommendation> results = [];

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

    const Map<String, String> titleMap = {
      'dietary': 'Dietary advice',
      'activity': 'Physical activity',
      'monitoring': 'What to monitor',
      'general': 'General advice',
    };

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = RegExp(
        r'^(?:\d+[\.\)]\s*)?([A-Z]+)\s*:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (match != null) {
        final labelRaw = match.group(1)!.toUpperCase();
        final messageText = match.group(2)!.trim();

        String? category;
        for (final key in categoryMap.keys) {
          if (labelRaw.contains(key)) {
            category = categoryMap[key];
            break;
          }
        }

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

  // ─── TEST CONNECTION ──────────────────────────────────────────────────────

  static Future<bool> testConnection() async {
    for (final model in _models) {
      try {
        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'user', 'content': "Reply with 'ok'"},
                ],
                'max_tokens': 5,
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}