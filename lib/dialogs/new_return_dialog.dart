import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/products_repository.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_theme.dart';

class NewReturnDialog extends ConsumerStatefulWidget {
  const NewReturnDialog({super.key});

  @override
  ConsumerState<NewReturnDialog> createState() => _NewReturnDialogState();
}

class _NewReturnDialogState extends ConsumerState<NewReturnDialog> {
  Product? _selectedProduct;
  final TextEditingController _qtyController =
      TextEditingController(text: '1');
  String _selectedReason = 'Producto dañado';
  final TextEditingController _otherReasonController = TextEditingController();
  bool _isLoading = false;

  final List<String> _reasonOptions = [
    'Producto dañado',
    'Producto vencido',
    'Cambio de producto',
    'Error de cobro',
    'Otro',
  ];

  @override
  void dispose() {
    _qtyController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _processReturn() async {
    if (_selectedProduct == null) {
      _showSnack('Selecciona un producto', color: AppTheme.error);
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      _showSnack('La cantidad debe ser mayor a 0', color: AppTheme.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final newStock = _selectedProduct!.stockQuantity + qty;
      await repo.updateProduct(
        productId: _selectedProduct!.id,
        name: _selectedProduct!.name,
        price: _selectedProduct!.price,
        stockQuantity: newStock,
        minStock: _selectedProduct!.minStock,
        isActive: _selectedProduct!.isActive,
        barcode: _selectedProduct!.barcode,
        categoryId: _selectedProduct!.categoryId,
      );
      ref.invalidate(productsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Devolución procesada correctamente',
          color: AppTheme.success);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', color: AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final activeProducts = products.where((p) => p.isActive).toList();

        return AppDialog(
          headerIcon: Icons.keyboard_return_rounded,
          headerColor: AppTheme.warning,
          title: 'Nueva Devolución',
          subtitle: 'Restaurar stock por devolución de producto',
          maxWidth: 480,
          canClose: !_isLoading,
          footer: AppDialogFooterButtons(
            actionLabel: 'Procesar Devolución',
            actionIcon: Icons.check_circle_outline,
            actionColor: AppTheme.warning,
            isLoading: _isLoading,
            isEnabled: _selectedProduct != null,
            onAction: _processReturn,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product selector
                const AppDialogSectionTitle(
                  title: 'Producto a devolver',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Product>(
                  initialValue: _selectedProduct,
                  isExpanded: true,
                  decoration: appInputDecoration(context,
                      label: 'Seleccionar producto',
                      icon: Icons.search_outlined),
                  items: activeProducts
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                                '${p.name} — ${currencyFormat.format(p.price)}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProduct = v),
                ),

                // Stock info chip
                if (_selectedProduct != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory,
                            size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Stock actual: ${_selectedProduct!.stockQuantity} unidades',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const AppDialogSectionTitle(
                  title: 'Cantidad a devolver',
                  icon: Icons.format_list_numbered,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: appInputDecoration(context,
                      label: 'Cantidad', icon: Icons.numbers, hint: '1'),
                ),

                const SizedBox(height: 20),
                const AppDialogSectionTitle(
                  title: 'Motivo de la devolución',
                  icon: Icons.help_outline,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  isExpanded: true,
                  decoration: appInputDecoration(context,
                      label: 'Motivo', icon: Icons.article_outlined),
                  items: _reasonOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedReason = v ?? 'Otro'),
                ),
                if (_selectedReason == 'Otro') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherReasonController,
                    maxLines: 2,
                    decoration: appInputDecoration(context,
                        label: 'Especifica el motivo',
                        icon: Icons.edit_note_outlined,
                        hint: 'Describe el motivo de la devolución...'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
