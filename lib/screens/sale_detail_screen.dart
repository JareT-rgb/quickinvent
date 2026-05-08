import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/sale.dart';
import '../models/sale_detail_item.dart';
import '../widgets/receipt_generator.dart';

class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({required this.sale, super.key});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final items = sale.items ?? <SaleDetailItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Venta #${sale.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Recibo',
            onPressed: () async {
              try {
                final pdfBytes = await generateReceiptPdf(
                  saleId: int.tryParse(sale.id) ?? 0,
                  saleItems: items,
                  totalAmount: sale.totalAmount,
                  paymentMethod: sale.paymentMethod,
                );
                await Printing.layoutPdf(onLayout: (format) => pdfBytes);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al imprimir: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Venta completada!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ticket: ${sale.id}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QUICKINVENT ABARROTES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy, hh:mm a',
                      ).format(sale.createdAt.toLocal()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 40),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} x${item.quantity}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currencyFormat.format(item.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 40),
                    _buildTotalRow(
                      'TOTAL',
                      currencyFormat.format(sale.totalAmount),
                      isBold: true,
                    ),
                    _buildTotalRow(
                      'Pago (${sale.paymentMethod})',
                      currencyFormat.format(sale.receivedAmount),
                    ),
                    _buildTotalRow(
                      'Cambio',
                      currencyFormat.format(sale.change),
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      '¡Gracias por su compra!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(
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
