import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/state/api_key_controller.dart';
import '../../application/state/workout_capture_controller.dart';
import '../../application/state/workout_session_controller.dart';
import '../../domain/models/workout_template.dart';
import 'active_workout_screen.dart';
import 'openrouter_key_prompt_screen.dart';
import 'setup_screen.dart';
import 'workout_summary_screen.dart';

class WorkoutHomeScreen extends StatelessWidget {
  const WorkoutHomeScreen({super.key});

  Future<void> _saveParsedSet({
    required WorkoutCaptureController captureController,
    required WorkoutSessionController sessionController,
  }) async {
    final parsed = captureController.parsed;
    final transcript = captureController.transcript;

    if (parsed == null || transcript == null) {
      return;
    }

    await sessionController.saveParsedSet(parsed: parsed, transcript: transcript);
    captureController.markSaved();
  }

  Future<void> _startSession({
    required WorkoutSessionController sessionController,
    required WorkoutCaptureController captureController,
    required WorkoutTemplate template,
  }) async {
    await sessionController.startSession(template);
    captureController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ApiKeyController, WorkoutSessionController, WorkoutCaptureController>(
      builder: (context, apiKeyController, sessionController, captureController, _) {
        if (apiKeyController.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final openRouterClient = apiKeyController.client;
        if (openRouterClient == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Auto Gym Track - API Key Required')),
            body: OpenRouterKeyPromptScreen(
              isSaving: apiKeyController.isSaving,
              error: apiKeyController.error,
              onSave: apiKeyController.saveKey,
            ),
          );
        }

        if (sessionController.isFinished) {
          return WorkoutSummaryScreen(
            templateName: sessionController.templateName,
            duration: sessionController.sessionDuration,
            totalSets: sessionController.totalSetsCompleted,
            totalExercises: sessionController.totalExercisesPerformed,
            onDone: () => sessionController.reset(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            actions: [
              if (sessionController.hasSession)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilledButton.tonalIcon(
                    onPressed: () => sessionController.finishSession(),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Finish'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
            ],
          ),
          body: sessionController.hasSession
              ? ActiveWorkoutScreen(
                  plannedExercises: sessionController.plannedExercises,
                  currentExerciseIndex: sessionController.currentExerciseIndex,
                  onExerciseChanged: sessionController.goToExercise,
                  history: sessionController.history,
                  openRouterClient: openRouterClient,
                  onSaveParsed: () =>
                      _saveParsedSet(captureController: captureController, sessionController: sessionController),
                )
              : SetupScreen(
                  onStartWorkout: (template) => _startSession(
                    sessionController: sessionController,
                    captureController: captureController,
                    template: template,
                  ),
                ),
        );
      },
    );
  }
}
