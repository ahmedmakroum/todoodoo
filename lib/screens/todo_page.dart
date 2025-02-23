import 'package:flutter/material.dart';
import 'package:todoodoo/screens/add_task_page.dart';
import 'package:todoodoo/services/database_service.dart';
import 'package:todoodoo/models/task_model.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({Key? key}) : super(key: key);

  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  late DatabaseService _databaseService;
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _databaseService.getTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _addTask(TaskModel task) async {
    await _databaseService.insertTask(task);
    await _loadTasks();
  }

  Future<void> _updateTask(TaskModel task) async {
    await _databaseService.updateTask(task);
    await _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    await _databaseService.deleteTask(id);
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Card(
            child: ListTile(
              title: Text(task.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deadline: ${task.dueDate}'),
                  Text('Label: ${task.labelId}'),
                  Text('Repeats: ${task.repeats ? 'Yes' : 'No'}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // Implement edit functionality
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteTask(task.id!);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskPage(onAddTask: _addTask)),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}