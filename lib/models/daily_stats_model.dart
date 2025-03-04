import 'package:flutter/foundation.dart';

class DailyStats {
  int id;
  DateTime date;
  int tasksDone;
  int focusMinutes;
  int workoutsCompleted;
  int caloriesConsumed;
  int caloriesBurned;

  DailyStats({
    this.id = 0,
    required this.date,
    this.tasksDone = 0,
    this.focusMinutes = 0,
    this.workoutsCompleted = 0,
    this.caloriesConsumed = 0,
    this.caloriesBurned = 0,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date.toIso8601String(),
      'tasks_done': tasksDone,
      'focus_minutes': focusMinutes,
      'workouts_completed': workoutsCompleted,
      'calories_consumed': caloriesConsumed,
      'calories_burned': caloriesBurned,
    };
    
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id'] as int? ?? 0,
      date: DateTime.parse(map['date'] as String),
      tasksDone: map['tasks_done'] as int? ?? 0,
      focusMinutes: map['focus_minutes'] as int? ?? 0,
      workoutsCompleted: map['workouts_completed'] as int? ?? 0,
      caloriesConsumed: map['calories_consumed'] as int? ?? 0,
      caloriesBurned: map['calories_burned'] as int? ?? 0,
    );
  }

  DailyStats copyWith({
    int? id,
    DateTime? date,
    int? tasksDone,
    int? focusMinutes,
    int? workoutsCompleted,
    int? caloriesConsumed,
    int? caloriesBurned,
  }) {
    return DailyStats(
      id: id ?? this.id,
      date: date ?? this.date,
      tasksDone: tasksDone ?? this.tasksDone,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}
