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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historial de Ventas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Text(
                    'Control de transacciones y efectivo',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Ventas hoy',
                        '$todayCount',
                        Icons.shopping_cart_outlined,
                        AppTheme.info,
                        'transacciones',
                      ),
                      _buildSummaryCard(
                        'Ingresos hoy',
                        currencyFormat.format(todayRevenue),
                        Icons.attach_money,
                        AppTheme.success,
                        'total del día',
                      ),
                      _buildSummaryCard(
                        'Efectivo hoy',
                        currencyFormat.format(todayCash),
                        Icons.payments_outlined,
                        AppTheme.warning,
                        'en caja',
                      ),
                      _buildSummaryCard(
                        'Total filtrado',
                        currencyFormat.format(totalRevenue),
                        Icons.analytics_outlined,
                        AppTheme.primary,
                        'ventas filtradas',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) =>
                                        setState(() => _searchQuery = value),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar por ID o método...',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 20,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: AppTheme.radiusSmall,
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildDateInput(
                                  _startDate != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_startDate!)
                                      : 'Desde',
                                  () => _pickDate(true),
                                ),
                                const SizedBox(width: 8),
                                _buildDateInput(
                                  _endDate != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_endDate!)
                                      : 'Hasta',
                                  () => _pickDate(false),
                                ),
                                const SizedBox(width: 12),
                                _buildDropdown(),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: filteredSales.isEmpty
                                ? const Center(
                                    child: Text('No hay ventas que coincidan'),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: MediaQuery.of(context).size.width - 80, // Approximate padding
                                        ),
                                        child: DataTable(
                                          headingRowHeight: 45,
                                          horizontalMargin: 16,
                                          columnSpacing: 16,
                                          dataRowMaxHeight: 52,
                                          columns: _buildColumns(),
                                          rows: filteredSales
                                              .map(
                                                (s) => _buildDataRow(
                                                  s,
                                                  currencyFormat,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${filteredSales.length} ventas - Total: ${currencyFormat.format(totalRevenue)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
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
      width: 130,
      height: 40,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            border: OutlineInputBorder(borderRadius: AppTheme.radiusSmall),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: Text(label, style: const TextStyle(fontSize: 13)),
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
