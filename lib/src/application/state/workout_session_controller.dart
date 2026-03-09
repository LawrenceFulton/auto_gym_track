import 'package:flutter/foundation.dart';

import '../../application/parser/parsed_workout_set.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/set_entry.dart';
import '../../domain/models/workout_template.dart';

class WorkoutSessionController extends ChangeNotifier {
  WorkoutSessionController({required WorkoutRepository repository}) : _repository = repository;

  final WorkoutRepository _repository;

  int? _sessionId;
  WorkoutTemplate? _template;
  int _currentExerciseIndex = 0;
  List<SetEntry> _history = const [];
  bool _isFinished = false;
  DateTime? _startedAt;

  // Map of exercise names to their last performed sets
  Map<String, List<SetEntry>> _lastPerformanceRef = {};

  // Cache for pre-loaded reference data to eliminate start-session lag
  final Map<String, List<SetEntry>> _preCachedRefs = {};

  int? get sessionId => _sessionId;
  String get templateName => _template?.name ?? 'Untitled Workout';
  List<PlannedExercise> get plannedExercises => _template?.exercises ?? const [];
  int get currentExerciseIndex => _currentExerciseIndex;

  String get currentExercise => _template?.exercises[_currentExerciseIndex].name ?? 'Exercise';
  PlannedExercise? get currentPlannedExercise =>
      _template != null && _template!.exercises.isNotEmpty ? _template!.exercises[_currentExerciseIndex] : null;

  List<SetEntry> get history => _history;
  bool get hasSession => _sessionId != null;
  bool get isFinished => _isFinished;

  Duration get sessionDuration {
    if (_startedAt == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_startedAt!);
  }

  int get totalSetsCompleted => _history.length;
  int get totalExercisesPerformed => _history.map((e) => e.exerciseName).toSet().length;

  bool get canGoToNextExercise => _template != null && _currentExerciseIndex < _template!.exercises.length - 1;
  bool get canGoToPreviousExercise => _currentExerciseIndex > 0;

  int get setsDoneForCurrentExercise {
    return getSetsDoneForExercise(currentExercise);
  }

  int getSetsDoneForExercise(String exerciseName) {
    return _history.where((entry) => entry.exerciseName == exerciseName).length;
  }

  List<SetEntry> getLastPerformanceForExercise(String exerciseName) {
    return _lastPerformanceRef[exerciseName] ?? const [];
  }

  /// Pre-caches reference data for a template to make starting the session instant.
  Future<void> preCacheTemplateReferences(WorkoutTemplate template) async {
    final futures = template.exercises.map((e) {
      if (_preCachedRefs.containsKey(e.name)) {
        return Future.value(_preCachedRefs[e.name]);
      }
      return _repository.getLastSetHistoryForExercise(e.name);
    }).toList();

    final results = await Future.wait(futures);

    for (var i = 0; i < template.exercises.length; i++) {
      final name = template.exercises[i].name;
      final history = results[i];
      if (history != null && history.isNotEmpty) {
        _preCachedRefs[name] = history;
      }
    }
  }

  Future<void> startSession(WorkoutTemplate template) async {
    final cleanName = template.name.trim().isEmpty ? 'Untitled Workout' : template.name.trim();

    // Start session creation and history fetching in parallel
    final sessionIdFuture = _repository.createSession(cleanName);

    // Fetch last session data for each exercise in this template (parallelized)
    final historyFutures = template.exercises.map((e) {
      // Use pre-cached data if available, otherwise fetch
      if (_preCachedRefs.containsKey(e.name)) {
        return Future.value(_preCachedRefs[e.name]);
      }
      return _repository.getLastSetHistoryForExercise(e.name);
    }).toList();

    final results = await Future.wait([sessionIdFuture, ...historyFutures]);

    _sessionId = results[0] as int;
    _template = template;
    _currentExerciseIndex = 0;
    _history = const [];
    _isFinished = false;
    _startedAt = DateTime.now();

    _lastPerformanceRef = {};
    for (var i = 0; i < template.exercises.length; i++) {
      final history = results[i + 1] as List<SetEntry>;
      if (history.isNotEmpty) {
        _lastPerformanceRef[template.exercises[i].name] = history;
      }
    }

    notifyListeners();
  }

  Future<void> finishSession() async {
    final id = _sessionId;
    if (id != null) {
      if (_history.isEmpty) {
        // If no sets were done, delete the session entirely and return to setup.
        await _repository.deleteSession(id);
        reset();
      } else {
        await _repository.finishSession(id);
        _isFinished = true;
        notifyListeners();
      }
    }
  }

  void reset() {
    _sessionId = null;
    _template = null;
    _currentExerciseIndex = 0;
    _history = const [];
    _isFinished = false;
    _startedAt = null;
    _lastPerformanceRef = {};
    // Keep _preCachedRefs to speed up re-selection
    notifyListeners();
  }

  void goToExercise(int index) {
    if (_template != null && index >= 0 && index < _template!.exercises.length) {
      _currentExerciseIndex = index;
      notifyListeners();
    }
  }

  void goToNextExercise() {
    if (canGoToNextExercise) {
      _currentExerciseIndex++;
      notifyListeners();
    }
  }

  void goToPreviousExercise() {
    if (canGoToPreviousExercise) {
      _currentExerciseIndex--;
      notifyListeners();
    }
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

  Future<void> deleteSet(int setId) async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }
    await _repository.deleteSet(setId);
    _history = await _repository.getSessionSetHistory(sessionId);
    notifyListeners();
  }

  Future<void> updateSet(int setId, {required int reps, required double weight, required String unit}) async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }
    await _repository.updateSet(setId, reps: reps, weight: weight, unit: unit);
    _history = await _repository.getSessionSetHistory(sessionId);
    notifyListeners();
  }
}
