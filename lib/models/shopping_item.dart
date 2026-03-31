class ShoppingItem {
  final String id;
  final String shoppingListId;
  final String productId;
  final String productName;
  final String categoryId;
  final double quantity;
  final String unit;
  final double? estimatedPrice;
  final bool isPurchased;
  final double? actualPrice;
  final String? notes;

  ShoppingItem({
    required this.id,
    required this.shoppingListId,
    required this.productId,
    required this.productName,
    required this.categoryId,
    this.quantity = 1,
    this.unit = 'unidad',
    this.estimatedPrice,
    this.isPurchased = false,
    this.actualPrice,
    this.notes,
  });

  double get totalEstimated => (estimatedPrice ?? 0) * quantity;
  double get totalActual => (actualPrice ?? estimatedPrice ?? 0) * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shoppingListId': shoppingListId,
      'productId': productId,
      'productName': productName,
      'categoryId': categoryId,
      'quantity': quantity,
      'unit': unit,
      'estimatedPrice': estimatedPrice,
      'isPurchased': isPurchased ? 1 : 0,
      'actualPrice': actualPrice,
      'notes': notes,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as String,
      shoppingListId: map['shoppingListId'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      categoryId: map['categoryId'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String? ?? 'unidad',
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble(),
      isPurchased: (map['isPurchased'] as int?) == 1,
      actualPrice: (map['actualPrice'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? shoppingListId,
    String? productId,
    String? productName,
    String? categoryId,
    double? quantity,
    String? unit,
    double? estimatedPrice,
    bool? isPurchased,
    double? actualPrice,
    String? notes,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isPurchased: isPurchased ?? this.isPurchased,
      actualPrice: actualPrice ?? this.actualPrice,
      notes: notes ?? this.notes,
    );
  }
}
