import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late Database _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  Future<Database> initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'todo.db');
    return await openDatabase(
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
            due_date TEXT,
            repeats INTEGER
          )
        ''');
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
    return List.generate(maps.length, (i) {
      return TaskModel.fromMap(maps[i]);
    });
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
}