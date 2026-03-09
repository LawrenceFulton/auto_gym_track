import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/state/workout_capture_controller.dart';
import '../../application/state/workout_session_controller.dart';
import '../../application/workout/workout_flow_controller.dart';
import '../../data/services/openrouter_client.dart';
import '../../domain/models/set_entry.dart';
import '../../domain/models/workout_template.dart';
import 'history_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    required this.plannedExercises,
    required this.currentExerciseIndex,
    required this.onExerciseChanged,
    required this.history,
    required this.onSaveParsed,
    required this.openRouterClient,
  });

  final List<PlannedExercise> plannedExercises;
  final int currentExerciseIndex;
  final ValueChanged<int> onExerciseChanged;
  final List<SetEntry> history;
  final Future<void> Function() onSaveParsed;
  final OpenRouterClient openRouterClient;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late PageController _pageController;
  bool _holdActive = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentExerciseIndex);
    // Watch for state changes to auto-confirm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAutoSaveListener();
    });
  }

  @override
  void didUpdateWidget(ActiveWorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentExerciseIndex != _pageController.page?.round()) {
      _pageController.animateToPage(
        widget.currentExerciseIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setupAutoSaveListener() {
    final captureController = context.read<WorkoutCaptureController>();
    captureController.addListener(() {
      if (captureController.state == WorkoutFlowState.reviewing) {
        widget.onSaveParsed();
      }
    });
  }

  Future<void> _startHoldRecording(BuildContext context, String currentExercise, int setsDone) async {
    if (_holdActive) {
      return;
    }

    _holdActive = true;
    await context.read<WorkoutCaptureController>().startRecording(
      currentExercise: currentExercise,
      nextSetNumber: setsDone + 1,
      openRouterClient: widget.openRouterClient,
    );
  }

  Future<void> _stopHoldRecording(BuildContext context) async {
    if (!_holdActive) {
      return;
    }

    _holdActive = false;
    await context.read<WorkoutCaptureController>().stopRecordingAndExtract();
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<WorkoutCaptureController>();
    final session = context.watch<WorkoutSessionController>();
    final busy = switch (flow.state) {
      WorkoutFlowState.transcribing || WorkoutFlowState.extracting => true,
      _ => false,
    };
    final recording = flow.state == WorkoutFlowState.recording;

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: widget.onExerciseChanged,
        itemCount: widget.plannedExercises.length,
        itemBuilder: (context, index) {
          final exercise = widget.plannedExercises[index];
          final exerciseHistory = widget.history.where((e) => e.exerciseName == exercise.name).toList();
          final setsDone = exerciseHistory.length;
          final lastPerformance = session.getLastPerformanceForExercise(exercise.name);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 22, child: Icon(Icons.fitness_center_rounded)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Exercise ${index + 1} of ${widget.plannedExercises.length}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
                                ],
                              ),
                            ),
                            if (busy && session.currentExercise == exercise.name)
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            else if (session.currentExercise == exercise.name)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  flow.state.name.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Text('Progress', style: Theme.of(context).textTheme.labelMedium),
                            Text(
                              '$setsDone / ${exercise.plannedSets} sets',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (setsDone / exercise.plannedSets).clamp(0.0, 1.0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ],
                        ),
                        if (lastPerformance.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(Icons.history_rounded, size: 14, color: Theme.of(context).hintColor),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Last Session:',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: lastPerformance.map((set) {
                                    return Text(
                                      '${set.weight}${set.unit} x ${set.reps}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (flow.error != null && session.currentExercise == exercise.name) ...[
                  const SizedBox(height: 10),
                  Text(flow.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (flow.transcript != null &&
                    flow.state != WorkoutFlowState.saved &&
                    session.currentExercise == exercise.name) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('"${flow.transcript}"', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text('Exercise History', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(child: HistoryScreen(entries: exerciseHistory)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: GestureDetector(
        onLongPressStart: busy
            ? null
            : (_) => _startHoldRecording(context, session.currentExercise, session.setsDoneForCurrentExercise),
        onLongPressEnd: (_) => _stopHoldRecording(context),
        child: FloatingActionButton(
          onPressed: () {}, // Empty as we use long press
          backgroundColor: recording ? Colors.red : null,
          child: Icon(recording ? Icons.mic : Icons.mic_none_rounded),
        ),
      ),
    );
  }
}
