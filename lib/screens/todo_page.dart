import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({Key? key}) : super(key: key);

  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  List<TaskModel> tasks = [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query('Tasks');
      final List<TaskModel> loadedTasks = await Future.wait(
        maps.map((map) => TaskModel.fromMap(map, _databaseService))
      );
      setState(() {
        tasks = loadedTasks;
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }



  Future<void> _deleteTask(TaskModel task) async {
    try {
      await _databaseService.deleteTask(task.id!);
      // Cancel any scheduled notifications for this task
      if (task.dueDate != null) {
        await NotificationService().cancelNotification(task.id!);
      }
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await _databaseService.insertTask(task);
                if (task.dueDate != null) {
                  await NotificationService().scheduleTaskNotification(task);
                }
                await _loadTasks();
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return tasks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a task to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id.toString()),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteTask(task),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final updatedTask = TaskModel(
                        id: task.id,
                        title: task.title,
                        status: task.status == 'done' ? 'todo' : 'done',
                        dueDate: task.dueDate,
                        repeats: task.repeats,
                        projectId: task.projectId,
                        labels: task.labels,
                      );
                      await _databaseService.updateTask(updatedTask);
                      await _loadTasks();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: task.status == 'done'
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                                width: 2,
                              ),
                              color: task.status == 'done'
                                  ? colorScheme.primary
                                  : Colors.transparent,
                            ),
                            child: task.status == 'done'
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    decoration: task.status == 'done'
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.status == 'done'
                                        ? colorScheme.outline
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (task.dueDate != null ||
                                    task.labels.isNotEmpty ||
                                    task.repeats) ...[  
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (task.dueDate != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: task.dueDate!.isBefore(DateTime.now())
                                                ? colorScheme.error.withOpacity(0.1)
                                                : colorScheme.primaryContainer.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: task.dueDate!.isBefore(DateTime.now())
                                                    ? colorScheme.error
                                                    : colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                task.dueDate!.toLocal().toString().split(' ')[0],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: task.dueDate!.isBefore(DateTime.now())
                                                      ? colorScheme.error
                                                      : colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ...task.labels.map((label) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondaryContainer.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.label,
                                                  size: 16,
                                                  color: colorScheme.secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  label.name,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: colorScheme.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                      if (task.repeats)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.tertiaryContainer.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.repeat,
                                                size: 16,
                                                color: colorScheme.tertiary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Daily',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: colorScheme.tertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}