import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/products_repository.dart';
import '../providers/products_provider.dart';
import '../utils/common_abarrotes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';

class QuickImportDialog extends ConsumerStatefulWidget {
  const QuickImportDialog({super.key});

  @override
  ConsumerState<QuickImportDialog> createState() => _QuickImportDialogState();
}

class _QuickImportDialogState extends ConsumerState<QuickImportDialog> {
  final List<Map<String, dynamic>> _catalog = CommonAbarrotes.catalog;
  final Set<int> _selectedIndices = {};
  bool _isImporting = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    // Por defecto seleccionamos todos
    for (int i = 0; i < _catalog.length; i++) {
      _selectedIndices.add(i);
    }
  }

  Future<void> _runImport() async {
    if (_selectedIndices.isEmpty) return;

    setState(() {
      _isImporting = true;
      _progress = 0;
    });

    final itemsToImport = _selectedIndices.map((i) => _catalog[i]).toList();
    
    try {
      // Importamos uno por uno para poder mostrar progreso visual
      final repo = ref.read(productsRepositoryProvider);
      
      for (int i = 0; i < itemsToImport.length; i++) {
        await repo.importCommonProducts([itemsToImport[i]]);
        setState(() {
          _progress = (i + 1) / itemsToImport.length;
        });
      }

      ref.invalidate(productsProvider);
      ref.invalidate(categoriesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se importaron ${itemsToImport.length} productos correctamente'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Asistente de Carga Rápida',
      subtitle: 'Selecciona los productos básicos que deseas añadir',
      headerIcon: Icons.auto_awesome_motion_rounded,
      headerColor: Colors.amber,
      canClose: !_isImporting,
      maxWidth: 500,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isImporting ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: (_isImporting || _selectedIndices.isEmpty) ? null : _runImport,
            icon: _isImporting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_download_outlined, size: 20),
            label: Text(_isImporting ? 'Importando...' : 'Importar Selección (${_selectedIndices.length})'),
          ),
        ],
      ),
      body: SizedBox(
        height: 400,
        child: Column(
          children: [
            if (_isImporting)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: _progress, borderRadius: BorderRadius.circular(10)),
                    const SizedBox(height: 8),
                    Text('${(_progress * 100).toInt()}% completado', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _catalog.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _catalog[index];
                  final isSelected = _selectedIndices.contains(index);

                  return CheckboxListTile(
                    value: isSelected,
                    enabled: !_isImporting,
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${item['category']} • \$${item['price']}', style: const TextStyle(fontSize: 12)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
