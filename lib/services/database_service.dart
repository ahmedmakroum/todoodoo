import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import '../models/daily_stats_model.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import '../models/label_model.dart';
import '../models/vision_model.dart';
import '../models/project_model.dart';
import '../models/board_task_model.dart';
import '../models/calendar_event_model.dart';
import '../models/workout_model.dart';
import '../models/calorie_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initializeForPlatform() async {
    // Initialize FFI for Linux
    if (Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Schedule daily reset
    _scheduleDailyReset();
  }

  Future<void> _scheduleDailyReset() async {
    // Calculate time until next midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Schedule the reset
    Future.delayed(timeUntilMidnight, () async {
      await _performDailyReset();
      _scheduleDailyReset(); // Schedule next reset
    });
  }

  Future<void> _performDailyReset() async {
    final db = await database;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // Save yesterday's stats before reset
    final stats = await _collectDailyStats(yesterday);
    await db.insert('DailyStats', stats.toMap());

    // Delete non-repeating tasks that are completed
    await db.delete(
      'Tasks',
      where: 'status = ? AND repeats = 0',
      whereArgs: ['completed'],
    );

    // Reset repeating tasks
    await db.update(
      'Tasks',
      {'status': 'pending'},
      where: 'repeats = 1',
    );

    // Clear today's calorie entries
    await db.delete('CalorieEntries');

    // Notify about the reset
    if (!Platform.isLinux) {
      final notificationService = NotificationService();
      await notificationService.showDailyResetNotification(stats);
    }
  }

  Future<DailyStats> _collectDailyStats(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Count completed tasks
    final tasksResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Tasks WHERE status = ? AND date(due_date) >= date(?) AND date(due_date) < date(?)',
      ['completed', startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    final tasksDone = Sqflite.firstIntValue(tasksResult) ?? 0;

    // Sum focus minutes
    final focusResult = await db.rawQuery(
      'SELECT SUM(duration_seconds) as total FROM FocusSessions WHERE datetime(start_time) BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    final focusSeconds = Sqflite.firstIntValue(focusResult) ?? 0;

    // Count completed workouts
    final workoutsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM WorkoutPlans WHERE is_completed = 1 AND datetime(completion_date) BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    final workoutsCompleted = Sqflite.firstIntValue(workoutsResult) ?? 0;

    // Sum calories
    final caloriesResult = await db.rawQuery(
      'SELECT SUM(calories) as total FROM CalorieEntries WHERE datetime(timestamp) BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    final caloriesConsumed = Sqflite.firstIntValue(caloriesResult) ?? 0;

    return DailyStats(
      date: date,
      tasksDone: tasksDone,
      focusMinutes: focusSeconds ~/ 60,
      workoutsCompleted: workoutsCompleted,
      caloriesConsumed: caloriesConsumed,
      caloriesBurned: 0, // TODO: Implement calorie burning tracking
    );
  }

  Future<List<DailyStats>> getDailyStats({int limit = 7}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'DailyStats',
      orderBy: 'date DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => DailyStats.fromMap(maps[i]));
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'todo.db');

    return await openDatabase(
      path,
      version: 13, // Ensure the version number is correct
      onCreate: (Database db, int version) async {
        // Create DailyStats table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS DailyStats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            tasks_done INTEGER NOT NULL DEFAULT 0,
            focus_minutes INTEGER NOT NULL DEFAULT 0,
            workouts_completed INTEGER NOT NULL DEFAULT 0,
            calories_consumed INTEGER NOT NULL DEFAULT 0,
            calories_burned INTEGER NOT NULL DEFAULT 0
          )
        ''');
        // Create Tasks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            project_id INTEGER,
            status TEXT NOT NULL,
            due_date TEXT,
            repeats INTEGER DEFAULT 0
          )
        ''');

        // Create Labels table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Labels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT
          )
        ''');

        // Create TaskLabels table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS TaskLabels (
            task_id INTEGER,
            label_id INTEGER,
            PRIMARY KEY (task_id, label_id),
            FOREIGN KEY (task_id) REFERENCES Tasks (id) ON DELETE CASCADE,
            FOREIGN KEY (label_id) REFERENCES Labels (id) ON DELETE CASCADE
          )
        ''');

        // Create Projects table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT
          )
        ''');

        // Create Visions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Visions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            target_date TEXT NOT NULL,
            type TEXT NOT NULL
          )
        ''');

        // Create FocusSessions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS FocusSessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            task_id INTEGER
          )
        ''');

        // Create CalendarEvents table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS CalendarEvents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            start_time TEXT,
            end_time TEXT,
            date TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0
          )
        ''');

        // Create BoardTasks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS BoardTasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL,
            color TEXT,
            position INTEGER NOT NULL,
            is_completed INTEGER DEFAULT 0
          )
        ''');

        // Create workout_plans table
        await db.execute('''
          CREATE TABLE workout_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            day_of_week TEXT,
            is_completed INTEGER
          )
        ''');

        // Create workout_exercises table
        await db.execute('''
          CREATE TABLE workout_exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER,
            name TEXT,
            sets INTEGER,
            reps INTEGER,
            weight REAL,
            notes TEXT,
            is_completed INTEGER,
            FOREIGN KEY(plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
          )
        ''');

        // Create CalorieEntries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS CalorieEntries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            food_name TEXT NOT NULL,
            calories INTEGER NOT NULL,
            serving_size REAL NOT NULL,
            serving_unit TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            notes TEXT
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 11) {
          // Create DailyStats table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS DailyStats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              tasks_done INTEGER NOT NULL DEFAULT 0,
              focus_minutes INTEGER NOT NULL DEFAULT 0,
              workouts_completed INTEGER NOT NULL DEFAULT 0,
              calories_consumed INTEGER NOT NULL DEFAULT 0,
              calories_burned INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 4) {
          // Create Visions table if it doesn't exist
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Visions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT NOT NULL,
              is_completed INTEGER DEFAULT 0,
              target_date TEXT NOT NULL,
              type TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 5) {
          // Create Projects table if it doesn't exist
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Projects (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              color TEXT
            )
          ''');
        }

        if (oldVersion < 6) {
          // Create CalendarEvents table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS CalendarEvents (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              start_time TEXT,
              end_time TEXT,
              date TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 7) {
          // Create BoardTasks table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS BoardTasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              status TEXT NOT NULL,
              color TEXT,
              position INTEGER NOT NULL,
              is_completed INTEGER DEFAULT 0
            )
          ''');
        }

        if (oldVersion < 8) {
          // Add is_completed column to BoardTasks table
          await db.execute(
              'ALTER TABLE BoardTasks ADD COLUMN is_completed INTEGER DEFAULT 0');
        }

        if (oldVersion < 9) {
          // Add is_completed column to CalendarEvents table
          await db.execute(
              'ALTER TABLE CalendarEvents ADD COLUMN is_completed INTEGER DEFAULT 0');
        }

        if (oldVersion < 10) {
          // Create CalorieEntries table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS CalorieEntries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              food_name TEXT NOT NULL,
              calories INTEGER NOT NULL,
              serving_size REAL NOT NULL,
              serving_unit TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              notes TEXT
            )
          ''');

          // Create DailyCalorieSummary table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS DailyCalorieSummary (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              total_calories INTEGER NOT NULL,
              target_calories INTEGER NOT NULL,
              breakfast_calories INTEGER DEFAULT 0,
              lunch_calories INTEGER DEFAULT 0,
              dinner_calories INTEGER DEFAULT 0,
              snack_calories INTEGER DEFAULT 0
            )
          ''');

          // Create WorkoutPlans table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS WorkoutPlans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              day_of_week TEXT NOT NULL,
              is_completed INTEGER DEFAULT 0
            )
          ''');

          // Create WorkoutExercises table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS WorkoutExercises (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              plan_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              sets INTEGER NOT NULL,
              reps INTEGER NOT NULL,
              weight REAL NOT NULL,
              notes TEXT,
              is_completed INTEGER DEFAULT 0,
              FOREIGN KEY (plan_id) REFERENCES WorkoutPlans (id) ON DELETE CASCADE
            )
          ''');

          // Create CalorieEntries table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS CalorieEntries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              food_name TEXT NOT NULL,
              calories INTEGER NOT NULL,
              serving_size REAL NOT NULL,
              serving_unit TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              notes TEXT
            )
          ''');

          // Create DailyCalorieSummaries table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS DailyCalorieSummaries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              total_calories INTEGER NOT NULL,
              target_calories INTEGER NOT NULL,
              breakfast_calories INTEGER DEFAULT 0,
              lunch_calories INTEGER DEFAULT 0,
              dinner_calories INTEGER DEFAULT 0,
              snack_calories INTEGER DEFAULT 0
            )
          ''');
        }

        if (oldVersion < 7) {
          // Create BoardTasks table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS BoardTasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              status TEXT NOT NULL,
              color TEXT,
              position INTEGER NOT NULL
            )
          ''');
        }

        if (oldVersion < 1) {
          // Create workout_plans table
          await db.execute('''
            CREATE TABLE workout_plans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              day_of_week TEXT,
              is_completed INTEGER
            )
          ''');

          // Create workout_exercises table
          await db.execute('''
            CREATE TABLE workout_exercises (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              plan_id INTEGER,
              name TEXT,
              sets INTEGER,
              reps INTEGER,
              weight REAL,
              notes TEXT,
              is_completed INTEGER,
              FOREIGN KEY(plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 13) {
          // Create CalorieEntries table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS CalorieEntries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              food_name TEXT NOT NULL,
              calories INTEGER NOT NULL,
              serving_size REAL NOT NULL,
              serving_unit TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              notes TEXT
            )
          ''');
        }
      },
    );
  }

  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert('Tasks', task.toMap());
  }

  Future<List<TaskModel>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Tasks');
    return Future.wait(maps.map((map) => TaskModel.fromMap(map, this)));
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return await db.update(
      'Tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'Tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertLabel(LabelModel label) async {
    final db = await database;
    return await db.insert('Labels', label.toMap());
  }

  Future<List<LabelModel>> getLabels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Labels');
    return List.generate(maps.length, (i) => LabelModel.fromMap(maps[i]));
  }

  Future<int> deleteLabel(int id) async {
    final db = await database;
    return await db.delete('Labels', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> assignLabelToTask(int taskId, int labelId) async {
    final db = await database;
    await db.insert('TaskLabels', {
      'task_id': taskId,
      'label_id': labelId,
    });
  }

  Future<void> removeLabelFromTask(int taskId, int labelId) async {
    final db = await database;
    await db.delete(
      'TaskLabels',
      where: 'task_id = ? AND label_id = ?',
      whereArgs: [taskId, labelId],
    );
  }

  Future<List<LabelModel>> getLabelsForTask(int taskId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT l.* FROM Labels l
      INNER JOIN TaskLabels tl ON l.id = tl.label_id
      WHERE tl.task_id = ?
    ''', [taskId]);
    return List.generate(maps.length, (i) => LabelModel.fromMap(maps[i]));
  }

  Future<void> createBoardTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS BoardTasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        color TEXT,
        position INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertBoardTask(BoardTask task) async {
    final db = await database;
    return await db.insert('BoardTasks', task.toMap());
  }

  Future<List<BoardTask>> getBoardTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('BoardTasks', orderBy: 'position ASC');
    return List.generate(maps.length, (i) => BoardTask.fromMap(maps[i]));
  }

  Future<int> updateBoardTask(BoardTask task) async {
    final db = await database;
    return await db.update(
      'BoardTasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteBoardTask(int id) async {
    final db = await database;
    return await db.delete(
      'BoardTasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertCalendarEvent(CalendarEvent event) async {
    final db = await database;

    // Ensure we're using the date from the event
    final eventDate = event.date;

    return await db.insert('CalendarEvents', {
      'title': event.title,
      'description': event.description,
      'start_time': event.startTime?.toIso8601String(),
      'end_time': event.endTime?.toIso8601String(),
      'date':
          eventDate.toIso8601String(), // Use the date directly from the event
      'is_completed': event.isCompleted ? 1 : 0,
    });
  }

  Future<int> updateCalendarEvent(CalendarEvent event) async {
    final db = await database;

    // Ensure we're using the date from the event
    final eventDate = event.date;

    return await db.update(
      'CalendarEvents',
      {
        'title': event.title,
        'description': event.description,
        'start_time': event.startTime?.toIso8601String(),
        'end_time': event.endTime?.toIso8601String(),
        'date':
            eventDate.toIso8601String(), // Use the date directly from the event
        'is_completed': event.isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<List<Map<String, dynamic>>> getCalendarEventsForDay(
      DateTime date) async {
    final db = await database;
    return await db.query(
      'CalendarEvents',
      where: 'date = ?',
      whereArgs: [DateTime(date.year, date.month, date.day).toIso8601String()],
    );
  }

  Future<int> deleteCalendarEvent(int id) async {
    final db = await database;
    return await db.delete(
      'CalendarEvents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllCalendarEvents() async {
    final db = await database;
    return await db.query('CalendarEvents');
  }

  Future<int> insertVision(Vision vision) async {
    final db = await database;
    return await db.insert('Visions', vision.toMap());
  }

  Future<List<Vision>> getVisions(String type, DateTime targetDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Visions',
      where: 'type = ? AND target_date = ?',
      whereArgs: [type, targetDate.toIso8601String()],
    );
    return List.generate(maps.length, (i) => Vision.fromMap(maps[i]));
  }

  Future<int> updateVision(Vision vision) async {
    final db = await database;
    return await db.update(
      'Visions',
      vision.toMap(),
      where: 'id = ?',
      whereArgs: [vision.id],
    );
  }

  // Workout Methods
  Future<int> insertWorkoutPlan(WorkoutPlan plan) async {
    final db = await database;
    final planId = await db.insert('workout_plans', plan.toMap());
    for (final exercise in plan.exercises) {
      exercise.id = await db.insert('workout_exercises', {
        ...exercise.toMap(),
        'plan_id': planId,
      });
    }
    return planId;
  }

  Future<void> deleteWorkoutExercise(int id) async {
    final db = await database;
    await db.delete(
      'workout_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateWorkoutPlan(WorkoutPlan plan) async {
    final db = await database;
    await db.update(
      'workout_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );

    // Get existing exercises from the database
    final existingExercises = await db.query(
      'workout_exercises',
      where: 'plan_id = ?',
      whereArgs: [plan.id],
    );

    // Convert existing exercises to a map for easy lookup
    final existingExerciseMap = {
      for (var exercise in existingExercises)
        exercise['id']: WorkoutExercise.fromMap(exercise)
    };

    // Update or insert exercises
    for (final exercise in plan.exercises) {
      if (exercise.id != 0 && existingExerciseMap.containsKey(exercise.id)) {
        await db.update(
          'workout_exercises',
          exercise.toMap(),
          where: 'id = ?',
          whereArgs: [exercise.id],
        );
        existingExerciseMap.remove(exercise.id);
      } else {
        exercise.id = await db.insert('workout_exercises', {
          ...exercise.toMap(),
          'plan_id': plan.id,
        });
      }
    }

    // Delete exercises that are no longer in the plan
    for (final exerciseId in existingExerciseMap.keys) {
      await deleteWorkoutExercise(exerciseId as int);
    }
  }

  Future<void> deleteWorkoutPlan(int id) async {
    final db = await database;
    await db.delete(
      'workout_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<WorkoutPlan>> getWorkoutPlans() async {
    final db = await database;
    final planMaps = await db.query('workout_plans');
    final plans = planMaps.map((map) => WorkoutPlan.fromMap(map)).toList();
    for (final plan in plans) {
      final exerciseMaps = await db.query(
        'workout_exercises',
        where: 'plan_id = ?',
        whereArgs: [plan.id],
      );
      plan.exercises =
          exerciseMaps.map((map) => WorkoutExercise.fromMap(map)).toList();
    }
    return plans;
  }

  // Calorie Methods
  Future<int> insertCalorieEntry(CalorieEntry entry) async {
    final db = await database;
    final id = await db.insert('CalorieEntries', entry.toMap());
    await _updateDailyCalorieSummary(entry.timestamp);
    return id;
  }

  Future<void> deleteCalorieEntry(int id) async {
    final db = await database;
    final entry = await db.query(
      'CalorieEntries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (entry.isNotEmpty) {
      final timestamp = DateTime.parse(entry.first['timestamp'] as String);
      await db.delete(
        'CalorieEntries',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _updateDailyCalorieSummary(timestamp);
    }
  }

  Future<int> updateCalorieEntry(CalorieEntry entry) async {
    final db = await database;
    await db.update(
      'CalorieEntries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    await _updateDailyCalorieSummary(entry.timestamp);
    return entry.id;
  }

  Future<List<CalorieEntry>> getCalorieEntriesForDay(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'CalorieEntries',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    return List.generate(maps.length, (i) => CalorieEntry.fromMap(maps[i]));
  }

  Future<void> _updateDailyCalorieSummary(DateTime date) async {
    final db = await database;
    final entries = await getCalorieEntriesForDay(date);

    final totalCalories = entries.fold(0, (sum, entry) => sum + entry.calories);
    final mealTypeCalories = <String, int>{
      'breakfast': 0,
      'lunch': 0,
      'dinner': 0,
      'snack': 0,
    };

    for (final entry in entries) {
      mealTypeCalories[entry.mealType] =
          (mealTypeCalories[entry.mealType] ?? 0) + entry.calories;
    }

    final summary = DailyCalorieSummary(
      date: DateTime(date.year, date.month, date.day),
      totalCalories: totalCalories,
      targetCalories: 2000, // Default target, could be made configurable
      mealTypeCalories: mealTypeCalories,
    );

    await db.insert(
      'DailyCalorieSummaries',
      summary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailyCalorieSummary?> getDailyCalorieSummary(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'DailyCalorieSummaries',
      where: 'date = ?',
      whereArgs: [DateTime(date.year, date.month, date.day).toIso8601String()],
    );

    if (maps.isEmpty) return null;
    return DailyCalorieSummary.fromMap(maps.first);
  }

  Future<int> deleteVision(int id) async {
    final db = await database;
    return await db.delete(
      'Visions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertProject(ProjectModel project) async {
    final db = await database;
    return await db.insert('Projects', project.toMap());
  }

  Future<List<ProjectModel>> getProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Projects');
    return List.generate(maps.length, (i) => ProjectModel.fromMap(maps[i]));
  }

  Future<int> updateProject(ProjectModel project) async {
    final db = await database;
    return await db.update(
      'Projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return await db.delete('Projects', where: 'id = ?', whereArgs: [id]);
  }
}
