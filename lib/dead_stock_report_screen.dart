import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'sales_repository.dart';

class DeadStockReport extends ConsumerWidget {
  final List<String> productNames;

  const DeadStockReport({super.key, required this.productNames});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadStockAsync = ref.watch(deadStockProvider(productNames));

    return deadStockAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, s) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error: $e'),
        ),
      ),
      data: (deadStock) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                    SizedBox(width: 8),
                    Text('Productos muertos (sin venta en +30 días)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                if (deadStock.isEmpty)
                  const Text('No hay productos muertos', style: TextStyle(color: AppTheme.textSecondary)),
                if (deadStock.isNotEmpty)
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        children: ['PRODUCTO', 'CATEGORIA', 'DIAS SIN VENTA'].map((h) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                        )).toList(),
                      ),
                      ...deadStock.map((item) => _buildDeadRow(item['name'] as String, 'Sin categoría', '${item['days']}d')),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildDeadRow(String name, String cat, String days) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(name, style: const TextStyle(fontSize: 13))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(cat, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(days, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
