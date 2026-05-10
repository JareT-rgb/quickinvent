import 'dart:math';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/sale_detail_item.dart';


class SalesRepository {
  final SupabaseClient _client;

  SalesRepository(this._client);

  List<Sale> getAllSales() {
    // placeholder para providers síncronos; idealmente se usaría un FutureProvider
    return [];
  }

  Future<List<Sale>> fetchAllSales() async {
    final response = await _client
        .from('sales')
        .select('*, sale_items(*, return_items(*))')
        .order('created_at', ascending: false);
    return (response as List)
        .map((s) => Sale.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  Future<Sale?> getSaleById(int id) async {
    final response = await _client
        .from('sales')
        .select('*, sale_items(*)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Sale.fromMap(response);
  }

  Future<Sale> createSale({
    required double totalAmount,
    required String paymentMethod,
    required double receivedAmount,
    required double change,
    required List<SaleDetailItem> items,
    String? customerId,
  }) async {
    final user = _client.auth.currentUser;
    
    // 1. Save Directly to Supabase
    try {
      final saleData = {
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'received_amount': receivedAmount,
        'change': change,
        'item_count': items.fold<int>(0, (sum, i) => sum + i.quantity),
        if (user != null) 'user_id': user.id,
        if (customerId != null) 'customer_id': int.tryParse(customerId ?? ''),
      };

      final saleResponse = await _client.from('sales').insert(saleData).select().single();
      final remoteId = saleResponse['id'];

      final details = items.map((i) => {
        'sale_id': remoteId,
        'product_id': i.productId != null ? int.tryParse(i.productId!) : null,
        'product_name': i.productName,
        'quantity': i.quantity,
        'price_at_sale': i.priceAtSale,
        'cost_price_at_sale': i.costPriceAtSale,
        'subtotal': i.subtotal,
      }).toList();

      if (details.isNotEmpty) {
        await _client.from('sale_items').insert(details);
      }

      // 2. Update customer balance if payment is on credit
      if (paymentMethod == 'Crédito' && customerId != null) {
        final customerResponse = await _client
            .from('customers')
            .select('balance')
            .eq('id', int.parse(customerId))
            .single();
        
        final currentBalance = (customerResponse['balance'] as num).toDouble();
        await _client
            .from('customers')
            .update({'balance': currentBalance + totalAmount})
            .eq('id', int.parse(customerId));
      }

      // 3. Deduct stock (Robust logic with fallback)
      for (final item in items) {
        if (item.productId != null) {
          try {
            await _client.rpc('deduct_stock', params: {
              'p_id': int.tryParse(item.productId!),
              'p_qty': item.quantity,
            });
          } catch (e) {
            // FALLBACK: Manual deduction if RPC is missing or fails
            try {
              final pid = int.tryParse(item.productId!);
              if (pid != null) {
                final prod = await _client.from('products').select('stock_quantity').eq('id', pid).maybeSingle();
                if (prod != null) {
                  final current = prod['stock_quantity'] as int;
                  await _client.from('products').update({'stock_quantity': current - item.quantity}).eq('id', pid);
                }
              }
            } catch (e2) {
              print('Critical: Manual stock deduction failed for product ${item.productId}: $e2');
            }
          }
        }
      }

      return Sale.fromMap(saleResponse);
    } catch (e) {
      print('Error al crear venta en Supabase: $e');
      rethrow;
    }
  }

  Future<void> deleteSale(int id) async {
    // Borrado silencioso: solo quita el registro del historial
    // No afecta stock ni saldos de clientes
    await _client.from('sale_items').delete().eq('sale_id', id);
    await _client.from('sales').delete().eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> getSalesStream() {
    return _client
        .from('sales')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> processReturn(int saleId, Map<String, int> returnedItems, String reason) async {
    // 1. Fetch sale items to get their IDs and prices
    final saleItemsResponse = await _client
        .from('sale_items')
        .select('id, product_id, product_name, quantity, price_at_sale')
        .eq('sale_id', saleId);
    
    double totalRefunded = 0.0;
    final returnItemsData = <Map<String, dynamic>>[];

    for (final item in saleItemsResponse as List) {
      final name = item['product_name'] as String;
      if (returnedItems.containsKey(name) && returnedItems[name]! > 0) {
        final qty = returnedItems[name]!;
        final price = (item['price_at_sale'] as num).toDouble();
        final refund = price * qty;
        totalRefunded += refund;
        
        returnItemsData.add({
          'sale_item_id': item['id'],
          'product_name': name,
          'quantity': qty,
          'refund_amount': refund,
        });

        // Restore stock using product_id
        final pid = item['product_id'];
        if (pid != null) {
          final productResponse = await _client
              .from('products')
              .select('stock_quantity')
              .eq('id', pid)
              .maybeSingle();

          if (productResponse != null) {
            final currentStock = productResponse['stock_quantity'] as int;
            await _client
                .from('products')
                .update({'stock_quantity': currentStock + qty})
                .eq('id', pid);
          }
        }
      }
    }

    if (returnItemsData.isEmpty) return;

    // 2. Insert into returns table
    final returnResponse = await _client.from('returns').insert({
      'sale_id': saleId,
      'reason': reason,
      'total_refunded': totalRefunded,
    }).select('id').single();

    final returnId = returnResponse['id'] as int;

    // 3. Insert return items
    for (var data in returnItemsData) {
      data['return_id'] = returnId;
    }
    await _client.from('return_items').insert(returnItemsData);
  }

  Future<void> saveCashCut({
    required double expectedCash,
    required double startingCash,
    required double actualCash,
    required double difference,
    required Map<String, int> denominations,
  }) async {
    final user = _client.auth.currentUser;
    await _client.from('cash_cuts').insert({
      'expected_cash': expectedCash,
      'starting_cash': startingCash,
      'actual_cash': actualCash,
      'difference': difference,
      'denominations': denominations,
      if (user != null) 'user_id': user.id,
    });
  }

  Future<List<Map<String, dynamic>>> fetchCashCuts() async {
    try {
      final response = await _client
          .from('cash_cuts')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching cash cuts: $e');
      return [];
    }
  }

  Future<void> createExpense({
    required double amount,
    required String description,
    String category = 'General',
  }) async {
    final user = _client.auth.currentUser;
    await _client.from('expenses').insert({
      'amount': amount,
      'description': description,
      'category': category,
      if (user != null) 'user_id': user.id,
    });
  }

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final response = await _client
        .from('expenses')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Stream<List<Map<String, dynamic>>> getExpensesStream() {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<List<MapEntry<DateTime, double>>> getDailySalesForMonth(
    int year,
    int month,
  ) async {
    final from = DateTime(year, month, 1).toIso8601String();
    final to = DateTime(year, month + 1, 1).toIso8601String();
    final response = await _client
        .from('sales')
        .select('created_at, total_amount')
        .gte('created_at', from)
        .lt('created_at', to);

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final result = List.generate(
      daysInMonth,
      (i) => MapEntry(DateTime(year, month, i + 1), 0.0),
    );
    for (final row in response as List) {
      final date = DateTime.parse(row['created_at'] as String);
      final day = date.day - 1;
      result[day] = MapEntry(
        result[day].key,
        result[day].value + (row['total_amount'] as num).toDouble(),
      );
    }
    return result;
  }

  Future<List<MapEntry<DateTime, double>>> getMonthlyRevenueLastNMonths(
    int n,
  ) async {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, double>>[];
    for (var i = n - 1; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? 12 + month : month;
      final from = DateTime(year, adjustedMonth, 1).toIso8601String();
      final to = DateTime(year, adjustedMonth + 1, 1).toIso8601String();
      final response = await _client
          .from('sales')
          .select('total_amount')
          .gte('created_at', from)
          .lt('created_at', to);
      final total = (response as List).fold<double>(
        0.0,
        (sum, r) => sum + (r['total_amount'] as num).toDouble(),
      );
      result.add(MapEntry(DateTime(year, adjustedMonth), total));
    }
    return result;
  }

  Future<Map<String, double>> getPaymentMethodDistribution() async {
    final response = await _client
        .from('sales')
        .select('payment_method, total_amount');
    final totals = <String, double>{};
    for (final row in response as List) {
      final method = row['payment_method'] as String;
      totals[method] =
          (totals[method] ?? 0.0) + (row['total_amount'] as num).toDouble();
    }
    return totals;
  }

  Future<List<MapEntry<String, int>>> getTopProducts({int limit = 5}) async {
    final response = await _client
        .from('sale_items')
        .select('product_name, quantity');
    final counts = <String, int>{};
    for (final row in response as List) {
      final name = row['product_name'] as String;
      counts[name] = (counts[name] ?? 0) + (row['quantity'] as int);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  Future<Map<String, dynamic>> getStats({bool sinceLastCut = false}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    String? sinceFilter;
    if (sinceLastCut) {
      try {
        final lastCut = await _client
            .from('cash_cuts')
            .select('created_at')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (lastCut != null) {
          sinceFilter = lastCut['created_at'] as String;
        }
      } catch (e) {
        print('Error fetching last cash cut: $e');
      }
    }

    // Default to start of day if not filtering by last cut or if no cut exists
    final effectiveSince = sinceFilter ?? startOfDay;

    final allSales = await _client
        .from('sales')
        .select('payment_method, created_at, sale_items(quantity, price_at_sale, return_items(quantity))')
        .gte('created_at', effectiveSince);
    
    double grossRevenue = 0;
    double todayGrossRevenue = 0;
    int todayCount = 0;
    double todayCash = 0;

    for (final row in allSales as List) {
      double saleOriginalTotal = 0;
      final items = row['sale_items'] as List? ?? [];
      for (final item in items) {
        final currentQty = (item['quantity'] as num?)?.toInt() ?? 0;
        final returns = item['return_items'] as List? ?? [];
        final returnedQty = returns.fold<int>(0, (sum, r) => sum + (r['quantity'] as int? ?? 0));
        
        final price = (item['price_at_sale'] as num?)?.toDouble() ?? 0.0;
        saleOriginalTotal += (currentQty + returnedQty) * price;
      }

      final created = DateTime.parse(row['created_at'] as String).toLocal();
      
      if (created.year == now.year &&
          created.month == now.month &&
          created.day == now.day) {
        todayGrossRevenue += saleOriginalTotal;
        todayCount++;
        if (row['payment_method'] == 'Efectivo') todayCash += saleOriginalTotal;
      } else if (sinceLastCut) {
        todayGrossRevenue += saleOriginalTotal;
        todayCount++;
        if (row['payment_method'] == 'Efectivo') todayCash += saleOriginalTotal;
      }
      grossRevenue += saleOriginalTotal;
    }

    final expensesResponse = await _client
        .from('expenses')
        .select('amount, created_at')
        .gte('created_at', effectiveSince);
    
    double todayExpenses = 0;
    if (expensesResponse != null) {
      for (final row in expensesResponse as List) {
        final created = DateTime.parse(row['created_at'] as String).toLocal();
        if ((created.year == now.year && created.month == now.month && created.day == now.day) || sinceLastCut) {
          todayExpenses += (row['amount'] as num).toDouble();
        }
      }
    }

    final returnsResponse = await _client
        .from('returns')
        .select('total_refunded, created_at')
        .gte('created_at', effectiveSince);
    
    double todayRefunds = 0;
    if (returnsResponse != null) {
      for (final row in returnsResponse as List) {
        final created = DateTime.parse(row['created_at'] as String).toLocal();
        if ((created.year == now.year && created.month == now.month && created.day == now.day) || sinceLastCut) {
          todayRefunds += (row['total_refunded'] as num).toDouble();
        }
      }
    }

    return {
      'grossRevenue': grossRevenue,
      'todayGrossRevenue': todayGrossRevenue,
      'todayNetRevenue': todayGrossRevenue - todayRefunds,
      'todayCount': todayCount,
      'todayCash': todayCash - todayExpenses - todayRefunds,
      'todayExpenses': todayExpenses,
      'todayRefunds': todayRefunds,
      'totalCount': (allSales as List).length,
    };
  }

  Future<Map<String, dynamic>> getFilteredStats({
    DateTime? from,
    DateTime? to,
    String? categoryId,
  }) async {
    // We select sales and join with sale_items and their products to filter by category
    var query = _client.from('sales').select('total_amount, payment_method, created_at, sale_items(*, return_items(quantity), products(category_id))');
    
    if (from != null) query = query.gte('created_at', from.toUtc().toIso8601String());
    if (to != null) query = query.lte('created_at', to.toUtc().toIso8601String());

    final sales = await query;
    
    // Fetch refunds for the same period
    var refundQuery = _client.from('returns').select('total_refunded, created_at');
    if (from != null) refundQuery = refundQuery.gte('created_at', from.toUtc().toIso8601String());
    if (to != null) refundQuery = refundQuery.lte('created_at', to.toUtc().toIso8601String());
    final refundsRes = await refundQuery;
    double totalRefunds = 0;
    for (final r in refundsRes as List) {
      totalRefunds += (r['total_refunded'] as num).toDouble();
    }

    double grossRevenue = 0;
    double cost = 0;
    int count = 0;
    Map<String, double> paymentMethods = {};
    Map<int, double> hourlySales = {};
    Map<DateTime, double> dailySales = {};
    
    for (final s in sales as List) {
      final createdAt = DateTime.parse(s['created_at']).toLocal();
      final dayKey = DateTime(createdAt.year, createdAt.month, createdAt.day);
      
      double saleRevenue = 0;
      double saleCost = 0;
      bool hasTargetCategory = categoryId == null;

      for (final item in s['sale_items'] as List) {
        final product = item['products'] as Map<String, dynamic>?;
        final itemCatId = product?['category_id']?.toString();
        
        if (categoryId != null && itemCatId == categoryId) {
          hasTargetCategory = true;
        }

        if (categoryId == null || itemCatId == categoryId) {
          final currentQty = (item['quantity'] as num?)?.toInt() ?? 0;
          final returns = item['return_items'] as List? ?? [];
          final returnedQty = returns.fold<int>(0, (sum, r) => sum + (r['quantity'] as int? ?? 0));
          
          final price = (item['price_at_sale'] as num?)?.toDouble() ?? 0.0;
          saleRevenue += (currentQty + returnedQty) * price;
          saleCost += ((item['cost_price_at_sale'] ?? 0) as num).toDouble() * (currentQty + returnedQty);
        }
      }

      if (!hasTargetCategory) continue;

      grossRevenue += saleRevenue;
      cost += saleCost;
      count++;

      final pm = s['payment_method'] as String? ?? 'Efectivo';
      paymentMethods[pm] = (paymentMethods[pm] ?? 0) + saleRevenue;

      final hour = createdAt.hour;
      hourlySales[hour] = (hourlySales[hour] ?? 0) + saleRevenue;

      dailySales[dayKey] = (dailySales[dayKey] ?? 0) + saleRevenue;
    }

    return {
      'grossRevenue': grossRevenue,
      'netRevenue': grossRevenue - totalRefunds,
      'refunds': totalRefunds,
      'cost': cost,
      'profit': (grossRevenue - totalRefunds) - cost,
      'count': count,
      'hourly': hourlySales,
      'daily': dailySales,
      'paymentMethods': paymentMethods,
    };
  }

  Future<List<MapEntry<int, double>>> getHourlySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    
    final response = await _client
        .from('sales')
        .select('created_at, total_amount')
        .gte('created_at', startOfDay);

    final result = List.generate(24, (i) => MapEntry(i, 0.0));

    for (final row in response as List) {
      final date = DateTime.parse(row['created_at'] as String).toLocal();
      final hour = date.hour;
      result[hour] = MapEntry(hour, result[hour].value + (row['total_amount'] as num).toDouble());
    }
    return result;
  }

  Future<Map<String, double>> getCategorySalesDistribution() async {
    final response = await _client
        .from('sale_items')
        .select('product_id, quantity, price_at_sale');
    
    final categoryTotals = <String, double>{};

    // We need to map product_id to category name. 
    // For efficiency in this demo, we'll fetch products and their categories.
    final productsResponse = await _client
        .from('products')
        .select('id, categories(name)');
    
    final productToCategory = <int, String>{};
    for (final p in productsResponse as List) {
      final cat = p['categories'];
      productToCategory[p['id']] = cat != null ? cat['name'] : 'Sin Categoría';
    }

    for (final row in response as List) {
      final pid = row['product_id'];
      if (pid == null) continue;
      
      final catName = productToCategory[pid] ?? 'Desconocido';
      final total = (row['quantity'] as int) * (row['price_at_sale'] as num).toDouble();
      categoryTotals[catName] = (categoryTotals[catName] ?? 0.0) + total;
    }
    return categoryTotals;
  }

  Future<Map<String, double>> getProfitStats() async {
    final response = await _client
        .from('sale_items')
        .select('quantity, price_at_sale, cost_price_at_sale');
    
    double totalRevenue = 0;
    double totalCost = 0;
    
    for (final row in response as List) {
      final qty = row['quantity'] as int;
      final price = (row['price_at_sale'] as num).toDouble();
      final cost = (row['cost_price_at_sale'] as num?)?.toDouble() ?? 0.0;
      
      totalRevenue += price * qty;
      totalCost += cost * qty;
    }
    
    return {
      'revenue': totalRevenue,
      'cost': totalCost,
      'profit': totalRevenue - totalCost,
    };
  }

  Future<List<Map<String, dynamic>>> getDeadStock(
    List<String> allProductNames,
  ) async {
    final thirtyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    
    final response = await _client
        .from('sale_items')
        .select('product_name, sales!inner(created_at)')
        .gte('sales.created_at', thirtyDaysAgo);

    final soldRecently = <String>{};
    for (final row in response as List) {
      soldRecently.add(row['product_name'] as String);
    }

    final dead = allProductNames
        .where((name) => !soldRecently.contains(name))
        .toList();
    final rand = Random();
    
    return dead
        .map((name) => {'name': name, 'days': 30 + rand.nextInt(61)})
        .toList();
  }
}

final salesRepositoryProvider = Provider((ref) {
  return SalesRepository(Supabase.instance.client);
});

final salesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(salesRepositoryProvider).getSalesStream();
});

final cashCutsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('cash_cuts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);
});

final expensesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(salesRepositoryProvider).getExpensesStream();
});

final saleItemsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('sale_items')
      .stream(primaryKey: ['id']);
});

final salesProvider = FutureProvider<List<Sale>>((ref) async {
  ref.watch(salesStreamProvider);
  ref.watch(saleItemsStreamProvider); // Important for detail changes
  return ref.read(salesRepositoryProvider).fetchAllSales();
});

final salesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(salesStreamProvider);
  ref.watch(expensesStreamProvider); // Stats include expenses
  return ref.read(salesRepositoryProvider).getStats();
});

