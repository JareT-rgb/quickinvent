import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product.dart';
import 'products_provider.dart';
import 'products_repository.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  final Product product;

  const EditProductDialog({super.key, required this.product});

  @override
  ConsumerState<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _barcodeController;
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product.stockQuantity.toString(),
    );
    _minStockController = TextEditingController(
      text: widget.product.minStock.toString(),
    );
    _barcodeController = TextEditingController(
      text: widget.product.barcode ?? '',
    );
    _selectedCategoryId = widget.product.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ref
          .read(productsRepositoryProvider)
          .fetchCategories();
      setState(() {
        _categories = categories
            .map((c) => {'id': c.id.toString(), 'name': c.name})
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
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
      await ref
          .read(productsRepositoryProvider)
          .updateProduct(
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
          );

      ref.invalidate(productsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar producto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  prefixIcon: Icon(Icons.label_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el stock';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingrese un stock válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock mínimo',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el stock mínimo';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingrese un valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Código de barras (opcional)',
                  prefixIcon: Icon(Icons.qr_code_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat['id'] as String,
                    child: Text(cat['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProduct,
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Actualizar'),
          ),
        ),
      ],
    );
  }
}
