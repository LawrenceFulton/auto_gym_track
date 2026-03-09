import 'package:flutter/foundation.dart';

import '../../application/parser/parsed_workout_set.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/set_entry.dart';
import '../../domain/models/workout_template.dart';

class WorkoutSessionController extends ChangeNotifier {
  WorkoutSessionController({required WorkoutRepository repository}) : _repository = repository;

  final WorkoutRepository _repository;

  int? _sessionId;
  String _templateName = 'Core Day';
  String _currentExercise = 'Push-ups';
  List<SetEntry> _history = const [];

  int? get sessionId => _sessionId;
  String get templateName => _templateName;
  String get currentExercise => _currentExercise;
  List<SetEntry> get history => _history;
  bool get hasSession => _sessionId != null;

  Future<void> startSession(WorkoutTemplate template) async {
    final cleanName = template.name.trim().isEmpty ? 'Untitled Workout' : template.name.trim();
    final sessionId = await _repository.createSession(cleanName);
    final firstExercise = template.exercises.isEmpty ? 'Exercise' : template.exercises.first.name;

    _sessionId = sessionId;
    _templateName = cleanName;
    _currentExercise = firstExercise;
    _history = const [];
    notifyListeners();
  }

  Future<void> saveParsedSet({required ParsedWorkoutSet parsed, required String transcript}) async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }

    await _repository.addParsedSet(sessionId: sessionId, parsed: parsed, transcript: transcript);
    _history = await _repository.getSessionSetHistory(sessionId);
    notifyListeners();
  }
}
