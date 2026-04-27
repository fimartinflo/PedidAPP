class PriceRecord {
  final String id;
  final String productId;
  final double price;
  final DateTime date;
  final String? source; // 'manual', 'shopping_list', 'receipt'

  PriceRecord({
    required this.id,
    required this.productId,
    required this.price,
    DateTime? date,
    this.source,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'price': price,
      'date': date.toIso8601String(),
      'source': source,
    };
  }

  factory PriceRecord.fromMap(Map<String, dynamic> map) {
    return PriceRecord(
      id: map['id'] as String,
      productId: map['productId'] as String,
      price: (map['price'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      source: map['source'] as String?,
    );
  }
}
