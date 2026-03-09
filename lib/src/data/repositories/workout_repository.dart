import '../../application/parser/parsed_workout_set.dart';
import '../../domain/models/set_entry.dart';
import '../../domain/models/workout_template.dart';

abstract class WorkoutRepository {
  Future<int> createSession(String templateName);

  Future<void> finishSession(int sessionId);

  Future<void> deleteSession(int sessionId);

  Future<void> addParsedSet({required int sessionId, required ParsedWorkoutSet parsed, required String transcript});

  Future<void> deleteSet(int setId);

  Future<void> updateSet(int setId, {required int reps, required double weight, required String unit});

  Future<List<SetEntry>> getSessionSetHistory(int sessionId);

  Future<List<SetEntry>> getLastSetHistoryForExercise(String exerciseName);

  Future<List<WorkoutTemplate>> getWorkoutTemplates();

  Future<void> saveWorkoutTemplate(WorkoutTemplate template);

  Future<void> deleteWorkoutTemplate(String name);
}
