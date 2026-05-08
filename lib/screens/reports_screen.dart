import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import '../repositories/sales_repository.dart';
import 'dead_stock_report_screen.dart';
import '../providers/products_provider.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportReportToCsv(BuildContext context, ReportData report) async {
    final List<List<dynamic>> rows = [];
    
    // Header
    rows.add(['REPORTE DE NEGOCIO - QUICKINVENT']);
    rows.add(['Fecha de exportación', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())]);
    rows.add([]);

    // Stats
    rows.add(['INDICADORES CLAVE']);
    rows.add(['Métrica', 'Valor']);
    rows.add(['Ventas Totales', report.stats['totalRevenue']]);
    rows.add(['Ingreso Diario', report.stats['todayRevenue']]);
    rows.add(['Transacciones', report.stats['totalCount']]);
    rows.add(['Gastos de Hoy', report.stats['todayExpenses']]);
    rows.add([]);

    // Cash Cuts
    rows.add(['HISTORIAL DE ARQUEOS']);
    rows.add(['Fecha', 'Esperado', 'Real', 'Diferencia', 'Estado']);
    for (var cut in report.cashCuts) {
      final date = DateTime.parse(cut['created_at'] as String);
      final diff = (cut['difference'] as num).toDouble();
      final status = diff == 0 ? 'Cuadrada' : (diff > 0 ? 'Sobrante' : 'Faltante');
      rows.add([
        DateFormat('dd/MM/yyyy HH:mm').format(date),
        cut['expected_cash'],
        cut['actual_cash'],
        diff,
        status
      ]);
    }

    // Manual CSV conversion to avoid package issues
    String csvData = rows.map((row) {
      return row.map((field) {
        String f = field.toString();
        if (f.contains(',') || f.contains('\n') || f.contains('"')) {
          return '"${f.replaceAll('"', '""')}"';
        }
        return f;
      }).join(',');
    }).join('\n');

    Uint8List bytes = Uint8List.fromList(utf8.encode(csvData));

    try {
      await FileSaver.instance.saveFile(
        name: 'Reporte_QuickInvent_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
        bytes: bytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte exportado exitosamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDataProvider);
    final productsAsync = ref.watch(productsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (products) {
          return reportAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
            data: (report) {
              final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
              
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: const Text('Análisis y Reportes', style: TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: cs.surface,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: IconButton.filledTonal(
                          onPressed: () => _exportReportToCsv(context, report),
                          icon: const Icon(Icons.file_download_outlined),
                          tooltip: 'Exportar Reporte',
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader('Indicadores Clave'),
                        _buildMetricGrid(report, products, currencyFormat),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('Rendimiento Temporal'),
                        _buildChartsSection(report, currencyFormat),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('Distribución y Ventas'),
                        _buildSecondaryStats(report, products, currencyFormat),
                        const SizedBox(height: 32),

                        _buildSectionHeader('Auditoría de Caja'),
                        _buildCashAuditSection(report.cashCuts, currencyFormat),
                        const SizedBox(height: 32),

                        _buildSectionHeader('Historial de Gastos'),
                        _buildExpensesSection(report.expenses, currencyFormat),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('Auditoría de Inventario'),
                        DeadStockReport(productNames: products.map((p) => p.name).toList()),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildMetricGrid(ReportData report, List products, NumberFormat currencyFormat) {
    final stats = report.stats;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _MetricCard(
              title: 'Ventas Totales',
              value: currencyFormat.format(stats['totalRevenue']),
              subtitle: '${stats['totalCount']} transacciones',
              icon: Icons.payments_outlined,
              color: AppTheme.primary,
            ),
            _MetricCard(
              title: 'Efectivo en Caja',
              value: currencyFormat.format(stats['todayCash']),
              subtitle: 'Corte neto actual',
              icon: Icons.account_balance_wallet_outlined,
              color: AppTheme.success,
            ),
            _MetricCard(
              title: 'Ingreso Diario',
              value: currencyFormat.format(stats['todayRevenue']),
              subtitle: 'Ventas brutas hoy',
              icon: Icons.auto_graph_rounded,
              color: AppTheme.info,
            ),
            _MetricCard(
              title: 'Gastos de Hoy',
              value: currencyFormat.format(stats['todayExpenses']),
              subtitle: 'Egresos registrados',
              icon: Icons.money_off_csred_rounded,
              color: AppTheme.error,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(ReportData report, NumberFormat currencyFormat) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : (constraints.maxWidth / 2) - 12,
              child: _buildMonthlyRevenueChart(report.monthly, currencyFormat),
            ),
            SizedBox(
              width: isMobile ? double.infinity : (constraints.maxWidth / 2) - 12,
              child: _buildDailySalesChart(report.daily, currencyFormat),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryStats(ReportData report, List products, NumberFormat currencyFormat) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : (constraints.maxWidth / 2) - 12,
              child: _buildMostSoldProducts(report),
            ),
            SizedBox(
              width: isMobile ? double.infinity : (constraints.maxWidth / 2) - 12,
              child: _buildPaymentMethods(report, currencyFormat),
            ),
            const SizedBox(height: 32),
            _buildCashAuditSection(report.cashCuts, currencyFormat),
          ],
        );
      },
    );
  }

  Widget _buildExpensesSection(List<Map<String, dynamic>> expenses, NumberFormat format) {
    return _ChartContainer(
      title: 'Gastos Registrados',
      subtitle: 'Salidas de caja y pagos operativos',
      icon: Icons.money_off_csred_rounded,
      color: AppTheme.error,
      child: expenses.isEmpty
          ? const _EmptyChart()
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final date = DateTime.parse(expense['created_at'] as String);
                final amount = (expense['amount'] as num).toDouble();
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long_rounded, color: AppTheme.error, size: 20),
                  ),
                  title: Text(
                    expense['description'] ?? 'Sin descripción',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(date),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    format.format(amount),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.error, fontSize: 15),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCashAuditSection(List<Map<String, dynamic>> cuts, NumberFormat format) {
    return _ChartContainer(
      title: 'Auditoría de Caja',
      subtitle: 'Historial de arqueos y diferencias',
      icon: Icons.assignment_turned_in_rounded,
      child: cuts.isEmpty
          ? const _EmptyChart()
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cuts.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final cut = cuts[index];
                final date = DateTime.parse(cut['created_at'] as String);
                final diff = (cut['difference'] as num).toDouble();
                final color = diff == 0 ? AppTheme.success : (diff > 0 ? AppTheme.info : AppTheme.error);
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(diff == 0 ? Icons.check : (diff > 0 ? Icons.add : Icons.remove), color: color, size: 20),
                  ),
                  title: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Fondo: ${format.format(cut['starting_cash'])} | Real: ${format.format(cut['actual_cash'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        format.format(diff),
                        style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15),
                      ),
                      Text(
                        diff == 0 ? 'Cuadrada' : (diff > 0 ? 'Sobrante' : 'Faltante'),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMonthlyRevenueChart(List<MapEntry<DateTime, double>> monthly, NumberFormat currencyFormat) {
    return _ChartContainer(
      title: 'Ingresos Mensuales',
      subtitle: 'Histórico de los últimos 6 meses',
      icon: Icons.bar_chart_rounded,
      child: monthly.isEmpty 
        ? const _EmptyChart() 
        : _BarChartContent(monthly: monthly, currencyFormat: currencyFormat),
    );
  }

  Widget _buildDailySalesChart(List<MapEntry<DateTime, double>> daily, NumberFormat currencyFormat) {
    return _ChartContainer(
      title: 'Ventas Diarias',
      subtitle: 'Rendimiento del mes actual',
      icon: Icons.show_chart_rounded,
      color: AppTheme.info,
      child: daily.isEmpty 
        ? const _EmptyChart() 
        : _LineChartContent(daily: daily, currencyFormat: currencyFormat),
    );
  }

  Widget _buildPaymentMethods(ReportData report, NumberFormat currencyFormat) {
    final distribution = report.paymentMethods;
    final total = distribution.values.fold(0.0, (a, b) => a + b);

    return _ChartContainer(
      title: 'Métodos de Pago',
      subtitle: 'Preferencia de los clientes',
      icon: Icons.pie_chart_outline_rounded,
      child: total == 0 
        ? const _EmptyChart() 
        : Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: distribution.entries.map((e) {
                      final pct = total > 0 ? e.value / total : 0.0;
                      final color = switch (e.key) {
                        'Efectivo' => AppTheme.success,
                        'Tarjeta' => AppTheme.info,
                        'Transferencia' => AppTheme.primary,
                        'Crédito' => AppTheme.error,
                        _ => AppTheme.warning,
                      };
                      return PieChartSectionData(
                        color: color,
                        value: e.value,
                        title: pct > 0.05 ? '${(pct * 100).toStringAsFixed(0)}%' : '',
                        radius: 45,
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 35,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...distribution.entries.map((e) {
                final color = switch (e.key) {
                  'Efectivo' => AppTheme.success,
                  'Tarjeta' => AppTheme.info,
                  'Transferencia' => AppTheme.primary,
                  'Crédito' => AppTheme.error,
                  _ => AppTheme.warning,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(currencyFormat.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                );
              }),
            ],
          ),
    );
  }

  Widget _buildMostSoldProducts(ReportData report) {
    final top = report.topProducts;
    return _ChartContainer(
      title: 'Productos Estrella',
      subtitle: 'Basado en volumen de ventas',
      icon: Icons.star_outline_rounded,
      color: AppTheme.warning,
      child: top.isEmpty 
        ? const _EmptyChart() 
        : Column(
            children: top.take(5).map((e) => _SoldItem(name: e.key, qty: e.value)).toList(),
          ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Color color;

  const _ChartContainer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _BarChartContent extends StatelessWidget {
  final List<MapEntry<DateTime, double>> monthly;
  final NumberFormat currencyFormat;

  const _BarChartContent({required this.monthly, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final maxY = monthly.isEmpty 
        ? 100.0 
        : monthly.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.25;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barGroups: monthly.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.primary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
                  if (value.toInt() >= monthly.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      DateFormat.MMM('es').format(monthly[value.toInt()].key).toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _LineChartContent extends StatelessWidget {
  final List<MapEntry<DateTime, double>> daily;
  final NumberFormat currencyFormat;

  const _LineChartContent({required this.daily, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final maxY = daily.isEmpty 
        ? 100.0 
        : daily.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.25;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= daily.length || idx % 5 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(DateFormat('d').format(daily[idx].key), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: daily.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
              isCurved: true,
              color: AppTheme.info,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppTheme.info.withValues(alpha: 0.2), AppTheme.info.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.query_stats, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('No hay datos suficientes para generar esta gráfica', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: AppTheme.warning, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Text('$qty uds', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }
}
