import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../repositories/sales_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../widgets/animated_pressable.dart';
import '../dialogs/held_carts_dialog.dart';

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
        _expectedCash = (stats['todayCash'] as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  double get _calculatedTotal {
    if (_useManualInput) return (double.tryParse(_manualInputController.text) ?? 0.0);
    double total = 0;
    _counts.forEach((value, qty) => total += value * qty);
    return total;
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _startingCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final realCash = _calculatedTotal;
    final totalExpected = _expectedCash + _startingCash;
    final diff = realCash - totalExpected;
    final format = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDynamicSummary(format, totalExpected, realCash, diff),
                const SizedBox(height: 32),
                
                _buildConfigCard(isDark),
                const SizedBox(height: 32),

                _buildModeSelector(isDark),
                const SizedBox(height: 24),
                
                if (_useManualInput)
                  _buildManualInputSection(isDark)
                else ...[
                  _buildDenominationSection('Billetes', _counts.keys.where((v) => v >= 20).toList(), isDark),
                  const SizedBox(height: 32),
                  _buildDenominationSection('Monedas', _counts.keys.where((v) => v < 20).toList(), isDark),
                ],
                
                const SizedBox(height: 48),
                _buildFinalizeButton(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar.large(
      title: const Text('Cierre de Caja'),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        TextButton.icon(
          onPressed: _showAddExpenseDialog,
          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error, size: 18),
          label: const Text('GASTO', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadTodayCashSales),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDynamicSummary(NumberFormat format, double expected, double real, double diff) {
    final color = diff == 0 ? AppTheme.success : (diff > 0 ? AppTheme.info : AppTheme.error);
    
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: AppTheme.radiusLarge,
          border: Border.all(color: color.withOpacity(0.15), width: 2),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BALANCE DE CIERRE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(format.format(diff), style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, letterSpacing: -1.5)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(diff == 0 ? Icons.check_circle_rounded : (diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded), color: color, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _miniStat('Ventas', format.format(_expectedCash), AppTheme.primary),
                const SizedBox(width: 12),
                _miniStat('Fondo', format.format(_startingCash), AppTheme.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusMedium, boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIGURACIÓN INICIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          TextField(
            controller: _startingCashController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w900),
            decoration: const InputDecoration(
              labelText: 'Fondo inicial (Cambio)',
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _modeTab('DESGLOSE', !_useManualInput),
          _modeTab('MANUAL', _useManualInput),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool active) {
    return Expanded(
      child: AnimatedPressable(
        onTap: () => setState(() => _useManualInput = label == 'MANUAL'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildDenominationSection(String title, List<double> values, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.5)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220, 
            childAspectRatio: 1.8, 
            crossAxisSpacing: 12, 
            mainAxisSpacing: 12
          ),
          itemCount: values.length,
          itemBuilder: (context, i) => _DenominationCard(
            value: values[i], 
            count: _counts[values[i]] ?? 0, 
            onUpdate: (n) => _updateCount(values[i], n)
          ),
        ),
      ],
    );
  }

  void _updateCount(double val, int delta) {
    setState(() => _counts[val] = (_counts[val]! + delta).clamp(0, 9999));
  }

  Widget _buildManualInputSection(bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusLarge, boxShadow: AppTheme.softShadow),
        child: Column(
          children: [
            const Icon(Icons.edit_document, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            TextField(
              controller: _manualInputController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primary),
              decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
            ),
            const Text('MONTO TOTAL CONTADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: AnimatedPressable(
          onTap: _isSaving ? null : _performCashCut,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.radiusMedium,
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            alignment: Alignment.center,
            child: _isSaving 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('FINALIZAR Y CERRAR CAJA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  Future<void> _performCashCut() async {
    if (_calculatedTotal == 0 && !_useManualInput) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el dinero contado')));
       return;
    }
    setState(() => _isSaving = true);
    try {
      final realCash = _calculatedTotal;
      final totalExpected = _expectedCash + _startingCash;
      final diff = realCash - totalExpected;
      await ref.read(salesRepositoryProvider).saveCashCut(
        expectedCash: _expectedCash,
        startingCash: _startingCash,
        actualCash: realCash,
        difference: diff,
        denominations: _counts.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Corte registrado'), backgroundColor: AppTheme.success));
        setState(() {
          _isSaving = false;
          _counts.updateAll((k, v) => 0);
          _manualInputController.clear();
        });
        _loadTodayCashSales();
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddExpenseDialog() async {
    final amountC = TextEditingController();
    final descC = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AppDialog(
        headerIcon: Icons.money_off_rounded,
        headerColor: AppTheme.error,
        title: 'Registrar Gasto',
        subtitle: 'El monto se descontará del efectivo esperado',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
              const SizedBox(height: 16),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Motivo / Descripción')),
            ],
          ),
        ),
        footer: AppDialogFooterButtons(
          actionLabel: 'REGISTRAR GASTO',
          actionIcon: Icons.check_circle_rounded,
          actionColor: AppTheme.error,
          onAction: () async {
            if (amountC.text.isNotEmpty) {
              await ref.read(salesRepositoryProvider).createExpense(
                amount: double.parse(amountC.text), 
                description: descC.text
              );
              if (context.mounted) { 
                Navigator.pop(context); 
                _loadTodayCashSales(); 
              }
            }
          },
        ),
      ),
    );
  }
}

class _DenominationCard extends StatelessWidget {
  final double value;
  final int count;
  final Function(int) onUpdate;

  const _DenominationCard({required this.value, required this.count, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final color = value >= 1000 ? const Color(0xFF6A1B9A) :
                 value >= 500 ? const Color(0xFF1565C0) :
                 value >= 200 ? const Color(0xFF2E7D32) :
                 value >= 100 ? const Color(0xFFC62828) :
                 value >= 50 ? const Color(0xFFAD1457) :
                 value >= 20 ? const Color(0xFF00695C) : AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: count > 0 ? color.withOpacity(0.3) : AppTheme.divider.withOpacity(0.5), width: count > 0 ? 2 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$$value', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
              if (count > 0)
                FadeIn(duration: const Duration(milliseconds: 200), child: Text('\$${(value * count).toStringAsFixed(0)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _btn(Icons.remove_rounded, () => onUpdate(-1), count > 0),
              Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              _btn(Icons.add_rounded, () => onUpdate(1), true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, bool enabled) {
    return AnimatedPressable(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: (enabled ? AppTheme.primary : AppTheme.textMuted).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: enabled ? AppTheme.primary : AppTheme.textMuted),
      ),
    );
  }
}
