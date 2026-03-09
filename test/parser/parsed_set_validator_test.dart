import 'package:auto_gym_track/src/application/parser/parsed_set_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParsedSetValidator', () {
    final validator = ParsedSetValidator();

    test('parses a valid payload', () {
      final result = validator.fromJson({
        'exercise_name': 'Bench Press',
        'sets': [
          {'set_number': 1, 'reps': 8, 'weight': 85, 'unit': 'kg'},
        ],
        'notes': null,
        'confidence': 0.9,
      });

      expect(result.exerciseName, 'Bench Press');
      expect(result.sets.single.reps, 8);
      expect(result.sets.single.weight, 85);
      expect(result.confidence, 0.9);
    });

    test('throws for missing sets', () {
      expect(
        () => validator.fromJson({
          'exercise_name': 'Bench Press',
          'sets': <Map<String, Object?>>[],
          'notes': null,
          'confidence': 0.9,
        }),
        throwsA(isA<ParsedSetValidationException>()),
      );
    });
  });
}
