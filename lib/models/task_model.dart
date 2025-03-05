import '../models/label_model.dart';
import '../services/database_service.dart';

class TaskModel {
  final int? id;
  final String title;
  final int? projectId;
  final String status;
  final DateTime? dueDate;
  final bool repeats;
  final List<LabelModel> labels;

  TaskModel({
    this.id,
    required this.title,
    this.projectId,
    required this.status,
    this.dueDate,
    this.repeats = false,
    this.labels = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'project_id': projectId,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'repeats': repeats ? 1 : 0,
    };
  }

  static Future<TaskModel> fromMap(Map<String, dynamic> map, DatabaseService db) async {
    final labels = await db.getLabelsForTask(map['id']);
    return TaskModel(
      id: map['id'],
      title: map['title'],
      projectId: map['project_id'],
      status: map['status'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      repeats: map['repeats'] == 1,
      labels: labels,
    );
  }
}