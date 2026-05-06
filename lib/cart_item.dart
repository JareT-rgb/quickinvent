import 'product.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get subtotal => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && runtimeType == other.runtimeType && product.id == other.product.id;

  @override
  int get hashCode => product.id.hashCode;
}