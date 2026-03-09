class ParsedWorkoutSet {
  const ParsedWorkoutSet({required this.exerciseName, required this.sets, required this.confidence, this.notes});

  final String exerciseName;
  final List<ParsedSetItem> sets;
  final double confidence;
  final String? notes;
}

class ParsedSetItem {
  const ParsedSetItem({required this.setNumber, required this.reps, required this.weight, required this.unit});

  final int setNumber;
  final int reps;
  final double weight;
  final String unit;
}
