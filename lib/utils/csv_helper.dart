import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import '../models/product.dart';

class CSVHelper {
  /// Parses CSV string into a list of Product-ready maps.
  static List<Map<String, dynamic>> csvToProductMaps(String csvData) {
    // Detect delimiter: common are ',' and ';'
    List<String> lines = csvData.split(RegExp(r'\r?\n'));
    if (lines.isEmpty || lines[0].isEmpty) return [];
    
    String firstLine = lines[0];
    String delimiter = ',';
    if (firstLine.contains(';')) {
      // If there are more semicolons than commas, use semicolon
      int commas = firstLine.split(',').length;
      int semicolons = firstLine.split(';').length;
      if (semicolons > commas) delimiter = ';';
    }

    List<String> header = _splitCSVLine(lines[0], delimiter);
    List<Map<String, dynamic>> results = [];
    
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;
      
      List<String> values = _splitCSVLine(line, delimiter);
      if (values.length < 2) continue; // Minimum: Name and Price
      
      Map<String, dynamic> map = {};
      for (int j = 0; j < header.length; j++) {
        if (j < values.length) {
          String key = _mapHeaderToKey(header[j]);
          String valStr = values[j].trim();
          dynamic value = valStr;
          
          if (key == 'price' || key == 'stock_quantity' || key == 'min_stock' || key == 'cost_price') {
            // Clean currency symbols and extra spaces
            String cleanVal = valStr.replaceAll(RegExp(r'[^\d\.]'), '');
            value = num.tryParse(cleanVal) ?? 0;
          } else if (key == 'is_active') {
            String v = valStr.toLowerCase();
            value = v == 'sí' || v == 'si' || v == 'yes' || v == '1' || v == 'true' || v == 'activo';
          }
          map[key] = value;
        }
      }
      results.add(map);
    }
    return results;
  }

  /// Helper to split CSV lines respecting quotes
  static List<String> _splitCSVLine(String line, String delimiter) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer buffer = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result.map((e) => e.replaceAll('"', '').trim()).toList();
  }

  static Future<void> saveCSV(String fileName, String csvContent) async {
    // Add UTF-8 BOM so Excel opens it correctly with accents
    final List<int> bytes = [0xEF, 0xBB, 0xBF] + utf8.encode(csvContent);
    await FileSaver.instance.saveFile(
      name: '$fileName.csv',
      bytes: Uint8List.fromList(bytes),
    );
  }

  static String generateTemplate() {
    return 'Nombre,Precio Venta,Costo,Stock Actual,Stock Minimo,Codigo de Barras,Categoria ID,Activo (Si/No),Imagen URL\n'
           'Arroz Extra 1kg,25.50,18.00,50,10,750100012345,9,Si,\n'
           'Pepsi 600ml,16.00,11.50,24,6,750100054321,3,Si,';
  }

  static String productsToCSV(List<Product> products) {
    List<String> lines = [];
    // Header without accents for better compatibility if needed, though BOM fixes it
    lines.add('ID,Nombre,Precio Venta,Costo,Stock Actual,Stock Minimo,Codigo de Barras,Categoria ID,Activo,Imagen URL');
    
    for (var p in products) {
      lines.add('${p.id},"${p.name}",${p.price},${p.costPrice},${p.stockQuantity},${p.minStock},${p.barcode ?? ''},${p.categoryId ?? ''},${p.isActive ? 'Si' : 'No'},${p.imageUrl ?? ''}');
    }
    return lines.join('\n');
  }

  static String _mapHeaderToKey(String header) {
    header = header.toLowerCase().trim();
    if (header.contains('nombre')) return 'name';
    if (header.contains('precio')) return 'price';
    if (header.contains('stock actual') || header.contains('cantidad')) return 'stock_quantity';
    if (header.contains('stock m')) return 'min_stock';
    if (header.contains('barras') || header.contains('barcode')) return 'barcode';
    if (header.contains('categor')) return 'category_id';
    if (header.contains('activo')) return 'is_active';
    if (header.contains('costo')) return 'cost_price';
    if (header.contains('url') || header.contains('imagen')) return 'image_url';
    return header;
  }
}
