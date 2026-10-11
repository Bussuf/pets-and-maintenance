class Item {
  final String id;
  String categoryId;
  String name;
  String? description;
  String? imageUrl;
  int sortOrder;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      categoryId: map['category_id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['image_url'],
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Item copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    String? imageUrl,
    int? sortOrder,
  }) {
    return Item(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, categoryId: $categoryId, name: $name, description: $description, imageUrl: $imageUrl, sortOrder: $sortOrder}';
  }
}