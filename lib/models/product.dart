class Product {
  final String id;
  final String name;
  final String categoryId;
  final String unit; // unidad, kg, litro, paquete, etc.
  final double currentStock;
  final double minimumStock;
  final double? estimatedPrice;
  final String? notes;
  final String? barcode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.unit = 'unidad',
    this.currentStock = 0,
    this.minimumStock = 1,
    this.estimatedPrice,
    this.notes,
    this.barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;

  double get stockNeeded =>
      isLowStock ? (minimumStock - currentStock + minimumStock) : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'unit': unit,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'estimatedPrice': estimatedPrice,
      'notes': notes,
      'barcode': barcode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryId: map['categoryId'] as String,
      unit: map['unit'] as String? ?? 'unidad',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0,
      minimumStock: (map['minimumStock'] as num?)?.toDouble() ?? 1,
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      barcode: map['barcode'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? unit,
    double? currentStock,
    double? minimumStock,
    double? estimatedPrice,
    String? notes,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      notes: notes ?? this.notes,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
