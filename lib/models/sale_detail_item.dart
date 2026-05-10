class SaleDetailItem {
  final String? productId; // Added to handle stock deduction accurately
  final String productName;
  final int quantity;
  final double priceAtSale;
  final double costPriceAtSale;
  final double subtotal;
  final int returnedQuantity;

  SaleDetailItem({
    this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtSale,
    this.costPriceAtSale = 0.0,
    required this.subtotal,
    this.returnedQuantity = 0,
  });

  factory SaleDetailItem.fromMap(Map<String, dynamic> map) {
    final returns = map['return_items'] as List?;
    final returnedQty = returns?.fold<int>(0, (sum, r) => sum + (r['quantity'] as int? ?? 0)) ?? 0;

    return SaleDetailItem(
      productId: map['product_id']?.toString() ?? map['productId']?.toString(),
      productName:
          map['product_name'] ?? map['productName'] ?? 'Producto desconocido',
      quantity: map['quantity'] as int? ?? 0,
      priceAtSale:
          (map['price_at_sale'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0.0,
      costPriceAtSale: (map['cost_price_at_sale'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      returnedQuantity: returnedQty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
      'cost_price_at_sale': costPriceAtSale,
      'subtotal': subtotal,
      'returned_quantity': returnedQuantity,
    };
  }

  SaleDetailItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? priceAtSale,
    double? subtotal,
    int? returnedQuantity,
  }) {
    return SaleDetailItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      priceAtSale: priceAtSale ?? this.priceAtSale,
      subtotal: subtotal ?? this.subtotal,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    );
  }
}
