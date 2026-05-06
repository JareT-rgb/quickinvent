import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'new_return_dialog.dart';
import 'product_return.dart';
import 'products_repository.dart';

// Provider para obtener el historial de devoluciones
final returnsHistoryProvider = FutureProvider<List<ProductReturn>>((ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.fetchReturns();
});

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(returnsHistoryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$'); 

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Devoluciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Devolución',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const NewReturnDialog(),
                barrierDismissible: false,
              );
            },
          ),
        ],
      ),
      body: returnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar devoluciones: $err')),
        data: (returns) {
          if (returns.isEmpty) {
            return const Center(child: Text('No hay devoluciones registradas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              final item = returns[index];
              final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(item.createdAt.toLocal());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.quantity} x ${item.productName}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      if (item.reason != null && item.reason!.isNotEmpty) Text('Motivo: ${item.reason}'),
                      const Divider(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Reembolsado: ${currencyFormat.format(item.amountReturned)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}