import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/products_provider.dart';
import '../providers/cart_notifier.dart';
import '../providers/scanner_status_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/cart_item.dart';
import '../widgets/product_image.dart';
import '../widgets/animated_pressable.dart';
import '../widgets/app_dialog.dart';
import '../dialogs/held_carts_dialog.dart';
import '../dialogs/checkout_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cart = ref.watch(cartProvider);
    final scannerStatus = ref.watch(scannerStatusProvider);
    
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final filteredProducts = products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                               (p.barcode?.contains(_searchQuery) ?? false);
          
          bool matchesCategory = _selectedCategory == 'Todas';
          if (!matchesCategory && categoriesAsync.hasValue) {
            final categories = categoriesAsync.value ?? [];
            final foundCategory = categories.cast<Category?>().firstWhere(
              (c) => c?.name == _selectedCategory,
              orElse: () => null as Category?,
            );
            if (foundCategory != null) {
              matchesCategory = p.categoryId == foundCategory.id.toString();
            }
          }
          
          return p.isActive && matchesSearch && matchesCategory;
        }).toList();

        double total = cart.fold(0, (sum, item) => sum + item.subtotal);

        Widget mainContent = Column(
          children: [
            if (scannerStatus.isActive && !isMobile) _buildScannerBanner(scannerStatus),
            _buildSearchAndFilters(isMobile, categoriesAsync),
            Expanded(
              child: filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : (size.width > 1200 ? 5 : 4),
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                    ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Row(
            children: [
              Expanded(child: mainContent),
              if (!isMobile) _buildCartPanel(cart, total),
            ],
          ),
          floatingActionButton: isMobile && cart.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showMobileCart(context, cart, total),
                  label: Text('${cart.length} items - \$${total.toStringAsFixed(2)}'),
                  icon: const Icon(Icons.shopping_cart),
                )
              : null,
        );
      },
    );
  }

  Widget _buildScannerBanner(ScannerStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.phonelink_ring, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text('Escáner remoto activo: ${status.lastBarcode ?? "Esperando..."}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile, AsyncValue<List<Category>> categoriesAsync) {
    final categories = ['Todas', ...(categoriesAsync.value?.map((c) => c.name) ?? [])];

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Buscar producto o escanear...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.qr_code_scanner),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (v) => setState(() => _selectedCategory = cat),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                );
              },
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
      onTap: isOutOfStock ? null : () {
        final error = ref.read(cartProvider.notifier).addItem(product);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppTheme.error, duration: const Duration(seconds: 1)),
          );
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.radiusMedium,
          side: BorderSide(color: isOutOfStock ? AppTheme.error.withValues(alpha: 0.2) : AppTheme.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    placeholderIcon: Icons.inventory_2_outlined,
                  ),
                  if (isLowStock || isOutOfStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? AppTheme.error : AppTheme.warning,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isOutOfStock ? 'AGOTADO' : 'BAJO STOCK',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                      Text('${product.stockQuantity} pza', style: TextStyle(fontSize: 10, color: isLowStock ? AppTheme.error : AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No se encontraron productos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCartPanel(List<CartItem> cart, double total) {
    return Container(
      width: 350,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          _buildCartHeader(),
          Expanded(child: _buildCartList(cart)),
          _buildTotalSection(total, cart),
        ],
      ),
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: const Row(
        children: [
          Icon(Icons.shopping_cart_outlined, color: AppTheme.primary),
          SizedBox(width: 10),
          Text('Carrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCartList(List<CartItem> cart) {
    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('Carrito vacío', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cart.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) => _buildCartItemRow(cart[index]),
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    return Row(
      children: [
        ProductImage(imageUrl: item.product.imageUrl, size: 45),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('\$${item.product.price.toStringAsFixed(2)} c/u', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Row(
          children: [
            _CartQtyBtn(icon: Icons.remove, onTap: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id)),
            InkWell(
              onTap: () => _showQuantityDialog(context, item),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15),
                ),
              ),
            ),
            _CartQtyBtn(
              icon: Icons.add, 
              onTap: () {
                final error = ref.read(cartProvider.notifier).incrementQuantity(item.product.id);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: AppTheme.error, duration: const Duration(seconds: 1)),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
          onPressed: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildTotalSection(double total, List<CartItem> cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: cart.isEmpty ? null : () => _startCheckout(cart, total),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium)),
              child: const Text('COBRAR AHORA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, CartItem item) {
    final controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cantidad: ${item.product.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock disponible: ${item.product.stockQuantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: appInputDecoration(context, label: 'Nueva cantidad', icon: Icons.edit),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                final error = ref.read(cartProvider.notifier).updateQuantity(item.product.id, val);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: AppTheme.error),
                  );
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _startCheckout(List<CartItem> cart, double total) {
    showDialog(
      context: context,
      builder: (context) => CheckoutDialog(
        cartItems: cart,
        totalAmount: total,
        onComplete: () {
          // Additional logic after checkout if needed
        },
      ),
    );
  }

  void _showMobileCart(BuildContext context, List<CartItem> cart, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: _buildCartPanel(cart, total),
      ),
    );
  }
}

class _CartQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CartQtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.divider), borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 14, color: AppTheme.primary),
      ),
    );
  }
}
