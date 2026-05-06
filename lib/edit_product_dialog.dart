import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'products_repository.dart';
import 'product.dart';
import 'category.dart';
import 'products_provider.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  const EditProductDialog({required this.product, super.key});

  final Product product;

  @override
  ConsumerState<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _barcodeController;
  Category? _selectedCategory;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(text: product.price.toString());
    _stockController = TextEditingController(text: product.stockQuantity.toString());
    _minStockController = TextEditingController(text: product.minStock.toString());
    _barcodeController = TextEditingController(text: product.barcode ?? '');
    _isActive = product.isActive;

    final categories = ref.read(categoriesProvider).value ?? [];
    if (product.categoryId != null) {
      try {
        _selectedCategory = categories.firstWhere(
          (cat) => cat.id.toString() == product.categoryId,
        );
      } on StateError {
        _selectedCategory = null;
      }
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ref.read(productsRepositoryProvider).updateProduct(
              productId: widget.product.id,
              name: _nameController.text,
              price: double.parse(_priceController.text),
              stockQuantity: int.parse(_stockController.text),
              minStock: int.parse(_minStockController.text),
              isActive: _isActive,
              barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
              categoryId: _selectedCategory?.id.toString(),
            );

        ref.invalidate(productsProvider);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto actualizado con éxito')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar producto: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Editar producto', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('Subir imagen', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeThumbColor: const Color(0xFF8BC34A),
                        ),
                        const Text('Producto activo', 
                          style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: 'Precio *',
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: categoriesAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, s) => const Text('Error'),
                                data: (categories) => DropdownButtonFormField<Category?>(
                                  // ignore: deprecated_member_use
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Categoría *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Ninguna')),
                                    ...categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name))),
                                  ],
                                  onChanged: (value) => setState(() => _selectedCategory = value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                decoration: InputDecoration(
                                  labelText: 'Stock actual *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _minStockController,
                                decoration: InputDecoration(
                                  labelText: 'Stock mínimo *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Código de barras *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: TextButton(onPressed: () {}, child: const Text('Generar')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar cambios', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
