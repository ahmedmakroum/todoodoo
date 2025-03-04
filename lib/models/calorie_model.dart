class CalorieEntry {
  int id;
  String foodName;
  int calories;
  double servingSize;
  String servingUnit;
  DateTime timestamp;
  String mealType; // breakfast, lunch, dinner, snack
  String? notes;

  CalorieEntry({
    this.id = 0,
    required this.foodName,
    required this.calories,
    required this.servingSize,
    required this.servingUnit,
    required this.timestamp,
    required this.mealType,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'food_name': foodName,
      'calories': calories,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'timestamp': timestamp.toIso8601String(),
      'meal_type': mealType,
      'notes': notes,
    };
    
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  factory CalorieEntry.fromMap(Map<String, dynamic> map) {
    return CalorieEntry(
      id: map['id'] as int,
      foodName: map['food_name'] as String,
      calories: map['calories'] as int,
      servingSize: map['serving_size'] as double,
      servingUnit: map['serving_unit'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      mealType: map['meal_type'] as String,
      notes: map['notes'] as String?,
    );
  }
}

class DailyCalorieSummary {
  int id;
  DateTime date;
  int totalCalories;
  int targetCalories;
  Map<String, int> mealTypeCalories; // Breakdown by meal type

  DailyCalorieSummary({
    this.id = 0,
    required this.date,
    required this.totalCalories,
    required this.targetCalories,
    required this.mealTypeCalories,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date.toIso8601String(),
      'total_calories': totalCalories,
      'target_calories': targetCalories,
      'breakfast_calories': mealTypeCalories['breakfast'] ?? 0,
      'lunch_calories': mealTypeCalories['lunch'] ?? 0,
      'dinner_calories': mealTypeCalories['dinner'] ?? 0,
      'snack_calories': mealTypeCalories['snack'] ?? 0,
    };
    
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  factory DailyCalorieSummary.fromMap(Map<String, dynamic> map) {
    return DailyCalorieSummary(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      totalCalories: map['total_calories'] as int,
      targetCalories: map['target_calories'] as int,
      mealTypeCalories: {
        'breakfast': map['breakfast_calories'] as int,
        'lunch': map['lunch_calories'] as int,
        'dinner': map['dinner_calories'] as int,
        'snack': map['snack_calories'] as int,
      },
    );
  }
}
