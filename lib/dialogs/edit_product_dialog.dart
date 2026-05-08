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
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _stockController =
        TextEditingController(text: widget.product.stockQuantity.toString());
    _minStockController =
        TextEditingController(text: widget.product.minStock.toString());
    _barcodeController =
        TextEditingController(text: widget.product.barcode ?? '');
    _selectedCategoryId = widget.product.categoryId;
    _currentImageUrl = widget.product.imageUrl;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats =
          await ref.read(productsRepositoryProvider).fetchCategories();
      setState(() {
        _categories =
            cats.map((c) => {'id': c.id.toString(), 'name': c.name}).toList();
      });
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
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }
    setState(() => _isLoading = true);
    try {
      String? imageUrl = _currentImageUrl;
      if (_selectedImageFile != null) {
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          await ref
              .read(productsRepositoryProvider)
              .deleteProductImage(_currentImageUrl);
        }
        imageUrl = await ref
            .read(productsRepositoryProvider)
            .uploadProductImage(
                _nameController.text.trim(), _selectedImageFile!);
      }

      await ref.read(productsRepositoryProvider).updateProduct(
            productId: widget.product.id,
            name: _nameController.text.trim(),
            price: double.tryParse(_priceController.text) ?? 0.0,
            stockQuantity: int.tryParse(_stockController.text) ?? 0,
            minStock: int.tryParse(_minStockController.text) ?? 0,
            isActive: widget.product.isActive,
            barcode: _barcodeController.text.trim().isEmpty
                ? null
                : _barcodeController.text.trim(),
            categoryId: _selectedCategoryId,
            imageUrl: imageUrl,
          );

      ref.invalidate(productsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Producto actualizado exitosamente'),
            ]),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppDialog(
      headerIcon: Icons.edit_note_rounded,
      headerColor: AppTheme.primary,
      title: 'Editar Producto',
      subtitle: widget.product.name,
      canClose: !_isLoading,
      maxHeight: 750,
      footer: AppDialogFooterButtons(
        actionLabel: 'Guardar Cambios',
        actionIcon: Icons.check_circle_outline,
        actionColor: AppTheme.primary,
        isLoading: _isLoading,
        onAction: _updateProduct,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab bar - Rediseñado para verse Premium
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Text('DATOS BÁSICOS'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('STOCK & EXTRAS'),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Flexible(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1 ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ImagePickerWidget(
                                initialImageUrl: _currentImageUrl,
                                onImageChanged: (file, url) {
                                  setState(() {
                                    _selectedImageFile = file;
                                    if (file != null) _currentImageUrl = null;
                                  });
                                },
                                height: 110,
                                width: 110,
                                shape: BoxShape.circle,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: appInputDecoration(context,
                              label: 'Nombre del producto',
                              icon: Icons.label_outlined,
                              hint: 'Ej: Leche Entera 1L'),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Ingrese el nombre'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: appInputDecoration(context,
                              label: 'Precio de venta',
                              icon: Icons.attach_money,
                              hint: '0.00'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (double.tryParse(v) == null) return 'Inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          decoration: appInputDecoration(context,
                              label: 'Categoría',
                              icon: Icons.category_outlined),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c['id'] as String,
                                    child: Text(c['name'] as String),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v),
                        ),
                      ],
                    ),
                  ),

                  // ── Tab 2 ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                decoration: appInputDecoration(context,
                                    label: 'Stock actual',
                                    icon: Icons.format_list_numbered,
                                    hint: '0'),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requerido';
                                  if (int.tryParse(v) == null) return 'Inválido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                decoration: appInputDecoration(context,
                                    label: 'Stock mínimo',
                                    icon: Icons.warning_amber_outlined,
                                    hint: '0'),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requerido';
                                  if (int.tryParse(v) == null) return 'Inválido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: cs.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Se enviará una alerta cuando el stock baje del mínimo.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.primary.withValues(alpha: 0.85)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _barcodeController,
                          decoration: appInputDecoration(context,
                              label: 'Código de barras (opcional)',
                              icon: Icons.qr_code_outlined,
                              hint: 'Escanea o escribe el código'),
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
  }
}
