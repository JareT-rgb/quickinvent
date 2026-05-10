import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/cart_notifier.dart';
import '../providers/held_carts_notifier.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_theme.dart';

class HeldCartsDialog extends ConsumerWidget {
  const HeldCartsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldCarts = ref.watch(heldCartsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialog(
      headerIcon: Icons.pause_circle_outline_rounded,
      headerColor: AppTheme.accent,
      title: 'Ventas en Espera',
      subtitle: '${heldCarts.length} carritos pausados temporalmente',
      maxWidth: 500,
      body: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: heldCarts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text('No hay ventas retenidas', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                itemCount: heldCarts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cart = heldCarts[index];
                  return FadeInRight(
                    delay: Duration(milliseconds: index * 50),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.accent, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Venta #${cart.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                Text('${cart.items.length} productos • ${DateFormat('HH:mm').format(cart.createdAt)}', 
                                     style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${cart.totalAmount.toStringAsFixed(2)}', 
                                   style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                    onPressed: () => ref.read(heldCartsProvider.notifier).removeHeldCart(cart.id),
                                    tooltip: 'Eliminar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.restore_rounded, color: AppTheme.primary, size: 20),
                                    onPressed: () {
                                      if (ref.read(cartProvider).isNotEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vacía el carrito actual primero')));
                                        return;
                                      }
                                      ref.read(cartProvider.notifier).setCart(cart.items);
                                      ref.read(heldCartsProvider.notifier).removeHeldCart(cart.id);
                                      Navigator.pop(context);
                                    },
                                    tooltip: 'Reanudar',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}