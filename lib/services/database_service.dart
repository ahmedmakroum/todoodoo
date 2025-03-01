import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import '../models/task_model.dart';
import '../models/label_model.dart';
import '../models/vision_model.dart';
import '../models/project_model.dart';

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
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'todo.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE Tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            project_id INTEGER,
            status TEXT NOT NULL,
            due_date TEXT,
            repeats INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE Labels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE TaskLabels (
            task_id INTEGER,
            label_id INTEGER,
            PRIMARY KEY (task_id, label_id),
            FOREIGN KEY (task_id) REFERENCES Tasks (id) ON DELETE CASCADE,
            FOREIGN KEY (label_id) REFERENCES Labels (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE Projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE Visions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            target_date TEXT NOT NULL,
            type TEXT NOT NULL
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
    return Future.wait(
      maps.map((map) => TaskModel.fromMap(map, this))
    );
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