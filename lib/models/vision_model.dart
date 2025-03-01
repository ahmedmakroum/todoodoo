class Vision {
  final int? id;
  final String content;
  final bool isCompleted;
  final DateTime targetDate;
  final String type; // 'monthly' or 'yearly'

  Vision({
    this.id,
    required this.content,
    this.isCompleted = false,
    required this.targetDate,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'is_completed': isCompleted ? 1 : 0,
      'target_date': targetDate.toIso8601String(),
      'type': type,
    };
  }

  Vision copyWith({
    int? id,
    String? content,
    bool? isCompleted,
    DateTime? targetDate,
    String? type,
  }) {
    return Vision(
      id: id ?? this.id,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      targetDate: targetDate ?? this.targetDate,
      type: type ?? this.type,
    );
  }

  static Vision fromMap(Map<String, dynamic> map) {
    return Vision(
      id: map['id'],
      content: map['content'],
      isCompleted: map['is_completed'] == 1,
      targetDate: DateTime.parse(map['target_date']),
      type: map['type'],
    );
  }
} 