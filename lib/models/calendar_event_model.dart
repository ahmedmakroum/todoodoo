class CalendarEvent {
  int id;
  String title;
  String? description;
  DateTime? startTime;
  DateTime? endTime;
  String? color;
  bool isCompleted;

  CalendarEvent({
    this.id = 0,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.color,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'color': color,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      color: map['color'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
    );
  }
}
