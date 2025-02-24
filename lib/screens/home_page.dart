import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:todoodoo/screens/add_task_page.dart';
import 'package:todoodoo/screens/settings_page.dart';
import 'package:todoodoo/screens/todo_page.dart';
import 'package:todoodoo/screens/calendar_page.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import '../providers/focus_mode_provider.dart';
import 'planner_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState with SingleTickerProviderStateMixin {
  // Timer Logic
  int totalWorkTime = 1500; // 25 minutes default
  int remainingTime = 1500;
  double progress = 0.0;
  bool isRunning = false;
  Timer? _timer;

  // Database and Notifications
  late TabController _tabController;
  late Database database;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Sample Data
  List<Map<String, dynamic>> projects = [
    {'id': 1, 'name': 'CareerFoundry Course'},
    {'id': 2, 'name': 'Marketing Team Project'},
  ];

  List<Map<String, dynamic>> labels = [
    {'id': 1, 'name': 'Study'},
    {'id': 2, 'name': 'Sports'},
    {'id': 3, 'name': 'Work'},
    {'id': 4, 'name': 'Personal'},
    {'id': 5, 'name': 'Habit'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    initializeDatabase();
    initializeNotifications();
  }

  Future<void> initializeDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'todo.db');
    database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE Tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            project_id INTEGER,
            label_id INTEGER,
            status TEXT,
            due_date TEXT
          )
        ''');
      },
    );
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _startTimer() {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (remainingTime > 0 && isRunning) {
          setState(() {
            remainingTime--;
            progress = 1 - (remainingTime / totalWorkTime);
          });
        } else {
          _stopTimer();
          _showTimeUpDialog(context as BuildContext);
        }
      });
    }
    setState(() {
      isRunning = true;
    });
  }

  void _stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    setState(() {
      isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      remainingTime = totalWorkTime;
      progress = 0.0;
    });
  }

  void _showTimeUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Time\'s Up!'),
          content: Text('You\'ve completed your work session.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showTimerSettingsDialog(BuildContext context) {
    int selectedHours = totalWorkTime ~/ 3600;
    int selectedMinutes = (totalWorkTime % 3600) ~/ 60;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Set Timer'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Hours'),
                      IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () {
                          setState(() {
                            if (selectedHours < 23) selectedHours++;
                          });
                        },
                      ),
                      Text('$selectedHours'),
                      IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () {
                          setState(() {
                            if (selectedHours > 0) selectedHours--;
                          });
                        },
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Minutes'),
                      IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes < 59) selectedMinutes++;
                          });
                        },
                      ),
                      Text('$selectedMinutes'),
                      IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes > 0) selectedMinutes--;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      totalWorkTime = (selectedHours * 3600) + (selectedMinutes * 60);
                      remainingTime = totalWorkTime;
                      progress = 0.0;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Set'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int hours = remainingTime ~/ 3600;
    final int minutes = (remainingTime % 3600) ~/ 60;
    final int seconds = remainingTime % 60;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Timer Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isRunning ? _stopTimer : _startTimer,
                        child: Text(isRunning ? 'Pause' : 'Start'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _resetTimer,
                        child: Text('Reset'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _showTimerSettingsDialog(context),
                        child: Text('Set'),
                      ),
                    ],
                  ),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                  ),
                ],
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // View Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.home),
                    text: 'Home',
                  ),
                  Tab(
                    icon: Icon(Icons.list),
                    text: 'To-do List',
                  ),
                  Tab(
                    icon: Icon(Icons.calendar_today),
                    text: 'Calendar',
                  ),
                  Tab(
                    icon: Icon(Icons.dashboard),
                    text: 'Trello',
                  ),
                ],
              ),
            ),

            // Content Area with TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Home Tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Projects Section
                      _buildSection(
                        'Projects',
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.folder_outlined),
                                title: Text(projects[index]['name']),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Labels Section
                      _buildSection(
                        'Labels',
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: labels.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: Center(
                                child: ListTile(
                                  leading: const Icon(Icons.label_outline),
                                  title: Text(
                                    labels[index]['name'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Section
                      _buildSection(
                        'Status',
                        Row(
                          children: const [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'To do',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Doing',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Done',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // To-do List Tab
                  ToDoPage(),
                  
                  // Calendar Tab
                  CalendarPage(),
                  
                  // Trello Tab (pointing to Planner)
                  PlannerPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskPage(onAddTask: (TaskModel ) {  },)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.expand_more),
                SizedBox(width: 8),
                Icon(Icons.add),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}