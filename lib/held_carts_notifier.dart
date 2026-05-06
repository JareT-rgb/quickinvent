import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_item.dart';

class HeldCartsNotifier extends Notifier<List<List<CartItem>>> {
  @override
  List<List<CartItem>> build() {
    // The initial state is an empty list of carts.
    return [];
  }

  // Guarda un carrito en la lista de ventas en espera
  void holdCart(List<CartItem> cart) {
    if (cart.isNotEmpty) {
      state = [...state, cart];
    }
  }

  // Elimina un carrito de la lista de espera y lo devuelve para ser reanudado
  List<CartItem> resumeCart(int index) {
    // Guardamos una referencia al carrito que vamos a devolver
    final cartToResume = state[index];
    // Creamos una nueva lista sin el carrito que estamos reanudando
    state = state.where((cart) => cart != cartToResume).toList();
    return cartToResume;
  }

  void deleteCart(int index) {
    // Ensure the index is valid before attempting to remove.
    if (index >= 0 && index < state.length) {
      final updatedCarts = List<List<CartItem>>.from(state);
      updatedCarts.removeAt(index);
      state = updatedCarts;
    }
  }
}

final heldCartsProvider = NotifierProvider<HeldCartsNotifier, List<List<CartItem>>>(() => HeldCartsNotifier());