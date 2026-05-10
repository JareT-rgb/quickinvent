import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/sales_repository.dart';
import '../models/report_filter.dart';
export '../models/report_filter.dart';

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
  final double netProfit;
  final double totalCost;
  final double averageTicket;

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
    required this.netProfit,
    required this.totalCost,
    required this.averageTicket,
  });
}

class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => ReportFilter();
  
  void updateFilter(ReportFilter filter) => state = filter;
}

final reportFilterProvider = NotifierProvider<ReportFilterNotifier, ReportFilter>(() => ReportFilterNotifier());

final reportDataProvider = FutureProvider<ReportData>((ref) async {
  // Watch EVERYTHING that changes to ensure real-time
  ref.watch(salesStreamProvider);
  ref.watch(saleItemsStreamProvider);
  ref.watch(cashCutsStreamProvider);
  ref.watch(expensesStreamProvider);
  
  final filter = ref.watch(reportFilterProvider);
  final repo = ref.read(salesRepositoryProvider);
  
  try {
    final dRange = filter.dateTimeRange;
    
    // Fetch all required data using the new filtered stats method
    final filteredData = await repo.getFilteredStats(
      from: dRange?.start,
      to: dRange?.end,
      categoryId: filter.categoryId,
    );

    // Basic stats
    final revenue = (filteredData['revenue'] as num?)?.toDouble() ?? 0.0;
    final cost = (filteredData['cost'] as num?)?.toDouble() ?? 0.0;
    final count = (filteredData['count'] as num?)?.toInt() ?? 0;

    // Daily trends from filtered data
    final dailyMap = filteredData['daily'] as Map<DateTime, double>? ?? {};
    final List<MapEntry<DateTime, double>> daily = dailyMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Hourly peak hours from filtered data
    final List<MapEntry<int, double>> hourly = List.generate(24, (i) {
      final hourMap = filteredData['hourly'] as Map<int, double>?;
      return MapEntry(i, hourMap?[i] ?? 0.0);
    });

    // Distribution
    final paymentMethods = filteredData['paymentMethods'] as Map<String, double>? ?? {};
    
    // Categorical distribution (if not filtered by category, show all)
    Map<String, double> categorySales = {};
    if (filter.categoryId == null) {
      categorySales = await repo.getCategorySalesDistribution();
    } else {
      // If filtered, category sales is just 100% of the revenue for that category
      categorySales = {'Categoría Seleccionada': revenue};
    }

    final topProducts = await repo.getTopProducts(limit: 5);
    final cashCuts = await repo.fetchCashCuts();
    final expenses = await repo.fetchExpenses();
    final monthly = await repo.getMonthlyRevenueLastNMonths(6);

    return ReportData(
      stats: {
        'totalRevenue': revenue,
        'totalCount': count,
      },
      monthly: monthly,
      daily: daily,
      hourly: hourly,
      paymentMethods: paymentMethods,
      categorySales: categorySales,
      topProducts: topProducts,
      cashCuts: cashCuts,
      expenses: expenses,
      netProfit: revenue - cost,
      totalCost: cost,
      averageTicket: count > 0 ? revenue / count : 0,
    );
  } catch (e, stack) {
    print('Error in reportDataProvider: $e');
    print(stack);
    return ReportData(
      stats: {'totalRevenue': 0.0, 'totalCount': 0},
      monthly: [],
      daily: [],
      hourly: [],
      paymentMethods: {},
      categorySales: {},
      topProducts: [],
      cashCuts: [],
      expenses: [],
      netProfit: 0.0,
      totalCost: 0.0,
      averageTicket: 0.0,
    );
  }
});

final deadStockProvider = FutureProvider.family<List<Map<String, dynamic>>, List<String>>((ref, productNames) async {
  return ref.read(salesRepositoryProvider).getDeadStock(productNames);
});
