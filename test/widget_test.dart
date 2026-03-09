import 'package:auto_gym_track/main.dart';
import 'package:auto_gym_track/src/application/parser/parsed_workout_set.dart';
import 'package:auto_gym_track/src/data/repositories/workout_repository.dart';
import 'package:auto_gym_track/src/data/services/openrouter_key_store.dart';
import 'package:auto_gym_track/src/domain/models/set_entry.dart';
import 'package:auto_gym_track/src/domain/models/workout_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prompts for OpenRouter key when no key is stored', (WidgetTester tester) async {
    await tester.pumpWidget(
      AutoGymTrackApp(keyStore: InMemoryOpenRouterKeyStore(), workoutRepository: _InMemoryWorkoutRepository()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Connect OpenRouter'), findsOneWidget);
    expect(find.text('Save Key'), findsOneWidget);
  });

  testWidgets('shows workout chooser when key is already stored', (WidgetTester tester) async {
    await tester.pumpWidget(
      AutoGymTrackApp(
        keyStore: InMemoryOpenRouterKeyStore(seedKey: 'test-key'),
        workoutRepository: _InMemoryWorkoutRepository(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Choose Workout'), findsOneWidget);
    expect(find.text('Workout Preview'), findsOneWidget);
    expect(find.text('Confirm Workout', skipOffstage: false), findsOneWidget);
  });
}

class _InMemoryWorkoutRepository implements WorkoutRepository {
  final List<WorkoutTemplate> _templates = [];

  @override
  Future<void> addParsedSet({
    required int sessionId,
    required ParsedWorkoutSet parsed,
    required String transcript,
  }) async {}

  @override
  Future<int> createSession(String templateName) async => 1;

  @override
  Future<void> finishSession(int sessionId) async {}

  @override
  Future<void> deleteSession(int sessionId) async {}

  @override
  Future<void> deleteSet(int setId) async {}

  @override
  Future<void> updateSet(int setId, {required int reps, required double weight, required String unit}) async {}

  @override
  Future<List<SetEntry>> getSessionSetHistory(int sessionId) async => const [];

  @override
  Future<List<SetEntry>> getLastSetHistoryForExercise(String exerciseName) async => const [];

  @override
  Future<List<WorkoutTemplate>> getWorkoutTemplates() async => List.unmodifiable(_templates);

  @override
  Future<void> saveWorkoutTemplate(WorkoutTemplate template) async {
    _templates.add(template);
  }

  @override
  Future<void> deleteWorkoutTemplate(String name) async {
    _templates.removeWhere((t) => t.name == name);
  }
}
