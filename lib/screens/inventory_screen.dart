import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/products_repository.dart';
import '../providers/products_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../dialogs/add_product_dialog.dart';
import '../dialogs/edit_product_dialog.dart';
import '../dialogs/quick_import_dialog.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import 'barcode_print_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  bool _onlyLowStock = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(productsAsync),
          _buildLowStockBanner(productsAsync),
          _buildFilters(categoriesAsync),
          Expanded(
            child: _buildProductList(productsAsync, categoriesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Product>> productsAsync) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final activeCount = productsAsync.value?.where((p) => p.isActive).length ?? 0;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
      child: LayoutBuilder(
        builder: (context, headerConstraints) {
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inventario', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('$activeCount productos activos', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.print_outlined, color: AppTheme.primary),
                    tooltip: 'Imprimir Etiquetas',
                    onPressed: () {
                      if (productsAsync.hasValue) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarcodePrintScreen(products: productsAsync.value!),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_motion_rounded, color: Colors.amber),
                    tooltip: 'Carga Rápida de Abarrotes',
                    onPressed: () => showDialog(context: context, builder: (context) => const QuickImportDialog()),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => showDialog(context: context, builder: (context) => const AddProductDialog()),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(isMobile ? 'Nuevo' : 'Nuevo Producto'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildLowStockBanner(AsyncValue<List<Product>> productsAsync) {
    return productsAsync.maybeWhen(
      data: (products) {
        final lowStock = products.where((p) => p.stockQuantity <= p.minStock).toList();
        if (lowStock.isEmpty) return const SizedBox.shrink();
        
        if (_onlyLowStock) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.1), 
            borderRadius: AppTheme.radiusMedium, 
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.2))
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
              const SizedBox(width: 12),
              Expanded(child: Text('${lowStock.length} productos tienen stock bajo o agotado', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold))),
              TextButton(
                onPressed: () => setState(() => _onlyLowStock = true), 
                child: const Text('Ver detalles', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline))
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildFilters(AsyncValue<List<Category>> categoriesAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: appInputDecoration(
                context, 
                label: 'Buscar producto...', 
                icon: Icons.search,
                suffix: _searchQuery.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ) : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          categoriesAsync.when(
            loading: () => const SizedBox(width: 150, height: 44),
            error: (e, s) => const SizedBox.shrink(),
            data: (cats) {
              final options = ['Todas', ...cats.map((c) => c.name)];
              return Container(
                width: 180,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.divider), borderRadius: AppTheme.radiusSmall),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? 'Todas'),
                  ),
                ),
              );
            },
          ),
          if (_onlyLowStock) ...[
            const SizedBox(width: 8),
            InputChip(
              avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
              label: const Text('Stock Bajo', style: TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: AppTheme.error,
              onPressed: () => setState(() => _onlyLowStock = false),
              onDeleted: () => setState(() => _onlyLowStock = false),
              deleteIconColor: Colors.white,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList(AsyncValue<List<Product>> productsAsync, AsyncValue<List<Category>> categoriesAsync) {
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final filtered = products.where((p) {
          // Search filter
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                               (p.barcode?.contains(_searchQuery) ?? false);
          
          // Category filter
          bool matchesCategory = _selectedCategory == 'Todas';
          if (!matchesCategory && categoriesAsync.hasValue) {
            final cat = categoriesAsync.value!.cast<Category?>().firstWhere(
              (c) => c?.name == _selectedCategory, 
              orElse: () => null as Category?,
            );
            if (cat != null) matchesCategory = p.categoryId == cat.id.toString();
          }

          // Low stock filter
          bool matchesLowStock = !_onlyLowStock || (p.stockQuantity <= p.minStock);

          return matchesSearch && matchesCategory && matchesLowStock;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('No se encontraron productos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                if (_onlyLowStock || _searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      _onlyLowStock = false;
                      _searchQuery = '';
                      _searchController.clear();
                    }), 
                    child: const Text('Limpiar filtros')
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            return _ProductListItem(
              product: product,
              onEdit: () => showDialog(context: context, builder: (context) => EditProductDialog(product: product)),
              onDelete: () => _confirmDelete(product),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text('¿Estás seguro de que deseas eliminar "${product.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(productsRepositoryProvider).deleteProduct(product.id);
        ref.invalidate(productsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto eliminado'), backgroundColor: AppTheme.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListItem({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockQuantity <= product.minStock;
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: isLowStock ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.divider.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductImage(imageUrl: product.imageUrl, size: 60, borderRadius: BorderRadius.circular(8)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.barcode != null) ...[
                        const Icon(Icons.qr_code_2, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(product.barcode!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.inventory_2_outlined, size: 14, color: isLowStock ? AppTheme.error : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${product.stockQuantity} unid.', style: TextStyle(fontSize: 12, color: isLowStock ? AppTheme.error : AppTheme.textSecondary, fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(currencyFormat.format(product.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 12),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
