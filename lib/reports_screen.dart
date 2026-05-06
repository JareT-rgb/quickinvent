import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';
import 'dead_stock_report_screen.dart';
import 'products_provider.dart';
import 'sales_repository.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDataProvider);
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        return reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (report) {
            final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
            final stats = report.stats;
            final totalRevenue = stats['totalRevenue'] as double;
            final todayRevenue = stats['todayRevenue'] as double;
            final totalCount = stats['totalCount'] as int;
            final activeProducts = products.where((p) => p.isActive).length;
            final lowStockCount = products.where((p) => p.stockQuantity < p.minStock).length;

            final monthly = report.monthly;
            final thisMonthRevenue = monthly.isNotEmpty ? monthly.last.value : 0.0;
            final prevMonthRevenue = monthly.length > 1 ? monthly[monthly.length - 2].value : 0.0;
            final monthDiff = prevMonthRevenue > 0
                ? ((thisMonthRevenue - prevMonthRevenue) / prevMonthRevenue * 100)
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reportes y Análisis', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text('Resumen del rendimiento del negocio', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implementar selector de rango de fechas
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Últimos 30 días'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryCards(
                    totalRevenue: totalRevenue,
                    todayRevenue: todayRevenue,
                    totalCount: totalCount,
                    activeProducts: activeProducts,
                    lowStockCount: lowStockCount,
                    currencyFormat: currencyFormat,
                  ),
                  const SizedBox(height: 24),
                  _buildComparisonCard(
                    thisMonth: thisMonthRevenue,
                    lastMonth: prevMonthRevenue,
                    diffPercent: monthDiff,
                    currencyFormat: currencyFormat,
                  ),
                  const SizedBox(height: 24),
                  _buildChartsSection(report, currencyFormat),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildMostSoldProducts(report)),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildPaymentMethods(report, currencyFormat)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DeadStockReport(productNames: products.map((p) => p.name).toList()),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCards({
    required double totalRevenue,
    required double todayRevenue,
    required int totalCount,
    required int activeProducts,
    required int lowStockCount,
    required NumberFormat currencyFormat,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          title: 'Ingresos totales',
          value: currencyFormat.format(totalRevenue),
          subtitle: '$totalCount ventas realizadas',
          icon: Icons.account_balance_wallet,
          color: AppTheme.primary,
        ),
        _MetricCard(
          title: 'Ventas de hoy',
          value: currencyFormat.format(todayRevenue),
          subtitle: 'Ingresos del día actual',
          icon: Icons.today,
          color: AppTheme.info,
        ),
        _MetricCard(
          title: 'Productos activos',
          value: '$activeProducts',
          subtitle: 'En catálogo',
          icon: Icons.inventory_2,
          color: AppTheme.success,
        ),
        _MetricCard(
          title: 'Stock bajo',
          value: '$lowStockCount',
          subtitle: 'Requieren atención',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildChartsSection(ReportData report, NumberFormat currencyFormat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: _buildMonthlyRevenueChart(report.monthly, currencyFormat)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildDailySalesChart(report.daily, currencyFormat)),
      ],
    );
  }

  Widget _buildMonthlyRevenueChart(List<MapEntry<DateTime, double>> monthly, NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresos mensuales (últimos 6 meses)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            if (monthly.isEmpty)
              const SizedBox(height: 150, child: Center(child: Text('Sin datos', style: TextStyle(color: AppTheme.textSecondary)))),
            if (monthly.isNotEmpty)
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: monthly.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: AppTheme.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= monthly.length) return const Text('');
                            return Text(DateFormat.MMM('es').format(monthly[value.toInt()].key), style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesChart(List<MapEntry<DateTime, double>> daily, NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ventas diarias - ${DateFormat.MMM('es').format(DateTime.now())}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            if (daily.isEmpty)
              const SizedBox(height: 150, child: Center(child: Text('Sin datos', style: TextStyle(color: AppTheme.textSecondary)))),
            if (daily.isNotEmpty)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: daily.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                        isCurved: true,
                        color: AppTheme.info,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: AppTheme.info.withValues(alpha: 0.1)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard({
    required double thisMonth,
    required double lastMonth,
    required double diffPercent,
    required NumberFormat currencyFormat,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comparación mensual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ComparisonValue(label: 'Este mes', value: currencyFormat.format(thisMonth), color: AppTheme.primary),
                _ComparisonValue(label: 'Mes pasado', value: currencyFormat.format(lastMonth), color: AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                diffPercent >= 0
                    ? '↑ Incremento de ${diffPercent.abs().toStringAsFixed(1)}% respecto al mes anterior'
                    : '↓ Decremento de ${diffPercent.abs().toStringAsFixed(1)}% respecto al mes anterior',
                style: TextStyle(color: diffPercent >= 0 ? AppTheme.success : AppTheme.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods(ReportData report, NumberFormat currencyFormat) {
    final distribution = report.paymentMethods;
    final total = distribution.values.fold(0.0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Métodos de pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            if (total == 0)
              const Center(child: Text('Sin datos', style: TextStyle(color: AppTheme.textSecondary))),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: distribution.entries.map((e) {
                    final pct = total > 0 ? e.value / total : 0.0;
                    final color = e.key == 'Efectivo'
                        ? AppTheme.success
                        : e.key == 'Tarjeta'
                            ? AppTheme.info
                            : AppTheme.warning;
                    return PieChartSectionData(
                      color: color,
                      value: e.value,
                      title: '${(pct * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((e) {
              final color = e.key == 'Efectivo' ? AppTheme.success : e.key == 'Tarjeta' ? AppTheme.info : AppTheme.warning;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(e.key, style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text(currencyFormat.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMostSoldProducts(ReportData report) {
    final top = report.topProducts;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Productos más vendidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            if (top.isEmpty)
              const Center(child: Text('Sin datos', style: TextStyle(color: AppTheme.textSecondary))),
            ...top.take(5).map((e) => _SoldItem(name: e.key, qty: e.value)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.title, required this.value, this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

class _SoldItem extends StatelessWidget {
  final String name;
  final int qty;
  const _SoldItem({required this.name, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text('$qty uds', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.info)),
        ],
      ),
    );
  }
}

class _ComparisonValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ComparisonValue({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
    ]);
  }
}
