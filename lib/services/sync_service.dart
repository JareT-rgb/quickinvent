import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'; // Para Value y Constant
import '../database/local_db.dart';
import '../repositories/sales_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final syncServiceProvider = Provider((ref) => SyncService(ref));

class SyncService {
  final Ref _ref;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService(this._ref);

  void start() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => syncPendingSales());
    // Inicialización suave
    Future.delayed(const Duration(seconds: 5), () => syncPendingSales());
  }

  void stop() {
    _syncTimer?.cancel();
  }

  Future<void> syncPendingSales() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = _ref.read(localDbProvider);
      
      // 1. Buscar ventas no sincronizadas
      final unsyncedSales = await (db.select(db.localSales)..where((t) => t.isSynced.equals(false))).get();
      
      if (unsyncedSales.isEmpty) {
        _isSyncing = false;
        return;
      }

      print('🔄 Sincronizando ${unsyncedSales.length} ventas pendientes...');

      for (final sale in unsyncedSales) {
        try {
          // Obtener items de esta venta
          final items = await (db.select(db.localSaleItems)..where((t) => t.localSaleId.equals(sale.id))).get();
          
          final saleItems = items.map((i) => {
            'product_id': i.productId,
            'product_name': i.productName,
            'quantity': i.quantity,
            'price_at_sale': i.priceAtSale,
            'cost_price_at_sale': i.costPriceAtSale,
            'subtotal': i.subtotal,
          }).toList();

          // 1. Subir encabezado
          final saleResponse = await Supabase.instance.client.from('sales').insert({
            'total_amount': sale.totalAmount,
            'payment_method': sale.paymentMethod,
            'created_at': sale.createdAt.toIso8601String(),
          }).select().single();

          final remoteSaleId = saleResponse['id'];

          // 2. Subir detalle
          if (saleItems.isNotEmpty) {
            final itemsToInsert = saleItems.map((item) => {
              'sale_id': remoteSaleId,
              'product_id': item['product_id'],
              'product_name': item['product_name'],
              'quantity': item['quantity'],
              'price_at_sale': item['price_at_sale'],
              'cost_price_at_sale': item['cost_price_at_sale'],
              'subtotal': item['subtotal'],
            }).toList();

            await Supabase.instance.client.from('sale_items').insert(itemsToInsert);
          }

          // 3. Marcar como sincronizado localmente
          await (db.update(db.localSales)..where((t) => t.id.equals(sale.id))).write(
            LocalSalesCompanion(
              isSynced: const Value(true),
              remoteId: Value(remoteSaleId.toString()),
            )
          );
        } catch (e) {
          print('❌ Error en venta #${sale.id}: $e');
        }
      }
    } catch (e) {
      print('❌ Error sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Stream<int> get pendingSyncCountStream {
    final db = _ref.read(localDbProvider);
    return (db.select(db.localSales)..where((t) => t.isSynced.equals(false)))
        .watch()
        .map((list) => list.length);
  }
}

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncServiceProvider).pendingSyncCountStream;
});
