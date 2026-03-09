import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/state/workout_capture_controller.dart';
import '../../application/workout/workout_flow_controller.dart';
import '../../data/services/openrouter_client.dart';
import '../../domain/models/set_entry.dart';
import 'history_screen.dart';
import 'review_parsed_set_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    required this.currentExercise,
    required this.history,
    required this.onSaveParsed,
    required this.openRouterClient,
  });

  final String currentExercise;
  final List<SetEntry> history;
  final Future<void> Function() onSaveParsed;
  final OpenRouterClient openRouterClient;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  bool _holdActive = false;

  Future<void> _startHoldRecording(BuildContext context) async {
    if (_holdActive) {
      return;
    }

    _holdActive = true;
    await context.read<WorkoutCaptureController>().startRecording(
      currentExercise: widget.currentExercise,
      nextSetNumber: widget.history.length + 1,
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
    final busy = switch (flow.state) {
      WorkoutFlowState.transcribing || WorkoutFlowState.extracting => true,
      _ => false,
    };
    final recording = flow.state == WorkoutFlowState.recording;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 22, child: Icon(Icons.fitness_center_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Exercise', style: Theme.of(context).textTheme.titleSmall),
                        Text(widget.currentExercise, style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(flow.state.name.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Listener(
            onPointerDown: busy ? null : (_) => _startHoldRecording(context),
            onPointerUp: (_) => _stopHoldRecording(context),
            onPointerCancel: (_) => _stopHoldRecording(context),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : () {},
                icon: busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(recording ? Icons.mic : Icons.mic_none_rounded),
                label: Text(busy ? 'Processing...' : (recording ? 'Recording... release to stop' : 'Hold to Record')),
              ),
            ),
          ),
          if (flow.error != null) ...[
            const SizedBox(height: 10),
            Text(flow.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (flow.transcript != null) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('"${flow.transcript}"', style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ],
          if (flow.parsed != null) ...[
            const SizedBox(height: 12),
            ReviewParsedSetScreen(parsed: flow.parsed!, onConfirm: widget.onSaveParsed),
          ],
          const SizedBox(height: 12),
          Text('Set History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(child: HistoryScreen(entries: widget.history)),
        ],
      ),
    );
  }
}
