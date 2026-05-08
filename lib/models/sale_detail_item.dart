class SaleDetailItem {
  final String? productId; // Added to handle stock deduction accurately
  final String productName;
  final int quantity;
  final double priceAtSale;
  final double subtotal;

  SaleDetailItem({
    this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtSale,
    required this.subtotal,
  });

  factory SaleDetailItem.fromMap(Map<String, dynamic> map) {
    return SaleDetailItem(
      productId: map['product_id']?.toString() ?? map['productId']?.toString(),
      productName:
          map['product_name'] ?? map['productName'] ?? 'Producto desconocido',
      quantity: map['quantity'] as int? ?? 0,
      priceAtSale:
          (map['price_at_sale'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
      'subtotal': subtotal,
    };
  }

  SaleDetailItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? priceAtSale,
    double? subtotal,
  }) {
    return SaleDetailItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      priceAtSale: priceAtSale ?? this.priceAtSale,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
