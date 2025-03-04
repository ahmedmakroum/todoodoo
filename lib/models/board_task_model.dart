class BoardTask {
  int id;
  String title;
  String? description;
  String status; // 'monday', 'tuesday', etc.
  String? color;
  int position;
  bool isCompleted;

  BoardTask({
    this.id = 0,
    required this.title,
    this.description,
    required this.status,
    this.color,
    required this.position,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'status': status,
      'color': color,
      'position': position,
      'is_completed': isCompleted ? 1 : 0,
    };
    
    // Only include id if it's not 0 (for updates)
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  factory BoardTask.fromMap(Map<String, dynamic> map) {
    return BoardTask(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      color: map['color'] as String?,
      position: map['position'] as int,
      isCompleted: (map['is_completed'] as int?) == 1,
    );
  }
}
