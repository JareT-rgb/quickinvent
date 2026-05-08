import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

/// Gestiona el estado del carrito de compras actual con validación de stock.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  /// Añade un producto al carrito. Si ya existe, intenta incrementar su cantidad.
  /// Retorna un mensaje de error si no hay stock suficiente, de lo contrario null.
  String? addItem(Product product) {
    // Si el producto no tiene stock inicial
    if (product.stockQuantity <= 0) {
      return 'Este producto está agotado';
    }

    final itemIndex = state.indexWhere((item) => item.product.id == product.id);

    if (itemIndex != -1) {
      // Si ya existe en el carrito, delegamos al incremento
      return incrementQuantity(product.id);
    } else {
      // Si es nuevo en el carrito, lo añadimos (ya validamos que hay al menos 1 arriba)
      state = [...state, CartItem(product: product)];
      return null;
    }
  }

  /// Elimina un producto del carrito.
  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Incrementa en uno la cantidad de un producto validando el stock disponible.
  /// Retorna un mensaje de error si se excede el stock, de lo contrario null.
  String? incrementQuantity(String productId) {
    final item = state.firstWhere((item) => item.product.id == productId);
    
    // Validamos si hay stock suficiente para una unidad más
    if (item.quantity + 1 > item.product.stockQuantity) {
      return 'Stock máximo alcanzado (${item.product.stockQuantity} unidades)';
    }

    state = [
      for (final i in state)
        if (i.product.id == productId) i.copyWith(quantity: i.quantity + 1) else i,
    ];
    return null;
  }

  /// Establece una cantidad específica para un producto validando el stock.
  /// Retorna un mensaje de error si se excede el stock, de lo contrario null.
  String? updateQuantity(String productId, int newQuantity) {
    if (newQuantity < 1) return 'La cantidad mínima es 1';
    
    final item = state.firstWhere((item) => item.product.id == productId);
    
    if (newQuantity > item.product.stockQuantity) {
      return 'Stock insuficiente (${item.product.stockQuantity} disponibles)';
    }

    state = [
      for (final i in state)
        if (i.product.id == productId) i.copyWith(quantity: newQuantity) else i,
    ];
    return null;
  }

  /// Decrementa en uno la cantidad de un producto.
  void decrementQuantity(String productId) {
    final item = state.firstWhere((item) => item.product.id == productId);
    if (item.quantity > 1) {
      state = [for (final i in state) if (i.product.id == productId) i.copyWith(quantity: i.quantity - 1) else i];
    } else {
      removeItem(productId);
    }
  }

  /// Vacía completamente el carrito.
  void clearCart() {
    state = [];
  }

  /// Reemplaza el carrito actual.
  void setCart(List<CartItem> newCart) {
    state = newCart;
  }
}

/// Provider para acceder al [CartNotifier] y su estado.
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});