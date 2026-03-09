import 'dart:io';

import 'package:auto_gym_track/src/application/parser/parsed_workout_set.dart';
import 'package:auto_gym_track/src/data/db/workout_database.dart';
import 'package:auto_gym_track/src/data/repositories/sqlite_workout_repository.dart';
import 'package:auto_gym_track/src/domain/models/workout_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late WorkoutDatabase database;
  late SqliteWorkoutRepository repository;

  setUp(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('auto_gym_track_test_');
    database = WorkoutDatabase(overridePath: p.join(tempDir.path, 'test.db'), databaseFactory: databaseFactoryFfi);
    repository = SqliteWorkoutRepository(database);
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('creates session and stores parsed sets', () async {
    final sessionId = await repository.createSession('Push Day');

    await repository.addParsedSet(
      sessionId: sessionId,
      transcript: 'Bench press, three sets of eight at eighty-five kilos.',
      parsed: const ParsedWorkoutSet(
        exerciseName: 'Bench Press',
        sets: [
          ParsedSetItem(setNumber: 1, reps: 8, weight: 85, unit: 'kg'),
          ParsedSetItem(setNumber: 2, reps: 8, weight: 85, unit: 'kg'),
        ],
        notes: null,
        confidence: 0.9,
      ),
    );

    final history = await repository.getSessionSetHistory(sessionId);
    expect(history.length, 2);
    expect(history.first.reps, 8);
    expect(history.first.unit, 'kg');
  });

  test('persists workout templates across repository reopen', () async {
    final customTemplate = const WorkoutTemplate(
      name: 'Leg Day',
      exercises: [
        PlannedExercise(name: 'Deadlift', plannedSets: 5),
        PlannedExercise(name: 'Lunges', plannedSets: 3),
      ],
    );

    await repository.saveWorkoutTemplate(customTemplate);
    final templatesBeforeClose = await repository.getWorkoutTemplates();
    expect(templatesBeforeClose.any((template) => template.name == 'Leg Day'), isTrue);

    await database.close();

    final reopenedDatabase = WorkoutDatabase(
      overridePath: p.join(tempDir.path, 'test.db'),
      databaseFactory: databaseFactoryFfi,
    );
    final reopenedRepository = SqliteWorkoutRepository(reopenedDatabase);

    final templatesAfterReopen = await reopenedRepository.getWorkoutTemplates();
    final saved = templatesAfterReopen.firstWhere((template) => template.name == 'Leg Day');
    expect(saved.exercises.length, 2);
    expect(saved.exercises.first.name, 'Deadlift');
    expect(saved.exercises.first.plannedSets, 5);

    await reopenedDatabase.close();
  });
}
