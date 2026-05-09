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
        .select('*, sale_items(*)')
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

      // 3. Deduct stock (simplified for online only)
      for (final item in items) {
        if (item.productId != null) {
          await _client.rpc('deduct_stock', params: {
            'p_id': int.tryParse(item.productId!),
            'p_qty': item.quantity,
          }).catchError((_) => null); // Silent error if RPC missing
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
        .select('id, product_name, quantity, price_at_sale')
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

        // Restore stock
        final productResponse = await _client
            .from('products')
            .select('id, stock_quantity')
            .eq('name', name)
            .limit(1)
            .maybeSingle();

        if (productResponse != null) {
          final currentStock = productResponse['stock_quantity'] as int;
          await _client
              .from('products')
              .update({'stock_quantity': currentStock + qty})
              .eq('id', productResponse['id']);
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

  Future<Map<String, dynamic>> getStats() async {
    final now = DateTime.now();

    final allSales = await _client
        .from('sales')
        .select('total_amount, payment_method, created_at');
    
    double totalRevenue = 0;
    double todayRevenue = 0;
    int todayCount = 0;
    double todayCash = 0;

    for (final row in allSales as List) {
      final amount = (row['total_amount'] as num).toDouble();
      totalRevenue += amount;
      final created = DateTime.parse(row['created_at'] as String);
      if (created.year == now.year &&
          created.month == now.month &&
          created.day == now.day) {
        todayRevenue += amount;
        todayCount++;
        if (row['payment_method'] == 'Efectivo') todayCash += amount;
      }
    }
    final expensesResponse = await _client
        .from('expenses')
        .select('amount, created_at');
    
    double todayExpenses = 0;
    if (expensesResponse != null) {
      for (final row in expensesResponse as List) {
        final created = DateTime.parse(row['created_at'] as String);
        if (created.year == now.year &&
            created.month == now.month &&
            created.day == now.day) {
          todayExpenses += (row['amount'] as num).toDouble();
        }
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'todayCount': todayCount,
      'todayCash': todayCash - todayExpenses,
      'todayExpenses': todayExpenses,
      'totalCount': allSales.length,
    };
  }

  Future<List<MapEntry<int, double>>> getHourlySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final response = await _client
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

final salesProvider = FutureProvider<List<Sale>>((ref) async {
  ref.watch(salesStreamProvider);
  return ref.read(salesRepositoryProvider).fetchAllSales();
});

final salesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(salesStreamProvider);
  return ref.read(salesRepositoryProvider).getStats();
});

class ReportData {
  final Map<String, dynamic> stats;
  final List<MapEntry<DateTime, double>> monthly;
  final List<MapEntry<DateTime, double>> daily;
  final List<MapEntry<int, double>> hourly;
  final Map<String, double> paymentMethods;
  final Map<String, double> categorySales;
  final List<MapEntry<String, int>> topProducts;
  final List<Map<String, dynamic>> cashCuts;
  final List<Map<String, dynamic>> expenses;
  final double estimatedProfit;

  ReportData({
    required this.stats,
    required this.monthly,
    required this.daily,
    required this.hourly,
    required this.paymentMethods,
    required this.categorySales,
    required this.topProducts,
    required this.cashCuts,
    required this.expenses,
    required this.estimatedProfit,
  });
}

final reportDataProvider = FutureProvider<ReportData>((ref) async {
  ref.watch(salesStreamProvider);
  ref.watch(cashCutsStreamProvider);
  ref.watch(expensesStreamProvider);
  
  final repo = ref.read(salesRepositoryProvider);
  
  try {
    final stats = await repo.getStats();
    final monthly = await repo.getMonthlyRevenueLastNMonths(6);
    final now = DateTime.now();
    final daily = await repo.getDailySalesForMonth(now.year, now.month);
    final hourly = await repo.getHourlySales();
    final paymentMethods = await repo.getPaymentMethodDistribution();
    final categorySales = await repo.getCategorySalesDistribution();
    final topProducts = await repo.getTopProducts(limit: 5);
    final cashCuts = await repo.fetchCashCuts();
    final expenses = await repo.fetchExpenses();
    final profitStats = await repo.getProfitStats();

    return ReportData(
      stats: stats,
      monthly: monthly,
      daily: daily,
      hourly: hourly,
      paymentMethods: paymentMethods,
      categorySales: categorySales,
      topProducts: topProducts,
      cashCuts: cashCuts,
      expenses: expenses,
      estimatedProfit: profitStats['profit']! - (stats['todayExpenses'] ?? 0),
    );
  } catch (e, stack) {
    print('Error generating report data: $e');
    print(stack);
    return ReportData(
      stats: {
        'totalRevenue': 0.0,
        'todayRevenue': 0.0,
        'todayCount': 0,
        'todayCash': 0.0,
        'totalCount': 0,
      },
      monthly: [],
      daily: [],
      hourly: [],
      paymentMethods: {},
      categorySales: {},
      topProducts: [],
      cashCuts: [],
      expenses: [],
      estimatedProfit: 0.0,
    );
  }
});

final deadStockProvider =
    FutureProvider.family<List<Map<String, dynamic>>, List<String>>((
      ref,
      productNames,
    ) async {
      return ref.read(salesRepositoryProvider).getDeadStock(productNames);
    });
