class ProjectModel {
  final int? id;
  final String name;
  final String? color;

  ProjectModel({
    this.id,
    required this.name,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'],
      color: map['color'],
    );
  }
} 