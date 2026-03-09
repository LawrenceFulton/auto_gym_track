import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/application/state/api_key_controller.dart';
import 'src/application/state/workout_capture_controller.dart';
import 'src/application/state/workout_session_controller.dart';
import 'src/data/db/workout_database.dart';
import 'src/data/repositories/sqlite_workout_repository.dart';
import 'src/data/repositories/workout_repository.dart';
import 'src/data/services/openrouter_key_store.dart';
import 'src/data/services/speech_to_text_service.dart';
import 'src/ui/screens/workout_home_screen.dart';
import 'src/ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AutoGymTrackApp());
}

class AutoGymTrackApp extends StatelessWidget {
  const AutoGymTrackApp({super.key, this.keyStore, this.workoutRepository});

  final OpenRouterKeyStore? keyStore;
  final WorkoutRepository? workoutRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OpenRouterKeyStore>(create: (_) => keyStore ?? const SecureOpenRouterKeyStore()),
        Provider<WorkoutRepository>(create: (_) => workoutRepository ?? SqliteWorkoutRepository(WorkoutDatabase())),
        Provider<SpeechToTextService>(create: (_) => DeviceSpeechToTextService()),
        ChangeNotifierProvider<ApiKeyController>(
          create: (context) => ApiKeyController(keyStore: context.read<OpenRouterKeyStore>())..initialize(),
        ),
        ChangeNotifierProvider<WorkoutSessionController>(
          create: (context) => WorkoutSessionController(repository: context.read<WorkoutRepository>()),
        ),
        ChangeNotifierProvider<WorkoutCaptureController>(
          create: (context) => WorkoutCaptureController(speechToTextService: context.read<SpeechToTextService>()),
        ),
      ],
      child: MaterialApp(title: 'Auto Gym Track', theme: AppTheme.light(), home: const WorkoutHomeScreen()),
    );
  }
}
