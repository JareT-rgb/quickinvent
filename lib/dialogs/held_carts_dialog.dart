import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_notifier.dart';
import '../providers/held_carts_notifier.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_theme.dart';

class HeldCartsDialog extends ConsumerWidget {
  const HeldCartsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldCarts = ref.watch(heldCartsProvider);

    return AppDialog(
      headerIcon: Icons.pause_circle_outline_rounded,
      headerColor: AppTheme.warning,
      title: 'Ventas en Espera',
      subtitle: '${heldCarts.length} venta(s) pausada(s)',
      maxWidth: 460,
      footer: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cerrar'),
        ),
      ),
      body: heldCarts.isEmpty
          ? const SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFD1D5DB)),
                    SizedBox(height: 8),
                    Text(
                      'No hay ventas en espera',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: heldCarts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cart = heldCarts[index];
                final totalItems =
                    cart.fold<int>(0, (sum, item) => sum + item.quantity);
                final totalAmount =
                    cart.fold<double>(0, (sum, item) => sum + item.subtotal);

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.4)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          color: AppTheme.warning, size: 20),
                    ),
                    title: Text(
                      'Venta #${index + 1} — $totalItems productos',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Total: \$${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (ref.read(cartProvider).isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Limpia el carrito actual antes de reanudar.'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            final resumedCart = ref
                                .read(heldCartsProvider.notifier)
                                .resumeCart(index);
                            ref.read(cartProvider.notifier).setCart(resumedCart);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.play_circle_outline, size: 18),
                          label: const Text('Reanudar'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error, size: 20),
                          tooltip: 'Eliminar',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: () {
                            ref
                                .read(heldCartsProvider.notifier)
                                .deleteCart(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}