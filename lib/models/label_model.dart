class LabelModel {
  final int? id;
  final String name;
  final String? color;

  LabelModel({
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

  factory LabelModel.fromMap(Map<String, dynamic> map) {
    return LabelModel(
      id: map['id'],
      name: map['name'],
      color: map['color'],
    );
  }
} 