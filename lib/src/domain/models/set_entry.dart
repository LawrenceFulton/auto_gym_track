class SetEntry {
  const SetEntry({
    this.id,
    required this.exerciseEntryId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.unit,
    required this.sourceTranscript,
    required this.createdAt,
  });

  final int? id;
  final int exerciseEntryId;
  final int setNumber;
  final int reps;
  final double weight;
  final String unit;
  final String sourceTranscript;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'exercise_entry_id': exerciseEntryId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      'unit': unit,
      'source_transcript': sourceTranscript,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SetEntry.fromMap(Map<String, Object?> map) {
    return SetEntry(
      id: map['id'] as int?,
      exerciseEntryId: map['exercise_entry_id'] as int,
      setNumber: map['set_number'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
      unit: map['unit'] as String,
      sourceTranscript: map['source_transcript'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
