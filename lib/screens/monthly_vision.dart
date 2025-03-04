import 'package:flutter/material.dart';
import '../models/vision_model.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class MonthlyVisionPage extends StatefulWidget {
  const MonthlyVisionPage({Key? key}) : super(key: key);

  @override
  _MonthlyVisionPageState createState() => _MonthlyVisionPageState();
}

class _MonthlyVisionPageState extends State<MonthlyVisionPage> {
  final List<DateTime> months = [];
  final DateTime startDate = DateTime(2024);
  final DateTime endDate = DateTime(2030);

  @override
  void initState() {
    super.initState();
    _generateMonthsList();
  }

  void _generateMonthsList() {
    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Vision'),
      ),
      body: ListView.builder(
        itemCount: months.length,
        itemBuilder: (context, index) {
          final month = months[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                DateFormat('MMMM yyyy').format(month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonthDetailPage(selectedDate: month),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class MonthDetailPage extends StatefulWidget {
  final DateTime selectedDate;

  const MonthDetailPage({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _MonthDetailPageState createState() => _MonthDetailPageState();
}

class _MonthDetailPageState extends State<MonthDetailPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _visionController = TextEditingController();
  List<Vision> visions = [];

  @override
  void initState() {
    super.initState();
    _loadVisions();
  }

  Future<void> _loadVisions() async {
    final loadedVisions = await _databaseService.getVisions('monthly', widget.selectedDate);
    setState(() {
      visions = loadedVisions;
    });
  }

  void _showAddVisionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vision'),
        content: TextField(
          controller: _visionController,
          decoration: const InputDecoration(
            hintText: 'Enter your vision',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_visionController.text.isNotEmpty) {
                final vision = Vision(
                  content: _visionController.text,
                  targetDate: widget.selectedDate,
                  type: 'monthly',
                );
                await _databaseService.insertVision(vision);
                _visionController.clear();
                Navigator.pop(context);
                await _loadVisions();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(widget.selectedDate)),
      ),
      body: Column(
        children: [
          Expanded(
            child: visions.isEmpty
                ? Center(
                    child: Text(
                      'No visions yet for ${DateFormat('MMMM yyyy').format(widget.selectedDate)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: visions.length,
                    itemBuilder: (context, index) {
                      final vision = visions[index];
                      return Dismissible(
                        key: Key(vision.id.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          await _databaseService.deleteVision(vision.id!);
                          await _loadVisions();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Checkbox(
                              value: vision.isCompleted,
                              onChanged: (bool? value) async {
                                final updatedVision = vision.copyWith(
                                  isCompleted: value,
                                );
                                await _databaseService.updateVision(updatedVision);
                                await _loadVisions();
                              },
                            ),
                            title: Text(
                              vision.content,
                              style: TextStyle(
                                decoration: vision.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Vision'),
                                    content: const Text('Are you sure you want to delete this vision?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await _databaseService.deleteVision(vision.id!);
                                          Navigator.pop(context);
                                          await _loadVisions();
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              _visionController.text = vision.content;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Vision'),
                                  content: TextField(
                                    controller: _visionController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your vision',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (_visionController.text.isNotEmpty) {
                                          final updatedVision = vision.copyWith(
                                            content: _visionController.text,
                                          );
                                          await _databaseService.updateVision(updatedVision);
                                          _visionController.clear();
                                          Navigator.pop(context);
                                          await _loadVisions();
                                        }
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVisionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }
}