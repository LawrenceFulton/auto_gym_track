import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/state/workout_session_controller.dart';
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditDialog(context, entry),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, entry),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, SetEntry entry) {
    if (entry.id == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set?'),
        content: const Text('Are you sure you want to remove this set from your history?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<WorkoutSessionController>().deleteSet(entry.id!);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, SetEntry entry) {
    if (entry.id == null) {
      return;
    }

    final repsController = TextEditingController(text: entry.reps.toString());
    final weightController = TextEditingController(text: entry.weight.toString());
    String unit = entry.unit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                decoration: const InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: unit,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lb', child: Text('lb')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => unit = val);
                  }
                },
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text) ?? entry.reps;
                final weight = double.tryParse(weightController.text) ?? entry.weight;
                context.read<WorkoutSessionController>().updateSet(entry.id!, reps: reps, weight: weight, unit: unit);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
