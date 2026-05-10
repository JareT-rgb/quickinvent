import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/app_dialog.dart';
import '../models/product.dart';
import '../repositories/products_repository.dart';
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
  bool _isActive = true;
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
    _isActive = widget.product.isActive;
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
            isActive: _isActive,
            barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
            categoryId: _selectedCategoryId,
            imageUrl: imageUrl,
          );

      // Real-time streams handle the update automatically
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text('Cambios guardados con éxito')]),
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

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar producto?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('¿Estás seguro de que quieres borrar "${widget.product.name}"?'),
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
      setState(() => _isLoading = true);
      try {
        await ref.read(productsRepositoryProvider).deleteProduct(widget.product.id);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto borrado con éxito'), backgroundColor: AppTheme.success),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al borrar: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
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
      footer: Row(
        children: [
          IconButton(
            onPressed: _isLoading ? null : _deleteProduct,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.error.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppDialogFooterButtons(
              actionLabel: 'Guardar Cambios',
              actionIcon: Icons.save_rounded,
              isLoading: _isLoading,
              onAction: _updateProduct,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Identificación del Producto',
                  icon: Icons.badge_rounded,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ImagePickerWidget(
                            initialImageUrl: _currentImageUrl,
                            onImageChanged: (file, url) {
                              setState(() {
                                _selectedImageFile = file;
                                _currentImageUrl = url;
                              });
                            },
                            height: 120,
                            width: 120,
                            shape: BoxShape.rectangle,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: appInputDecoration(context, label: 'Código de Barras', icon: Icons.qr_code_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _ActionButton(
                            icon: Icons.auto_fix_high_rounded,
                            onPressed: () => setState(() => _barcodeController.text = DateTime.now().millisecondsSinceEpoch.toString()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSectionCard(
                  title: 'Inventario y Estado',
                  icon: Icons.analytics_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 24, color: AppTheme.primary, fontWeight: FontWeight.w900),
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
                              decoration: appInputDecoration(context, label: 'Stock Actual', icon: Icons.inventory_2_rounded),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minStockController,
                              keyboardType: TextInputType.number,
                              decoration: appInputDecoration(context, label: 'Mínimo', icon: Icons.notification_important_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Producto Activo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: const Text('Visible en el punto de venta', style: TextStyle(fontSize: 11)),
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTipCard('Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Detalles del Producto',
            icon: Icons.edit_rounded,
            child: Column(
              children: [
                Center(
                  child: ImagePickerWidget(
                    initialImageUrl: _currentImageUrl,
                    onImageChanged: (file, url) => setState(() {
                      _selectedImageFile = file;
                      _currentImageUrl = url;
                    }),
                    height: 140,
                    width: 140,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: appInputDecoration(context, label: 'Nombre', icon: Icons.shopping_bag_outlined),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: appInputDecoration(context, label: 'Categoría', icon: Icons.category_outlined),
                  items: _categories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Control de Stock',
            icon: Icons.inventory_2_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: appInputDecoration(context, label: 'Precio', icon: Icons.attach_money),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration(context, label: 'Stock', icon: Icons.add_business_rounded),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration(context, label: 'Mínimo', icon: Icons.warning_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: appInputDecoration(context, label: 'Código', icon: Icons.qr_code_rounded),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.auto_fix_high_rounded,
                      onPressed: () => setState(() => _barcodeController.text = DateTime.now().millisecondsSinceEpoch.toString()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.08), AppTheme.primary.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 24, color: AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 13, color: AppTheme.primary.withOpacity(0.8), height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
      ),
    );
  }
}
