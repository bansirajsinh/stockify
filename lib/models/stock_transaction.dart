enum TransactionType { stockIn, stockOut }

class StockTransaction {
  final String id;
  final String productId;
  final TransactionType type;
  final int quantity;
  final String reason;
  final DateTime timestamp;
  final String userId;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      type: map['type'] == 'stockIn' ? TransactionType.stockIn : TransactionType.stockOut,
      quantity: map['quantity'] ?? 0,
      reason: map['reason'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'] ?? '',
    );
  }
}