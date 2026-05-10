import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/cart_notifier.dart';
import '../providers/products_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/held_carts_notifier.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../widgets/animated_pressable.dart';
import '../dialogs/held_carts_dialog.dart';
import '../dialogs/checkout_dialog.dart';
import '../providers/scanner_status_provider.dart';
import '../widgets/product_image.dart';
import 'sale_completion_screen.dart';
import 'scanner_screen.dart';
import '../dialogs/scanner_selection_dialog.dart';
import '../utils/safe_haptic.dart';


class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    
    // Remote Scanner Listener
    ref.listen(scannerStatusProvider, (previous, next) {
      if (next.lastBarcode != null && 
          next.lastScanMode == 'pos' && 
          (next.lastScanTime != previous?.lastScanTime)) {
        productsAsync.whenData((products) async {
          try {
            final product = products.firstWhere((p) => p.barcode == next.lastBarcode);
            final error = ref.read(cartProvider.notifier).addDelta(product, next.quantityDelta);
            
            // Enrich the scan record for the mobile UI
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              await Supabase.instance.client
                  .from('barcode_scans')
                  .update({
                    'status': error != null ? 'out_of_stock' : 'success',
                    'product_name': product.name,
                    'stock_quantity': product.stockQuantity,
                    'price': product.price,
                  })
                  .eq('user_id', userId)
                  .eq('barcode', next.lastBarcode!)
                  .order('created_at', ascending: false)
                  .limit(1);
            }

            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), duration: const Duration(seconds: 1)));
            }
          } catch (_) {
            // Mark as not found
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              await Supabase.instance.client
                  .from('barcode_scans')
                  .update({'status': 'not_found'})
                  .eq('user_id', userId)
                  .eq('barcode', next.lastBarcode!)
                  .order('created_at', ascending: false)
                  .limit(1);
            }
          }
        });
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < 600; // Refined threshold for the main content area
        final total = cart.fold<double>(0, (sum, item) => sum + item.subtotal);

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildModernHeader(isMobile || availableWidth < 500), // Hide text if area is very narrow
                    _buildSearchPanel(),
                    Expanded(
                      child: productsAsync.when(
                        data: (products) => _buildProductGrid(products),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  ],
                ),
              ),
              if (availableWidth > 800) // Only show cart panel on side if enough space
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30)],
                  ),
                  child: _buildCartPanel(cart, total),
                ),
            ],
          ),
          floatingActionButton: availableWidth <= 800 ? FloatingActionButton.extended(
            onPressed: () {
              SafeHaptic.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, controller) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final cart = ref.watch(cartProvider);
                        final total = cart.fold<double>(0, (sum, item) => sum + item.subtotal);
                        return _buildCartPanel(cart, total);
                      },
                    ),
                  ),
                ),
              );
            },
            label: Text('CARRITO (${cart.length})'),
            icon: const Icon(Icons.shopping_cart),
            backgroundColor: AppTheme.primary,
          ) : null,
        );
      },
    );
  }

  Widget _buildModernHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 40 : 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FadeInLeft(
              duration: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terminal de Venta',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Escanea o selecciona productos', 
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                icon: Icons.pause_circle_outline_rounded,
                color: AppTheme.accent,
                tooltip: 'Ventas en Espera',
                onPressed: () => showDialog(context: context, builder: (context) => const HeldCartsDialog()),
              ),
              const SizedBox(width: 8),
              _buildSyncIndicator(ref.watch(scannerStatusProvider).isActive, isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator(bool isActive, bool isMobile) {
    // Para la demo asumimos online, en producción se usaría connectivity_plus
    const bool isOnline = true; 

    final indicator = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (!isOnline ? AppTheme.error : (isActive ? AppTheme.primary : AppTheme.textMuted)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            !isOnline ? Icons.wifi_off_rounded : (isActive ? Icons.cloud_done_rounded : Icons.mobile_off_rounded),
            color: !isOnline ? AppTheme.error : (isActive ? AppTheme.primary : AppTheme.textMuted),
            size: 16,
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text(
              !isOnline ? 'SIN INTERNET' : (isActive ? 'ESCANER VINCULADO' : 'ESCANER DESCONECTADO'),
              style: TextStyle(
                color: !isOnline ? AppTheme.error : (isActive ? AppTheme.primary : AppTheme.textMuted),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );

    return indicator;
  }

  Widget _buildSearchPanel() {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o código...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
                    onPressed: () => showDialog(context: context, builder: (_) => const ScannerSelectionDialog()),
                  ),
                  if (_searchQuery.isNotEmpty) 
                    IconButton(icon: const Icon(Icons.close), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    }),
                ],
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 12),
          categoriesAsync.maybeWhen(
            data: (cats) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary),
                  onPressed: () {
                    _categoryScrollController.animateTo(
                      _categoryScrollController.offset - 100,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Todos', 
                          isSelected: _selectedCategory == 'Todas',
                          onTap: () => setState(() => _selectedCategory = 'Todas'),
                        ),
                        ...cats.map((c) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: c.name, 
                            isSelected: _selectedCategory == c.name,
                            onTap: () => setState(() => _selectedCategory = c.name),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
                  onPressed: () {
                    _categoryScrollController.animateTo(
                      _categoryScrollController.offset + 100,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final filtered = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery) || (p.barcode?.contains(_searchQuery) ?? false);
      bool matchesCategory = _selectedCategory == 'Todas';
      if (!matchesCategory && categoriesAsync.hasValue) {
        final cat = categoriesAsync.value!.firstWhere((c) => c.name == _selectedCategory);
        matchesCategory = p.categoryId == cat.id.toString();
      }
      return p.isActive && matchesSearch && matchesCategory;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
        
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _PosProductCard(product: filtered[index]),
        );
      },
    );
  }

  Widget _buildCartPanel(List<CartItem> cart, double total) {
    return Column(
      children: [
        _buildCartHeader(cart.length),
        Expanded(child: _buildCartList(cart)),
        _buildCheckoutSection(total, cart),
      ],
    );
  }

  Widget _buildCartHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_rounded, color: AppTheme.primary, size: 28),
          const SizedBox(width: 16),
          const Text('Carrito Activo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const Spacer(),
          if (count > 0)
            Material(
              color: Colors.transparent,
              child: IconButton(
                padding: const EdgeInsets.all(12),
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 28),
                onPressed: () {
                  SafeHaptic.mediumImpact();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Vaciar Carrito'),
                      content: const Text('¿Estás seguro de que deseas eliminar todos los productos del carrito?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
                        TextButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).clearCart();
                            Navigator.pop(context);
                          }, 
                          child: const Text('VACIAR', style: TextStyle(color: AppTheme.error))
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Vaciar Carrito',
              ),
            ),
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
            FadeIn(
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.shopping_basket_outlined, size: 60, color: AppTheme.textMuted.withOpacity(0.2)),
            ),
            const SizedBox(height: 16),
            const Text('Sin productos en el carrito', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: cart.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => FadeInLeft(
        duration: const Duration(milliseconds: 150),
        child: _CartItemRow(
          item: cart[index],
          onTap: () => _showQuantityDialog(context, cart[index]),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(double total, List<CartItem> cart) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = AppTheme.primary;
    final sidebarBg = isDark ? theme.cardColor : const Color(0xFF065F46);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: const Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monto Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: cart.isEmpty ? null : () {
                    ref.read(heldCartsProvider.notifier).holdCart(cart, total);
                    ref.read(cartProvider.notifier).clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Venta pausada correctamente'),
                        backgroundColor: AppTheme.accent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.pause_rounded),
                  label: const Text('RETENER'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                    foregroundColor: AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: AnimatedPressable(
                  onTap: cart.isEmpty ? null : () {
                    SafeHaptic.heavyImpact();
                    _startCheckout(cart, total);
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: cart.isEmpty ? null : AppTheme.primaryGradient,
                      color: cart.isEmpty ? AppTheme.textMuted.withOpacity(0.2) : null,
                      borderRadius: AppTheme.radiusMedium,
                      boxShadow: cart.isEmpty ? null : [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'COBRAR',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
            ],
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
        title: Text('Cantidad: ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ingresa cantidad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                final error = ref.read(cartProvider.notifier).updateQuantity(item.product.id, val);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _startCheckout(List<CartItem> cart, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckoutDialog(
        cartItems: cart,
        totalAmount: total,
        onComplete: () {
          ref.read(cartProvider.notifier).clearCart();
        },
      ),
    );
  }
}

class _PosProductCard extends ConsumerStatefulWidget {
  final Product product;
  const _PosProductCard({required this.product});

  @override
  ConsumerState<_PosProductCard> createState() => _PosProductCardState();
}

class _PosProductCardState extends ConsumerState<_PosProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLowStock = widget.product.stockQuantity <= widget.product.minStock;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: _isHovered ? (Matrix4.identity()..setEntry(3, 2, 0.001)..translate(0.0, -5.0, 0.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: AppTheme.radiusMedium,
          boxShadow: _isHovered ? AppTheme.deepShadow : AppTheme.softShadow,
          border: Border.all(
            color: _isHovered ? AppTheme.primary : theme.dividerColor.withOpacity(0.1),
            width: _isHovered ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            final error = ref.read(cartProvider.notifier).addItem(widget.product);
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), duration: const Duration(seconds: 1)));
            }
          },
          borderRadius: AppTheme.radiusMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ProductImage(imageUrl: widget.product.imageUrl, size: double.infinity),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.product.name, 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('\$${widget.product.price.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isLowStock ? AppTheme.error : AppTheme.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        '${widget.product.stockQuantity} DISPONIBLES', 
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isLowStock ? AppTheme.error : AppTheme.primary)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  final CartItem item;
  final VoidCallback onTap;
  const _CartItemRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Text('\$${item.product.price} x ${item.quantity}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
          ),
          Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primary)),
          const SizedBox(width: 8),
          IconButton(
            padding: const EdgeInsets.all(12),
            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error, size: 24),
            onPressed: () {
              SafeHaptic.lightImpact();
              ref.read(cartProvider.notifier).removeItem(item.product.id);
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : theme.dividerColor.withOpacity(0.1)),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
