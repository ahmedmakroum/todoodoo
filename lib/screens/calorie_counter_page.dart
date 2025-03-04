import 'package:flutter/material.dart';
import '../models/calorie_model.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class CalorieCounterPage extends StatefulWidget {
  const CalorieCounterPage({Key? key}) : super(key: key);

  @override
  _CalorieCounterPageState createState() => _CalorieCounterPageState();
}

class _CalorieCounterPageState extends State<CalorieCounterPage> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _servingUnitController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMealType = 'breakfast';
  List<CalorieEntry> _todayEntries = [];
  int _totalCalories = 0;
  final int _targetCalories = 2000; // Default target, can be made configurable

  @override
  void initState() {
    super.initState();
    _loadTodayEntries();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayEntries() async {
    final db = await DatabaseService().database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'CalorieEntries',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    setState(() {
      _todayEntries = List.generate(maps.length, (i) => CalorieEntry.fromMap(maps[i]));
      _totalCalories = _todayEntries.fold(0, (sum, entry) => sum + entry.calories);
    });
  }

  Future<void> _addEntry() async {
    if (_formKey.currentState!.validate()) {
      final entry = CalorieEntry(
        foodName: _foodNameController.text,
        calories: int.parse(_caloriesController.text),
        servingSize: double.parse(_servingSizeController.text),
        servingUnit: _servingUnitController.text,
        timestamp: DateTime.now(),
        mealType: _selectedMealType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final db = await DatabaseService().database;
      await db.insert('CalorieEntries', entry.toMap());

      _foodNameController.clear();
      _caloriesController.clear();
      _servingSizeController.clear();
      _servingUnitController.clear();
      _notesController.clear();

      await _loadTodayEntries();
    }
  }

  Future<void> _deleteEntry(CalorieEntry entry) async {
    final db = await DatabaseService().database;
    await db.delete(
      'CalorieEntries',
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    await _loadTodayEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Tracker'),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _totalCalories / _targetCalories,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _totalCalories > _targetCalories ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_totalCalories / $_targetCalories kcal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          
          // Food entry form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _foodNameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a food name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            decoration: const InputDecoration(
                              labelText: 'Calories',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter calories';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _servingSizeController,
                            decoration: const InputDecoration(
                              labelText: 'Serving Size',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter serving size';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _servingUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Serving Unit (g, ml, piece, etc.)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a serving unit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMealType,
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                        DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                        DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                        DropdownMenuItem(value: 'snack', child: Text('Snack')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _selectedMealType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addEntry,
                      child: const Text('Add Food Entry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Today's entries
          Expanded(
            child: ListView.builder(
              itemCount: _todayEntries.length,
              itemBuilder: (context, index) {
                final entry = _todayEntries[index];
                return ListTile(
                  title: Text(entry.foodName),
                  subtitle: Text(
                    '${entry.calories} kcal - ${entry.servingSize} ${entry.servingUnit}\n'
                    '${entry.mealType.toUpperCase()} - ${DateFormat.jm().format(entry.timestamp)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteEntry(entry),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
