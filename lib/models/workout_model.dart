import 'package:flutter/material.dart';

class WorkoutExercise {
  int id;
  String name;
  int sets;
  int reps;
  double weight;
  String? notes;
  bool isCompleted;

  WorkoutExercise({
    this.id = 0,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.notes,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
    };
    
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as int,
      name: map['name'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: map['weight'] as double,
      notes: map['notes'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }
}

class WorkoutPlan {
  int id;
  String name;
  String dayOfWeek;
  List<WorkoutExercise> exercises;
  bool isCompleted;

  WorkoutPlan({
    this.id = 0,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'day_of_week': dayOfWeek,
      'is_completed': isCompleted ? 1 : 0,
    };
    
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      id: map['id'] as int,
      name: map['name'] as String,
      dayOfWeek: map['day_of_week'] as String,
      exercises: [],  // Exercises will be loaded separately
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }
}
