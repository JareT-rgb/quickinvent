import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'sale_detail_item.dart';

Future<Uint8List> generateReceiptPdf({
  required int saleId,
  required List<SaleDetailItem> saleItems,
  required double totalAmount,
  required String paymentMethod,
}) async {
  final pdf = pw.Document();
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  // Opcional: Cargar una fuente que soporte caracteres especiales si es necesario
  // final font = pw.Font.ttf(await rootBundle.load("assets/fonts/OpenSans-Regular.ttf"));

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80, // Formato para impresora térmica de 80mm
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabecera
            pw.Center(
              child: pw.Text('QuickInvent', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Recibo de Venta'),
            pw.Text('Folio: #$saleId'),
            pw.Text('Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Divider(),
            ),

            // Tabla de productos
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD6D6D6)),
              headers: ['Cant', 'Producto', 'Subtotal'],
              data: saleItems.map((item) {
                return [
                  item.quantity,
                  item.productName,
                  currencyFormat.format(item.subtotal),
                ];
              }).toList(),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Divider(),
            ),

            // Totales
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text(currencyFormat.format(totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Pagado con: $paymentMethod')]),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('¡Gracias por su compra!')),
          ],
        );
      },
    ),
  );

  return pdf.save();
}