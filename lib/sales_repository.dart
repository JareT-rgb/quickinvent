import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sale.dart';
import 'sale_detail_item.dart';

class SalesRepository {
  final _client = Supabase.instance.client;

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
  }) async {
    final user = _client.auth.currentUser;
    final saleData = {
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'received_amount': receivedAmount,
      'change': change,
      'item_count': items.fold<int>(0, (sum, i) => sum + i.quantity),
      if (user != null) 'user_id': user.id,
    };

    final saleResponse = await _client
        .from('sales')
        .insert(saleData)
        .select()
        .single();
    final saleId = saleResponse['id'] as int;

    final details = items
        .map(
          (i) => {
            'sale_id': saleId,
            'product_name': i.productName,
            'quantity': i.quantity,
            'price_at_sale': i.priceAtSale,
            'subtotal': i.subtotal,
          },
        )
        .toList();

    if (details.isNotEmpty) {
      await _client.from('sale_items').insert(details);
    }

    return Sale.fromMap(saleResponse);
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
    return {
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'todayCount': todayCount,
      'todayCash': todayCash,
      'totalCount': allSales.length,
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
        .select('product_name')
        .gte('created_at', thirtyDaysAgo);
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

final salesRepositoryProvider = Provider((ref) => SalesRepository());

final salesProvider = FutureProvider<List<Sale>>((ref) async {
  return ref.read(salesRepositoryProvider).fetchAllSales();
});

final salesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(salesRepositoryProvider).getStats();
});

class ReportData {
  final Map<String, dynamic> stats;
  final List<MapEntry<DateTime, double>> monthly;
  final List<MapEntry<DateTime, double>> daily;
  final Map<String, double> paymentMethods;
  final List<MapEntry<String, int>> topProducts;

  ReportData({
    required this.stats,
    required this.monthly,
    required this.daily,
    required this.paymentMethods,
    required this.topProducts,
  });
}

final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final repo = ref.read(salesRepositoryProvider);
  final stats = await repo.getStats();
  final monthly = await repo.getMonthlyRevenueLastNMonths(6);
  final now = DateTime.now();
  final daily = await repo.getDailySalesForMonth(now.year, now.month);
  final paymentMethods = await repo.getPaymentMethodDistribution();
  final topProducts = await repo.getTopProducts(limit: 5);
  return ReportData(
    stats: stats,
    monthly: monthly,
    daily: daily,
    paymentMethods: paymentMethods,
    topProducts: topProducts,
  );
});

final deadStockProvider =
    FutureProvider.family<List<Map<String, dynamic>>, List<String>>((
      ref,
      productNames,
    ) async {
      return ref.read(salesRepositoryProvider).getDeadStock(productNames);
    });
