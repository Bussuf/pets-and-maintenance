// מודל קבוצה מעודכן הכולל צבע, אייקון ומיון מותאם אישית
class Category {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final int? color; // ערך Color.value (ARGB) כערך מספרי
  final String? icon; // מזהה מחרוזת של האייקון (לדוגמה: 'folder', 'pets')
  final int sortOrder; // מיקום המיון הידני

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.color,
    this.icon,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'color': color,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      color: map['color'] as int?,
      icon: map['icon'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    int? color,
    String? icon,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}