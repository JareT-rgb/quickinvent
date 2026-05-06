class SaleDetailItem {
  final String productName;
  final int quantity;
  final double priceAtSale;

  SaleDetailItem({
    required this.productName,
    required this.quantity,
    required this.priceAtSale,
  });

  double get subtotal => quantity * priceAtSale;

  factory SaleDetailItem.fromMap(Map<String, dynamic> map) {
    return SaleDetailItem(
      // Si el producto original fue eliminado, mostramos un texto alternativo.
      productName: (map['products']?['name'] as String?) ?? 'Producto eliminado',
      quantity: map['quantity'] as int,
      priceAtSale: (map['price_at_sale'] as num).toDouble(),
    );
  }
}