import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' show FilePicker, FilePickerResult, FileType;
import '../utils/csv_helper.dart';
import '../utils/excel_helper.dart';
import '../providers/products_provider.dart';
import '../repositories/products_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';

class BulkImportDialog extends ConsumerStatefulWidget {
  const BulkImportDialog({super.key});

  @override
  ConsumerState<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends ConsumerState<BulkImportDialog> {
  List<Map<String, dynamic>>? _previewData;
  bool _isImporting = false;
  String? _error;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        List<Map<String, dynamic>> data;

        if (file.name.toLowerCase().endsWith('.xlsx')) {
          data = ExcelHelper.parseExcelToProductMaps(file.bytes!);
        } else {
          String content;
          try {
            content = utf8.decode(file.bytes!);
          } catch (_) {
            // Fallback for files saved with non-UTF8 encoding (like standard Windows Excel CSV)
            content = latin1.decode(file.bytes!);
          }
          data = CSVHelper.csvToProductMaps(content);
        }

        setState(() {
          _previewData = data;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Error al leer el archivo: $e');
    }
  }

  Future<void> _import() async {
    if (_previewData == null || _previewData!.isEmpty) return;

    setState(() {
      _isImporting = true;
      _error = null;
    });

    try {
      final repo = ref.read(productsRepositoryProvider);
      await repo.bulkInsertProducts(_previewData!);

      ref.invalidate(productsProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importación completada: ${_previewData!.length} productos agregados'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error al guardar: ${e.toString().contains('Permission denied') ? 'Error de permisos (Inicia sesión)' : e}';
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Importación Masiva (CSV)',
      subtitle: 'Sube un archivo .csv con tus productos',
      headerIcon: Icons.upload_file_rounded,
      maxWidth: 600,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: AppTheme.radiusSmall,
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
              ),
            if (_previewData == null)
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: AppTheme.radiusMedium,
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Instrucciones:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        SizedBox(height: 8),
                        Text('• Usa la plantilla para asegurar el formato correcto.'),
                        Text('• Puedes subir archivos .csv o .xlsx (Excel).'),
                        Text('• Las columnas de Nombre y Precio son obligatorias.'),
                        Text('• Para Activo usa "Si" o "No".'),
                      ],
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.file_open),
                            label: const Text('Seleccionar archivo CSV'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => CSVHelper.saveCSV('plantilla_quickinvent', CSVHelper.generateTemplate()),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Descargar Plantilla de Ejemplo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              Container(
                height: 300,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: ListView.separated(
                  itemCount: _previewData!.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _previewData![index];
                    return ListTile(
                      dense: true,
                      title: Text(item['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Precio: \$${item['price']} | Stock: ${item['stock_quantity']}'),
                      trailing: item['barcode'] != null ? Text(item['barcode'].toString()) : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('${_previewData!.length} productos detectados', style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isImporting ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          if (_previewData != null)
            FilledButton(
              onPressed: _isImporting ? null : _import,
              child: _isImporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Comenzar Importación'),
            ),
        ],
      ),
    );
  }
}
