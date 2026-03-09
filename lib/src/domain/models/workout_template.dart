class WorkoutTemplate {
  const WorkoutTemplate({required this.name, required this.exercises});

  final String name;
  final List<PlannedExercise> exercises;
}

class PlannedExercise {
  const PlannedExercise({required this.name, required this.plannedSets});

  final String name;
  final int plannedSets;
}
