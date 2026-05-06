import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'products_provider.dart';
import 'products_repository.dart';
import 'product.dart';

class NewReturnDialog extends ConsumerStatefulWidget {
  const NewReturnDialog({super.key});

  @override
  ConsumerState<NewReturnDialog> createState() => _NewReturnDialogState();
}

class _NewReturnDialogState extends ConsumerState<NewReturnDialog> {
  Product? selectedProduct;
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = 'Producto dañado';
  bool _isLoading = false;

  final List<String> _reasonOptions = [
    'Producto dañado',
    'Producto vencido',
    'Cambio de producto',
    'Error de cobro',
    'Otro',
  ];

  Future<void> _processReturn() async {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Incrementar stock del producto
      final repo = ref.read(productsRepositoryProvider);
      final newStock = selectedProduct!.stockQuantity + qty;
      await repo.updateProduct(
        productId: selectedProduct!.id,
        name: selectedProduct!.name,
        price: selectedProduct!.price,
        stockQuantity: newStock,
        minStock: selectedProduct!.minStock,
        isActive: selectedProduct!.isActive,
        barcode: selectedProduct!.barcode,
        categoryId: selectedProduct!.categoryId,
      );
      ref.invalidate(productsProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devolución procesada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar devolución: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nueva Devolución', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Seleccionar Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Product>(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: products.where((p) => p.isActive).map((p) => DropdownMenuItem(
                value: p,
                child: Text('${p.name} (${currencyFormat.format(p.price)})'),
              )).toList(),
              onChanged: (val) => setState(() => selectedProduct = val),
            ),
            const SizedBox(height: 16),
            const Text('Cantidad a devolver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Motivo de la devolución', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedReason,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: _reasonOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedReason = val ?? 'Otro'),
            ),
            const SizedBox(height: 16),
            if (_selectedReason == 'Otro')
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Especifica el motivo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _processReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Procesar Devolución', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
