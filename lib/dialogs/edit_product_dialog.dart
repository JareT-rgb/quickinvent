import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/app_dialog.dart';
import '../models/product.dart';
import '../repositories/products_repository.dart';
import '../providers/products_provider.dart';
import '../theme/app_theme.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  final Product product;
  const EditProductDialog({super.key, required this.product});

  @override
  ConsumerState<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<EditProductDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _barcodeController;
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _currentImageUrl;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    _minStockController = TextEditingController(text: widget.product.minStock.toString());
    _barcodeController = TextEditingController(text: widget.product.barcode ?? '');
    _selectedCategoryId = widget.product.categoryId;
    _currentImageUrl = widget.product.imageUrl;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ref.read(productsRepositoryProvider).fetchCategories();
      if (mounted) {
        setState(() {
          _categories = cats.map((c) => {'id': c.id.toString(), 'name': c.name}).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      String? imageUrl = _currentImageUrl;
      if (_selectedImageFile != null) {
        imageUrl = await ref
            .read(productsRepositoryProvider)
            .uploadProductImage(_nameController.text.trim(), _selectedImageFile!);
      }

      await ref.read(productsRepositoryProvider).updateProduct(
            productId: widget.product.id,
            name: _nameController.text.trim(),
            price: double.tryParse(_priceController.text) ?? 0.0,
            stockQuantity: int.tryParse(_stockController.text) ?? 0,
            minStock: int.tryParse(_minStockController.text) ?? 0,
            isActive: widget.product.isActive,
            barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
            categoryId: _selectedCategoryId,
            imageUrl: imageUrl,
          );

      // Real-time streams handle the update automatically
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text('Cambios guardados con éxito')]),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return AppDialog(
      headerIcon: Icons.edit_note_outlined,
      title: 'Editar Producto',
      subtitle: 'Actualiza la información del inventario',
      maxWidth: isDesktop ? 850 : 500,
      footer: AppDialogFooterButtons(
        actionLabel: 'Guardar Cambios',
        actionIcon: Icons.save_rounded,
        isLoading: _isLoading,
        onAction: _updateProduct,
      ),
      body: Form(
        key: _formKey,
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSectionTitle('Identificación del Producto', Icons.badge_outlined),
                const SizedBox(height: 16),
                ImagePickerWidget(
                  initialImageUrl: _currentImageUrl,
                  onImageChanged: (file, url) {
                    setState(() {
                      _selectedImageFile = file;
                      _currentImageUrl = url;
                    });
                  },
                  height: 160,
                  width: 160,
                  shape: BoxShape.rectangle,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: appInputDecoration(context, label: 'Nombre del Producto', icon: Icons.shopping_bag_outlined),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: appInputDecoration(context, label: 'Categoría', icon: Icons.category_outlined),
                  items: _categories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: appInputDecoration(context, label: 'Código de Barras', icon: Icons.qr_code_scanner),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.auto_fix_high, color: AppTheme.primary),
                      tooltip: 'Generar código automáticamente',
                      onPressed: () {
                        setState(() {
                          _barcodeController.text = DateTime.now().millisecondsSinceEpoch.toString();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Container(width: 1, height: 400, color: AppTheme.divider.withValues(alpha: 0.5)),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSectionTitle('Finanzas e Inventario', Icons.analytics_outlined),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20, color: AppTheme.primary, fontWeight: FontWeight.w900),
                  decoration: appInputDecoration(context, label: 'Precio de Venta', icon: Icons.attach_money),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration(context, label: 'Stock Actual', icon: Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration(context, label: 'Stock Mínimo', icon: Icons.warning_amber_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTipCard('Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Producto Activo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Si se desactiva, no aparecerá en el POS', style: TextStyle(fontSize: 12)),
                  value: widget.product.isActive,
                  onChanged: null,
                  activeColor: AppTheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Básico'), Tab(text: 'Stock')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ImagePickerWidget(initialImageUrl: _currentImageUrl, onImageChanged: (file, url) => setState(() { _selectedImageFile = file; _currentImageUrl = url; }), height: 120, width: 120),
                    const SizedBox(height: 20),
                    TextFormField(controller: _nameController, decoration: appInputDecoration(context, label: 'Nombre', icon: Icons.shopping_bag_outlined)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(value: _selectedCategoryId, items: _categories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(), onChanged: (v) => setState(() => _selectedCategoryId = v), decoration: appInputDecoration(context, label: 'Categoría', icon: Icons.category_outlined)),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: appInputDecoration(context, label: 'Precio', icon: Icons.attach_money)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _stockController, keyboardType: TextInputType.number, decoration: appInputDecoration(context, label: 'Stock', icon: Icons.inventory_2_outlined)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _minStockController, keyboardType: TextInputType.number, decoration: appInputDecoration(context, label: 'Mínimo', icon: Icons.warning_amber_outlined)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: appInputDecoration(context, label: 'Código', icon: Icons.qr_code_scanner),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.auto_fix_high, color: AppTheme.primary),
                          onPressed: () {
                            setState(() {
                              _barcodeController.text = DateTime.now().millisecondsSinceEpoch.toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: AppTheme.radiusSmall, border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1))),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}
