import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:animate_do/animate_do.dart';
import '../repositories/sales_repository.dart';
import 'dead_stock_report_screen.dart';
import '../providers/products_provider.dart';
import '../utils/excel_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDataProvider);
    final productsAsync = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildModernSliverAppBar(context, ref, products, report, isDark),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader('Dashboard de Rendimiento', Icons.auto_graph_rounded),
                        _buildMetricGrid(report, products, currencyFormat, isDark),
                        const SizedBox(height: 40),
                        
                        _buildSectionHeader('Distribución de Ventas', Icons.pie_chart_rounded),
                        _buildInteractiveCharts(report, currencyFormat, isDark),
                        const SizedBox(height: 40),
                        
                        _buildSectionHeader('Auditoría de Arqueos', Icons.account_balance_wallet_rounded),
                        _buildCashCutSection(report, currencyFormat, isDark),
                        const SizedBox(height: 40),

                        _buildSectionHeader('Top Productos Vendidos', Icons.star_rounded),
                        _buildTopProductsSection(products, isDark),
                        const SizedBox(height: 40),
                        
                        _buildSectionHeader('Análisis de Stock Crítico', Icons.inventory_2_rounded),
                        FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: DeadStockReport(productNames: products.map((p) => p.name).toList())
                        ),
                        const SizedBox(height: 80),
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

  Widget _buildModernSliverAppBar(BuildContext context, WidgetRef ref, List products, ReportData report, bool isDark) {
    return SliverAppBar.large(
      title: const Text('Análisis de Negocio'),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 22),
          ),
          onPressed: () => ref.invalidate(reportDataProvider),
        ),
        _buildExportMenu(context, ref, products, report),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildExportMenu(BuildContext context, WidgetRef ref, List products, ReportData report) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.ios_share_rounded, color: AppTheme.primary, size: 22),
      ),
      onSelected: (value) async {
        if (value == 'inventory') await ExcelHelper.exportProducts(products.cast());
        else if (value == 'sales') {
          final allSales = await ref.read(salesRepositoryProvider).fetchAllSales();
          await ExcelHelper.exportSales(allSales);
        } else {
          _exportReportToCsv(context, report);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'inventory', child: Text('Exportar Inventario')),
        const PopupMenuItem(value: 'sales', child: Text('Exportar Ventas')),
        const PopupMenuItem(value: 'csv', child: Text('Exportar CSV')),
      ],
    );
  }

  Future<void> _exportReportToCsv(BuildContext context, ReportData report) async {
    final List<List<dynamic>> rows = [];
    rows.add(['REPORTE DE NEGOCIO - QUICKINVENT']);
    rows.add(['Fecha', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())]);
    rows.add(['Total Ingresos', report.stats['totalRevenue']]);
    rows.add(['Transacciones', report.stats['totalCount']]);
    
    String csvData = rows.map((row) => row.join(',')).join('\n');
    Uint8List bytes = Uint8List.fromList(utf8.encode(csvData));
    await FileSaver.instance.saveFile(name: 'Reporte_${DateTime.now().millisecondsSinceEpoch}.csv', bytes: bytes);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 12),
            Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(ReportData report, List products, NumberFormat fmt, bool isDark) {
    final revenue = (report.stats['totalRevenue'] as num).toDouble();
    return Row(
      children: [
        Expanded(
          child: SparklineCard(
            title: 'Ventas Totales',
            value: revenue,
            prefix: '\$',
            data: const [10, 20, 15, 30, 25, 45, 40, 60], // Datos simulados de tendencia
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SparklineCard(
            title: 'Ticket Promedio',
            value: revenue / (report.stats['totalCount'] == 0 ? 1 : report.stats['totalCount']),
            prefix: '\$',
            data: const [50, 45, 60, 55, 70, 65, 80],
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, num value, IconData icon, Color color, int index, {String prefix = '', String suffix = ''}) {
    return FadeInUp(
      duration: const Duration(milliseconds: 250),
      delay: Duration(milliseconds: index * 50),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusMedium,
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.divider.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                FittedBox(
                  child: AnimatedCounter(
                    value: value,
                    prefix: prefix,
                    suffix: suffix,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCharts(ReportData report, NumberFormat fmt, bool isDark) {
    final theme = Theme.of(context);
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: AppTheme.radiusLarge,
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Text('Volumen por Categoría', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Spacer(),
                Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: RepaintBoundary(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 70,
                    sections: _getSections(report.categorySales),
                  ),
                ),
              ),
            ),
            if (_touchedIndex != -1)
              FadeIn(
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    '${report.categorySales.keys.elementAt(_touchedIndex)}: ${fmt.format(report.categorySales.values.elementAt(_touchedIndex))}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections(Map<String, double> data) {
    final keys = data.keys.toList();
    final values = data.values.toList();
    return List.generate(keys.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final color = AppTheme.primary.withValues(alpha: 0.3 + (0.15 * i));

      return PieChartSectionData(
        color: color,
        value: values[i],
        title: isTouched ? '${values[i].toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  Widget _buildCashCutSection(ReportData report, NumberFormat fmt, bool isDark) {
    final theme = Theme.of(context);
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: AppTheme.radiusMedium, boxShadow: AppTheme.softShadow, border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: report.cashCuts.length.clamp(0, 5),
          separatorBuilder: (_, __) => const Divider(indent: 20, endIndent: 20, height: 1),
          itemBuilder: (context, index) {
            final cut = report.cashCuts[index];
            final diff = (cut['difference'] as num).toDouble();
            final isBalanced = diff == 0;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Icon(isBalanced ? Icons.check_circle_rounded : Icons.warning_rounded, color: isBalanced ? AppTheme.success : AppTheme.error),
              title: Text('Corte de Caja', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(DateFormat('dd/MM HH:mm').format(DateTime.parse(cut['created_at'])), style: const TextStyle(fontSize: 12)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt.format(cut['actual_cash']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(isBalanced ? 'CONCILIADO' : 'DIF. ${fmt.format(diff)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isBalanced ? AppTheme.success : AppTheme.error)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopProductsSection(List products, bool isDark) {
    final theme = Theme.of(context);
    // Sort products by some dummy logic for demo if sales count not available
    final topProducts = (products.toList()..sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity))).take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: AppTheme.radiusMedium, boxShadow: AppTheme.softShadow, border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))),
      child: Column(
        children: topProducts.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('${p.stockQuantity} vendidos', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.8 - (topProducts.indexOf(p) * 0.2),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  color: AppTheme.primary,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
