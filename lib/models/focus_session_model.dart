// lib/models/focus_session_model.dart
class FocusSession {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final int? taskId;

  FocusSession({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.taskId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': durationSeconds,
      'task_id': taskId,
    };
  }

  static FocusSession fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      durationSeconds: map['duration_seconds'],
      taskId: map['task_id'],
    );
  }
}