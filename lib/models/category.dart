class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.icon = 'category',
    this.color = '#4CAF50',
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'category',
      color: map['color'] as String? ?? '#4CAF50',
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static List<Category> defaultCategories() {
    return [
      Category(id: 'cat_1', name: 'Alimentos', icon: 'restaurant', color: '#FF9800', sortOrder: 0),
      Category(id: 'cat_2', name: 'Bebidas', icon: 'local_drink', color: '#2196F3', sortOrder: 1),
      Category(id: 'cat_3', name: 'Limpieza', icon: 'cleaning_services', color: '#4CAF50', sortOrder: 2),
      Category(id: 'cat_4', name: 'Higiene Personal', icon: 'soap', color: '#E91E63', sortOrder: 3),
      Category(id: 'cat_5', name: 'Lácteos', icon: 'egg', color: '#FFC107', sortOrder: 4),
      Category(id: 'cat_6', name: 'Carnes', icon: 'set_meal', color: '#F44336', sortOrder: 5),
      Category(id: 'cat_7', name: 'Frutas y Verduras', icon: 'eco', color: '#8BC34A', sortOrder: 6),
      Category(id: 'cat_8', name: 'Panadería', icon: 'bakery_dining', color: '#795548', sortOrder: 7),
      Category(id: 'cat_9', name: 'Snacks', icon: 'fastfood', color: '#FF5722', sortOrder: 8),
      Category(id: 'cat_10', name: 'Otros', icon: 'more_horiz', color: '#607D8B', sortOrder: 9),
    ];
  }
}
