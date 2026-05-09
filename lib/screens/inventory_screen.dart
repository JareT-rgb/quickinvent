import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/products_provider.dart';
import '../providers/categories_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../dialogs/add_product_dialog.dart';
import '../dialogs/edit_product_dialog.dart';
import '../dialogs/bulk_import_dialog.dart';
import '../dialogs/quick_import_dialog.dart';
import '../utils/excel_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/premium_widgets.dart';
import '../screens/barcode_print_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  bool _onlyLowStock = false;
  bool _isGridView = true;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              _buildHeader(productsAsync),
              _buildLowStockBanner(productsAsync),
              _buildGlassFilters(categoriesAsync, isDark),
              Expanded(
                child: _buildResponsiveProductContent(productsAsync, categoriesAsync),
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodePrintScreen(products: products))),
            ),
            ExpandableFabItem(
              icon: Icons.download_rounded,
              label: 'Exportar Inventario',
              onTap: () => ExcelHelper.exportProducts(products),
            ),
          ],
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Product>> productsAsync) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 40 : 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FadeInLeft(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión de Stock', 
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Control total de tu inventario premium', 
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodePrintScreen(products: products)));
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
              padding: const EdgeInsets.all(8),
              decoration: AppTheme.glassDecoration(isDark: isDark).copyWith(
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Buscar productos...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            categoriesAsync.maybeWhen(
              data: (cats) {
                final options = ['Todas', ...cats.map((c) => c.name)];
                return PremiumSegmentedControl(
                  options: options,
                  selectedIndex: options.indexOf(_selectedCategory).clamp(0, options.length - 1),
                  onSelected: (i) => setState(() => _selectedCategory = options[i]),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.maybeWhen(
      data: (cats) {
        final options = ['Todas', ...cats.map((c) => c.name)];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.primary),
              items: options.map((o) => DropdownMenuItem(
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

  Widget _buildResponsiveProductContent(AsyncValue<List<Product>> productsAsync, AsyncValue<List<Category>> categoriesAsync) {
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
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) => FadeInUp(
                  delay: Duration(milliseconds: index * 50),
                  child: _ProductGridCard(
                    product: filtered[index],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showDialog(context: context, builder: (context) => EditProductDialog(product: filtered[index]));
                    },
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) => FadeInRight(
                delay: Duration(milliseconds: index * 50),
                child: _ProductListTile(
                  product: filtered[index],
                  onTap: () => showDialog(context: context, builder: (context) => EditProductDialog(product: filtered[index])),
                ),
              ),
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
        final cat = categoriesAsync.value!.firstWhere((c) => c.name == _selectedCategory);
        matchesCategory = p.categoryId == cat.id.toString();
      }
      bool matchesLowStock = !_onlyLowStock || (p.stockQuantity <= p.minStock);
      return p.isActive && matchesSearch && matchesCategory && matchesLowStock;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.textMuted.withValues(alpha: 0.2)),
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
          color: AppTheme.error.withValues(alpha: 0.05),
          borderRadius: AppTheme.radiusMedium,
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.1), width: 1.5),
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
          color: color.withValues(alpha: 0.1),
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
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: _isHovered ? (Matrix4.identity()..translate(0, -10, 0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusMedium,
          boxShadow: _isHovered ? AppTheme.deepShadow : AppTheme.softShadow,
          border: Border.all(
            color: _isHovered ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.divider.withValues(alpha: 0.3),
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
                            color: (isLowStock ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.1),
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
        border: Border.all(color: isLowStock ? AppTheme.error.withValues(alpha: 0.2) : AppTheme.divider.withValues(alpha: 0.3)),
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
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
