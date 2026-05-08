import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/sales_repository.dart';
import '../models/sale.dart';
import '../dialogs/ticket_dialog.dart';
import '../theme/app_theme.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _paymentFilter;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(salesProvider);
    ref.invalidate(salesStatsProvider);
  }

  List<Sale> _filterSales(List<Sale> sales) {
    return sales.where((s) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          s.id.toString().contains(_searchQuery) ||
          s.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPayment =
          _paymentFilter == null ||
          _paymentFilter == 'Todos' ||
          s.paymentMethod == _paymentFilter;
      final matchesStart =
          _startDate == null ||
          s.createdAt.isAfter(_startDate!.subtract(const Duration(days: 1)));
      final matchesEnd =
          _endDate == null ||
          s.createdAt.isBefore(_endDate!.add(const Duration(days: 1)));
      return matchesSearch && matchesPayment && matchesStart && matchesEnd;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(salesStatsProvider);
    final salesAsync = ref.watch(salesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (stats) {
            return salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (allSales) {
                final filteredSales = _filterSales(allSales);
                final todayRevenue = stats['todayRevenue'] as double;
                final todayCount = stats['todayCount'] as int;
                final todayCash = stats['todayCash'] as double;
                final totalRevenue = filteredSales.fold(
                  0.0,
                  (sum, s) => sum + s.totalAmount,
                );

                return Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de Ventas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Control de transacciones y efectivo',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      // Summary cards - responsive grid
                      _buildSummarySection(
                        isMobile: isMobile,
                        todayCount: todayCount,
                        todayRevenue: todayRevenue,
                        todayCash: todayCash,
                        totalRevenue: totalRevenue,
                        currencyFormat: currencyFormat,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(isMobile ? 10.0 : 16.0),
                                child: isMobile
                                    ? _buildMobileFilters()
                                    : _buildDesktopFilters(),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _onRefresh,
                                  child: isMobile
                                      ? _buildMobileList(filteredSales, currencyFormat)
                                      : _buildDesktopTable(filteredSales, currencyFormat, constraints),
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${filteredSales.length} ventas - Total: ${currencyFormat.format(totalRevenue)}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Summary Cards ─────────────────────────────────────
  Widget _buildSummarySection({
    required bool isMobile,
    required int todayCount,
    required double todayRevenue,
    required double todayCash,
    required double totalRevenue,
    required NumberFormat currencyFormat,
  }) {
    final cards = [
      _SummaryData('Ventas hoy', '$todayCount', Icons.shopping_cart_outlined, AppTheme.info, 'transacciones'),
      _SummaryData('Ingresos hoy', currencyFormat.format(todayRevenue), Icons.attach_money, AppTheme.success, 'total del día'),
      _SummaryData('Efectivo hoy', currencyFormat.format(todayCash), Icons.payments_outlined, AppTheme.warning, 'en caja'),
      _SummaryData('Total filtrado', currencyFormat.format(totalRevenue), Icons.analytics_outlined, AppTheme.primary, 'ventas filtradas'),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: cards.map((d) => _buildSummaryCardCompact(d)).toList(),
      );
    }

    return Row(
      children: cards.map((d) => Expanded(child: _buildSummaryCard(d))).toList(),
    );
  }

  Widget _buildSummaryCardCompact(_SummaryData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, color: data.color, size: 18),
            const SizedBox(height: 6),
            Text(
              data.value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Text(data.title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(_SummaryData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: AppTheme.radiusSmall,
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                  Text(data.title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(data.subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile Filters ────────────────────────────────────
  Widget _buildMobileFilters() {
    return Column(
      children: [
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Buscar por ID o método...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(borderRadius: AppTheme.radiusSmall, borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateInput(
                _startDate != null ? DateFormat('dd/MM/yy').format(_startDate!) : 'Desde',
                () => _pickDate(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateInput(
                _endDate != null ? DateFormat('dd/MM/yy').format(_endDate!) : 'Hasta',
                () => _pickDate(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildDropdown()),
          ],
        ),
      ],
    );
  }

  // ── Desktop Filters ───────────────────────────────────
  Widget _buildDesktopFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar por ID o método...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: AppTheme.radiusSmall, borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateInput(
            _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Desde',
            () => _pickDate(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateInput(
            _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Hasta',
            () => _pickDate(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildDropdown()),
      ],
    );
  }

  // ── Mobile List ───────────────────────────────────────
  Widget _buildMobileList(List<Sale> sales, NumberFormat currencyFormat) {
    if (sales.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No hay ventas que coincidan', style: TextStyle(color: AppTheme.textSecondary))),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final sale = sales[index];
        return InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => TicketDialog(sale: sale),
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: AppTheme.radiusSmall,
                  ),
                  child: Text(
                    'S${sale.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(sale.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                      ),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(sale.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(sale.paymentMethod, style: const TextStyle(fontSize: 12)),
                    Text(
                      '${sale.itemCount ?? sale.items?.length ?? 0} art.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Desktop DataTable ─────────────────────────────────
  Widget _buildDesktopTable(List<Sale> sales, NumberFormat currencyFormat, BoxConstraints constraints) {
    if (sales.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No hay ventas que coincidan')),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth - 80,
          ),
          child: DataTable(
            headingRowHeight: 45,
            horizontalMargin: 16,
            columnSpacing: 16,
            dataRowMaxHeight: 52,
            columns: _buildColumns(),
            rows: sales.map((s) => _buildDataRow(s, currencyFormat)).toList(),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    const style = TextStyle(
      color: AppTheme.textSecondary,
      fontWeight: FontWeight.bold,
      fontSize: 11,
    );
    return const [
      DataColumn(label: Text('ID', style: style)),
      DataColumn(label: Text('FECHA', style: style)),
      DataColumn(label: Text('ARTÍCULOS', style: style)),
      DataColumn(label: Text('PAGO', style: style)),
      DataColumn(label: Text('TOTAL', style: style)),
      DataColumn(label: Text('', style: style)),
    ];
  }

  DataRow _buildDataRow(Sale sale, NumberFormat currencyFormat) {
    void openTicket() => showDialog(
          context: context,
          builder: (context) => TicketDialog(sale: sale),
        );

    return DataRow(
      cells: [
        DataCell(
          Text('S${sale.id}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          onTap: openTicket,
        ),
        DataCell(
          Text(DateFormat('dd/MM/yy HH:mm').format(sale.createdAt),
              style: const TextStyle(fontSize: 12)),
          onTap: openTicket,
        ),
        DataCell(
          Text('${sale.itemCount ?? sale.items?.length ?? 0} art.',
              style: const TextStyle(fontSize: 13)),
          onTap: openTicket,
        ),
        DataCell(
          Text(sale.paymentMethod, style: const TextStyle(fontSize: 13)),
          onTap: openTicket,
        ),
        DataCell(
          Text(
            currencyFormat.format(sale.totalAmount),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 13),
          ),
          onTap: openTicket,
        ),
        DataCell(
          TextButton.icon(
            onPressed: openTicket,
            icon: const Icon(Icons.receipt_outlined, size: 16),
            label: const Text('Ver', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInput(String label, VoidCallback onTap) {
    return SizedBox(
      height: 40,
      width: double.infinity, // Constrain width to avoid InputDecorator error
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            border: OutlineInputBorder(borderRadius: AppTheme.radiusSmall),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    final options = ['Todos', 'Efectivo', 'Tarjeta', 'Transferencia'];
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: AppTheme.radiusSmall,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _paymentFilter ?? 'Todos',
          hint: const Text('Método'),
          items: options.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _paymentFilter = val),
        ),
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  _SummaryData(this.title, this.value, this.icon, this.color, this.subtitle);
}
