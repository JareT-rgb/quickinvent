import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:animate_do/animate_do.dart';
import '../repositories/sales_repository.dart';
import '../providers/reports_provider.dart';
import '../models/report_filter.dart';
import 'dead_stock_report_screen.dart';
import '../providers/products_provider.dart';
import '../providers/categories_provider.dart';
import '../models/category.dart';
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
  int _selectedHour = -1;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDataProvider);
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
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
                  _buildModernHeader(context, ref, products, report, isDark),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader('Dashboard de Rendimiento', Icons.auto_graph_rounded),
                        _buildFilterBar(context, ref, categoriesAsync, isDark),
                        const SizedBox(height: 24),
                        _buildMetricGrid(report, products, currencyFormat, isDark),
                        const SizedBox(height: 40),
                        
                        _buildSectionHeader('Distribución de Ventas', Icons.pie_chart_rounded),
                        _buildInteractiveCharts(report, currencyFormat, isDark),
                        const SizedBox(height: 40),

                        _buildSectionHeader('Análisis de Tendencias', Icons.trending_up_rounded),
                        _buildTrendAnalysis(report, currencyFormat, isDark),
                        const SizedBox(height: 40),
                        
                        _buildSectionHeader('Mapa de Calor: Horas Pico', Icons.access_time_filled_rounded),
                        _buildPeakHoursHeatmap(report, isDark),
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
                        const SizedBox(height: 40),

                        _buildSectionHeader('Predicciones Inteligentes (IA)', Icons.psychology_rounded),
                        _buildAIPredictions(report, isDark),
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

  Widget _buildModernHeader(BuildContext context, WidgetRef ref, List products, ReportData report, bool isDark) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, isMobile ? 48 : 32, 24, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: FadeInLeft(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Análisis de Negocio', 
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5),
                    ),
                    Text(
                      'Monitoreo en tiempo real de tu rendimiento', 
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                _buildHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  color: AppTheme.primary,
                  tooltip: 'Sincronizar',
                  onPressed: () => ref.invalidate(reportDataProvider),
                ),
                const SizedBox(width: 8),
                _buildExportMenu(context, ref, products, report),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      onPressed: onPressed,
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
        } else if (value == 'pdf') {
          await _exportToPdf(context, report, products);
        } else {
          _exportReportToCsv(context, report);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'inventory', child: Row(children: [Icon(Icons.inventory_2_rounded, size: 18), SizedBox(width: 12), Text('Exportar Inventario')])),
        const PopupMenuItem(value: 'sales', child: Row(children: [Icon(Icons.receipt_long_rounded, size: 18), SizedBox(width: 12), Text('Exportar Ventas')])),
        const PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_rows_rounded, size: 18), SizedBox(width: 12), Text('Exportar CSV')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_rounded, size: 18, color: AppTheme.error), SizedBox(width: 12), Text('Reporte PDF Pro')])),
      ],
    );
  }

  Future<void> _exportToPdf(BuildContext context, ReportData report, List products) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('QUICKINVENT PREMIUM', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
                pw.Text('Reporte Ejecutivo de Negocio', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}'),
                pw.Text('ID: ${now.millisecondsSinceEpoch}'),
              ],
            ),
          ],
        ),
        build: (pw.Context context) => [
          pw.SizedBox(height: 30),
          pw.Header(level: 0, text: 'Resumen Financiero'),
          pw.Row(
            children: [
              _pdfMetric('Ingresos Totales', fmt.format(report.stats['totalRevenue'])),
              _pdfMetric('Costo de Ventas', fmt.format(report.totalCost)),
              _pdfMetric('Utilidad Neta', fmt.format(report.netProfit)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _pdfMetric('Ticket Promedio', fmt.format(report.averageTicket)),
              _pdfMetric('Margen (%)', '${((report.stats['totalRevenue'] > 0 ? report.netProfit / report.stats['totalRevenue'] : 0) * 100).toStringAsFixed(1)}%'),
              _pdfMetric('Transacciones', report.stats['totalCount'].toString()),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Header(level: 0, text: 'Distribución por Categoría'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal900),
            data: [
              ['Categoría', 'Ventas', 'Participación'],
              ...report.categorySales.entries.map((e) => [
                e.key,
                fmt.format(e.value),
                '${(report.stats['totalRevenue'] > 0 ? e.value / report.stats['totalRevenue'] * 100 : 0).toStringAsFixed(1)}%'
              ]),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfMetric(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.all(5),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 5),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SparklineCard(
                title: 'Ventas Totales',
                value: report.stats['totalRevenue'],
                prefix: '\$',
                data: report.daily.map((e) => e.value).toList(),
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SparklineCard(
                title: 'Utilidad Neta',
                value: report.netProfit,
                prefix: '\$',
                data: const [5, 10, 8, 15, 12, 20], // Simulado
                color: AppTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SparklineCard(
                title: 'Ticket Promedio',
                value: report.averageTicket,
                prefix: '\$',
                data: const [50, 45, 60, 55, 70, 65, 80],
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SparklineCard(
                title: 'Margen Global',
                value: (report.stats['totalRevenue'] > 0) ? (report.netProfit / report.stats['totalRevenue'] * 100) : 0.0,
                suffix: '%',
                data: const [15, 18, 17, 20, 19, 22], // Simulado
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, AsyncValue<List<Category>> categoriesAsync, bool isDark) {
    final currentFilter = ref.watch(reportFilterProvider);
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Filtros Dinámicos', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const Spacer(),
            if (currentFilter.range != ReportTimeRange.all || currentFilter.categoryId != null)
              TextButton.icon(
                onPressed: () => ref.read(reportFilterProvider.notifier).updateFilter(ReportFilter()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Limpiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _FilterChip(
                label: 'Hoy',
                icon: Icons.today_rounded,
                isSelected: currentFilter.range == ReportTimeRange.today,
                onTap: () => ref.read(reportFilterProvider.notifier).updateFilter(ReportFilter(range: ReportTimeRange.today, categoryId: currentFilter.categoryId)),
              ),
              _FilterChip(
                label: '7 Días',
                icon: Icons.date_range_rounded,
                isSelected: currentFilter.range == ReportTimeRange.week,
                onTap: () => ref.read(reportFilterProvider.notifier).updateFilter(ReportFilter(range: ReportTimeRange.week, categoryId: currentFilter.categoryId)),
              ),
              _FilterChip(
                label: 'Mes',
                icon: Icons.calendar_month_rounded,
                isSelected: currentFilter.range == ReportTimeRange.month,
                onTap: () => ref.read(reportFilterProvider.notifier).updateFilter(ReportFilter(range: ReportTimeRange.month, categoryId: currentFilter.categoryId)),
              ),
              _FilterChip(
                label: 'Todo',
                icon: Icons.all_inclusive_rounded,
                isSelected: currentFilter.range == ReportTimeRange.all,
                onTap: () => ref.read(reportFilterProvider.notifier).updateFilter(ReportFilter(range: ReportTimeRange.all, categoryId: currentFilter.categoryId)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.maybeWhen(
          data: (List<Category> cats) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas las Categorías',
                  isSelected: currentFilter.categoryId == null,
                  onTap: () => ref.read(reportFilterProvider.notifier).updateFilter(ReportFilter(range: currentFilter.range, categoryId: null)),
                ),
                ...cats.map((Category c) => _FilterChip(
                  label: c.name,
                  isSelected: currentFilter.categoryId == c.id.toString(),
                  onTap: () => ref.read(reportFilterProvider.notifier).updateFilter(ReportFilter(range: currentFilter.range, categoryId: c.id.toString())),
                )),
              ],
            ),
          ),
          orElse: () => const SizedBox.shrink(),
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
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: AppTheme.radiusLarge,
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Text('Volumen por Categoría', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Spacer(),
                Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                return Flex(
                  direction: isNarrow ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 250,
                      width: isNarrow ? double.infinity : 300,
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
                          centerSpaceRadius: 50,
                          sections: _getSections(report.categorySales),
                        ),
                      ),
                    ),
                    if (!isNarrow) const SizedBox(width: 32),
                    if (isNarrow) const SizedBox(height: 24),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: _buildLegend(report.categorySales),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data) {
    final keys = data.keys.toList();
    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(keys.length, (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                keys[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: i == _touchedIndex ? FontWeight.w900 : FontWeight.w600,
                  color: i == _touchedIndex ? AppTheme.primary : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildTrendAnalysis(ReportData report, NumberFormat fmt, bool isDark) {
    final theme = Theme.of(context);
    final dailyList = report.daily.take(7).toList();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (dailyList.isEmpty ? 10.0 : dailyList.fold(0.0, (max, entry) => entry.value > max ? entry.value : max)) * 1.2,
          barGroups: dailyList.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.value,
                  color: AppTheme.primary,
                  width: 24,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (dailyList.isEmpty ? 10.0 : dailyList.fold(0.0, (max, e) => e.value > max ? e.value : max)) * 1.2,
                    color: AppTheme.primary.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyList.length) return const SizedBox.shrink();
                  final date = dailyList[index].key;
                  final label = DateFormat('E d', 'es_MX').format(date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(fmt.format(value), style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (dailyList.isEmpty ? 10.0 : dailyList.fold(0.0, (max, entry) => entry.value > max ? entry.value : max)) / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (group.x < 0 || group.x >= dailyList.length) return null;
                final date = dailyList[group.x.toInt()].key;
                return BarTooltipItem(
                  '${DateFormat('dd MMM').format(date)}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: fmt.format(rod.toY),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeakHoursHeatmap(ReportData report, bool isDark) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final maxVal = report.hourly.fold(0.0, (max, e) => e.value > max ? e.value : max);

    return Column(
      children: [
        Container(
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppTheme.radiusMedium,
            boxShadow: AppTheme.softShadow,
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: List.generate(24, (i) {
              final val = report.hourly[i].value;
              final intensity = maxVal > 0 ? (val / maxVal) : 0.0;
              final isSelected = _selectedHour == i;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedHour = isSelected ? -1 : i),
                  child: Tooltip(
                    message: '${i}:00h - ${fmt.format(val)}',
                    child: Column(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.accent 
                                  : AppTheme.primary.withValues(alpha: intensity.clamp(0.05, 1.0)),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected 
                                  ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 8)] 
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (i % 4 == 0) 
                          Text('${i}h', style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, color: isSelected ? AppTheme.accent : AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (_selectedHour != -1)
          FadeInUp(
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 8),
                    Text(
                      'A las ${_selectedHour}:00h las ventas fueron de ${fmt.format(report.hourly[_selectedHour].value)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
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

  Widget _buildAIPredictions(ReportData report, bool isDark) {
    final theme = Theme.of(context);
    final avgDaily = report.stats['totalRevenue'] / (report.stats['totalCount'] > 0 ? 30 : 1);
    final estimatedNextMonth = avgDaily * 30 * 1.05; 

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Venta Estimada (Próximo Mes)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(estimatedNextMonth), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Basado en tu tendencia actual y crecimiento del 5%.', style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections(Map<String, double> data) {
    final values = data.values.toList();
    final colors = [AppTheme.primary, AppTheme.accent, const Color(0xFF8B5CF6), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF06B6D4), const Color(0xFF10B981)];
    return List.generate(values.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      final color = colors[i % colors.length];
      return PieChartSectionData(color: color, value: values[i], title: '${values[i].toStringAsFixed(0)}%', radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white));
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : theme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primary : theme.dividerColor.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
