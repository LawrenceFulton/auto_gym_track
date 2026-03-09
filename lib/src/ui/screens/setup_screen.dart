import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/workout_repository.dart';
import '../../domain/models/workout_template.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onStartWorkout});

  final ValueChanged<WorkoutTemplate> onStartWorkout;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const List<WorkoutTemplate> _defaultTemplates = [
    WorkoutTemplate(
      name: 'Core Day',
      exercises: [
        PlannedExercise(name: 'Push-ups', plannedSets: 3),
        PlannedExercise(name: 'Plank', plannedSets: 3),
        PlannedExercise(name: 'Squat Crunch', plannedSets: 3),
      ],
    ),
    WorkoutTemplate(
      name: 'Upper Body',
      exercises: [
        PlannedExercise(name: 'Bench Press', plannedSets: 3),
        PlannedExercise(name: 'Overhead Press', plannedSets: 3),
        PlannedExercise(name: 'Bent Over Row', plannedSets: 3),
      ],
    ),
  ];

  List<WorkoutTemplate> _templates = const [];
  int _selectedTemplateIndex = 0;
  bool _isLoading = true;

  WorkoutTemplate? get _selectedTemplate {
    if (_templates.isEmpty) {
      return null;
    }
    return _templates[_selectedTemplateIndex.clamp(0, _templates.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final repository = context.read<WorkoutRepository>();

    try {
      var templates = await repository.getWorkoutTemplates();
      if (templates.isEmpty) {
        for (final template in _defaultTemplates) {
          await repository.saveWorkoutTemplate(template);
        }
        templates = await repository.getWorkoutTemplates();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _templates = templates;
        _selectedTemplateIndex = 0;
        _isLoading = false;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load workouts: $exception')));
    }
  }

  Future<void> _openCreateWorkoutScreen() async {
    final repository = context.read<WorkoutRepository>();
    final created = await Navigator.of(
      context,
    ).push<WorkoutTemplate>(MaterialPageRoute(builder: (_) => const CreateWorkoutScreen()));

    if (created == null) {
      return;
    }

    try {
      await repository.saveWorkoutTemplate(created);

      if (!mounted) {
        return;
      }

      setState(() {
        _templates = [..._templates, created];
        _selectedTemplateIndex = _templates.length - 1;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save workout: $exception')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedTemplate = _selectedTemplate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 22, child: Icon(Icons.playlist_add_check_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose Workout', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 2),
                        const Text('Pick a template or build one that matches your session.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _templates.isEmpty ? null : _selectedTemplateIndex,
            decoration: const InputDecoration(labelText: 'Workout Template'),
            items: [
              for (var i = 0; i < _templates.length; i++)
                DropdownMenuItem<int>(value: i, child: Text(_templates[i].name)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedTemplateIndex = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Text('Workout Preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: selectedTemplate == null
                  ? const Text('No workout templates available yet.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...selectedTemplate.exercises.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.name)),
                                Text('${item.plannedSets} sets', style: Theme.of(context).textTheme.labelLarge),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Reps and weight are filled from voice memos while training.'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openCreateWorkoutScreen,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Workout'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: selectedTemplate == null ? null : () => widget.onStartWorkout(selectedTemplate),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Confirm Workout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  static const _exerciseOptions = [
    'Push-ups',
    'Plank',
    'Squat Crunch',
    'Bench Press',
    'Overhead Press',
    'Bent Over Row',
    'Deadlift',
    'Lunges',
  ];

  final _nameController = TextEditingController();
  final List<_ExerciseDraft> _drafts = [_ExerciseDraft(name: _exerciseOptions.first, sets: 3)];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _drafts.add(_ExerciseDraft(name: _exerciseOptions.first, sets: 3));
    });
  }

  void _removeExercise(int index) {
    if (_drafts.length == 1) {
      return;
    }
    setState(() {
      _drafts.removeAt(index);
    });
  }

  void _saveWorkout() {
    final workoutName = _nameController.text.trim();
    if (workoutName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a workout name.')));
      return;
    }

    final template = WorkoutTemplate(
      name: workoutName,
      exercises: _drafts
          .map((draft) => PlannedExercise(name: draft.name, plannedSets: draft.sets))
          .toList(growable: false),
    );

    Navigator.of(context).pop(template);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Workout name (e.g. Core Day)'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    for (var i = 0; i < _drafts.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final exerciseDropdown = DropdownButtonFormField<String>(
                              initialValue: _drafts[i].name,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Exercise'),
                              items: [
                                for (final option in _exerciseOptions)
                                  DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option, overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _drafts[i] = _drafts[i].copyWith(name: value);
                                });
                              },
                            );

                            final setsDropdown = SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                initialValue: _drafts[i].sets,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Sets'),
                                items: [
                                  for (var sets = 1; sets <= 8; sets++)
                                    DropdownMenuItem<int>(value: sets, child: Text('$sets')),
                                ],
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _drafts[i] = _drafts[i].copyWith(sets: value);
                                  });
                                },
                              ),
                            );

                            if (constraints.maxWidth < 430) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  exerciseDropdown,
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      setsDropdown,
                                      IconButton(
                                        onPressed: () => _removeExercise(i),
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Remove exercise',
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: exerciseDropdown),
                                const SizedBox(width: 12),
                                setsDropdown,
                                IconButton(
                                  onPressed: () => _removeExercise(i),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Remove exercise',
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Exercise'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveWorkout,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Workout'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Reps and weight are captured later from your voice memo while training.'),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDraft {
  const _ExerciseDraft({required this.name, required this.sets});

  final String name;
  final int sets;

  _ExerciseDraft copyWith({String? name, int? sets}) {
    return _ExerciseDraft(name: name ?? this.name, sets: sets ?? this.sets);
  }
}
