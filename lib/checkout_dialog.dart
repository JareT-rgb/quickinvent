import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_item.dart';
import 'cart_notifier.dart';
import 'products_provider.dart';
import 'products_repository.dart';
import 'app_theme.dart';
import 'sale_detail_item.dart';
import 'sales_repository.dart';
import 'sale_completion_screen.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutDialog({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  String selectedMethod = 'Efectivo';
  final TextEditingController _amountReceivedController = TextEditingController();
  double change = 0.0;

  @override
  void initState() {
    super.initState();
    _amountReceivedController.addListener(_calculateChange);
  }

  void _calculateChange() {
    final received = double.tryParse(_amountReceivedController.text) ?? 0.0;
    setState(() {
      if (received >= widget.totalAmount) {
        change = received - widget.totalAmount;
      } else {
        change = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    final received = double.tryParse(_amountReceivedController.text) ?? 0.0;
    if (received < widget.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto recibido es insuficiente')),
      );
      return;
    }

    // Descontar stock de cada producto
    final repo = ref.read(productsRepositoryProvider);
    for (final item in widget.cartItems) {
      final product = item.product;
      final newStock = product.stockQuantity - item.quantity;
      await repo.updateProduct(
        productId: product.id,
        name: product.name,
        price: product.price,
        stockQuantity: newStock < 0 ? 0 : newStock,
        minStock: product.minStock,
        isActive: newStock <= 0 ? false : product.isActive,
        barcode: product.barcode,
        categoryId: product.categoryId,
      );
    }
    ref.invalidate(productsProvider);

    // Guardar venta
    final sale = await ref.read(salesRepositoryProvider).createSale(
      totalAmount: widget.totalAmount,
      paymentMethod: selectedMethod,
      receivedAmount: received,
      change: change,
      items: widget.cartItems
          .map((i) => SaleDetailItem(
                productName: i.product.name,
                quantity: i.quantity,
                priceAtSale: i.product.price,
              ))
          .toList(),
    );

    if (!mounted) return;

    // Limpiar carrito
    ref.read(cartProvider.notifier).clearCart();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SaleCompletionScreen(
          totalAmount: widget.totalAmount,
          paymentMethod: selectedMethod,
          receivedAmount: received,
          change: change,
        ),
        // Nota: En un entorno real, pasaríamos los items y el saleId al constructor
        // si el widget SaleCompletionScreen lo requiere.
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cobrar venta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Text('Total a cobrar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text(
                    '\$${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentMethodButton(
                  label: 'Efectivo',
                  icon: Icons.payments_outlined,
                  isSelected: selectedMethod == 'Efectivo',
                  onTap: () => setState(() => selectedMethod = 'Efectivo'),
                ),
                const SizedBox(width: 8),
                _PaymentMethodButton(
                  label: 'Tarjeta',
                  icon: Icons.credit_card_outlined,
                  isSelected: selectedMethod == 'Tarjeta',
                  onTap: () => setState(() => selectedMethod = 'Tarjeta'),
                ),
                const SizedBox(width: 8),
                _PaymentMethodButton(
                  label: 'Transferencia',
                  icon: Icons.account_balance_outlined,
                  isSelected: selectedMethod == 'Transferencia',
                  onTap: () => setState(() => selectedMethod = 'Transferencia'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Monto recibido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountReceivedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                errorText: (double.tryParse(_amountReceivedController.text) ?? 0.0) < widget.totalAmount && _amountReceivedController.text.isNotEmpty ? 'Monto insuficiente' : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAmountChip(
                  amount: widget.totalAmount,
                  onTap: (val) => _amountReceivedController.text = val.toStringAsFixed(0),
                ),
                const SizedBox(width: 8),
                _QuickAmountChip(
                  amount: (widget.totalAmount / 10).ceil() * 10.0,
                  onTap: (val) => _amountReceivedController.text = val.toStringAsFixed(0),
                ),
                const SizedBox(width: 8),
                _QuickAmountChip(
                  amount: (widget.totalAmount / 50).ceil() * 50.0,
                  onTap: (val) => _amountReceivedController.text = val.toStringAsFixed(0),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cambio:', style: TextStyle(fontSize: 20)),
                Text(
                  '\$${change.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirmar pago'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? AppTheme.primary : Colors.grey, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final double amount;
  final Function(double) onTap;

  const _QuickAmountChip({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('\$${amount.toStringAsFixed(0)}'),
      onPressed: () => onTap(amount),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
