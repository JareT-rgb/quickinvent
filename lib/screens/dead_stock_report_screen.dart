import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reports_provider.dart';
import '../providers/categories_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class DeadStockReport extends ConsumerWidget {
  final List<Product> products;

  const DeadStockReport({super.key, required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadStockAsync = ref.watch(deadStockProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

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
        final categories = categoriesAsync.value ?? [];
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
                    Expanded(
                      child: Text('Productos muertos (sin venta en +30 días)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
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
                      ...deadStock.map((item) {
                        final name = item['name'] as String;
                        final days = '${item['days']}d';
                        
                        String catName = 'Sin categoría';
                        try {
                          final product = products.firstWhere((p) => p.name == name);
                          if (product.categoryId != null) {
                            final cat = categories.firstWhere((c) => c.id.toString() == product.categoryId.toString());
                            catName = cat.name;
                          }
                        } catch (_) {}

                        return _buildDeadRow(name, catName, days);
                      }),
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
