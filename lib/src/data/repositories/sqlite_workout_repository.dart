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
  Future<void> finishSession(int sessionId) async {
    final db = await _database.open();
    await db.update(
      'workout_sessions',
      {'ended_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    final db = await _database.open();
    await db.delete('workout_sessions', where: 'id = ?', whereArgs: [sessionId]);
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
  Future<void> deleteSet(int setId) async {
    final db = await _database.open();
    await db.delete('set_entries', where: 'id = ?', whereArgs: [setId]);
  }

  @override
  Future<void> updateSet(int setId, {required int reps, required double weight, required String unit}) async {
    final db = await _database.open();
    await db.update(
      'set_entries',
      {'reps': reps, 'weight': weight, 'unit': unit},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  @override
  Future<List<SetEntry>> getSessionSetHistory(int sessionId) async {
    final db = await _database.open();
    final rows = await db.rawQuery(
      '''
      SELECT se.*, ee.exercise_name
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
  Future<List<SetEntry>> getLastSetHistoryForExercise(String exerciseName) async {
    final db = await _database.open();

    // Find the most recent session that includes this exercise
    final lastSessionRows = await db.rawQuery(
      '''
      SELECT ee.session_id
      FROM exercise_entries ee
      INNER JOIN workout_sessions ws ON ws.id = ee.session_id
      WHERE ee.exercise_name = ? AND ws.ended_at IS NOT NULL
      ORDER BY ws.ended_at DESC
      LIMIT 1
    ''',
      [exerciseName],
    );

    if (lastSessionRows.isEmpty) {
      return const [];
    }

    final sessionId = lastSessionRows.first['session_id'] as int;

    // Get all sets for this exercise from that session
    final rows = await db.rawQuery(
      '''
      SELECT se.*, ee.exercise_name
      FROM set_entries se
      INNER JOIN exercise_entries ee ON ee.id = se.exercise_entry_id
      WHERE ee.session_id = ? AND ee.exercise_name = ?
      ORDER BY se.set_number ASC
    ''',
      [sessionId, exerciseName],
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

  @override
  Future<void> deleteWorkoutTemplate(String name) async {
    final db = await _database.open();
    await db.transaction((txn) async {
      final templates = await txn.query('workout_templates', where: 'name = ?', whereArgs: [name]);
      if (templates.isNotEmpty) {
        final templateId = templates.first['id'] as int;
        await txn.delete('template_exercises', where: 'template_id = ?', whereArgs: [templateId]);
        await txn.delete('workout_templates', where: 'id = ?', whereArgs: [templateId]);
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
