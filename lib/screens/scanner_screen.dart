import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.all],
  );

  bool _isProcessing = false;
  bool _auditMode = false; // Toggle between POS and Audit
  Map<String, dynamic>? _lastProduct;
  RealtimeChannel? _feedbackSubscription;

  @override
  void initState() {
    super.initState();
    _setupFeedbackListener();
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
            
            if (status != null && status != 'pending') {
              setState(() {
                _lastProduct = {
                  'name': productName,
                  'stock': stock,
                  'price': price,
                  'barcode': payload.newRecord['barcode'],
                  'status': status,
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
        HapticFeedback.lightImpact();
        break;
      case 'not_found':
        HapticFeedback.vibrate();
        break;
      case 'out_of_stock':
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _isProcessing = true;
          _lastProduct = null;
        });

        try {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await Supabase.instance.client.from('barcode_scans').insert({
              'barcode': code,
              'user_id': userId,
              'processed': false,
              'mode': _auditMode ? 'audit' : 'pos',
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al enviar escaneo: $e'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          debugPrint('Error: $e');
        } finally {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _isProcessing = false);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _feedbackSubscription?.unsubscribe();
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
          
          // Custom Overlay
          _buildScannerOverlay(),

          // Top Toolbar
          _buildTopToolbar(),

          // Product Info Card (Bottom)
          if (_lastProduct != null)
            Positioned(
              bottom: 40, left: 20, right: 20,
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: _buildProductCard(),
              ),
            ),
          
          if (_isProcessing && _lastProduct == null)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 50, left: 20, right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(icon: Icons.flash_on, onTap: () => _controller.toggleTorch()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
            child: Row(
              children: [
                Icon(_auditMode ? Icons.inventory_2 : Icons.shopping_cart, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(_auditMode ? 'MODO AUDITORÍA' : 'MODO POS', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _auditMode,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _auditMode = v),
                ),
              ],
            ),
          ),
          _CircleButton(icon: Icons.flip_camera_ios, onTap: () => _controller.switchCamera()),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    final status = _lastProduct!['status'];
    final isError = status == 'not_found' || status == 'out_of_stock';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isError ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(isError ? Icons.warning_rounded : Icons.check_circle_rounded, color: isError ? AppTheme.error : AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lastProduct!['name'] ?? 'Código: ${_lastProduct!['barcode']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                    if (!isError)
                      Text('Stock: ${_lastProduct!['stock']} unidades • \$${_lastProduct!['price']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (isError)
                      Text(status == 'not_found' ? 'Producto no registrado' : 'Sin existencias disponibles', style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (!isError && !_auditMode) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickQtyButton(label: '+1', onTap: () => _updateRemoteQty(1)),
                _QuickQtyButton(label: '+5', onTap: () => _updateRemoteQty(5)),
                _QuickQtyButton(label: 'Eliminar', color: AppTheme.error, onTap: () => _updateRemoteQty(-1)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateRemoteQty(int delta) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _lastProduct == null) return;
    
    HapticFeedback.selectionClick();
    await Supabase.instance.client.from('barcode_scans').insert({
      'barcode': _lastProduct!['barcode'],
      'user_id': userId,
      'quantity_delta': delta,
      'processed': false,
    });
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: AppTheme.primary,
          borderRadius: 20,
          borderLength: 40,
          borderWidth: 8,
          cutOutSize: MediaQuery.of(context).size.width * 0.75,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
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
        side: BorderSide(color: color.withValues(alpha: 0.5)),
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
