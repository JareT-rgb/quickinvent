class ProductReturn {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double amountReturned;
  final String? reason;
  final DateTime createdAt;

  ProductReturn({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.amountReturned,
    this.reason,
    required this.createdAt,
  });
}