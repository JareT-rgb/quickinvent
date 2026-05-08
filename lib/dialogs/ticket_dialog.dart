import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/sale.dart';
import '../models/sale_detail_item.dart';
import '../repositories/sales_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TicketDialog extends ConsumerStatefulWidget {
  final Sale? sale;
  final String title;

  const TicketDialog({
    super.key,
    this.sale,
    this.title = 'Ticket de Compra',
  });

  @override
  ConsumerState<TicketDialog> createState() => _TicketDialogState();
}

class _TicketDialogState extends ConsumerState<TicketDialog> {
  Sale? _sale;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
    // If the sale has no items, fetch the full version from Supabase
    if (widget.sale != null &&
        (widget.sale!.items == null || widget.sale!.items!.isEmpty)) {
      _fetchFullSale();
    }
  }

  Future<void> _fetchFullSale() async {
    setState(() => _isLoading = true);
    try {
      final id = int.tryParse(widget.sale!.id);
      if (id == null) return;
      final full =
          await ref.read(salesRepositoryProvider).getSaleById(id);
      if (mounted && full != null) setState(() => _sale = full);
    } catch (_) {
      // Keep the original sale if fetch fails
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sale == null) {
      return const AlertDialog(content: Text('Venta no encontrada'));
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final items = _sale!.items ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Container(
        width: 320,
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'QUICKINVENT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ticket #${_sale!.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            Text(
              dateFormat.format(_sale!.createdAt),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.black, thickness: 1),
            const SizedBox(height: 8),

            // Items
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin artículos registrados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.black54,
                      fontSize: 12),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.quantity}x ',
                              style: const TextStyle(
                                  fontFamily: 'Courier',
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                    fontFamily: 'Courier',
                                    color: Colors.black),
                              ),
                            ),
                            Text(
                              currencyFormat.format(item.subtotal),
                              style: const TextStyle(
                                  fontFamily: 'Courier',
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            const Divider(color: Colors.black, thickness: 1),
            const SizedBox(height: 8),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL:',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black)),
                Text(currencyFormat.format(_sale!.totalAmount),
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pago con:',
                    style:
                        TextStyle(fontFamily: 'Courier', color: Colors.black)),
                Text(currencyFormat.format(_sale!.receivedAmount),
                    style: const TextStyle(
                        fontFamily: 'Courier', color: Colors.black)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cambio:',
                    style:
                        TextStyle(fontFamily: 'Courier', color: Colors.black)),
                Text(currencyFormat.format(_sale!.change),
                    style: const TextStyle(
                        fontFamily: 'Courier', color: Colors.black)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Método:',
                    style:
                        TextStyle(fontFamily: 'Courier', color: Colors.black)),
                Text(_sale!.paymentMethod,
                    style: const TextStyle(
                        fontFamily: 'Courier', color: Colors.black)),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Gracias por su compra!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.divider),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _printTicket(
                          _sale!, currencyFormat, dateFormat),
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
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


Future<void> _printTicket(Sale sale, NumberFormat currencyFmt, DateFormat dateFmt) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text('QUICKINVENT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ),
            pw.SizedBox(height: 5),
            pw.Center(child: pw.Text('Ticket #${sale.id}', style: const pw.TextStyle(fontSize: 10))),
            pw.Center(child: pw.Text(dateFmt.format(sale.createdAt), style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 5),
            
            // Items
            ... (sale.items ?? []).map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.Text('${item.quantity}x ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Expanded(child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 9))),
                  pw.Text(currencyFmt.format(item.subtotal), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            )),
            
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 5),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text(currencyFmt.format(sale.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pago con:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(currencyFmt.format(sale.receivedAmount), style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Cambio:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(currencyFmt.format(sale.change), style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Método:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(sale.paymentMethod, style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Center(child: pw.Text('¡Gracias por su compra!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.SizedBox(height: 5),
            pw.Center(child: pw.Text('www.quickinvent.com', style: const pw.TextStyle(fontSize: 8))),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'Ticket_${sale.id}.pdf',
  );
}
