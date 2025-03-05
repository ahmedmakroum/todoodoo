import 'dart:async';
import '../models/focus_session_model.dart';  
import 'package:sqflite/sqflite.dart';




    class FocusSessionService {
    static final FocusSessionService _instance = FocusSessionService._internal();
    late final Database database;
    
    factory FocusSessionService() => _instance;
    
    FocusSessionService._internal();

    void initialize(Database db) {
        database = db;
    }
    
    Future<int> insertFocusSession(FocusSession session) async {
        return await database.insert('FocusSessions', session.toMap());
    }
    
    Future<List<FocusSession>> getFocusSessions() async {
        final List<Map<String, dynamic>> maps = await database.query('FocusSessions');
        return List.generate(maps.length, (i) => FocusSession.fromMap(maps[i]));
    }
    }
    