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
import 'package:todoodoo/screens/labels_page.dart';
import 'package:todoodoo/screens/daily_stats_page.dart';
import 'package:todoodoo/screens/projects_page.dart';
import 'package:todoodoo/screens/timer_page.dart';
import 'package:todoodoo/screens/workout_planner_page.dart';
import 'package:todoodoo/screens/calorie_counter_page.dart';
import 'package:todoodoo/screens/daily_stats_page.dart';
import '../providers/theme_provider.dart';
import 'board_planner_page.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';
import '../services/focus_mode_service.dart';
import '../services/database_service.dart';
import 'dart:io' show Platform;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Database database;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  int totalFocusedMinutes = 0;
  int todayFocusedMinutes = 0;
  int weekFocusedMinutes = 0;

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
    _tabController = TabController(length: 9, vsync: this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await DatabaseService().initializeForPlatform();
      database = await DatabaseService().database;
      await initializeNotifications();
      await loadFocusData();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> initializeNotifications() async {
    if (!Platform.isLinux) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    }
  }

  Future<void> loadFocusData() async {
    setState(() {
      totalFocusedMinutes = 436;
      todayFocusedMinutes = 45;
      weekFocusedMinutes = 180;
    });
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
    final themeMode = ref.watch(themeModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ).createShader(bounds),
          child: const Text(
            'ToDoodoo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ),
        ],
        bottom: TabBar(
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.check_box), text: 'Tasks'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
            Tab(icon: Icon(Icons.view_kanban), text: 'Board'),
            Tab(icon: Icon(Icons.folder), text: 'Projects'),
            Tab(icon: Icon(Icons.label), text: 'Labels'),
            Tab(icon: Icon(Icons.timer), text: 'Timer'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Workout'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Calories'),
            Tab(icon: Icon(Icons.analytics), text: 'Daily Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ToDoPage(),
          const CalendarPage(),
          const BoardPlannerPage(),
          const ProjectsPage(),
          const LabelsPage(),
          TimerPage(onSessionComplete: (duration) async {
            try {
              final session = FocusSession(
                startTime: DateTime.now().subtract(Duration(seconds: duration)),
                endTime: DateTime.now(),
                durationSeconds: duration,
              );
              
              await FocusSessionService().insertFocusSession(session);
              await loadFocusData();
            } catch (e) {
              debugPrint('Error saving focus session: $e');
            }
          }),
          const WorkoutPlannerPage(),
          const CalorieCounterPage(),
          const DailyStatsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskPage(
                onAddTask: (TaskModel task) async {
                  try {
                    final taskId = await database.insert('Tasks', task.toMap());
                    
                    for (final label in task.labels) {
                      if (label.id != null) {
                        await DatabaseService().assignLabelToTask(taskId, label.id!);
                      }
                    }
                    setState(() {});
                  } catch (e) {
                    debugPrint('Error adding task: $e');
                  }
                },
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        elevation: 4,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    database.close();
    super.dispose();
  }
}