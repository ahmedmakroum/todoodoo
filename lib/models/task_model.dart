class TaskModel {
  int? id;
  String title;
  String? dueDate;
  int labelId;
  bool repeats;

  TaskModel({
    this.id,
    required this.title,
    this.dueDate,
    required this.labelId,
    required this.repeats,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'due_date': dueDate,
      'label_id': labelId,
      'repeats': repeats ? 1 : 0,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      dueDate: map['due_date'],
      labelId: map['label_id'],
      repeats: map['repeats'] == 1,
    );
  }
}