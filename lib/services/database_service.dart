import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import '../models/task_model.dart';
import '../models/label_model.dart';

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
      version: 3,
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
        if (oldVersion < 3) {
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
}