import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dialogs/checkout_dialog.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../dialogs/held_carts_dialog.dart';
import '../providers/held_carts_notifier.dart';
import '../providers/products_provider.dart';
import '../providers/cart_notifier.dart';
import '../models/cart_item.dart';
import '../widgets/animated_pressable.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});
  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';
  RealtimeChannel? _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    _setupBarcodeListener();
  }

  void _setupBarcodeListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _barcodeSubscription = Supabase.instance.client
        .channel('public:barcode_scans')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'barcode_scans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final code = payload.newRecord['barcode'] as String?;
            final scanId = payload.newRecord['id'] as String?;
            if (code != null && code.isNotEmpty && scanId != null) {
              _processScannedCode(code, scanId);
            }
          },
        )
        .subscribe();
  }

  Future<void> _processScannedCode(String code, String scanId) async {
    final client = Supabase.instance.client;
    final products = ref.read(productsProvider).value ?? [];
    
    try {
      final product = products.firstWhere((p) => p.barcode == code);
      
      if (product.stockQuantity > 0) {
        ref.read(cartProvider.notifier).addItem(product);
        
        // Notify phone: Success
        await client.from('barcode_scans').update({
          'status': 'success',
          'product_name': product.name,
          'processed': true,
        }).eq('id', scanId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} agregado vía móvil'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Notify phone: Out of stock
        await client.from('barcode_scans').update({
          'status': 'out_of_stock',
          'product_name': product.name,
          'processed': true,
        }).eq('id', scanId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Agotado: ${product.name}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      // Notify phone: Not found
      await client.from('barcode_scans').update({
        'status': 'not_found',
        'processed': true,
      }).eq('id', scanId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código no encontrado: $code'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _barcodeSubscription?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final filteredProducts = products.where((p) {
          final matchesSearch =
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.barcode?.contains(_searchQuery) ?? false);
          return p.isActive && matchesSearch;
        }).toList();

        double total = cart.fold(0, (sum, item) => sum + item.subtotal);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            int crossAxisCount = 4;
            if (constraints.maxWidth < 500) {
              crossAxisCount = 2;
            } else if (constraints.maxWidth < 800) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth < 1100) {
              crossAxisCount = 4;
            } else {
              crossAxisCount = 5;
            }

            final mainContent = Container(
              color: AppTheme.background,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Buscar producto o escanear...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppTheme.textSecondary,
                            ),
                            suffixIcon: const Icon(
                              Icons.qr_code_scanner,
                              color: AppTheme.textMuted,
                            ),
                            filled: true,
                            fillColor: AppTheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: AppTheme.radiusMedium,
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (isMobile) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const HeldCartsDialog(),
                            );
                          },
                          icon: const Icon(Icons.pause),
                          tooltip: 'En espera',
                        ),
                      ] else ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const HeldCartsDialog(),
                            );
                          },
                          icon: const Icon(Icons.pause),
                          label: const Text('En espera'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? _buildEmptyState(
                            'No hay productos disponibles',
                            Icons.search_off,
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.82,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) =>
                                _buildProductCard(filteredProducts[index]),
                          ),
                  ),
                ],
              ),
            );

            Widget cartPanel() {
              return Container(
                width: isMobile ? double.infinity : 380,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: isMobile
                      ? null
                      : const Border(left: BorderSide(color: AppTheme.divider)),
                  boxShadow: isMobile
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(-2, 0),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Carrito',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: cart.isEmpty
                          ? _buildEmptyState(
                              'El carrito está vacío',
                              Icons.shopping_bag_outlined,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: cart.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final item = cart[index];
                                return _buildCartItemRow(item);
                              },
                            ),
                    ),
                    _buildTotalSection(total, cart),
                  ],
                ),
              );
            }

            if (isMobile) {
              return Scaffold(
                body: mainContent,
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + kToolbarHeight,
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: cartPanel(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: Text('${cart.length} items - \$${total.toStringAsFixed(2)}'),
                ),
              );
            }

            return Row(
              children: [
                Expanded(child: mainContent),
                cartPanel(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: AppTheme.radiusSmall,
          ),
          child: Center(
            child: Text(
              item.product.categoryId ?? 'Sin categoría',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${item.product.price.toStringAsFixed(2)} c/u',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QtyButton(
              icon: Icons.remove,
              onTap: () =>
                  ref.read(cartProvider.notifier).decrementQuantity(item.product.id),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            _QtyButton(
              icon: Icons.add,
              onTap: () =>
                  ref.read(cartProvider.notifier).incrementQuantity(item.product.id),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  ref.read(cartProvider.notifier).removeItem(item.product.id),
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: AppTheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Busca productos para agregarlos aquí',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(double total, List<CartItem> cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cart.length} artículos',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => CheckoutDialog(
                          cartItems: cart,
                          totalAmount: total,
                          onComplete: () {},
                        ),
                      );
                    },
              child: const Text('Cobrar venta'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      ref.read(heldCartsProvider.notifier).holdCart(cart);
                      ref.read(cartProvider.notifier).clearCart();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Venta guardada en espera'),
                        ),
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

    return AnimatedPressable(
      onTap: isOutOfStock
          ? null
          : () => ref.read(cartProvider.notifier).addItem(product),
      child: Hero(
        tag: 'prod_${product.id}',
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.radiusMedium,
            border: Border.all(
              color: isOutOfStock
                  ? AppTheme.error.withValues(alpha: 0.3)
                  : (isLowStock
                        ? AppTheme.warning.withValues(alpha: 0.4)
                        : AppTheme.divider.withValues(alpha: 0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppTheme.radiusMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.05),
                              AppTheme.primary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 32,
                            color: isOutOfStock ? AppTheme.error.withValues(alpha: 0.5) : AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      if (isLowStock || isOutOfStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isOutOfStock ? AppTheme.error : AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isOutOfStock ? Icons.close : Icons.priority_high,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${product.stockQuantity} pza',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLowStock ? AppTheme.error : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
