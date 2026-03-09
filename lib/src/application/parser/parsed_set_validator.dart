import 'parsed_workout_set.dart';

class ParsedSetValidationException implements Exception {
  ParsedSetValidationException(this.message);

  final String message;

  @override
  String toString() => 'ParsedSetValidationException: $message';
}

class ParsedSetValidator {
  ParsedWorkoutSet fromJson(Map<String, Object?> json) {
    final exerciseName = _stringValue(json['exercise_name'], 'exercise_name');
    final confidence = _doubleValue(json['confidence'], 'confidence');

    if (confidence < 0 || confidence > 1) {
      throw ParsedSetValidationException('confidence must be between 0 and 1');
    }

    final setsNode = json['sets'];
    if (setsNode is! List || setsNode.isEmpty) {
      throw ParsedSetValidationException('sets must be a non-empty array');
    }

    final sets = <ParsedSetItem>[];
    for (final node in setsNode) {
      if (node is! Map<String, Object?>) {
        throw ParsedSetValidationException('each set must be an object');
      }

      final setNumber = _intValue(node['set_number'], 'set_number');
      final reps = _intValue(node['reps'], 'reps');
      final weight = _doubleValue(node['weight'], 'weight');
      final unit = _stringValue(node['unit'], 'unit').toLowerCase().trim();

      if (setNumber <= 0) {
        throw ParsedSetValidationException('set_number must be >= 1');
      }
      if (reps <= 0) {
        throw ParsedSetValidationException('reps must be >= 1');
      }
      if (weight < 0) {
        throw ParsedSetValidationException('weight must be >= 0');
      }
      if (unit != 'kg' && unit != 'lb' && unit != 'lbs') {
        throw ParsedSetValidationException('unit must be kg, lb, or lbs');
      }

      sets.add(ParsedSetItem(setNumber: setNumber, reps: reps, weight: weight, unit: unit == 'lbs' ? 'lb' : unit));
    }

    final notes = json['notes'] as String?;

    return ParsedWorkoutSet(exerciseName: exerciseName, sets: sets, notes: notes, confidence: confidence);
  }

  String _stringValue(Object? value, String key) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw ParsedSetValidationException('$key must be a non-empty string');
  }

  int _intValue(Object? value, String key) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw ParsedSetValidationException('$key must be a number');
  }

  double _doubleValue(Object? value, String key) {
    if (value is num) {
      return value.toDouble();
    }
    throw ParsedSetValidationException('$key must be a number');
  }
}
