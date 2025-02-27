class TaskModel {
  final int? id;
  final String title;
  final int? projectId;
  final int? labelId;
  final String status;
  final DateTime? dueDate;
  final bool repeats;

  TaskModel({
    this.id,
    required this.title,
    this.projectId,
    this.labelId,
    required this.status,
    this.dueDate,
    this.repeats = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'project_id': projectId,
      'label_id': labelId,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'repeats': repeats ? 1 : 0,
    };
  } 

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      projectId: map['project_id'],
      labelId: map['label_id'],
      status: map['status'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      repeats: map['repeats'] == 1,
    );
  }
}