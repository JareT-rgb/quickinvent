import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import '../models/sale_detail_item.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';
import '../utils/receipt_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';

class SaleCompletionScreen extends ConsumerWidget {
  final double totalAmount;
  final String paymentMethod;
  final double receivedAmount;
  final double change;
  final List<CartItem> cartItems;
  final int? saleId;

  const SaleCompletionScreen({
    super.key,
    required this.totalAmount,
    required this.paymentMethod,
    required this.receivedAmount,
    required this.change,
    required this.cartItems,
    this.saleId,
  });

  Future<void> _printReceipt(BuildContext context, AppSettings settings) async {
    try {
      final items = cartItems
          .map(
            (i) => SaleDetailItem(
              productName: i.product.name,
              quantity: i.quantity,
              priceAtSale: i.product.price,
              subtotal: i.subtotal,
            ),
          )
          .toList();
      final pdfBytes = await generateReceiptPdf(
        saleId: saleId ?? DateTime.now().millisecondsSinceEpoch,
        saleItems: items,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        settings: settings,
      );
      await Printing.layoutPdf(onLayout: (format) => pdfBytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al imprimir: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final primaryColor = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120,
                    child: Lottie.network(
                      'https://assets9.lottiefiles.com/packages/lf20_yupep8il.json', // Premium Check Animation
                      repeat: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Venta completada!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Ticket: #${saleId ?? DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildTicketRow(
                    'TOTAL',
                    '\$${totalAmount.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  _buildTicketRow(
                    'Pago ($paymentMethod)',
                    '\$${receivedAmount.toStringAsFixed(2)}',
                  ),
                  _buildTicketRow(
                    'Cambio',
                    '\$${change.toStringAsFixed(2)}',
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Gracias por su compra!',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _printReceipt(context, settings),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Imprimir'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Nueva venta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
