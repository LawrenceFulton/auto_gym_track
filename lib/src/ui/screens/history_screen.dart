import 'package:flutter/material.dart';

import '../../domain/models/set_entry.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.entries});

  final List<SetEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_toggle_off_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                const Text('No sets logged yet.'),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${entry.setNumber}', style: Theme.of(context).textTheme.labelMedium),
            ),
            title: Text('${entry.reps} reps @ ${entry.weight} ${entry.unit}'),
            subtitle: Text(entry.sourceTranscript, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        },
      ),
    );
  }
}
