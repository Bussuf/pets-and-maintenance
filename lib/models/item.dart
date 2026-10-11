class Item {
  final String id;
  String categoryId;
  String name;
  String? description;
  String? imageUrl;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      categoryId: map['category_id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['image_url'],
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, categoryId: $categoryId, name: $name, description: $description, imageUrl: $imageUrl}';
  }
}
