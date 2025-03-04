// At the top of focus_mode_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/focus_session_model.dart';  // Ensure this path is correct
import '../providers/theme_provider.dart';
import '../providers/focus_mode_provider.dart';
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
    