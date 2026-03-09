import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart' as sqlite;

class WorkoutDatabase {
  WorkoutDatabase({this.overridePath, sqlite.DatabaseFactory? databaseFactory}) : _databaseFactory = databaseFactory;

  static const _schemaVersion = 2;

  final String? overridePath;
  final sqlite.DatabaseFactory? _databaseFactory;
  sqlite.Database? _database;

  Future<sqlite.Database> open() async {
    if (_database != null) {
      return _database!;
    }

    final dbPath = overridePath ?? await _defaultPath();
    final factory = _databaseFactory;

    if (factory != null) {
      _database = await factory.openDatabase(
        dbPath,
        options: sqlite.OpenDatabaseOptions(
          version: _schemaVersion,
          onCreate: (db, version) => _onCreate(db),
          onUpgrade: (db, oldVersion, newVersion) => _onUpgrade(db, oldVersion, newVersion),
        ),
      );
    } else {
      _database = await sqflite.openDatabase(
        dbPath,
        version: _schemaVersion,
        onCreate: (db, version) => _onCreate(db),
        onUpgrade: (db, oldVersion, newVersion) => _onUpgrade(db, oldVersion, newVersion),
      );
    }

    return _database!;
  }

  Future<void> _onCreate(sqlite.Database db) async {
    await db.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_name TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        media_ref TEXT,
        UNIQUE(session_id, exercise_name),
        FOREIGN KEY(session_id) REFERENCES workout_sessions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE set_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_entry_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        unit TEXT NOT NULL,
        source_transcript TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(exercise_entry_id) REFERENCES exercise_entries(id)
      )
    ''');

    await _createWorkoutTemplateTables(db);
  }

  Future<void> _onUpgrade(sqlite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createWorkoutTemplateTables(db);
    }
  }

  Future<void> _createWorkoutTemplateTables(sqlite.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS template_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        planned_sets INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY(template_id) REFERENCES workout_templates(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<String> _defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'auto_gym_track.db');
  }
}
