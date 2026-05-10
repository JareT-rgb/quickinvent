import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/cart_notifier.dart';
import '../providers/products_provider.dart';
import '../repositories/sales_repository.dart';
import '../models/sale_detail_item.dart';
import '../models/cart_item.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/app_dialog.dart';
import '../theme/app_theme.dart';
import 'ticket_dialog.dart';
import '../providers/customers_provider.dart';
import '../models/customer.dart';
import '../providers/app_settings_provider.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final VoidCallback onComplete;

  const CheckoutDialog({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.onComplete,
  });

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  bool _isProcessing = false;
  String _paymentMethod = 'Efectivo';
  Customer? _selectedCustomer;
  
  // Terminal connection state
  bool _terminalSuccess = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  double get _received => double.tryParse(_amountController.text) ?? 0.0;
  double get _change => _received - widget.totalAmount;
  bool get _hasEnough => _amountController.text.isNotEmpty && _received >= widget.totalAmount;
  bool get _isElectronic => _paymentMethod == 'Tarjeta' || _paymentMethod == 'Transferencia';

  Future<void> _processPayment() async {
    if (!_isElectronic && _paymentMethod != 'Crédito') {
      if (_amountController.text.isEmpty) { _showError('Ingrese el monto recibido'); return; }
      if (!_hasEnough) { _showError('Monto insuficiente'); return; }
    }
    if (_paymentMethod == 'Crédito' && _selectedCustomer == null) {
      _showError('Seleccione un cliente para crédito'); return;
    }

    setState(() => _isProcessing = true);

    try {
      final items = widget.cartItems.map((item) => SaleDetailItem(
        productId: item.product.id,
        productName: item.product.name,
        quantity: item.quantity,
        priceAtSale: item.product.price,
        costPriceAtSale: item.product.costPrice,
        subtotal: item.subtotal,
      )).toList();

      final sale = await ref.read(salesRepositoryProvider).createSale(
        totalAmount: widget.totalAmount,
        paymentMethod: _paymentMethod,
        receivedAmount: (_paymentMethod == 'Crédito' || _isElectronic) ? widget.totalAmount : _received,
        change: (_paymentMethod == 'Crédito' || _isElectronic) ? 0.0 : _change,
        items: items,
        customerId: _selectedCustomer?.id,
      );

      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(productsProvider);
      ref.invalidate(customersProvider);

      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        showDialog(context: context, barrierDismissible: false, builder: (context) => TicketDialog(sale: sale));
      }
    } catch (e) {
      if (mounted) _showError('Error en el pago: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppDialog(
      headerIcon: Icons.point_of_sale_rounded,
      headerColor: AppTheme.primary,
      title: 'Centro de Pagos',
      subtitle: 'Gestiona el cobro y la conexión con terminal',
      canClose: !_isProcessing,
      maxWidth: 850,
      footer: _buildFooter(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 650;
          return Column(
            children: [
              _buildHeaderTotals(theme, cs),
              Expanded(
                child: isWide 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildPaymentForm())),
                        VerticalDivider(width: 1, color: theme.dividerColor.withOpacity(0.1)),
                        Expanded(flex: 3, child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildSummarySection())),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [_buildPaymentForm(), const SizedBox(height: 24), _buildSummarySection()]),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderTotals(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.05)))),
      child: Row(
        children: [
          Expanded(child: _buildTotalCard('TOTAL A COBRAR', widget.totalAmount, AppTheme.primary, AppTheme.primary.withOpacity(0.05))),
          const SizedBox(width: 16),
          Expanded(
            child: _paymentMethod == 'Efectivo' 
              ? _buildTotalCard(_amountController.text.isEmpty ? 'CAMBIO' : (_hasEnough ? 'CAMBIO' : 'FALTA'), _change.abs(), 
                  _amountController.text.isEmpty ? theme.hintColor : (_hasEnough ? Colors.green : cs.error), 
                  _amountController.text.isEmpty ? theme.dividerColor.withOpacity(0.05) : (_hasEnough ? Colors.green.withOpacity(0.05) : cs.errorContainer.withOpacity(0.1)))
              : _buildTotalCard('MÉTODO ACTIVO', 0, Colors.blue, Colors.blue.withOpacity(0.05), isElectronic: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, double value, Color color, Color bgColor, {bool isElectronic = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2), width: 1.5)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              isElectronic ? _paymentMethod.toUpperCase() : '\$${value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _paymentMethod,
          decoration: appInputDecoration(context, label: 'Seleccionar Método', icon: Icons.payments_rounded),
          items: ['Efectivo', 'Tarjeta', 'Transferencia', 'Crédito']
              .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold))))
              .toList(),
          onChanged: (val) {
            setState(() {
              _paymentMethod = val ?? 'Efectivo';
              if (_isElectronic) {
                _amountController.text = widget.totalAmount.toStringAsFixed(2);
              } else {
                _amountController.text = '';
              }
            });
          },
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildDynamicPaymentWidget(),
        ),
      ],
    );
  }

  Widget _buildDynamicPaymentWidget() {
    if (_paymentMethod == 'Tarjeta') return _buildTerminalBridge();
    if (_paymentMethod == 'Transferencia') return _buildQRGenerator();
    if (_paymentMethod == 'Crédito') return _buildCustomerSelector();
    return _buildCashFlow();
  }

  Widget _buildTerminalBridge() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.1))),
      child: Column(
        children: [
          const Icon(Icons.contactless_rounded, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('ESPERANDO TERMINAL', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue)),
          const SizedBox(height: 8),
          const Text('Procesa el cobro en tu terminal física.', style: TextStyle(fontSize: 12, color: Colors.blue)),
          const SizedBox(height: 24),
          if (!_terminalSuccess) ...[
            const LinearProgressIndicator(backgroundColor: Colors.transparent),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _terminalSuccess = true),
              icon: const Icon(Icons.check),
              label: const Text('Confirmar pago en terminal'),
            ),
          ] else
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('PAGO CONFIRMADO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))],
            ),
        ],
      ),
    );
  }

  Widget _buildQRGenerator() {
    final settings = ref.watch(appSettingsProvider);
    
    // Create a real payment URI if settings are available, otherwise generic
    String qrData;
    if (settings.transferAccount.isNotEmpty) {
      // Format: Transferencia [Banco] - [CLABE] - [Nombre]
      qrData = 'transfer:${settings.transferAccount}?bank=${settings.transferBank}&name=${settings.transferName}&amount=${widget.totalAmount}&ref=QuickInvent';
    } else {
      qrData = 'https://quickinvent.app/setup-payment'; // Fallback
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withOpacity(0.1))),
      child: Column(
        children: [
          if (settings.transferAccount.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('⚠️ Configura tus datos en Ajustes', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 180.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primary),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          if (settings.transferAccount.isNotEmpty) ...[
            Text(settings.transferBank, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
            Text(settings.transferAccount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(settings.transferName, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ] else
            const Text('PAGO POR TRANSFERENCIA', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Consumer(builder: (context, ref, child) {
      final customersAsync = ref.watch(customersProvider);
      return customersAsync.when(
        data: (customers) => DropdownButtonFormField<Customer>(
          initialValue: _selectedCustomer,
          decoration: appInputDecoration(context, label: 'Cliente de Crédito', icon: Icons.person_search),
          items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          onChanged: (val) => setState(() => _selectedCustomer = val),
        ),
        loading: () => const LinearProgressIndicator(),
        error: (error, stackTrace) => const Text('Error al cargar clientes'),
      );
    });
  }

  Widget _buildCashFlow() {
    final theme = Theme.of(context);
    final platform = theme.platform;
    final isPC = platform == TargetPlatform.windows || platform == TargetPlatform.linux || platform == TargetPlatform.macOS;
    final isMobile = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    
    return Column(
      children: [
        _buildQuickCashButtons(),
        const SizedBox(height: 24),
        TextFormField(
          controller: _amountController,
          keyboardType: isPC ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.none,
          showCursor: true,
          readOnly: !isPC,
          autofocus: isPC,
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1),
          textAlign: TextAlign.center,
          decoration: appInputDecoration(context, label: 'Efectivo Recibido', icon: Icons.monetization_on_rounded, hint: '0.00'),
          onChanged: (_) => setState(() {}),
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          SizedBox(height: 260, child: NumericKeypad(controller: _amountController, onChange: () => setState(() {}))),
        ],
      ],
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.receipt_rounded, size: 18, color: theme.hintColor), const SizedBox(width: 8), Text('DETALLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.hintColor))]),
        const SizedBox(height: 16),
        ...widget.cartItems.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Text('${item.quantity}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
        )),
      ],
    );
  }

  Widget _buildQuickCashButtons() {
    final denominations = [20, 50, 100, 200, 500, 1000];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        _buildCashButton('Exacto', widget.totalAmount, isExact: true),
        ...denominations.map((d) => _buildCashButton('\$$d', d.toDouble())),
      ],
    );
  }

  Widget _buildCashButton(String label, double value, {bool isExact = false}) {
    final theme = Theme.of(context);
    final isSelected = _received == value;
    return InkWell(
      onTap: () => setState(() => _amountController.text = value.toStringAsFixed(0)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : (isExact ? AppTheme.primary.withOpacity(0.1) : theme.cardColor),
          borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected || isExact ? AppTheme.primary : theme.dividerColor.withOpacity(0.1)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : (isExact ? AppTheme.primary : theme.textTheme.bodyLarge?.color), fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }

  Widget _buildFooter() {
    final isReady = _isElectronic || _paymentMethod == 'Crédito' || _hasEnough;
    return Container(
      width: double.infinity, height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: (_isProcessing || !isReady) ? [Colors.grey.shade400, Colors.grey.shade500] : AppTheme.primaryGradient.colors),
      ),
      child: FilledButton(
        onPressed: (_isProcessing || !isReady) ? null : _processPayment,
        style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            else Icon(_paymentMethod == 'Tarjeta' ? Icons.terminal_rounded : (_paymentMethod == 'Transferencia' ? Icons.qr_code_2_rounded : Icons.check_circle_rounded), size: 24),
            const SizedBox(width: 14),
            Text(_isProcessing ? 'PROCESANDO...' : 'FINALIZAR VENTA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
