class ExerciseEntry {
  const ExerciseEntry({
    this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.orderIndex,
    this.mediaRef,
  });

  final int? id;
  final int sessionId;
  final String exerciseName;
  final int orderIndex;
  final String? mediaRef;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_name': exerciseName,
      'order_index': orderIndex,
      'media_ref': mediaRef,
    };
  }

  factory ExerciseEntry.fromMap(Map<String, Object?> map) {
    return ExerciseEntry(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      exerciseName: map['exercise_name'] as String,
      orderIndex: map['order_index'] as int,
      mediaRef: map['media_ref'] as String?,
    );
  }
}
