class ListTemplate {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<TemplateItem> items;

  ListTemplate({
    required this.id,
    required this.name,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalItems => items.length;

  double get totalEstimated =>
      items.fold(0, (sum, item) => sum + (item.estimatedPrice ?? 0) * item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ListTemplate.fromMap(Map<String, dynamic> map,
      {List<TemplateItem> items = const []}) {
    return ListTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      items: items,
    );
  }

  ListTemplate copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<TemplateItem>? items,
  }) {
    return ListTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}

class TemplateItem {
  final String id;
  final String templateId;
  final String productId;
  final String productName;
  final String categoryId;
  final double quantity;
  final String unit;
  final double? estimatedPrice;

  TemplateItem({
    required this.id,
    required this.templateId,
    required this.productId,
    required this.productName,
    required this.categoryId,
    this.quantity = 1,
    this.unit = 'unidad',
    this.estimatedPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'productId': productId,
      'productName': productName,
      'categoryId': categoryId,
      'quantity': quantity,
      'unit': unit,
      'estimatedPrice': estimatedPrice,
    };
  }

  factory TemplateItem.fromMap(Map<String, dynamic> map) {
    return TemplateItem(
      id: map['id'] as String,
      templateId: map['templateId'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      categoryId: map['categoryId'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String? ?? 'unidad',
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble(),
    );
  }
}
