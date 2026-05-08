import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_notifier.dart';
import '../providers/products_provider.dart';
import '../repositories/sales_repository.dart';
import '../models/sale_detail_item.dart';
import '../models/cart_item.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_theme.dart';
import 'ticket_dialog.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final VoidCallback onComplete;

  const CheckoutDialog({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.onComplete,
  });

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  String _paymentMethod = 'Efectivo';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _received => double.tryParse(_amountController.text) ?? 0.0;
  double get _change => _received - widget.totalAmount;
  bool get _hasEnough => _amountController.text.isNotEmpty && _received >= widget.totalAmount;

  Future<void> _processPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el monto recibido'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (!_hasEnough) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto insuficiente'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final items = widget.cartItems.map((item) => SaleDetailItem(
        productName: item.product.name,
        quantity: item.quantity,
        priceAtSale: item.product.price,
        subtotal: item.subtotal,
      )).toList();

      final sale = await ref.read(salesRepositoryProvider).createSale(
        totalAmount: widget.totalAmount,
        paymentMethod: _paymentMethod,
        receivedAmount: _received,
        change: _change,
        items: items,
      );

      // Clear cart and refresh products/stock
      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(productsProvider);

      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TicketDialog(sale: sale),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el pago: $e'), backgroundColor: Theme.of(context).colorScheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppDialog(
      headerIcon: Icons.point_of_sale_rounded,
      headerColor: AppTheme.primary,
      title: 'Procesar Pago',
      subtitle: 'Total: \$${widget.totalAmount.toStringAsFixed(2)}',
      canClose: !_isProcessing,
      maxWidth: 480,
      footer: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: (_isProcessing || !_hasEnough) ? null : _processPayment,
          icon: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: Text(
            _isProcessing ? 'Procesando...' : 'Procesar Pago',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen del pedido',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  ...widget.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                    '${item.quantity}x ${item.product.name}',
                                    overflow: TextOverflow.ellipsis)),
                            Text('\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                          '\$${widget.totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment method
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: appInputDecoration(context,
                  label: 'Método de pago',
                  icon: Icons.payment_rounded),
              items: ['Efectivo', 'Tarjeta', 'Transferencia']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _paymentMethod = val ?? 'Efectivo'),
            ),
            const SizedBox(height: 16),

            // Amount received
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.none,
              showCursor: true,
              readOnly: true,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: appInputDecoration(context,
                      label: 'Monto recibido',
                      icon: Icons.monetization_on_outlined,
                      hint: '0.00')
                  .copyWith(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Numeric keypad
            SizedBox(
              height: 220,
              child: NumericKeypad(
                controller: _amountController,
                onChange: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),

            // Change display
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _amountController.text.isNotEmpty
                  ? Container(
                      key: const ValueKey('change'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _hasEnough
                            ? Colors.green.withValues(alpha: 0.1)
                            : cs.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasEnough ? Colors.green : cs.error,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _hasEnough
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_rounded,
                                color: _hasEnough
                                    ? Colors.green[700]
                                    : cs.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hasEnough ? 'Cambio:' : 'Falta:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _hasEnough
                                      ? Colors.green[700]
                                      : cs.error,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${_change.abs().toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _hasEnough
                                  ? Colors.green[700]
                                  : cs.error,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }
}
