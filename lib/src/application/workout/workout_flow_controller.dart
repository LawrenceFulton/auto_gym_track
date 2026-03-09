import '../parser/parsed_workout_set.dart';

enum WorkoutFlowState { idle, recording, transcribing, extracting, reviewing, saved, error }

class WorkoutFlowController {
  WorkoutFlowController();

  WorkoutFlowState state = WorkoutFlowState.idle;
  ParsedWorkoutSet? parsed;
  String? transcript;
  String? error;

  Future<void> runExtractionForTranscript(
    String inputTranscript, {
    required String exerciseName,
    required int setNumber,
    Future<ParsedWorkoutSet> Function(String transcript, String exerciseName, int setNumber)? extractor,
  }) async {
    try {
      state = WorkoutFlowState.transcribing;
      transcript = inputTranscript;

      state = WorkoutFlowState.extracting;

      if (extractor != null) {
        parsed = await extractor(inputTranscript, exerciseName, setNumber);
      } else {
        // thow error
        throw Exception('Extractor function is not provided');
      }

      state = WorkoutFlowState.reviewing;
      error = null;
    } catch (exception) {
      state = WorkoutFlowState.error;
      error = exception.toString();
    }
  }

  void markSaved() {
    state = WorkoutFlowState.saved;
  }
}
