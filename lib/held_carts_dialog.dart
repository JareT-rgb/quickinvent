import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_notifier.dart';
import 'held_carts_notifier.dart';

class HeldCartsDialog extends ConsumerWidget {
  const HeldCartsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldCarts = ref.watch(heldCartsProvider);

    return AlertDialog(
      title: const Text('Ventas en Espera'),
      content: SizedBox(
        width: double.maxFinite,
        child: heldCarts.isEmpty
            ? const Center(child: Text('No hay ventas en espera.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: heldCarts.length,
                itemBuilder: (context, index) {
                  final cart = heldCarts[index];
                  final totalItems = cart.fold<int>(0, (sum, item) => sum + item.quantity);
                  final totalAmount = cart.fold<double>(0, (sum, item) => sum + item.subtotal);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('Venta #${index + 1} - $totalItems productos'),
                      subtitle: Text('Total: \$${totalAmount.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            child: const Text('Reanudar'),
                            onPressed: () {
                              // Solo reanudar si el carrito actual está vacío
                              if (ref.read(cartProvider).isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Limpia el carrito actual antes de reanudar una venta.'),
                                  backgroundColor: Colors.orange,
                                ));
                                return;
                              }
                              final resumedCart = ref.read(heldCartsProvider.notifier).resumeCart(index);
                              ref.read(cartProvider.notifier).setCart(resumedCart);
                              Navigator.of(context).pop();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              ref.read(heldCartsProvider.notifier).deleteCart(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}