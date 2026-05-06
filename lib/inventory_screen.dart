import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'low_stock_banner.dart';
import 'add_product_dialog.dart';
import 'edit_product_dialog.dart';
import 'products_provider.dart';
import 'products_repository.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _showInactive = false;
  String _searchQuery = '';
  String _selectedCategory = 'Todas las categorías';

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
          return matchesInactive && matchesSearch && matchesCategory;
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
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddProductDialog(),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo producto'),
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
                              value: _showInactive ? 'Inactivos' : 'Activos',
                              options: const ['Todos', 'Activos', 'Inactivos'],
                              onChanged: (val) => setState(
                                () => _showInactive =
                                    (val == 'Inactivos' || val == 'Todos'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _showInactive,
                                  onChanged: (v) => setState(
                                    () => _showInactive = v ?? false,
                                  ),
                                  activeColor: AppTheme.primary,
                                ),
                                const Text(
                                  'Ver inactivos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowHeight: 45,
                              horizontalMargin: 20,
                              columns: _buildColumns(),
                              rows: filteredProducts
                                  .map((p) => _buildDataRow(p, categoryMap))
                                  .toList(),
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
      DataColumn(label: Text('CATEGORIA', style: style)),
      DataColumn(label: Text('PRECIO', style: style)),
      DataColumn(label: Text('STOCK', style: style)),
      DataColumn(label: Text('CÓDIGO', style: style)),
      DataColumn(label: Text('ESTADO', style: style)),
      DataColumn(label: Text('ACCIONES', style: style)),
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
        ),
        DataCell(
          Text(
            catName,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        DataCell(
          Text(
            '\$${p.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13),
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
        ),
        DataCell(
          Text(
            p.barcode ?? 'N/A',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        DataCell(_StatusBadge(active: p.isActive)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppTheme.info,
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditProductDialog(product: p),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.error,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusMedium,
                      ),
                      title: const Text('Confirmar'),
                      content: Text(
                        '¿Deseas desactivar el producto "${p.name}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref
                          .read(productsRepositoryProvider)
                          .updateProduct(
                            productId: p.id,
                            name: p.name,
                            price: p.price,
                            stockQuantity: p.stockQuantity,
                            minStock: p.minStock,
                            isActive: false,
                            barcode: p.barcode,
                            categoryId: p.categoryId,
                          );
                      ref.invalidate(productsProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto desactivado')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
