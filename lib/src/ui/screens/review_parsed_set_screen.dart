import 'package:flutter/material.dart';

import '../../application/parser/parsed_workout_set.dart';

class ReviewParsedSetScreen extends StatelessWidget {
  const ReviewParsedSetScreen({super.key, required this.parsed, required this.onConfirm});

  final ParsedWorkoutSet parsed;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final confidenceLabel = '${(parsed.confidence * 100).toStringAsFixed(0)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Review Parsed Set', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Confidence $confidenceLabel', style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Exercise: ${parsed.exerciseName}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            ...parsed.sets.map(
              (set) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('Set ${set.setNumber}', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 10),
                    Text('${set.reps} reps @ ${set.weight} ${set.unit}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Confirm and Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
