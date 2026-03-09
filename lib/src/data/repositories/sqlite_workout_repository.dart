import 'package:sqflite/sqflite.dart';

import '../../application/parser/parsed_workout_set.dart';
import '../../domain/models/set_entry.dart';
import '../../domain/models/workout_template.dart';
import '../db/workout_database.dart';
import 'workout_repository.dart';

class SqliteWorkoutRepository implements WorkoutRepository {
  SqliteWorkoutRepository(this._database);

  final WorkoutDatabase _database;

  @override
  Future<int> createSession(String templateName) async {
    final db = await _database.open();
    return db.insert('workout_sessions', {
      'template_name': templateName,
      'started_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> addParsedSet({
    required int sessionId,
    required ParsedWorkoutSet parsed,
    required String transcript,
  }) async {
    final db = await _database.open();

    await db.transaction((txn) async {
      final exerciseEntryId = await _ensureExerciseEntry(
        txn: txn,
        sessionId: sessionId,
        exerciseName: parsed.exerciseName,
      );

      for (final set in parsed.sets) {
        await txn.insert('set_entries', {
          'exercise_entry_id': exerciseEntryId,
          'set_number': set.setNumber,
          'reps': set.reps,
          'weight': set.weight,
          'unit': set.unit,
          'source_transcript': transcript,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  @override
  Future<List<SetEntry>> getSessionSetHistory(int sessionId) async {
    final db = await _database.open();
    final rows = await db.rawQuery(
      '''
      SELECT se.*
      FROM set_entries se
      INNER JOIN exercise_entries ee ON ee.id = se.exercise_entry_id
      WHERE ee.session_id = ?
      ORDER BY se.created_at ASC
    ''',
      [sessionId],
    );

    return rows.map(SetEntry.fromMap).toList();
  }

  @override
  Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    final db = await _database.open();
    final templateRows = await db.query('workout_templates', orderBy: 'id ASC');

    final templates = <WorkoutTemplate>[];
    for (final templateRow in templateRows) {
      final templateId = templateRow['id'] as int;
      final exercisesRows = await db.query(
        'template_exercises',
        where: 'template_id = ?',
        whereArgs: [templateId],
        orderBy: 'order_index ASC',
      );

      templates.add(
        WorkoutTemplate(
          name: templateRow['name'] as String,
          exercises: exercisesRows
              .map(
                (row) => PlannedExercise(name: row['exercise_name'] as String, plannedSets: row['planned_sets'] as int),
              )
              .toList(growable: false),
        ),
      );
    }

    return templates;
  }

  @override
  Future<void> saveWorkoutTemplate(WorkoutTemplate template) async {
    final db = await _database.open();
    final cleanedName = template.name.trim();
    if (cleanedName.isEmpty) {
      throw Exception('Workout template name cannot be empty.');
    }

    await db.transaction((txn) async {
      final templateId = await txn.insert('workout_templates', {
        'name': cleanedName,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (var i = 0; i < template.exercises.length; i++) {
        final exercise = template.exercises[i];
        await txn.insert('template_exercises', {
          'template_id': templateId,
          'exercise_name': exercise.name,
          'planned_sets': exercise.plannedSets,
          'order_index': i,
        });
      }
    });
  }

  Future<int> _ensureExerciseEntry({
    required Transaction txn,
    required int sessionId,
    required String exerciseName,
  }) async {
    final existing = await txn.query(
      'exercise_entries',
      columns: ['id'],
      where: 'session_id = ? AND exercise_name = ?',
      whereArgs: [sessionId, exerciseName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    final orderIndex =
        Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COALESCE(MAX(order_index), -1) + 1 AS next_index FROM exercise_entries WHERE session_id = ?',
            [sessionId],
          ),
        ) ??
        0;

    return txn.insert('exercise_entries', {
      'session_id': sessionId,
      'exercise_name': exerciseName,
      'order_index': orderIndex,
    });
  }
}
