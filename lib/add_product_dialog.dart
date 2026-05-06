import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'products_provider.dart';
import 'products_repository.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  String? _selectedCategory;
  bool isActive = true;
  String? _imagePath;

  void _generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _barcodeController.text = timestamp.substring(timestamp.length - 12);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref.read(productsRepositoryProvider).addProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        isActive: isActive,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text.trim(),
        categoryId: _selectedCategory,
      );

      ref.invalidate(productsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto añadido con éxito')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el producto: $e')),
        );
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
                const Text('Nuevo producto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                        ),
                        child: _imagePath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 44, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  const Text('Subir imagen', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch(
                          value: isActive,
                          onChanged: (v) => setState(() => isActive = v),
                          activeThumbColor: const Color(0xFF8BC34A),
                        ),
                        const Text('Producto activo (visible en POS)', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nombre *',
                          hint: 'Nombre del producto',
                          validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'Precio *',
                                hint: '0.00',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Campo requerido';
                                  if (double.tryParse(value) == null) return 'Número válido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: categoriesAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, s) => const Text('Error cargando categorías'),
                                data: (categories) {
                                  final options = categories.map((c) => c.name).toList();
                                  return _buildDropdown(
                                    label: 'Categoría *',
                                    options: options,
                                    value: _selectedCategory,
                                    onChanged: (val) => setState(() => _selectedCategory = val),
                                    validator: (value) => value == null ? 'Selecciona una categoría' : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _stockController,
                                label: 'Stock inicial *',
                                hint: '0',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Campo requerido';
                                  if (int.tryParse(value) == null) return 'Entero';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _minStockController,
                                label: 'Stock mínimo *',
                                hint: '0',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Campo requerido';
                                  if (int.tryParse(value) == null) return 'Entero';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildBarcodeField(controller: _barcodeController),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Agregar producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.all(12)),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> options,
    String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: value,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.all(12)),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildBarcodeField({required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Código de barras *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ej. 7501234567890',
            suffixIcon: TextButton(onPressed: _generateBarcode, child: const Text('Generar')),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
