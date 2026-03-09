import 'package:flutter/foundation.dart';

import '../../application/workout/workout_flow_controller.dart';
import '../../data/services/openrouter_client.dart';
import '../../data/services/speech_to_text_service.dart';
import '../parser/parsed_workout_set.dart';

class WorkoutCaptureController extends ChangeNotifier {
  WorkoutCaptureController({required SpeechToTextService speechToTextService})
    : _speechToTextService = speechToTextService;

  final SpeechToTextService _speechToTextService;
  final WorkoutFlowController _flow = WorkoutFlowController();

  String? _pendingExercise;
  int? _pendingSetNumber;
  OpenRouterClient? _pendingClient;

  WorkoutFlowState get state => _flow.state;
  ParsedWorkoutSet? get parsed => _flow.parsed;
  String? get transcript => _flow.transcript;
  String? get error => _flow.error;

  Future<void> startRecording({
    required String currentExercise,
    required int nextSetNumber,
    required OpenRouterClient openRouterClient,
  }) async {
    if (_flow.state == WorkoutFlowState.recording ||
        _flow.state == WorkoutFlowState.transcribing ||
        _flow.state == WorkoutFlowState.extracting) {
      return;
    }

    _flow.state = WorkoutFlowState.recording;
    _flow.error = null;
    _flow.parsed = null;
    _flow.transcript = null;
    _pendingExercise = currentExercise;
    _pendingSetNumber = nextSetNumber;
    _pendingClient = openRouterClient;
    notifyListeners();

    try {
      await _speechToTextService.startListening();
    } catch (exception) {
      _flow.state = WorkoutFlowState.error;
      _flow.error = exception.toString();
      _pendingExercise = null;
      _pendingSetNumber = null;
      _pendingClient = null;
      notifyListeners();
    }
  }

  Future<void> stopRecordingAndExtract() async {
    if (_flow.state != WorkoutFlowState.recording) {
      return;
    }

    final exercise = _pendingExercise;
    final setNumber = _pendingSetNumber;
    final client = _pendingClient;

    _pendingExercise = null;
    _pendingSetNumber = null;
    _pendingClient = null;

    if (exercise == null || setNumber == null || client == null) {
      _flow.state = WorkoutFlowState.error;
      _flow.error = 'Recording context was lost. Please try again.';
      notifyListeners();
      return;
    }

    try {
      final transcript = await _speechToTextService.stopListening();
      await _flow.runExtractionForTranscript(
        transcript,
        exerciseName: exercise,
        setNumber: setNumber,
        extractor: (rawTranscript, exerciseName, setNumber) {
          return client.extractWorkoutSet(rawTranscript, exerciseName: exerciseName, setNumber: setNumber);
        },
      );
    } catch (exception) {
      _flow.state = WorkoutFlowState.error;
      _flow.error = exception.toString();
    }

    notifyListeners();
  }

  void markSaved() {
    _flow.markSaved();
    notifyListeners();
  }

  void reset() {
    _flow.state = WorkoutFlowState.idle;
    _flow.parsed = null;
    _flow.transcript = null;
    _flow.error = null;
    _pendingExercise = null;
    _pendingSetNumber = null;
    _pendingClient = null;
    notifyListeners();
  }
}
