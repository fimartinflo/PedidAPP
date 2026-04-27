class Product {
  final String id;
  final String name;
  final String categoryId;
  final String unit;
  final double currentStock;
  final double minimumStock;
  final double? estimatedPrice;
  final String? notes;
  final String? barcode;
  final DateTime? expiryDate;
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
    this.expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;

  double get stockNeeded =>
      isLowStock ? (minimumStock - currentStock + minimumStock) : 0;

  /// Days until expiry. Negative if already expired. Null if no date set.
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return exp.difference(today).inDays;
  }

  bool get isExpired {
    final days = daysUntilExpiry;
    return days != null && days < 0;
  }

  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days >= 0 && days <= 3;
  }

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
      'expiryDate': expiryDate?.toIso8601String(),
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
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
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
    DateTime? expiryDate,
    bool clearExpiryDate = false,
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
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
