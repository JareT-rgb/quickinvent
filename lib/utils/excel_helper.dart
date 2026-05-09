import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import '../models/product.dart';
import '../models/sale.dart';

class ExcelHelper {
  static Future<bool> exportProducts(List<Product> products) async {
    try {
      final excel = Excel.createExcel();
      final String sheetName = 'Inventario';
      excel.rename(excel.getDefaultSheet()!, sheetName);
      final sheet = excel[sheetName];

      // Define Styles
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('#2E7D32'), 
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers
      List<String> headers = [
        'ID',
        'Nombre del Producto',
        'Precio Venta',
        'Costo',
        'Margen %',
        'Stock Actual',
        'Stock Minimo',
        'Codigo de Barras',
        'Categoria ID',
        'Estado'
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data
      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        final rowIndex = i + 1;
        
        final margin = p.price > 0 ? ((p.price - p.costPrice) / p.price * 100) : 0.0;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(p.id);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(p.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = DoubleCellValue(p.price);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(p.costPrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue('${margin.toStringAsFixed(1)}%');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = IntCellValue(p.stockQuantity);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = IntCellValue(p.minStock);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(p.barcode ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = TextCellValue(p.categoryId ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex)).value = TextCellValue(p.isActive ? 'Activo' : 'Inactivo');
      }

      // Set Column Widths (Manual)
      sheet.setColumnWidth(1, 30); // Name
      sheet.setColumnWidth(7, 20); // Barcode

      final bytes = excel.save();
      if (bytes != null) {
        await FileSaver.instance.saveFile(
          name: 'Inventario_QuickInvent_${DateTime.now().millisecondsSinceEpoch}.xlsx',
          bytes: Uint8List.fromList(bytes),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error exporting products: $e');
      return false;
    }
  }

  static Future<void> exportSales(List<Sale> sales) async {
    final excel = Excel.createExcel();
    const String sheetName = 'Ventas';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    CellStyle headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    List<String> headers = [
      'ID Venta',
      'Fecha',
      'Hora',
      'Método de Pago',
      'Total',
      'Items',
      'Notas'
    ];

    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var i = 0; i < sales.length; i++) {
      final s = sales[i];
      final rowIndex = i + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('S${s.id}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue('${s.createdAt.hour}:${s.createdAt.minute}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(s.paymentMethod);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(s.totalAmount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = IntCellValue(s.itemCount ?? s.items?.length ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(s.notes ?? '');
    }

    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(3, 15);

    final bytes = excel.save();
    if (bytes != null) {
      await FileSaver.instance.saveFile(
        name: 'Ventas_QuickInvent_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: Uint8List.fromList(bytes),
      );
    }
  }

  static List<Map<String, dynamic>> parseExcelToProductMaps(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> results = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      if (sheet.maxRows < 2) continue;

      List<String> headers = [];
      for (var cell in sheet.rows[0]) {
        headers.add(cell?.value?.toString() ?? '');
      }

      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        Map<String, dynamic> map = {};
        bool hasData = false;

        for (int j = 0; j < headers.length; j++) {
          if (j < row.length) {
            String key = _mapHeaderToKey(headers[j]);
            var value = row[j]?.value;
            
            if (value != null) {
              hasData = true;
              // Normalize data
              if (key == 'price' || key == 'cost_price' || key == 'stock_quantity' || key == 'min_stock') {
                map[key] = num.tryParse(value.toString()) ?? 0;
              } else if (key == 'is_active') {
                String v = value.toString().toLowerCase();
                map[key] = v == 'si' || v == 'yes' || v == '1' || v == 'activo' || v == 'true';
              } else {
                map[key] = value.toString();
              }
            }
          }
        }
        if (hasData) results.add(map);
      }
    }
    return results;
  }

  static String _mapHeaderToKey(String header) {
    header = header.toLowerCase().trim();
    if (header.contains('nombre')) return 'name';
    if (header.contains('precio')) return 'price';
    if (header.contains('costo')) return 'cost_price';
    if (header.contains('stock actual') || header.contains('cantidad')) return 'stock_quantity';
    if (header.contains('stock m')) return 'min_stock';
    if (header.contains('barras') || header.contains('barcode')) return 'barcode';
    if (header.contains('categor')) return 'category_id';
    if (header.contains('activo') || header.contains('estado')) return 'is_active';
    if (header.contains('url') || header.contains('imagen')) return 'image_url';
    return header;
  }
}
