class DashboardStats {
  final double totalRevenue;
  final double thisMonthRevenue;
  final double previousMonthRevenue;
  final int activeProductsCount;
  final int deadProductsCount;

  DashboardStats({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.previousMonthRevenue,
    required this.activeProductsCount,
    required this.deadProductsCount,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalRevenue: (map['total_revenue'] as num).toDouble(),
      thisMonthRevenue: (map['this_month_revenue'] as num).toDouble(),
      previousMonthRevenue: (map['previous_month_revenue'] as num).toDouble(),
      activeProductsCount: map['active_products_count'] as int,
      deadProductsCount: map['dead_products_count'] as int,
    );
  }
}