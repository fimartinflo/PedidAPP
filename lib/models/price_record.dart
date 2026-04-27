class PriceRecord {
  final String id;
  final String productId;
  final double price;
  final DateTime date;
  final String? source;
  final String? store;

  PriceRecord({
    required this.id,
    required this.productId,
    required this.price,
    DateTime? date,
    this.source,
    this.store,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'price': price,
      'date': date.toIso8601String(),
      'source': source,
      'store': store,
    };
  }

  factory PriceRecord.fromMap(Map<String, dynamic> map) {
    return PriceRecord(
      id: map['id'] as String,
      productId: map['productId'] as String,
      price: (map['price'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      source: map['source'] as String?,
      store: map['store'] as String?,
    );
  }
}
