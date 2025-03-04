import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_task_model.dart';
import '../providers/board_provider.dart';

class BoardPlannerPage extends ConsumerStatefulWidget {
  const BoardPlannerPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BoardPlannerPage> createState() => _BoardPlannerPageState();
}

class _BoardPlannerPageState extends ConsumerState<BoardPlannerPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  BoardTask? _selectedTask;

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
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(boardProvider.notifier).loadTasks());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedTask = null;
  }

  void _showTaskForm({BoardTask? task, required String status}) {
    if (task != null) {
      _selectedTask = task;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task != null ? 'Edit Task' : 'Add Task'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          if (_selectedTask != null)
            TextButton(
              onPressed: () {
                ref.read(boardProvider.notifier).deleteTask(_selectedTask!.id);
                Navigator.pop(context);
                _resetForm();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final task = BoardTask(
                  id: _selectedTask?.id ?? 0,
                  title: _titleController.text,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  status: _selectedTask?.status ?? status.toLowerCase(),
                  position: _selectedTask?.position ?? 0,
                  isCompleted: _selectedTask?.isCompleted ?? false,
                );

                if (_selectedTask != null) {
                  ref.read(boardProvider.notifier).updateTask(task);
                } else {
                  ref.read(boardProvider.notifier).addTask(task);
                }

                Navigator.pop(context);
                _resetForm();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(String weekday) {
    final tasks = ref.watch(boardProvider).where(
          (task) => task.status.toLowerCase() == weekday.toLowerCase(),
        ).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weekday,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showTaskForm(status: weekday),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No tasks for $weekday',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (bool? value) {
                        task.isCompleted = value ?? false;
                        ref.read(boardProvider.notifier).updateTask(task);
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: task.description != null
                        ? Text(
                            task.description!,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          )
                        : null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (String newDay) {
                        ref
                            .read(boardProvider.notifier)
                            .moveTask(task, newDay.toLowerCase());
                      },
                      itemBuilder: (BuildContext context) {
                        return weekdays
                            .where((d) =>
                                d.toLowerCase() != task.status)
                            .map((String d) {
                          return PopupMenuItem<String>(
                            value: d,
                            child: Text('Move to $d'),
                          );
                        }).toList();
                      },
                    ),
                    onTap: () => _showTaskForm(task: task, status: weekday),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(boardProvider); // Watch for changes

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Planner'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: weekdays.map((day) => _buildDayColumn(day)).toList(),
          ),
        ),
      ),
    );
  }
}
