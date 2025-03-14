import 'package:sqflite/sqflite.dart';
import 'package:todoodoo/models/focus_session_model.dart';

class FocusSessionService {
  static final FocusSessionService _instance = FocusSessionService._internal();
  Database? _database; // use nullable field

  factory FocusSessionService() => _instance;
  FocusSessionService._internal();

  void initialize(Database db) {
    if (_database != null) {
      // Already initialized; ignore subsequent calls.
      return;
    }
    _database = db;
  }

  bool get isInitialized => _database != null;

  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return _database!;
  }

  insertFocusSession(FocusSession session) {}
}
