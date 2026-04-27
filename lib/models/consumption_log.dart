class ConsumptionLog {
  final String id;
  final String productId;
  final double quantity;
  final DateTime timestamp;

  ConsumptionLog({
    required this.id,
    required this.productId,
    required this.quantity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConsumptionLog.fromMap(Map<String, dynamic> map) {
    return ConsumptionLog(
      id: map['id'] as String,
      productId: map['productId'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
