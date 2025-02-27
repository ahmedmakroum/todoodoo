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
import 'package:todoodoo/screens/timer_page.dart'; // Import for the new timer page
import '../providers/theme_provider.dart';
import 'planner_page.dart';
import '../models/task_model.dart';
import '../services/focus_mode_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState with SingleTickerProviderStateMixin {
  // Database and Notifications
  late TabController _tabController;
  late Database database;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Focus Stats (to be loaded from shared preferences or database)
  int totalFocusedMinutes = 0;
  int todayFocusedMinutes = 0;
  int weekFocusedMinutes = 0;

  // Sample Data
  List<Map<String, dynamic>> projects = [
    {'id': 1, 'name': 'CareerFoundry Course'},
    {'id': 2, 'name': 'Marketing Team Project'},
  ];

  List<Map<String, dynamic>> labels = [
    {'id': 1, 'name': 'Study'},
    {'id': 2, 'name': 'Work'},
    {'id': 3, 'name': 'Personal'},
    {'id': 4, 'name': 'Habit'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    initializeDatabase().catchError((error) {
      debugPrint('Database initialization error: $error');
    });
    initializeNotifications().catchError((error) {
      debugPrint('Notifications initialization error: $error');
    });
    loadFocusData();
  }

  Future<void> initializeDatabase() async {
    try {
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'todo.db');
      database = await openDatabase(
        path,
        version: 2,  // Increment version number
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE Tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              project_id INTEGER,
              label_id INTEGER,
              status TEXT NOT NULL,
              due_date TEXT,
              repeats INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE FocusSessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_time TEXT NOT NULL,
              end_time TEXT NOT NULL,
              duration_seconds INTEGER NOT NULL,
              task_id INTEGER
            )
          ''');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE Tasks ADD COLUMN repeats INTEGER DEFAULT 0');
          }
        },
      );
      FocusSessionService().initialize(database);
    } catch (e) {
      debugPrint('Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> loadFocusData() async {
    // In a real app, you'd load this data from database or shared preferences
    // For this example, we'll use mock data
    setState(() {
      totalFocusedMinutes = 436; // Sample data
      todayFocusedMinutes = 45;  // Sample data
      weekFocusedMinutes = 180;  // Sample data
    });

    // In actual implementation, you would have code like:
    // final sessions = await database.query('FocusSessions', 
    //   where: 'end_time > ?', 
    //   whereArgs: [DateTime.now().subtract(Duration(days: 1)).toIso8601String()]
    // );
    // Calculate minutes from these sessions
  }
  
  String _formatFocusTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '$hours h ${mins > 0 ? '$mins min' : ''}';
    } else {
      return '$mins min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Focus Summary Section (replacing timer)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Focus Summary",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFocusStatCard("Today", _formatFocusTime(todayFocusedMinutes)),
                      _buildFocusStatCard("This Week", _formatFocusTime(weekFocusedMinutes)),
                      _buildFocusStatCard("Total", _formatFocusTime(totalFocusedMinutes)),
                    ],
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(4); // Navigate to timer tab
                    },
                    icon: Icon(Icons.timer),
                    label: Text('Start Focusing'),
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
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.unselectedWidgetColor,
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
                  Tab(
                    icon: Icon(Icons.timer),
                    text: 'Timer',
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
                  
                  // New Timer Tab
                  TimerPage(onSessionComplete: (duration) {
                    // Update focus statistics when a session completes
                    setState(() {
                      final minutes = duration ~/ 60;
                      todayFocusedMinutes += minutes;
                      weekFocusedMinutes += minutes;
                      totalFocusedMinutes += minutes;
                    });
                  }),
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
            MaterialPageRoute(
              builder: (context) => AddTaskPage(
                onAddTask: (TaskModel task) {
                  // Handle the new task here
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFocusStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
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
    _tabController.dispose();
    database.close(); // Close the database connection
    super.dispose();
  }
}