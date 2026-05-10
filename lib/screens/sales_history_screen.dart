import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../repositories/sales_repository.dart';
import '../models/sale.dart';
import '../dialogs/ticket_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _paymentFilter = 'Todos';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary, onPrimary: Colors.white, onSurface: AppTheme.textPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  List<Sale> _filterSales(List<Sale> sales) {
    return sales.where((s) {
      final matchesSearch = _searchQuery.isEmpty || s.id.toString().contains(_searchQuery);
      final matchesPayment = _paymentFilter == 'Todos' || s.paymentMethod == _paymentFilter;
      final matchesStart = _startDate == null || s.createdAt.isAfter(_startDate!.subtract(const Duration(days: 1)));
      final matchesEnd = _endDate == null || s.createdAt.isBefore(_endDate!.add(const Duration(days: 1)));
      return matchesSearch && matchesPayment && matchesStart && matchesEnd;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(salesStatsProvider);
    final salesAsync = ref.watch(salesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(statsAsync),
          SliverToBoxAdapter(child: _buildFilters(isDark)),
          salesAsync.when(
            loading: () => SliverToBoxAdapter(child: _buildShimmerLoading()),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (allSales) {
              final filtered = _filterSales(allSales);
              if (filtered.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState());
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sale = filtered[index];
                      // Only animate the first 12 items to keep scroll performance smooth
                      if (index < 12) {
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 40),
                          child: _SaleListItem(sale: sale),
                        );
                      }
                      return _SaleListItem(sale: sale);
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(AsyncValue<Map<String, dynamic>> statsAsync) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial de Ventas', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            const Text('Auditoría y control de transacciones realizadas', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            statsAsync.maybeWhen(
              data: (stats) => Row(
                children: [
                  Expanded(child: _buildMiniStat('Ingresos Hoy', (stats['todayGrossRevenue'] ?? 0.0) as num, '\$')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMiniStat('Transacciones', (stats['todayCount'] ?? 0) as num, '')),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, num value, String prefix) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          AnimatedCounter(value: value, prefix: prefix, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: AppTheme.glassDecoration(isDark: isDark).copyWith(boxShadow: AppTheme.softShadow),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(hintText: 'Buscar por ID...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
                  ),
                ),
                _DateChip(label: _startDate == null ? 'Desde' : DateFormat('dd/MM').format(_startDate!), onTap: () => _pickDate(true)),
                const SizedBox(width: 8),
                _DateChip(label: _endDate == null ? 'Hasta' : DateFormat('dd/MM').format(_endDate!), onTap: () => _pickDate(false)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumSegmentedControl(
            options: const ['Todos', 'Efectivo', 'Tarjeta', 'Crédito'],
            selectedIndex: ['Todos', 'Efectivo', 'Tarjeta', 'Crédito'].indexOf(_paymentFilter),
            onSelected: (i) => setState(() => _paymentFilter = ['Todos', 'Efectivo', 'Tarjeta', 'Crédito'][i]),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.white,
        child: Column(
          children: List.generate(5, (i) => Container(height: 80, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.history_rounded, size: 80, color: AppTheme.textMuted.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text('No se encontraron ventas', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _SaleListItem extends StatelessWidget {
  final Sale sale;
  const _SaleListItem({required this.sale});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => showDialog(context: context, builder: (context) => TicketDialog(sale: sale)),
        borderRadius: AppTheme.radiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Venta #${sale.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Row(
                      children: [
                        Text(DateFormat('dd MMMM, HH:mm').format(sale.createdAt), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        if (sale.hasReturns) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('DEVOLUCIÓN', style: TextStyle(color: AppTheme.error, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt.format(sale.totalAmount), 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 18, 
                      color: AppTheme.primary,
                      decoration: sale.hasReturns ? TextDecoration.lineThrough : null,
                      decorationColor: AppTheme.textMuted,
                    )),
                  if (sale.hasReturns)
                    Text(fmt.format(sale.netAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.error)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.textMuted.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(sale.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
      backgroundColor: AppTheme.primary.withOpacity(0.05),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
