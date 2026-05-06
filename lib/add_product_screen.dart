import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'category.dart';
import 'products_repository.dart';
import 'products_provider.dart';

/// Una pantalla dedicada para añadir un nuevo producto al inventario.
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  Category? _selectedCategory;
  bool _isActive = true;
  bool _isLoading = false;

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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(productsRepositoryProvider).addProduct(
            name: _nameController.text,
            price: double.parse(_priceController.text),
            stockQuantity: int.parse(_stockController.text),
            barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
            minStock: int.parse(_minStockController.text),
            isActive: _isActive,
            categoryId: _selectedCategory?.id.toString(), // Convertir int? a String?
          );

      ref.invalidate(productsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto añadido con éxito')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al añadir producto: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Marcador de posición para imagen (Página 6)
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Precio *', prefixText: '\$', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Categoría *', border: OutlineInputBorder()),
                      initialValue: _selectedCategory,
                      items: [
                        const DropdownMenuItem<Category?>(
                          value: null,
                          child: Text('Ninguna'),
                        ),
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
                    decoration: const InputDecoration(labelText: 'Stock inicial *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(labelText: 'Stock mínimo *', border: OutlineInputBorder()),
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
                border: const OutlineInputBorder(),
                suffixIcon: TextButton(onPressed: () {}, child: const Text('Generar')),
              ),
            ),
            const SizedBox(height: 16),
            // Switch de producto activo (Página 6)
            Row(
              children: [
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: const Color(0xFF8BC34A),
                ),
                const Text('Producto activo (visible en POS)'),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Agregar producto', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}