import 'package:flutter/material.dart';
import 'package:todoodoo/models/task_model.dart';

class AddTaskPage extends StatefulWidget {
  final Function(TaskModel) onAddTask;

  const AddTaskPage({Key? key, required this.onAddTask}) : super(key: key);

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _dueDate;
  int _labelId = 0;
  bool _repeats = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('Select Deadline'),
            ),
            SizedBox(height: 16),
            DropdownButton<int>(
              value: _labelId,
              onChanged: (int? newValue) {
                setState(() {
                  _labelId = newValue!;
                });
              },
              items: <int>[0, 1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('Label $value'),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Repeats'),
              value: _repeats,
              onChanged: (bool? value) {
                setState(() {
                  _repeats = value!;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final task = TaskModel(
                  title: _titleController.text,
                  dueDate: _dueDate?.toIso8601String(),
                  labelId: _labelId,
                  repeats: _repeats,
                );
                widget.onAddTask(task);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}