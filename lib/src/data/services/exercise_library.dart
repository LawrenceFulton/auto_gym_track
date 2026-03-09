import 'dart:convert';
import 'package:flutter/services.dart';

class Exercise {
  final String name;
  final List<String> synonyms;

  Exercise({required this.name, required this.synonyms});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      synonyms: (json['synonyms'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }
}

class ExerciseLibrary {
  static List<Exercise> _exercises = [];

  static List<Exercise> get exercises => _exercises;
  
  static List<String> get exerciseNames => _exercises.map((e) => e.name).toList();

  static Future<void> load() async {
    try {
      final String response = await rootBundle.loadString('assets/exercises.json');
      final data = await json.decode(response);
      if (data is List) {
        _exercises = data.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
        _exercises.sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (e) {
      // Fallback if file missing or error
      _exercises = [
        Exercise(name: 'Push-ups', synonyms: ['Liegestütze']),
        Exercise(name: 'Plank', synonyms: ['Unterarmstütz']),
        Exercise(name: 'Squat', synonyms: ['Kniebeuge']),
        Exercise(name: 'Bench Press', synonyms: ['Bankdrücken']),
      ];
    }
  }

  static List<String> search(String query) {
    if (query.isEmpty) return exerciseNames;
    
    final lowercaseQuery = query.toLowerCase();
    final results = <String>[];
    
    for (final exercise in _exercises) {
      bool match = false;
      if (exercise.name.toLowerCase().contains(lowercaseQuery)) {
        match = true;
      } else {
        for (final synonym in exercise.synonyms) {
          if (synonym.toLowerCase().contains(lowercaseQuery)) {
            match = true;
            break;
          }
        }
      }
      
      if (match) {
        results.add(exercise.name);
      }
    }
    
    return results;
  }
}
