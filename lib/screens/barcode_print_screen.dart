import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:animate_do/animate_do.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class BarcodePrintScreen extends StatelessWidget {
  final List<Product> products;

  const BarcodePrintScreen({super.key, required this.products});

  Future<void> _printLabels() async {
    final doc = pw.Document();
    final productsWithBarcode = products.where((p) => p.barcode != null && p.barcode!.isNotEmpty).toList();

    // Dimensiones en puntos (1cm = 28.346 points)
    const double labelWidth = 6.0 * 28.346;
    const double labelHeight = 2.0 * 28.346;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return [
            pw.Wrap(
              spacing: 5,
              runSpacing: 5,
              children: productsWithBarcode.map((p) {
                return pw.Container(
                  width: labelWidth,
                  height: labelHeight,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              p.name,
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                              maxLines: 2,
                              overflow: pw.TextOverflow.clip,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              '\$${p.price}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        flex: 3,
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.code128(),
                          data: p.barcode!,
                          drawText: true,
                          textStyle: const pw.TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final productsWithBarcode = products.where((p) => p.barcode != null && p.barcode!.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsualización de Etiquetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: productsWithBarcode.isEmpty ? null : _printLabels,
          ),
        ],
      ),
      body: productsWithBarcode.isEmpty
          ? const Center(
              child: Text('No hay productos con código de barras para imprimir.'),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Se imprimirán ${productsWithBarcode.length} etiquetas organizadas en cuadrícula.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _printLabels,
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimir Hoja'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 3 : 1),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 3.0, // 6:2 ratio
                    ),
                    itemCount: productsWithBarcode.length,
                    itemBuilder: (context, index) {
                      final p = productsWithBarcode[index];
                      return ZoomIn(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  color: AppTheme.primary.withOpacity(0.7),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '\$${p.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              BarcodeWidget(
                                                barcode: Barcode.code128(),
                                                data: p.barcode!,
                                                height: 45,
                                                drawText: true,
                                                style: const TextStyle(fontSize: 9),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
