import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../application/parser/parsed_set_validator.dart';
import '../../application/parser/parsed_workout_set.dart';

class OpenRouterClient {
  OpenRouterClient({required this.apiKey, http.Client? httpClient, ParsedSetValidator? validator})
    : _httpClient = httpClient ?? http.Client(),
      _validator = validator ?? ParsedSetValidator();

  final String apiKey;
  final http.Client _httpClient;
  final ParsedSetValidator _validator;

  Future<ParsedWorkoutSet> extractWorkoutSet(
    String transcript, {
    required String exerciseName,
    required int setNumber,
    String? unitPreference,
  }) async {
    final unitContext = unitPreference != null ? 'Use "$unitPreference" as the default unit if none is mentioned. ' : '';
    final response = await _httpClient
        .post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': 'openai/gpt-4o-mini',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You extract reps/weight/unit for ONE gym set into strict JSON only. The JSON should have this format: {"reps": int, "weight": number, "unit": "kg" or "lb", "notes": string or null, "confidence": number between 0 and 1}. ${unitContext}Only provide the JSON, no explanations. ',
              },
              {
                'role': 'user',
                'content': 'Context: exercise_name="$exerciseName", set_number=$setNumber. Transcript: "$transcript".',
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OpenRouter request failed with ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, Object?>;
    final choices = payload['choices'] as List<Object?>;
    final firstChoice = choices.first as Map<String, Object?>;
    final message = firstChoice['message'] as Map<String, Object?>;
    final content = message['content'] as String;
    final jsonContent = jsonDecode(content) as Map<String, Object?>;

    debugPrint('OpenRouter extraction payload: $jsonContent');

    final normalized = <String, Object?>{
      'exercise_name': exerciseName,
      'sets': [
        {
          'set_number': setNumber,
          'reps': jsonContent['reps'],
          'weight': jsonContent['weight'],
          'unit': jsonContent['unit'] ?? unitPreference ?? 'kg',
        },
      ],
      'notes': jsonContent['notes'],
      'confidence': jsonContent['confidence'] ?? 0.7,
    };

    return _validator.fromJson(normalized);
  }
}
