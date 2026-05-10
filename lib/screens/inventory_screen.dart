import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/products_provider.dart';
import '../providers/categories_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../repositories/products_repository.dart';
import '../dialogs/add_product_dialog.dart';
import '../dialogs/edit_product_dialog.dart';
import '../dialogs/bulk_import_dialog.dart';
import '../dialogs/quick_import_dialog.dart';
import '../utils/excel_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/premium_widgets.dart';
import '../screens/barcode_print_screen.dart';
import '../utils/safe_haptic.dart';
import '../providers/scanner_status_provider.dart';


class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}
class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  bool _onlyLowStock = false;
  bool _onlyOutOfStock = false;
  bool _onlyInactive = false;
  bool _isGridView = true;
  final _searchController = TextEditingController();

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = 'Todas';
      _onlyLowStock = false;
      _onlyOutOfStock = false;
      _onlyInactive = false;
    });
  }

  bool get _hasActiveFilters => 
      _searchQuery.isNotEmpty || 
      _selectedCategory != 'Todas' || 
      _onlyLowStock || 
      _onlyOutOfStock || 
      _onlyInactive;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final isMobile = MediaQuery.of(context).size.width < 700;
    final isDesktop = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows || 
         defaultTargetPlatform == TargetPlatform.linux || 
         defaultTargetPlatform == TargetPlatform.macOS);

    // Remote Scanner Listener for Inventory Audit
    ref.listen(scannerStatusProvider, (previous, next) {
      if (next.lastBarcode != null && 
          next.lastScanMode == 'audit' && 
          (next.lastScanTime != previous?.lastScanTime)) {
        setState(() {
          _searchController.text = next.lastBarcode!;
          _searchQuery = next.lastBarcode!;
        });
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Premium Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark 
                    ? [const Color(0xFF0F172A), AppTheme.backgroundDark]
                    : [Colors.white, const Color(0xFFF1F5F9)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(productsAsync, isMobile, isDesktop),
              _buildLowStockBanner(productsAsync),
              _buildGlassFilters(categoriesAsync, isDark),
              Expanded(
                child: _buildResponsiveProductContent(productsAsync, categoriesAsync, isDesktop),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: productsAsync.maybeWhen(
        data: (products) => ExpandableFab(
          items: [
            ExpandableFabItem(
              icon: Icons.add_rounded,
              label: 'Nuevo Producto',
              onTap: () => showDialog(context: context, builder: (context) => const AddProductDialog()),
            ),
            ExpandableFabItem(
              icon: Icons.upload_rounded,
              label: 'Importación Masiva',
              onTap: () => showDialog(context: context, builder: (context) => const BulkImportDialog()),
            ),
            ExpandableFabItem(
              icon: Icons.auto_fix_high_rounded,
              label: 'Carga Rápida (Abarrotes)',
              onTap: () => showDialog(context: context, builder: (context) => const QuickImportDialog()),
            ),
            ExpandableFabItem(
              icon: Icons.qr_code_2_rounded,
              label: 'Imprimir Etiquetas',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodePrintScreen(products: products.where((p) => p.isActive).toList()))),
            ),
            ExpandableFabItem(
              icon: Icons.download_rounded,
              label: 'Exportar Inventario',
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generando archivo Excel...'), duration: Duration(seconds: 2)),
                );
                final success = await ExcelHelper.exportProducts(products);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Inventario exportado con éxito' : 'Error al exportar inventario'),
                      backgroundColor: success ? AppTheme.success : AppTheme.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Product>> productsAsync, bool isMobile, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 40 : 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: isDesktop 
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Gestión de Stock', 
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5),
                      ),
                      const SizedBox(width: 12),
                      productsAsync.maybeWhen(
                        data: (products) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${products.where((p) => p.isActive).length}',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  Text(
                    'Control total de tu inventario premium', 
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              )
              : FadeInLeft(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Gestión de Stock', 
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5),
                        ),
                        const SizedBox(width: 12),
                        productsAsync.maybeWhen(
                          data: (products) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${products.where((p) => p.isActive).length}',
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    Text(
                      'Control total de tu inventario premium', 
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _HeaderIconButton(
                icon: _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: AppTheme.primary,
                tooltip: _isGridView ? 'Ver como lista' : 'Ver como cuadrícula',
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.qr_code_2_rounded,
                color: AppTheme.primary,
                tooltip: 'Imprimir Etiquetas',
                onPressed: () {
                  productsAsync.whenData((products) {
                    final activeProducts = products.where((p) => p.isActive).toList();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodePrintScreen(products: activeProducts)));
                  });
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                color: AppTheme.primary,
                tooltip: 'Sincronizar',
                onPressed: () => ref.invalidate(productsProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassFilters(AsyncValue<List<Category>> categoriesAsync, bool isDark) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: AppTheme.glassDecoration(isDark: isDark).copyWith(
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Buscar productos...',
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      if (_hasActiveFilters)
                        IconButton(
                          onPressed: _resetFilters,
                          tooltip: 'Limpiar filtros',
                          icon: const Icon(Icons.filter_alt_off_rounded, size: 18, color: AppTheme.error),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const Divider(height: 12, thickness: 0.5),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // State Filters (Compact)
                        _buildStateFilterChip('Bajo', Icons.warning_amber_rounded, _onlyLowStock, (v) => setState(() => _onlyLowStock = v)),
                        const SizedBox(width: 4),
                        _buildStateFilterChip('Agotado', Icons.block_flipped, _onlyOutOfStock, (v) => setState(() => _onlyOutOfStock = v)),
                        const SizedBox(width: 4),
                        _buildStateFilterChip('Ocultos', Icons.visibility_off_rounded, _onlyInactive, (v) => setState(() => _onlyInactive = v)),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('|', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),

                        // Categories (Smart & Compact)
                        categoriesAsync.maybeWhen(
                          data: (List<Category> cats) {
                            final allOptions = ['Todas', ...cats.map((c) => c.name)];
                            final visibleOptions = allOptions.take(4).toList(); // Todas + 3
                            final hiddenOptions = allOptions.length > 4 ? allOptions.sublist(4) : <String>[];
                            final isHiddenSelected = hiddenOptions.contains(_selectedCategory);

                            return Row(
                              children: [
                                ...visibleOptions.map((opt) {
                                  final isSelected = _selectedCategory == opt;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: ChoiceChip(
                                      label: Text(opt, style: const TextStyle(fontSize: 11)),
                                      selected: isSelected,
                                      onSelected: (v) => setState(() => _selectedCategory = opt),
                                      selectedColor: AppTheme.primary.withOpacity(0.2),
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: isSelected ? AppTheme.primary.withOpacity(0.5) : Colors.transparent),
                                      showCheckmark: false,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }),
                                if (hiddenOptions.isNotEmpty)
                                  PopupMenuButton<String>(
                                    tooltip: 'Más categorías',
                                    onSelected: (v) => setState(() => _selectedCategory = v),
                                    itemBuilder: (ctx) => hiddenOptions.map((opt) => PopupMenuItem(
                                      value: opt,
                                      child: Text(opt, style: const TextStyle(fontSize: 13)),
                                    )).toList(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isHiddenSelected ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isHiddenSelected ? AppTheme.primary.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isHiddenSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: Text(_selectedCategory, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                            ),
                                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.primary),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateFilterChip(String label, IconData icon, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primary),
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.transparent,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildCategoryDropdown(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.maybeWhen(
      data: (List<Category> cats) {
        final options = ['Todas', ...cats.map((c) => (c as Category).name)];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.primary),
              items: options.map((o) => DropdownMenuItem<String>(
                value: o, 
                child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'Todas'),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildResponsiveProductContent(AsyncValue<List<Product>> productsAsync, AsyncValue<List<Category>> categoriesAsync, bool isDesktop) {
    return productsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(24),
        child: SkeletonLoader.list(count: 8),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final filtered = _getFilteredProducts(products, categoriesAsync);
        
        if (filtered.isEmpty) {
          return const EmptyStateWidget(
            title: 'No hay productos',
            subtitle: 'Intenta ajustar tus filtros o agrega un nuevo producto.',
            icon: Icons.inventory_2_outlined,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 900 ? 4 : (width > 600 ? 2 : 1);
            final isMobile = width < 600;

            if (_isGridView && !isMobile) {
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemBuilder: (context, index) {
                  final card = _ProductGridCard(
                    product: filtered[index],
                    onTap: () {
                      SafeHaptic.lightImpact();
                      showDialog(context: context, builder: (context) => EditProductDialog(product: filtered[index]));
                    },
                  );

                  if (isDesktop) return card;

                  return FadeInUp(
                    delay: Duration(milliseconds: index * 50),
                    child: card,
                  );
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final tile = _ProductListTile(
                  product: filtered[index],
                  onTap: () => showDialog(context: context, builder: (context) => EditProductDialog(product: filtered[index])),
                );

                if (isDesktop) return tile;

                return FadeInRight(
                  delay: Duration(milliseconds: index * 50),
                  child: tile,
                );
              },
            );
          },
        );
      },
    );
  }

  List<Product> _getFilteredProducts(List<Product> products, AsyncValue<List<Category>> categoriesAsync) {
    return products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           (p.barcode?.contains(_searchQuery) ?? false);
      
      bool matchesCategory = _selectedCategory == 'Todas';
      if (!matchesCategory && categoriesAsync.hasValue) {
        final List<Category> cats = categoriesAsync.value!;
        final cat = cats.firstWhere((c) => c.name == _selectedCategory, orElse: () => cats.first);
        matchesCategory = p.categoryId == cat.id.toString();
      }

      bool matchesLowStock = !_onlyLowStock || (p.stockQuantity <= p.minStock && p.stockQuantity > 0);
      bool matchesOutOfStock = !_onlyOutOfStock || (p.stockQuantity <= 0);
      bool matchesStatus = _onlyInactive ? !p.isActive : p.isActive;

      return matchesSearch && matchesCategory && matchesLowStock && matchesOutOfStock && matchesStatus;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.textMuted.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text('Sin resultados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textSecondary)),
          TextButton(
            onPressed: () => setState(() { _searchQuery = ''; _searchController.clear(); _selectedCategory = 'Todas'; }),
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockBanner(AsyncValue<List<Product>> productsAsync) {
    final lowStock = productsAsync.value?.where((p) => p.stockQuantity <= p.minStock).toList() ?? [];
    if (lowStock.isEmpty || _onlyLowStock) return const SizedBox.shrink();

    return FadeIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.05),
          borderRadius: AppTheme.radiusMedium,
          border: Border.all(color: AppTheme.error.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppTheme.error, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text('${lowStock.length} productos requieren atención inmediata', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w800, fontSize: 14))),
            ElevatedButton(
              onPressed: () => setState(() => _onlyLowStock = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('CORREGIR', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({required this.icon, required this.color, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      onPressed: onPressed,
    );
  }
}

class _ProductGridCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.onTap});

  @override
  State<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<_ProductGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLowStock = widget.product.stockQuantity <= widget.product.minStock;
    
    final isDesktop = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows || 
         defaultTargetPlatform == TargetPlatform.linux || 
         defaultTargetPlatform == TargetPlatform.macOS);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: (isDesktop || !_isHovered) ? Matrix4.identity() : (Matrix4.identity()..translate(0, -10, 0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusMedium,
          boxShadow: _isHovered ? AppTheme.deepShadow : AppTheme.softShadow,
          border: Border.all(
            color: _isHovered ? AppTheme.primary.withOpacity(0.4) : AppTheme.divider.withOpacity(0.3),
            width: _isHovered ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppTheme.radiusMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ProductImage(imageUrl: widget.product.imageUrl, size: double.infinity),
                    ),
                    if (isLowStock)
                      Positioned(
                        top: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(10)),
                          child: const Text('ALERTA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    Positioned(
                      top: 12, left: 12,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: Consumer(
                          builder: (context, ref, _) => IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                            onPressed: () => _confirmDelete(context, ref, widget.product),
                            tooltip: 'Borrar Producto',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.product.name, 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${widget.product.price.toStringAsFixed(2)}', 
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 18)
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isLowStock ? AppTheme.error : AppTheme.primary).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.product.stockQuantity}', 
                            style: TextStyle(fontSize: 11, color: isLowStock ? AppTheme.error : AppTheme.primary, fontWeight: FontWeight.w900)
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
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductListTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockQuantity <= product.minStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: isLowStock ? AppTheme.error.withOpacity(0.2) : AppTheme.divider.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: ProductImage(imageUrl: product.imageUrl, size: 60, borderRadius: BorderRadius.circular(12)),
        title: SizedBox(
          height: 20,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              product.name, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
            ),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text('\$${product.price}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 16),
              Icon(Icons.inventory_2_rounded, size: 14, color: isLowStock ? AppTheme.error : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text('${product.stockQuantity} unidades', style: TextStyle(fontSize: 13, color: isLowStock ? AppTheme.error : AppTheme.textSecondary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        trailing: Consumer(
          builder: (context, ref, _) => IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            onPressed: () => _confirmDelete(context, ref, product),
            tooltip: 'Borrar Producto',
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Product product) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Borrar producto?', style: TextStyle(fontWeight: FontWeight.w900)),
      content: Text('¿Estás seguro de que quieres borrar "${product.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
          child: const Text('BORRAR'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await ref.read(productsRepositoryProvider).deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto borrado (desactivado)'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al borrar: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
