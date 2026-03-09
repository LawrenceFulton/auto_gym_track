import '../../application/parser/parsed_workout_set.dart';
import '../../domain/models/set_entry.dart';
import '../../domain/models/workout_template.dart';

abstract class WorkoutRepository {
  Future<int> createSession(String templateName);

  Future<void> addParsedSet({required int sessionId, required ParsedWorkoutSet parsed, required String transcript});

  Future<List<SetEntry>> getSessionSetHistory(int sessionId);

  Future<List<WorkoutTemplate>> getWorkoutTemplates();

  Future<void> saveWorkoutTemplate(WorkoutTemplate template);
}
