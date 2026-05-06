import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_item.dart';

class SuspendedSale {
  final DateTime date;
  final List<CartItem> items;
  final double total;

  SuspendedSale({required this.date, required this.items, required this.total});
}

class SuspendedSalesNotifier extends Notifier<List<SuspendedSale>> {
  @override
  List<SuspendedSale> build() {
    return [];
  }

  void suspendSale(List<CartItem> items, double total) {
    if (items.isEmpty) return;
    state = [...state, SuspendedSale(date: DateTime.now(), items: items, total: total)];
  }

  void removeSale(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }
}

final suspendedSalesProvider = NotifierProvider<SuspendedSalesNotifier, List<SuspendedSale>>(() {
  return SuspendedSalesNotifier();
});