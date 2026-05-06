import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_item.dart';
import 'sale_detail_item.dart';
import 'sales_repository.dart';
import 'cart_notifier.dart';

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

  double get change {
    if (_amountController.text.isEmpty) return 0.0;
    final received = double.tryParse(_amountController.text) ?? 0.0;
    return received - widget.totalAmount;
  }

  Future<void> _processPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el monto recibido'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amountReceived = double.tryParse(_amountController.text);
    if (amountReceived == null || amountReceived < widget.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monto insuficiente'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final items = widget.cartItems.map((item) {
        return SaleDetailItem(
          productName: item.product.name,
          quantity: item.quantity,
          priceAtSale: item.product.price,
          subtotal: item.subtotal,
        );
      }).toList();

      await ref
          .read(salesRepositoryProvider)
          .createSale(
            totalAmount: widget.totalAmount,
            paymentMethod: _paymentMethod,
            receivedAmount: amountReceived,
            change: change,
            items: items,
          );

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el pago: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Procesar Pago'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del pedido:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...widget.cartItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.product.name}'),
                          Text('\$${item.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${widget.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2196F3),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: [
                'Efectivo',
                'Tarjeta',
                'Transferencia',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) =>
                  setState(() => _paymentMethod = val ?? 'Efectivo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto recibido',
                prefixIcon: Icon(Icons.money),
                hintText: '0.00',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_amountController.text.isNotEmpty && change >= 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cambio:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '\$${change.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            child: _isProcessing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Procesar Pago'),
          ),
        ),
      ],
    );
  }
}
