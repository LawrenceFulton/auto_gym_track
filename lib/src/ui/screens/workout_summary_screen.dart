import 'package:flutter/material.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.templateName,
    required this.duration,
    required this.totalSets,
    required this.totalExercises,
    required this.onDone,
  });

  final String templateName;
  final Duration duration;
  final int totalSets;
  final int totalExercises;
  final VoidCallback onDone;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'Workout Complete!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job on your $templateName session.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SummaryStat(label: 'Time', value: _formatDuration(duration), icon: Icons.timer_outlined),
                  _SummaryStat(label: 'Exercises', value: '$totalExercises', icon: Icons.fitness_center_rounded),
                  _SummaryStat(label: 'Sets', value: '$totalSets', icon: Icons.repeat_rounded),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
