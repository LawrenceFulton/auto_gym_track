class WorkoutSession {
  const WorkoutSession({this.id, required this.templateName, required this.startedAt, this.endedAt});

  final int? id;
  final String templateName;
  final DateTime startedAt;
  final DateTime? endedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'template_name': templateName,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, Object?> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      templateName: map['template_name'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: (map['ended_at'] as String?) == null ? null : DateTime.parse(map['ended_at'] as String),
    );
  }
}
