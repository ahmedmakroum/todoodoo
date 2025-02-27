import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/label_model.dart';
import '../services/database_service.dart';
import 'package:todoodoo/services/notification_service.dart';

class AddTaskPage extends StatefulWidget {
  final Function(TaskModel) onAddTask;

  const AddTaskPage({
    Key? key,
    required this.onAddTask,
  }) : super(key: key);

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _dueDate;
  bool _repeats = false;
  List<LabelModel> _selectedLabels = [];
  List<LabelModel> _availableLabels = [];

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final labels = await _databaseService.getLabels();
    setState(() {
      _availableLabels = labels;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _handleSubmit() {
    if (_titleController.text.isNotEmpty) {
      final task = TaskModel(
        title: _titleController.text,
        status: 'todo',
        dueDate: _dueDate,
        repeats: _repeats,
        labels: _selectedLabels,
      );
      
      widget.onAddTask(task);
      
      // Schedule notification if there's a due date or if task repeats
      if (task.dueDate != null || task.repeats) {
        NotificationService().scheduleTaskNotification(task);
      }
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_dueDate == null 
                    ? 'No deadline set' 
                    : 'Deadline: ${_dueDate!.toLocal().toString().split(' ')[0]}'
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Set Deadline'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Labels', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _availableLabels.map((label) {
                      final isSelected = _selectedLabels.contains(label);
                      return FilterChip(
                        label: Text(label.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLabels.add(label);
                            } else {
                              _selectedLabels.remove(label);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Repeating Task'),
              value: _repeats,
              onChanged: (bool value) {
                setState(() {
                  _repeats = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}