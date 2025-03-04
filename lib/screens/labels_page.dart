import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../services/database_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LabelsPage extends StatefulWidget {
  const LabelsPage({Key? key}) : super(key: key);

  @override
  _LabelsPageState createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _labelController = TextEditingController();
  List<LabelModel> labels = [];
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final loadedLabels = await _databaseService.getLabels();
    setState(() {
      labels = loadedLabels;
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _addLabel() async {
    if (_labelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label name')),
      );
      return;
    }

    final label = LabelModel(
      name: _labelController.text,
      color: _selectedColor.value.toRadixString(16),
    );

    await _databaseService.insertLabel(label);
    _labelController.clear();
    await _loadLabels();
  }

  Future<void> _deleteLabel(LabelModel label) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Label?'),
        content: Text('Are you sure you want to delete "${label.name}"? This will remove it from all tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _databaseService.deleteLabel(label.id!);
      await _loadLabels();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'New Label',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addLabel,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: labels.length,
              itemBuilder: (context, index) {
                final label = labels[index];
                final labelColor = Color(int.parse(label.color ?? 'FF2196F3', radix: 16));
                return ListTile(
                  leading: Icon(Icons.label, color: labelColor),
                  title: Text(label.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteLabel(label),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
} 