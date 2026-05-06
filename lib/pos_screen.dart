import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'products_provider.dart';
import 'product.dart';
import 'cart_item.dart';
import 'cart_notifier.dart';
import 'checkout_dialog.dart';
import 'held_carts_dialog.dart';
import 'held_carts_notifier.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});
  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final filteredProducts = products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.barcode?.contains(_searchQuery) ?? false);
          return p.isActive && matchesSearch;
        }).toList();

        double total = cart.fold(0, (sum, item) => sum + item.subtotal);

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: AppTheme.background,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Buscar producto o escanear código...',
                              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                              suffixIcon: const Icon(Icons.qr_code_scanner, color: AppTheme.textMuted),
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(context: context, builder: (context) => const HeldCartsDialog());
                          },
                          icon: const Icon(Icons.pause),
                          label: const Text('En espera'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? _buildEmptyState('No hay productos disponibles', Icons.search_off)
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.82,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: const Border(left: BorderSide(color: AppTheme.divider)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(-2, 0))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.divider))),
                    child: const Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined, color: AppTheme.primary),
                        SizedBox(width: 10),
                        Text('Carrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cart.isEmpty
                        ? _buildEmptyState('El carrito está vacío', Icons.shopping_bag_outlined)
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: cart.length,
                            separatorBuilder: (_, _) => const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final item = cart[index];
                              return Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.08),
                                      borderRadius: AppTheme.radiusSmall,
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.product.name[0],
                                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text('\$${item.product.price.toStringAsFixed(2)} c/u', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _QtyButton(icon: Icons.remove, onTap: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      ),
                                      _QtyButton(icon: Icons.add, onTap: () => ref.read(cartProvider.notifier).incrementQuantity(item.product.id)),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                                        child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  _buildTotalSection(total, cart),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildTotalSection(double total, List<CartItem> cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cart.length} artículos', style: const TextStyle(color: AppTheme.textSecondary)),
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cart.isEmpty ? null : () {
                showDialog(
                  context: context,
                  builder: (context) => CheckoutDialog(cartItems: cart, totalAmount: total),
                );
              },
              child: const Text('Cobrar venta'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cart.isEmpty ? null : () {
                ref.read(heldCartsProvider.notifier).holdCart(cart);
                ref.read(cartProvider.notifier).clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Venta guardada en espera')),
                );
              },
              child: const Text('Poner en espera'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.stockQuantity < product.minStock;
    final isOutOfStock = product.stockQuantity <= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.radiusMedium,
        side: BorderSide(color: isOutOfStock ? AppTheme.error.withValues(alpha: 0.3) : (isLowStock ? AppTheme.warning.withValues(alpha: 0.4) : AppTheme.divider)),
      ),
      child: InkWell(
        borderRadius: AppTheme.radiusMedium,
        onTap: isOutOfStock ? null : () => ref.read(cartProvider.notifier).addItem(product),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOutOfStock ? AppTheme.error.withValues(alpha: 0.08) : AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: Center(
                  child: Text(
                    product.name[0],
                    style: TextStyle(
                      color: isOutOfStock ? AppTheme.error : AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOutOfStock ? AppTheme.error.withValues(alpha: 0.08) : (isLowStock ? AppTheme.warning.withValues(alpha: 0.08) : AppTheme.primary.withValues(alpha: 0.06)),
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: Text(
                  isOutOfStock ? 'Agotado' : (isLowStock ? 'Stock bajo' : 'Stock: ${product.stockQuantity}'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isOutOfStock ? AppTheme.error : (isLowStock ? AppTheme.warning : AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: AppTheme.radiusSmall,
        ),
        child: Icon(icon, size: 16, color: AppTheme.primary),
      ),
    );
  }
}
