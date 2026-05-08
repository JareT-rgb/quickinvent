import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/product.dart';
import '../theme/app_theme.dart';

class BarcodePrintScreen extends StatelessWidget {
  final List<Product> products;

  const BarcodePrintScreen({super.key, required this.products});

  Future<void> _printLabels() async {
    final doc = pw.Document();
    
    final productsWithBarcode = products.where((p) => p.barcode != null && p.barcode!.isNotEmpty).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Etiquetas de Inventario - QuickInvent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ),
            pw.SizedBox(height: 20),
            pw.GridView(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              children: productsWithBarcode.map((p) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(p.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                      pw.SizedBox(height: 5),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: p.barcode!,
                        width: 100,
                        height: 40,
                        drawText: true,
                        textStyle: pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('\$ ${p.price}', style: const pw.TextStyle(fontSize: 9)),
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
                  color: AppTheme.primary.withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: productsWithBarcode.length,
                    itemBuilder: (context, index) {
                      final p = productsWithBarcode[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              BarcodeWidget(
                                barcode: Barcode.code128(),
                                data: p.barcode!,
                                width: double.infinity,
                                height: 40,
                                drawText: true,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text('\$${p.price}', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ],
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
