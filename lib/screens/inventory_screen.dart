import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../dialogs/edit_product_dialog.dart';
import '../dialogs/add_product_dialog.dart';
import '../widgets/low_stock_banner.dart';
import '../providers/products_provider.dart';
import '../repositories/products_repository.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas las categorías';
  String _selectedFilter = 'Todos';
  bool _showInactive = false; // Keep for RLS/Logic if needed elsewhere, or remove if fully replaced

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final categoryNames = categoriesAsync.when(
          data: (cats) => ['Todas las categorías', ...cats.map((c) => c.name)],
          loading: () => <String>['Todas las categorías'],
          error: (e, s) => <String>['Todas las categorías'],
        );

        final categoryMap = categoriesAsync.when(
          data: (cats) => {for (var c in cats) c.name: c.id.toString()},
          loading: () => <String, String>{},
          error: (e, s) => <String, String>{},
        );

        final filteredProducts = products.where((p) {
          final matchesInactive = _showInactive || p.isActive;
          final matchesSearch =
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.barcode?.contains(_searchQuery) ?? false);
          final matchesCategory =
              _selectedCategory == 'Todas las categorías' ||
              p.categoryId == categoryMap[_selectedCategory];
          
          final isLowStock = p.stockQuantity < p.minStock;
          final matchesFilter = switch (_selectedFilter) {
            'Stock Bajo' => isLowStock,
            'Inactivos' => !p.isActive,
            'Activos' => p.isActive,
            _ => true,
          };

          return matchesInactive && matchesSearch && matchesCategory && matchesFilter;
        }).toList();

        final activeCount = products.where((p) => p.isActive).length;
        final inactiveCount = products.where((p) => !p.isActive).length;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventario',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$activeCount productos activos',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddProductDialog(),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Nuevo producto',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LowStockBanner(
                productNames: products
                    .where((p) => p.stockQuantity < p.minStock)
                    .map((p) => p.name)
                    .toList(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre o código...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.qr_code_scanner,
                                    size: 20,
                                    color: AppTheme.textMuted,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: AppTheme.radiusSmall,
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildDropdown(
                              value: _selectedCategory,
                              options: categoryNames,
                              onChanged: (val) =>
                                  setState(() => _selectedCategory = val!),
                            ),
                            const SizedBox(width: 8),
                            _buildDropdown(
                              value: _selectedFilter,
                              options: const ['Todos', 'Activos', 'Inactivos', 'Stock Bajo'],
                              onChanged: (val) => setState(() => _selectedFilter = val!),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width - 80, // Approximate padding
                              ),
                              child: DataTable(
                                headingRowHeight: 45,
                                horizontalMargin: 16,
                                columnSpacing: 20,
                                dataRowMaxHeight: 52,
                                columns: _buildColumns(),
                                rows: filteredProducts
                                    .map((p) => _buildDataRow(p, categoryMap))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${filteredProducts.length} productos mostrados',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$activeCount activos - $inactiveCount inactivos',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<DataColumn> _buildColumns() {
    const style = TextStyle(
      color: AppTheme.textSecondary,
      fontWeight: FontWeight.bold,
      fontSize: 11,
    );
    return const [
      DataColumn(label: Text('PRODUCTO', style: style)),
      DataColumn(label: Text('CATEGORÍA', style: style)),
      DataColumn(label: Text('PRECIO', style: style)),
      DataColumn(label: Text('STOCK', style: style)),
      DataColumn(label: Text('ESTADO', style: style)),
      DataColumn(label: Text('', style: style)),
    ];
  }

  DataRow _buildDataRow(dynamic p, Map<String, String> categoryMap) {
    final catName = categoryMap.entries
        .firstWhere(
          (e) => e.value == p.categoryId,
          orElse: () => const MapEntry('Sin Categoría', ''),
        )
        .key;

    final isLowStock = p.stockQuantity < p.minStock;

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          onTap: () => showDialog(
            context: context,
            builder: (context) => EditProductDialog(product: p),
          ),
        ),
        DataCell(
          Text(catName, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          onTap: () => showDialog(
            context: context,
            builder: (context) => EditProductDialog(product: p),
          ),
        ),
        DataCell(
          Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
          onTap: () => showDialog(
            context: context,
            builder: (context) => EditProductDialog(product: p),
          ),
        ),
        DataCell(
          Text(
            '${p.stockQuantity}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isLowStock ? AppTheme.error : AppTheme.textPrimary,
            ),
          ),
          onTap: () => showDialog(
            context: context,
            builder: (context) => EditProductDialog(product: p),
          ),
        ),
        DataCell(
          _StatusBadge(active: p.isActive),
          onTap: () => showDialog(
            context: context,
            builder: (context) => EditProductDialog(product: p),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.info),
                tooltip: 'Editar',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditProductDialog(product: p),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                tooltip: 'Eliminar',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium),
                      title: const Text('Confirmar eliminación'),
                      content: Text('¿Deseas eliminar permanentemente "${p.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref.read(productsRepositoryProvider).deleteProduct(p.id);
                      ref.invalidate(productsProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto eliminado')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: AppTheme.radiusSmall,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          items: options
              .map(
                (String item) =>
                    DropdownMenuItem(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: active ? AppTheme.success : AppTheme.error,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
