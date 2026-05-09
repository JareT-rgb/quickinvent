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

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
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
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty && code != _detectedCode) {
        setState(() {
          _detectedCode = code;
        });
        HapticFeedback.selectionClick();
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
      _audioPlayer.play(UrlSource('https://www.soundjay.com/buttons/button-09a.mp3')).catchError((e) {
        HapticFeedback.lightImpact();
        return null;
      });

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
          // En modo POS, enviamos el primer scan para que el backend lo procese
          await Supabase.instance.client.from('barcode_scans').insert({
            'barcode': _detectedCode,
            'user_id': userId,
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
    _controller.dispose();
    _feedbackSubscription?.unsubscribe();
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
          
          // Custom Overlay
          _buildScannerOverlay(),

          // Manual Scan Trigger Button
          _buildManualScanButton(),

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
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 5),
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
          const SizedBox(height: 250), // Position below the cutout
          GestureDetector(
            onTap: _processDetectedCode,
            child: ZoomIn(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: _detectedCode != null ? AppTheme.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    if (_detectedCode != null)
                      BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _detectedCode != null ? Icons.barcode_reader : Icons.center_focus_weak, 
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _detectedCode != null ? 'TOMAR CÓDIGO' : 'APUNTE AL CÓDIGO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_detectedCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FadeIn(
                child: Text(
                  'Detectado: $_detectedCode',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
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
    final product = _lastProduct!['full_product'] as Product?;
    
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
              if (_auditMode && !isError)
                IconButton(
                  onPressed: () => setState(() => _lastProduct = null),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                ),
            ],
          ),
          if (!isError && !_auditMode) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuantitySelector(),
                _QuickQtyButton(
                  label: 'Eliminar', 
                  color: AppTheme.error, 
                  onTap: () {
                    _updateRemoteQty(-_currentScanQty);
                    setState(() => _lastProduct = null);
                  },
                ),
              ],
            ),
          ],
          if (_auditMode && !isError && product != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openEditDialog(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
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

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$_currentScanQty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
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
