import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_model.dart';
import '../services/database_service.dart';

class WorkoutPlannerPage extends ConsumerStatefulWidget {
  const WorkoutPlannerPage({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutPlannerPage> createState() => _WorkoutPlannerPageState();
}

class _WorkoutPlannerPageState extends ConsumerState<WorkoutPlannerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<WorkoutExercise> _exercises = [];
  String _selectedDay = 'Monday';

  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showExerciseForm({WorkoutExercise? exercise, int? index}) {
    final nameController = TextEditingController(text: exercise?.name);
    final setsController = TextEditingController(text: exercise?.sets.toString());
    final repsController = TextEditingController(text: exercise?.reps.toString());
    final weightController = TextEditingController(text: exercise?.weight.toString());
    final notesController = TextEditingController(text: exercise?.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise != null ? 'Edit Exercise' : 'Add Exercise'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Exercise Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                TextFormField(
                  controller: setsController,
                  decoration: const InputDecoration(labelText: 'Sets'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Sets are required' : null,
                ),
                TextFormField(
                  controller: repsController,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Reps are required' : null,
                ),
                TextFormField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Weight is required' : null,
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (index != null)
            TextButton(
              onPressed: () {
                if (index < _exercises.length) {
                  setState(() {
                    _exercises.removeAt(index);
                  });
                }
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final exercise = WorkoutExercise(
                  name: nameController.text,
                  sets: int.parse(setsController.text),
                  reps: int.parse(repsController.text),
                  weight: double.parse(weightController.text),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );

                setState(() {
                  if (index != null && index < _exercises.length) {
                    _exercises[index] = exercise;
                  } else {
                    _exercises.add(exercise);
                  }
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutPlanForm({WorkoutPlan? existingPlan}) {
    if (existingPlan != null) {
      _nameController.text = existingPlan.name;
      _selectedDay = existingPlan.dayOfWeek;
      _exercises.clear();
      _exercises.addAll(existingPlan.exercises);
    } else {
      _nameController.clear();
      _exercises.clear();
      _selectedDay = 'Monday';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Workout Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Plan Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  items: weekdays
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(day),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDay = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Day of Week'),
                ),
                const SizedBox(height: 16),
                ..._exercises.asMap().entries.map(
                      (entry) => ListTile(
                        title: Text(entry.value.name),
                        subtitle: Text(
                            '${entry.value.sets} sets × ${entry.value.reps} reps @ ${entry.value.weight}kg'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showExerciseForm(exercise: entry.value, index: entry.key),
                        ),
                      ),
                    ),
                TextButton.icon(
                  onPressed: () => _showExerciseForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty && _exercises.isNotEmpty) {
                  final plan = WorkoutPlan(
                    id: existingPlan?.id ?? 0,
                    name: _nameController.text,
                    dayOfWeek: _selectedDay,
                    exercises: _exercises,
                  );

                  if (existingPlan != null) {
                    await DatabaseService().updateWorkoutPlan(plan);
                  } else {
                    await DatabaseService().insertWorkoutPlan(plan);
                  }
                  setState(() {}); // Refresh the list
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<WorkoutPlan>>(
        future: DatabaseService().getWorkoutPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No workout plans yet'),
                  TextButton.icon(
                    onPressed: _showWorkoutPlanForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Plan'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Dismissible(
                key: Key('plan_${plan.id}'),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Workout Plan'),
                      content: Text('Are you sure you want to delete "${plan.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await DatabaseService().deleteWorkoutPlan(plan.id);
                  setState(() {});
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(plan.name),
                    subtitle: Text(plan.dayOfWeek),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showWorkoutPlanForm(existingPlan: plan),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                    children: [
                      ...plan.exercises.asMap().entries.map(
                        (entry) => Dismissible(
                          key: Key('exercise_${plan.id}_${entry.key}'),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) async {
                            plan.exercises.removeAt(entry.key);
                            await DatabaseService().updateWorkoutPlan(plan);
                            setState(() {});
                          },
                          child: CheckboxListTile(
                            title: Text(entry.value.name),
                            subtitle: Text(
                                '${entry.value.sets} sets × ${entry.value.reps} reps @ ${entry.value.weight}kg'),
                            value: entry.value.isCompleted,
                            secondary: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showExerciseForm(
                                exercise: entry.value,
                                index: entry.key,
                              ),
                            ),
                            onChanged: (value) async {
                              entry.value.isCompleted = value ?? false;
                              await DatabaseService().updateWorkoutPlan(plan);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      ButtonBar(
                        children: [
                          TextButton.icon(
                            onPressed: () => _showExerciseForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Exercise'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'workout_fab',
        onPressed: _showWorkoutPlanForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
