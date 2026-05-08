import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/sales_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';

class CashRegisterScreen extends ConsumerStatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  ConsumerState<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends ConsumerState<CashRegisterScreen> {
  final Map<double, int> _counts = {
    1000.0: 0, 500.0: 0, 200.0: 0, 100.0: 0, 50.0: 0, 20.0: 0,
    10.0: 0, 5.0: 0, 2.0: 0, 1.0: 0, 0.5: 0,
  };

  double _expectedCash = 0.0;
  double _startingCash = 0.0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _useManualInput = false;
  final _manualInputController = TextEditingController();
  final _startingCashController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadTodayCashSales();
    _startingCashController.addListener(() {
      setState(() {
        _startingCash = double.tryParse(_startingCashController.text) ?? 0.0;
      });
    });
  }

  Future<void> _loadTodayCashSales() async {
    try {
      final stats = await ref.read(salesRepositoryProvider).getStats();
      setState(() {
        _expectedCash = stats['todayCash'] as double;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ventas: $e')),
        );
      }
    }
  }

  double get _calculatedTotal {
    if (_useManualInput) {
      return (double.tryParse(_manualInputController.text) ?? 0.0);
    }
    double total = 0;
    _counts.forEach((value, qty) {
      total += value * qty;
    });
    return total;
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _startingCashController.dispose();
    super.dispose();
  }

  Future<void> _showAddExpenseDialog() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    bool isSavingExpense = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          headerIcon: Icons.money_off_rounded,
          headerColor: AppTheme.error,
          title: 'Registrar Gasto',
          subtitle: 'Este monto se restará del efectivo esperado',
          footer: AppDialogFooterButtons(
            actionLabel: 'Registrar',
            actionIcon: Icons.check,
            actionColor: AppTheme.error,
            isLoading: isSavingExpense,
            onAction: () async {
              if (amountController.text.isEmpty || descController.text.isEmpty) return;
              setDialogState(() => isSavingExpense = true);
              try {
                await ref.read(salesRepositoryProvider).createExpense(
                  amount: double.parse(amountController.text),
                  description: descController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto registrado')),
                  );
                  _loadTodayCashSales();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                  );
                }
              } finally {
                setDialogState(() => isSavingExpense = false);
              }
            },
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: appInputDecoration(context, label: 'Monto', icon: Icons.attach_money),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: appInputDecoration(context, label: 'Descripción', icon: Icons.description_outlined, hint: 'Ej: Pago de luz, Proveedor Coca-Cola'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performCashCut() async {
    if (_calculatedTotal == 0 && !_useManualInput) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el dinero contado antes de guardar')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final repo = ref.read(salesRepositoryProvider);
      final realCash = _calculatedTotal;
      final totalExpected = _expectedCash + _startingCash;
      final diff = realCash - totalExpected;

      // Convert Map<double, int> to Map<String, int> for JSON storage
      final denominationsJson = _counts.map((key, value) => MapEntry(key.toString(), value));

      await repo.saveCashCut(
        expectedCash: _expectedCash,
        startingCash: _startingCash,
        actualCash: realCash,
        difference: diff,
        denominations: denominationsJson,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Corte de caja registrado exitosamente'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isSaving = false;
          _counts.updateAll((key, value) => 0);
          _manualInputController.clear();
          _startingCashController.text = '0';
        });
        _loadTodayCashSales();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el corte: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final realCash = _calculatedTotal;
    final totalExpected = _expectedCash + _startingCash;
    final diff = realCash - totalExpected;
    final format = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Arqueo de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            actions: [
              TextButton.icon(
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error),
                label: const Text('Gasto', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadTodayCashSales,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAccountingHeader(format, totalExpected, realCash, diff),
                const SizedBox(height: 32),
                
                _buildSectionTitle('Configuración Inicial'),
                const SizedBox(height: 12),
                _buildStartingCashField(cs),
                const SizedBox(height: 32),

                _buildModeSelector(cs),
                const SizedBox(height: 24),
                
                if (_useManualInput)
                  _buildManualInputSection(cs)
                else ...[
                  _buildDenominationGrid('Billetes', _counts.keys.where((v) => v >= 20).toList()),
                  const SizedBox(height: 32),
                  _buildDenominationGrid('Monedas', _counts.keys.where((v) => v < 20).toList()),
                ],
                
                const SizedBox(height: 48),
                _buildFooterButton(),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingHeader(NumberFormat format, double expected, double real, double diff) {
    final cs = Theme.of(context).colorScheme;
    final color = diff == 0 ? AppTheme.success : (diff > 0 ? AppTheme.info : AppTheme.error);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryItem('Ventas Hoy', format.format(_expectedCash), Icons.sell_outlined, cs.primary)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryItem('Fondo Inicial', format.format(_startingCash), Icons.storefront_outlined, AppTheme.info)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DIFERENCIA TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(format.format(diff), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
                    ],
                  ),
                  Icon(diff == 0 ? Icons.check_circle_rounded : (diff > 0 ? Icons.add_circle_rounded : Icons.remove_circle_rounded), 
                       color: color, size: 48),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: expected == 0 ? 0 : (real / expected).clamp(0, 1),
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
                borderRadius: BorderRadius.circular(10),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStartingCashField(ColorScheme cs) {
    return TextField(
      controller: _startingCashController,
      keyboardType: TextInputType.number,
      decoration: appInputDecoration(context, 
        label: 'Fondo de Caja (Cambio inicial)', 
        icon: Icons.payments_outlined,
        hint: '0.00'),
    );
  }

  Widget _buildModeSelector(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _buildTab('Desglose', !_useManualInput, Icons.account_tree_outlined)),
          Expanded(child: _buildTab('Manual', _useManualInput, Icons.edit_document)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _useManualInput = label == 'Manual'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? cs.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildDenominationGrid(String title, List<double> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 16, mainAxisSpacing: 16),
          itemCount: values.length,
          itemBuilder: (context, i) => _buildCounterCard(values[i]),
        ),
      ],
    );
  }

  Widget _buildCounterCard(double value) {
    final cs = Theme.of(context).colorScheme;
    final qty = _counts[value] ?? 0;
    final format = NumberFormat.simpleCurrency(locale: 'es_MX', decimalDigits: value < 1 ? 2 : 0);
    
    final color = value == 1000 ? const Color(0xFF6A1B9A) :
                 value == 500 ? const Color(0xFF1565C0) :
                 value == 200 ? const Color(0xFF2E7D32) :
                 value == 100 ? const Color(0xFFC62828) :
                 value == 50 ? const Color(0xFFAD1457) :
                 value == 20 ? const Color(0xFF00695C) : cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: qty > 0 ? color : cs.outlineVariant.withValues(alpha: 0.3), width: qty > 0 ? 2 : 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(format.format(value), style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
              if (qty > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(format.format(value * qty), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleBtn(Icons.remove, () => _updateCount(value, -1), color, qty > 0),
              Text('$qty', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              _circleBtn(Icons.add, () => _updateCount(value, 1), color, true),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, Color color, bool enabled) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: enabled ? color : Colors.grey),
      ),
    );
  }

  void _updateCount(double val, int delta) {
    setState(() {
      _counts[val] = (_counts[val]! + delta).clamp(0, 9999);
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(title.toUpperCase(), 
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textMuted));
  }

  Widget _buildManualInputSection(ColorScheme cs) {
    return TextField(
      controller: _manualInputController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      decoration: appInputDecoration(context, label: 'Monto Contado', icon: Icons.payments, hint: '0.00'),
    );
  }

  Widget _buildFooterButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _performCashCut,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check_circle),
        label: Text(_isSaving ? 'Guardando...' : 'Finalizar Arqueo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
