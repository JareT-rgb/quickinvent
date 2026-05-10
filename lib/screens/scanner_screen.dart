import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../repositories/products_repository.dart';
import '../dialogs/edit_product_dialog.dart';
import '../utils/safe_haptic.dart';


class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.all],
  );

  bool _isProcessing = false;
  bool _auditMode = false; // Toggle between POS and Audit
  String? _detectedCode;
  Map<String, dynamic>? _lastProduct;
  RealtimeChannel? _feedbackSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentScanQty = 1;
  RealtimeChannel? _presenceChannel;
  bool _isConnected = false;
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _setupFeedbackListener();
    _setupPresence();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _setupPresence() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final channelName = 'scanner_bridge:$userId';
    _presenceChannel = client.channel(channelName);

    _presenceChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        setState(() => _isConnected = true);
        _presenceChannel!.track({
          'device': 'mobile_scanner',
          'at': DateTime.now().toIso8601String(),
          'mode': _auditMode ? 'audit' : 'pos',
        });
      } else {
        setState(() => _isConnected = false);
      }
    });
  }

  void _setupFeedbackListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _feedbackSubscription = Supabase.instance.client
        .channel('public:barcode_scans_feedback')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'barcode_scans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status'] as String?;
            final productName = payload.newRecord['product_name'] as String?;
            final stock = payload.newRecord['stock_quantity'] as num?;
            final price = payload.newRecord['price'] as num?;
            final barcode = payload.newRecord['barcode'] as String?;
            
            // SEGURIDAD: Solo procesamos si coincide con lo que estamos viendo
            if (barcode != _detectedCode) return;

            if (status != null && status != 'pending') {
              // Si ya lo encontramos localmente con éxito, no dejamos que un "not_found" del server lo borre
              if (_lastProduct?['status'] == 'success' && status == 'not_found') {
                return;
              }

              setState(() {
                _lastProduct = {
                  'name': productName ?? _lastProduct?['name'],
                  'stock': stock ?? _lastProduct?['stock'],
                  'price': price ?? _lastProduct?['price'],
                  'barcode': barcode,
                  'status': status,
                  'full_product': _lastProduct?['full_product'],
                };
              });
              _provideFeedback(status);
            }
          },
        )
        .subscribe();
  }

  void _provideFeedback(String status) {
    if (!mounted) return;
    switch (status) {
      case 'success':
        SafeHaptic.lightImpact();
        break;
      case 'not_found':
        SafeHaptic.vibrate();
        break;
      case 'out_of_stock':
        SafeHaptic.heavyImpact();
        break;
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty && code != _detectedCode) {
        setState(() {
          _detectedCode = code;
        });
        SafeHaptic.selectionClick();
      }
    }
  }

  Future<void> _processDetectedCode() async {
    if (_detectedCode == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastProduct = null;
      _currentScanQty = 1;
    });

    try {
      // Play beep sound (don't await so it doesn't block processing)
      // On web, this might throw UnimplementedError if not handled carefully
      try {
        _audioPlayer.play(UrlSource('https://www.soundjay.com/buttons/button-09a.mp3')).catchError((_) => null);
      } catch (_) {
        // Silently ignore if audio fails
      }

      // Buscamos el producto localmente para asegurar que la info sea correcta y evitar errores falsos
      final product = await ref.read(productsRepositoryProvider).getProductByBarcode(_detectedCode!);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (product != null) {
        setState(() {
          _lastProduct = {
            'id': product.id,
            'name': product.name,
            'stock': product.stockQuantity,
            'price': product.price,
            'barcode': product.barcode,
            'status': 'success',
            'full_product': product,
          };
        });
        
        if (!_auditMode && userId != null) {
          // En modo POS, enviamos el primer scan con delta explícito
          await Supabase.instance.client.from('barcode_scans').insert({
            'barcode': _detectedCode,
            'user_id': userId,
            'quantity': _currentScanQty,
            'processed': false,
            'status': 'pending',
          });
        }
        _provideFeedback('success');
      } else {
        // Solo si realmente no existe en la DB mostramos el error
        setState(() {
          _lastProduct = {
            'name': null,
            'barcode': _detectedCode,
            'status': 'not_found',
          };
        });
        _provideFeedback('not_found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _controller.dispose();
    _feedbackSubscription?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          
          // Scanner Overlay with Laser
          _buildScannerOverlay(),

          // Manual Scan Trigger Button
          _buildManualScanButton(),

          // Top Toolbar
          _buildTopToolbar(),

          // Product Info Card (Bottom)
          if (_lastProduct != null)
            Positioned(
              bottom: 40, left: 16, right: 16,
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: _buildProductCard(),
              ),
            ),
          
          if (_isProcessing && _lastProduct == null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.black54),
                  child: const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualScanButton() {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 320),
          GestureDetector(
            onTap: _processDetectedCode,
            child: _buildScanPill(),
          ),
          if (_detectedCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FadeIn(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Detectado: $_detectedCode',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanPill() {
    final hasCode = _detectedCode != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: hasCode ? AppTheme.primaryGradient : null,
        color: hasCode ? null : Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          if (hasCode)
            BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, spreadRadius: 1),
        ],
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasCode ? Icons.barcode_reader : Icons.center_focus_weak, 
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            hasCode ? 'TOMAR CÓDIGO' : 'BUSCANDO CÓDIGO...',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: FadeInDown(
        child: Row(
          children: [
            // Exit Button (Left)
            _CircleButton(
              icon: Icons.close_rounded, 
              onTap: () async {
                await _controller.stop();
                if (mounted) Navigator.pop(context);
              },
              isGlass: true,
            ),
            
            const Spacer(),
            
            // Mode Indicator (Center)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.glassDecoration(isDark: true).copyWith(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _auditMode ? Icons.inventory_2_rounded : Icons.shopping_cart_rounded, 
                    size: 14, color: AppTheme.primaryLight
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _auditMode ? 'AUDITORÍA' : 'POS',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: _auditMode,
                      onChanged: (val) {
                        setState(() {
                          _auditMode = val;
                          _lastProduct = null;
                        });
                        _presenceChannel?.track({
                          'device': 'mobile_scanner',
                          'at': DateTime.now().toIso8601String(),
                          'mode': val ? 'audit' : 'pos',
                        });
                      },
                      activeColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Camera Tools (Right)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppTheme.glassDecoration(isDark: true).copyWith(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.flash_on_rounded, 
                    onTap: () => _controller.toggleTorch(),
                    isGlass: false, // Inside glass container
                    isSmall: true,
                  ),
                  const SizedBox(width: 4),
                  _CircleButton(
                    icon: Icons.flip_camera_ios, 
                    onTap: () => _controller.switchCamera(),
                    isGlass: false, // Inside glass container
                    isSmall: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    final status = _lastProduct!['status'];
    final isError = status == 'not_found' || status == 'out_of_stock';
    final product = _lastProduct!['full_product'] as Product?;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(isDark: false).copyWith(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withOpacity(0.95),
        boxShadow: AppTheme.deepShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isError ? AppTheme.error : AppTheme.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.warning_rounded : Icons.check_circle_rounded, 
                  color: isError ? AppTheme.error : AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastProduct!['name'] ?? 'Código: ${_lastProduct!['barcode']}', 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    if (!isError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          'Stock: ${_lastProduct!['stock']} • \$${_lastProduct!['price']}', 
                          style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    if (isError)
                      Text(
                        status == 'not_found' ? 'Producto no registrado' : 'Sin existencias disponibles', 
                        style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              if (_auditMode && !isError)
                _CircleButton(
                  icon: Icons.close_rounded, 
                  onTap: () => setState(() {
                    _lastProduct = null;
                    _detectedCode = null;
                  }),
                  isSmall: true,
                ),
            ],
          ),
          if (!isError && !_auditMode) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildQuantitySelector()),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'BORRAR',
                  color: AppTheme.error,
                  onTap: () {
                    _updateRemoteQty(-999);
                    setState(() {
                      _lastProduct = null;
                      _detectedCode = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickAction('+5', 5),
                  const SizedBox(width: 10),
                  _buildQuickAction('+10', 10),
                  const SizedBox(width: 10),
                  _buildQuickAction('+20', 20),
                  const SizedBox(width: 10),
                  _buildQuickAction('+50', 50),
                ],
              ),
            ),
          ],
          if (_auditMode && !isError && product != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openEditDialog(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text('EDITAR PRODUCTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openEditDialog(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProductDialog(product: product),
    );
    
    if (result == true) {
      // Si se editó con éxito, actualizamos la vista local
      final updatedProduct = await ref.read(productsRepositoryProvider).getProductByBarcode(product.barcode!);
      if (updatedProduct != null && mounted) {
        setState(() {
          _lastProduct = {
            'id': updatedProduct.id,
            'name': updatedProduct.name,
            'stock': updatedProduct.stockQuantity,
            'price': updatedProduct.price,
            'barcode': updatedProduct.barcode,
            'status': 'success',
            'full_product': updatedProduct,
          };
        });
      }
    }
  }

  Future<void> _updateRemoteQty(int delta) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _lastProduct == null) return;
    
    SafeHaptic.selectionClick();
    await Supabase.instance.client.from('barcode_scans').insert({
      'barcode': _lastProduct!['barcode'],
      'user_id': userId,
      'quantity': delta,
      'processed': false,
      'status': 'pending', // Esencial para que el POS lo procese
    });
  }

  Widget _buildScannerOverlay() {
    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: Colors.transparent,
                  overlayColor: Colors.black.withOpacity(0.6),
                  borderRadius: 30,
                  borderLength: 0,
                  borderWidth: 0,
                  cutOutSize: MediaQuery.of(context).size.width * 0.75,
                ),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.width * 0.75,
                child: CustomPaint(
                  painter: ScannerVisorPainter(
                    color: AppTheme.primary,
                    laserPosition: _laserController.value,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QtyControl(
            icon: Icons.remove_rounded,
            onTap: () {
              if (_currentScanQty > 1) {
                setState(() => _currentScanQty--);
                _updateRemoteQty(-1);
              }
            },
          ),
          Expanded(
            child: InkWell(
              onTap: _showManualQuantityDialog,
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Text(
                    '$_currentScanQty',
                    key: ValueKey(_currentScanQty),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ),
              ),
            ),
          ),
          _QtyControl(
            icon: Icons.add_rounded,
            onTap: () {
              setState(() => _currentScanQty++);
              _updateRemoteQty(1);
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, int delta) {
    return InkWell(
      onTap: () {
        setState(() => _currentScanQty += delta);
        _updateRemoteQty(delta);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  void _showManualQuantityDialog() {
    final controller = TextEditingController(text: _currentScanQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar Cantidad'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? 1;
              if (newQty > 0) {
                final delta = newQty - _currentScanQty;
                setState(() => _currentScanQty = newQty);
                if (delta != 0) _updateRemoteQty(delta);
              }
              Navigator.pop(context);
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _QtyControl({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppTheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: isPrimary ? Colors.white : AppTheme.primary),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isGlass;
  final bool isSmall;

  const _CircleButton({
    required this.icon, 
    required this.onTap, 
    this.isGlass = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 8 : 12),
        decoration: isGlass 
            ? AppTheme.glassDecoration(isDark: true).copyWith(shape: BoxShape.circle)
            : const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: isSmall ? 18 : 22),
      ),
    );
  }
}

class _QuickQtyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _QuickQtyButton({required this.label, required this.onTap, this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }
    return _getLeftTopPath(rect)..lineTo(rect.right, rect.bottom)..lineTo(rect.left, rect.bottom)..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderOffset ? cutOutSize / 2 + borderOffset : borderLength;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width;

    final backgroundPaint = Paint()..color = overlayColor..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth;
    final boxPaint = Paint()..color = borderColor..style = PaintingStyle.fill..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    canvas..saveLayer(rect, backgroundPaint)..drawRect(rect, backgroundPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.right - _borderLength, cutOutRect.top, cutOutRect.right, cutOutRect.top + _borderLength, topRight: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.left, cutOutRect.top, cutOutRect.left + _borderLength, cutOutRect.top + _borderLength, topLeft: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.right - _borderLength, cutOutRect.bottom - _borderLength, cutOutRect.right, cutOutRect.bottom, bottomRight: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.left, cutOutRect.bottom - _borderLength, cutOutRect.left + _borderLength, cutOutRect.bottom, bottomLeft: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)), boxPaint)..restore();
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(borderColor: borderColor, borderWidth: borderWidth, overlayColor: overlayColor);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  const _ConnectionIndicator({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isConnected ? AppTheme.primary : AppTheme.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppTheme.primary : AppTheme.error,
              boxShadow: [
                if (isConnected) BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'CONECTADO' : 'SIN RED',
            style: TextStyle(
              color: isConnected ? AppTheme.primary : AppTheme.error,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerVisorPainter extends CustomPainter {
  final Color color;
  final double laserPosition;

  ScannerVisorPainter({required this.color, required this.laserPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerSize = 40.0;
    final path = Path();

    // Top Left
    path.moveTo(0, cornerSize);
    path.lineTo(0, 0);
    path.lineTo(cornerSize, 0);

    // Top Right
    path.moveTo(size.width - cornerSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerSize);

    // Bottom Right
    path.moveTo(size.width, size.height - cornerSize);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerSize, size.height);

    // Bottom Left
    path.moveTo(cornerSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerSize);

    canvas.drawPath(path, paint);

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    // Laser Line
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0), color, color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, size.height * laserPosition - 0.5, size.width, 1))
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(0, size.height * laserPosition),
      Offset(size.width, size.height * laserPosition),
      laserPaint,
    );

    // Laser Glow
    final laserGlowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * laserPosition - 5, size.width, 10),
      laserGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerVisorPainter oldDelegate) => 
      oldDelegate.laserPosition != laserPosition || oldDelegate.color != color;
}
