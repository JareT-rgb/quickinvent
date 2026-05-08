import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/sales_repository.dart';
import '../providers/products_provider.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  final _searchController = TextEditingController();
  bool _isLoadingSales = true;
  bool _isProcessing = false;

  List<Sale> _allSales = [];
  List<Sale> _filteredSales = [];

  Sale? _selectedSale;
  final Map<String, bool> _selectedProducts = {};
  String _returnReason = 'Defectuoso';

  final List<String> _reasons = [
    'Defectuoso',
    'Caducado',
    'Error del cliente',
    'Error de sistema',
    'Otro'
  ];

  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadSales();
    _searchController.addListener(_filterSales);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoadingSales = true);
    try {
      final sales = await ref.read(salesRepositoryProvider).fetchAllSales();
      setState(() {
        _allSales = sales;
        _filteredSales = sales;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ventas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSales = false);
    }
  }

  void _filterSales() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredSales = _allSales;
      } else {
        _filteredSales = _allSales.where((s) {
          final id = s.id.toString();
          final date = _dateFormat.format(s.createdAt).toLowerCase();
          final total = s.totalAmount.toStringAsFixed(2);
          return id.contains(query) || date.contains(query) || total.contains(query);
        }).toList();
      }
    });
  }

  void _selectSale(Sale sale) {
    setState(() {
      _selectedSale = sale;
      _selectedProducts.clear();
      if (sale.items != null) {
        for (final item in sale.items!) {
          _selectedProducts[item.productName] = false;
        }
      }
    });
  }

  Future<void> _processReturn() async {
    final selectedNames = _selectedProducts.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un producto para devolver')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar Devolución'),
          ],
        ),
        content: Text(
          '¿Deseas procesar la devolución de ${selectedNames.length} artículo(s) de la Venta #${_selectedSale!.id}?\n\nEl stock será restaurado automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      // Build quantity map (1 per product since SaleDetailItem doesn't have separate ID)
      final items = _selectedSale!.items!;
      final returnMap = <String, int>{};
      for (final name in selectedNames) {
        final item = items.firstWhere((i) => i.productName == name, orElse: () => items.first);
        returnMap[name] = item.quantity;
      }

      await ref.read(salesRepositoryProvider).processReturn(
        int.parse(_selectedSale!.id),
        returnMap,
        _returnReason,
      );

      // Refresh products so stock updates in UI
      ref.invalidate(productsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Devolución procesada. Stock restaurado.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Remove the returned items from the selected sale's list
        final remainingItems = _selectedSale!.items!
            .where((i) => !selectedNames.contains(i.productName))
            .toList();

        setState(() {
          if (remainingItems.isEmpty) {
            // All items returned — remove sale from both lists
            _allSales.removeWhere((s) => s.id == _selectedSale!.id);
            _filteredSales.removeWhere((s) => s.id == _selectedSale!.id);
            _selectedSale = null;
            _selectedProducts.clear();
          } else {
            // Partial return — update the sale in place
            final updatedSale = Sale(
              id: _selectedSale!.id,
              items: remainingItems,
              totalAmount: _selectedSale!.totalAmount,
              paymentMethod: _selectedSale!.paymentMethod,
              receivedAmount: _selectedSale!.receivedAmount,
              change: _selectedSale!.change,
              createdAt: _selectedSale!.createdAt,
              itemCount: remainingItems.length,
            );
            // Sync local lists
            final idx = _allSales.indexWhere((s) => s.id == _selectedSale!.id);
            if (idx != -1) _allSales[idx] = updatedSale;
            final fidx = _filteredSales.indexWhere((s) => s.id == _selectedSale!.id);
            if (fidx != -1) _filteredSales[fidx] = updatedSale;
            _selectedSale = updatedSale;
            _selectedProducts.clear();
          }
        });
        // Do NOT call _loadSales() here — it would re-fetch from Supabase
        // and undo the local removals (the DB sale record still exists).
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _selectSaleResponsive(Sale sale, bool isMobile) {
    _selectSale(sale);
    if (isMobile) {
      _showReturnDetailSheet();
    }
  }

  void _showReturnDetailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _buildReturnDetailContent(isSheet: true, setSheetState: setSheetState),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final padding = isMobile ? 12.0 : 24.0;

        if (isMobile) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Devoluciones', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Selecciona una venta para devolver', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                _buildSearchField(cs),
                const SizedBox(height: 12),
                Expanded(child: _buildSalesList(cs, isMobile: true)),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Devoluciones', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Selecciona una venta para procesar una devolución',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
                    _buildSearchField(cs),
                    const SizedBox(height: 12),
                    Expanded(child: _buildSalesList(cs, isMobile: false)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _selectedSale == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_outlined, size: 72,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('Selecciona una venta de la lista',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              )),
                          ],
                        ),
                      )
                    : Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: _buildReturnDetailContent(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por ID, fecha o monto...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { _searchController.clear(); _filterSales(); },
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildSalesList(ColorScheme cs, {required bool isMobile}) {
    if (_isLoadingSales) return const Center(child: CircularProgressIndicator());
    if (_filteredSales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No se encontraron ventas', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSales,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredSales.length,
        itemBuilder: (context, index) {
          final sale = _filteredSales[index];
          final isSelected = _selectedSale?.id == sale.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 3 : 0,
            color: isSelected ? cs.primaryContainer.withValues(alpha: 0.5) : cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5), width: isSelected ? 2 : 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isSelected ? cs.primary : cs.surfaceContainerHighest,
                child: Text('#${sale.id}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : cs.onSurfaceVariant)),
              ),
              title: Text(_currencyFormat.format(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_dateFormat.format(sale.createdAt)),
              trailing: isMobile
                  ? const Icon(Icons.chevron_right)
                  : ElevatedButton.icon(
                      onPressed: () => _selectSaleResponsive(sale, isMobile),
                      icon: const Icon(Icons.assignment_return_outlined, size: 16),
                      label: const Text('Devolver'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 13)),
                    ),
              onTap: () => _selectSaleResponsive(sale, isMobile),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReturnDetailContent({bool isSheet = false, StateSetter? setSheetState}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final updateState = setSheetState ?? setState;

    if (_selectedSale == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSheet) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
          Row(
            children: [
              Icon(Icons.receipt_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('Venta #${_selectedSale!.id}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (isSheet) Navigator.pop(context);
                  setState(() { _selectedSale = null; _selectedProducts.clear(); });
                },
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(backgroundColor: cs.surfaceContainerHighest),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Total: ${_currencyFormat.format(_selectedSale!.totalAmount)}', style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          Text(_dateFormat.format(_selectedSale!.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          const Divider(height: 24),
          Row(
            children: [
              Checkbox(
                value: _selectedProducts.isNotEmpty && _selectedProducts.values.every((v) => v),
                tristate: true,
                onChanged: (val) { updateState(() { for (final key in _selectedProducts.keys) _selectedProducts[key] = val ?? false; }); },
              ),
              const Text('Seleccionar todos', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _selectedSale!.items == null || _selectedSale!.items!.isEmpty
                ? Center(child: Text('No hay artículos', style: TextStyle(color: cs.onSurfaceVariant)))
                : ListView(
                    children: _selectedSale!.items!.map((item) {
                      final isChecked = _selectedProducts[item.productName] ?? false;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isChecked ? cs.primary.withValues(alpha: 0.5) : Colors.transparent),
                        ),
                        child: CheckboxListTile(
                          value: isChecked,
                          onChanged: (val) { updateState(() { _selectedProducts[item.productName] = val ?? false; }); },
                          title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${item.quantity} unidad(es)'),
                          secondary: Text(_currencyFormat.format(item.subtotal), style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _returnReason,
            decoration: InputDecoration(
              labelText: 'Razón de devolución',
              prefixIcon: const Icon(Icons.help_outline),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => updateState(() => _returnReason = v ?? _reasons.first),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : () async {
                await _processReturn();
                if (isSheet && mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.assignment_return),
              label: Text(_isProcessing ? 'Procesando...' : 'Procesar Devolución', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}