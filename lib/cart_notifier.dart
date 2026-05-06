import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product.dart';
import 'cart_item.dart';

/// Gestiona el estado del carrito de compras actual.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // This is the initial state of the cart.
    return [];
  }

  /// Añade un producto al carrito. Si ya existe, incrementa su cantidad.
  void addItem(Product product) {
    // Busca el índice del producto en el carrito.
    final itemIndex = state.indexWhere((item) => item.product.id == product.id);

    if (itemIndex != -1) {
      // Si el producto ya existe, incrementa su cantidad.
      incrementQuantity(product.id);
    } else {
      // Si no está, lo añade a la lista.
      state = [...state, CartItem(product: product)];
    }
  }

  /// Elimina un producto del carrito, sin importar su cantidad.
  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Incrementa en uno la cantidad de un producto en el carrito.
  void incrementQuantity(String productId) {
    state = [
      for (final item in state)
        if (item.product.id == productId) item.copyWith(quantity: item.quantity + 1) else item,
    ];
  }

  /// Decrementa en uno la cantidad de un producto. Si la cantidad llega a cero, lo elimina.
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

  /// Reemplaza el carrito actual con una nueva lista de items.
  /// Usado para reanudar una venta en espera.
  void setCart(List<CartItem> newCart) {
    state = newCart;
  }
}

/// Provider para acceder al [CartNotifier] y su estado.
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});