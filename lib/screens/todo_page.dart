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

  Future<void> _addTask(TaskModel task) async {
    final db = await _databaseService.database;
    await db.insert('Tasks', task.toMap());
    await _loadTasks();
  }

  Future<void> _updateTask(TaskModel task) async {
    final db = await _databaseService.database;
    await db.update('Tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
    await _loadTasks();
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
    return tasks.isEmpty
        ? const Center(child: Text('No tasks yet'))
        : ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteTask(task),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.status == 'done' 
                          ? TextDecoration.lineThrough 
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.dueDate != null)
                        Text(
                          'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            color: task.dueDate!.isBefore(DateTime.now())
                                ? Colors.red
                                : null,
                          ),
                        ),
                      if (task.labels.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: task.labels.map((label) => 
                            Chip(
                              label: Text(label.name),
                              visualDensity: VisualDensity.compact,
                            ),
                          ).toList(),
                        ),
                      if (task.repeats) const Text('Repeats daily'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.repeats) 
                        const Icon(Icons.repeat, size: 20),
                      IconButton(
                        icon: Icon(
                          task.status == 'done' 
                              ? Icons.check_circle 
                              : Icons.check_circle_outline,
                        ),
                        onPressed: () async {
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
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}