import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';

class HeldCart {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime createdAt;

  HeldCart({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });
}

class HeldCartsNotifier extends Notifier<List<HeldCart>> {
  @override
  List<HeldCart> build() {
    return [];
  }

  void holdCart(List<CartItem> items, double total) {
    if (items.isEmpty) return;
    
    final newHeldCart = HeldCart(
      id: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
      items: List.from(items),
      totalAmount: total,
      createdAt: DateTime.now(),
    );
    
    state = [...state, newHeldCart];
  }

  void removeHeldCart(String id) {
    state = state.where((cart) => cart.id != id).toList();
  }
}

final heldCartsProvider = NotifierProvider<HeldCartsNotifier, List<HeldCart>>(() {
  return HeldCartsNotifier();
});